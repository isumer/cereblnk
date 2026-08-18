"""shellwrite — which files does this shell command write? (CB-123)

DelegationGuard was registered on the edit tools only. A shell
redirection reaches the same files under no delegation check, and a
blocked run said so out loud before taking that route: "I will write
the setup files from the command line to avoid the hook blocks."

Reads a PreToolUse hook payload on stdin. Emits, on stdout:

    (nothing)   no write intent — the command only reads, and the
                guard lets it through
    <path>...   one candidate target per line, checked against the
                same conductor-ownership table the edit path uses
    ?           write intent whose target cannot be resolved — the
                guard treats it as a conductor edit and blocks

WHAT THIS IS NOT. It is a floor, not a proof. A command can write a
file in ways no token walk will see: a script that redirects
internally, a base64 round trip, an editor invocation, an obfuscated
interpreter one-liner. Anything determined to get around this will.
The claim is bounded to what it detects: the ordinary write forms a
model actually reaches for when a Write is refused. It raises the cost
of the bypass from zero; it does not close it, and the changelog says
so rather than implying more.

The bias is deliberate: unresolved targets block, unknown utilities do
not. A guard that blocks every unrecognised command stops the
conductor from running `detect-stack`, `select-agents`, `run-quiet`
and git, all of which run-discipline requires it to run.
"""
import json
import shlex
import sys

# Redirection operators that create or extend a file. `>&` (as in
# `2>&1`) duplicates a descriptor and is deliberately absent.
WRITE_REDIR = {">", ">>", ">|"}

# Redirection targets that are not files anyone owns.
SINKS = {"/dev/null", "/dev/stdout", "/dev/stderr", "/dev/tty", "/dev/fd"}

# Utilities whose target is the LAST non-flag operand.
LAST_OPERAND = {"cp", "mv", "install", "rsync"}

# Utilities whose targets are EVERY non-flag operand.
ALL_OPERANDS = {"tee", "touch", "truncate"}

# Utilities that edit named files in place, but only under a flag.
IN_PLACE = {"sed": ("-i",), "perl": ("-i",), "ruby": ("-i",)}

# Utilities that write somewhere this walk cannot name.
OPAQUE = {"patch", "ed", "vi", "vim", "nano", "emacs", "dd", "tar", "unzip"}

# Nested shells: the code string is a shell command, so read it as one
# rather than guessing at it.
NESTED_SHELL = {"sh", "bash", "zsh", "dash"}

# Other inline-code interpreters: opaque only when the code names a
# write. The hint list stays narrow on purpose — `print(` and a bare
# `>` would make `python3 -c "print(a > b)"` a blocked command, and a
# guard that blocks arithmetic is one the conductor learns to route
# around.
INLINE = {"python", "python3", "py", "perl", "node", "ruby",
          "powershell", "pwsh", "awk"}
INLINE_FLAGS = {"-c", "-e", "-Command", "--command"}
WRITE_HINTS = ("open(", ".write", "writeFile", "writeFileSync",
               "Set-Content", "Out-File", "shutil.copy", "shutil.move",
               "os.rename", "os.replace", "File.write", "write_text")

# Command separators: what follows starts a new command head.
SEPARATORS = {"|", "||", "&&", ";", "&", "|&", "(", ")", "{", "}", "\n"}

UNRESOLVED = "?"


def _looks_like_flag(tok):
    return tok.startswith("-") and tok != "-"


def targets(command):
    """Yield write targets for a shell command, or UNRESOLVED."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        toks = list(lexer)
    except ValueError:
        # Unbalanced quoting: the command cannot be read, so its writes
        # cannot be ruled out. Same posture as unparseable hook input.
        return [UNRESOLVED]

    found, head, operands, i = [], None, [], 0

    def flush():
        if head in LAST_OPERAND:
            plain = [o for o in operands if not _looks_like_flag(o)]
            if plain:
                found.append(plain[-1])
            else:
                found.append(UNRESOLVED)
        elif head in ALL_OPERANDS:
            found.extend(o for o in operands if not _looks_like_flag(o))
        elif head in IN_PLACE:
            if any(o.startswith(IN_PLACE[head]) for o in operands
                   if _looks_like_flag(o)):
                plain = [o for o in operands if not _looks_like_flag(o)]
                # sed -i 's/x/y/' file  — the script is an operand too,
                # so every plain operand past the first is a candidate.
                found.extend(plain[1:] or [UNRESOLVED])
        elif head in NESTED_SHELL:
            for j, o in enumerate(operands):
                if o in INLINE_FLAGS and j + 1 < len(operands):
                    found.extend(targets(operands[j + 1]))
                    break
        elif head in INLINE:
            for j, o in enumerate(operands):
                if o in INLINE_FLAGS and j + 1 < len(operands):
                    if any(h in operands[j + 1] for h in WRITE_HINTS):
                        found.append(UNRESOLVED)
                    break
        elif head in OPAQUE:
            found.append(UNRESOLVED)
        elif head == "git" and operands[:1] in (["apply"], ["checkout"]):
            found.append(UNRESOLVED)

    while i < len(toks):
        tok = toks[i]
        if tok in WRITE_REDIR:
            if i + 1 < len(toks):
                nxt = toks[i + 1]
                if nxt not in SINKS and not nxt.startswith("/dev/fd"):
                    found.append(nxt)
                i += 2
                continue
            found.append(UNRESOLVED)
            i += 1
            continue
        if tok in SEPARATORS:
            flush()
            head, operands = None, []
            i += 1
            continue
        if head is None:
            head = tok.rsplit("/", 1)[-1]
        else:
            operands.append(tok)
        i += 1
    flush()
    # No collapse to a single UNRESOLVED: the caller checks every target
    # and stops at the first one the conductor does not own, and "?"
    # matches no ownership glob, so a mixed list blocks on its own. A
    # collapse here changed no outcome and no test could kill it.
    return found


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not command.strip():
        return 0
    for t in targets(command):
        # $CB_DIR and ${CB_DIR} are never expanded in the payload — the
        # command arrives as written. Both boundary skills tell the
        # conductor to redirect into the runtime directory through the
        # variable, and an unexpanded target matches no ownership glob,
        # so it would read as an unowned write. Substitute the shape
        # the table knows.
        for var in ("${CB_DIR}", "$CB_DIR"):
            if t.startswith(var):
                t = "/cereblnk" + t[len(var):]
        print(t)
    return 0


if __name__ == "__main__":
    sys.exit(main())
