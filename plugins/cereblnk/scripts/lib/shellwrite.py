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

MODES. `--in-place` narrows the answer to the commands that modify a
file that already exists — `sed -i`, `perl -i`, `patch`, `ed`, an
editor, `git apply`/`git checkout`. Redirections and copy/create
utilities are excluded there, because those are Write-shaped: an agent
that holds Write may already replace a whole file with the tool, so
blocking its shell equivalent would be stricter than the grant it was
given. ToolFloor (F-24) asks in this mode; DelegationGuard asks in the
default mode, where every write counts. The `--in-place` answer is a
subset of the default one, never a superset.

The bound is the same one stated above, and one case is named because
it is the obvious gap: an inline interpreter (`python3 -c`) that
rewrites a file in place reports UNRESOLVED in the default mode and
NOTHING here, because a write hint cannot say which shape it was. A
floor, still not a proof.
"""
import json
import re
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

# Utilities that write somewhere this walk cannot name. Split by shape:
# the first set opens a file that already exists and rewrites part of
# it; the second unpacks or streams new content. Only the first is an
# edit in the sense `disallowedTools: Edit` means.
OPAQUE_IN_PLACE = {"patch", "ed", "vi", "vim", "nano", "emacs"}
OPAQUE_CREATE = {"dd", "tar", "unzip"}
OPAQUE = OPAQUE_IN_PLACE | OPAQUE_CREATE

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
WRITE_HINTS = (".write", "writeFile", "writeFileSync",
               "Set-Content", "Out-File", "shutil.copy", "shutil.move",
               "os.rename", "os.replace", "File.write", "write_text")

# open() defaults to mode "r", so it is a write only when a mode
# argument says so: "w", "a", "x", or a bytes/plus variant.
OPEN_WRITE = re.compile(
    r"""open\s*\(          # the call
        [^)]*?             # the path, however it is spelled
        ,\s*               # a second positional or keyword argument
        (?:mode\s*=\s*)?   # open(f, mode="w") is the same thing
        (['"])             # its quote
        [rbt+]*[wax][rbt+]*  # a mode containing w, a or x
        \1
    """, re.X)

# Command separators: what follows starts a new command head.
SEPARATORS = {"|", "||", "&&", ";", "&", "|&", "(", ")", "{", "}", "\n"}

UNRESOLVED = "?"


def _looks_like_flag(tok):
    return tok.startswith("-") and tok != "-"


def targets(command, in_place=False):
    """Yield write targets for a shell command, or UNRESOLVED.

    With in_place=True, only the commands that rewrite an existing file
    are reported; see MODES in the module docstring.
    """
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
            if in_place:
                return
            plain = [o for o in operands if not _looks_like_flag(o)]
            if plain:
                found.append(plain[-1])
            else:
                found.append(UNRESOLVED)
        elif head in ALL_OPERANDS:
            if in_place:
                return
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
                    found.extend(targets(operands[j + 1], in_place))
                    break
        elif head in INLINE:
            if in_place:
                return
            for j, o in enumerate(operands):
                if o in INLINE_FLAGS and j + 1 < len(operands):
                    _src = operands[j + 1]
                    if any(h in _src for h in WRITE_HINTS) \
                            or OPEN_WRITE.search(_src):
                        found.append(UNRESOLVED)
                    break
        elif head in OPAQUE:
            if in_place and head not in OPAQUE_IN_PLACE:
                return
            found.append(UNRESOLVED)
        elif head == "git" and operands[:1] in (["apply"], ["checkout"]):
            found.append(UNRESOLVED)

    while i < len(toks):
        tok = toks[i]
        if tok in WRITE_REDIR:
            if in_place:
                # a redirection replaces or extends whole-file content,
                # which is what Write does; it is not an Edit
                i += 2 if i + 1 < len(toks) else 1
                continue
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
    in_place = "--in-place" in sys.argv[1:]
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not command.strip():
        return 0
    for t in targets(command, in_place):
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
