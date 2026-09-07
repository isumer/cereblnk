"""shellwrite — which files does this shell command write? (CB-123)

Emits paths, `?` for an unresolved target, or `!` for untokenizable input.
Unresolved targets block; unknown utilities do not, or required tools would stop.

Limit: this is a floor, not proof. Internal redirects, base64 round trips,
editors, and obfuscated interpreters can escape it; determined bypasses will.
It covers ordinary write forms and raises bypass cost without closing the gap.

`--in-place` includes edits to existing files but excludes Write-shaped creation.
Known gap: inline interpreters report `?` normally and nothing in this mode.
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

# Split opaque utilities by whether they edit existing files or create content.
OPAQUE_IN_PLACE = {"patch", "ed", "vi", "vim", "nano", "emacs"}
OPAQUE_CREATE = {"dd", "tar", "unzip"}
OPAQUE = OPAQUE_IN_PLACE | OPAQUE_CREATE

# Nested shells: the code string is a shell command, so read it as one
# rather than guessing at it.
NESTED_SHELL = {"sh", "bash", "zsh", "dash"}

# Keep hints narrow: `print(` or bare `>` would false-block Python arithmetic.
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
UNPARSEABLE = "!"


def _looks_like_flag(tok):
    return tok.startswith("-") and tok != "-"


def targets(command, in_place=False, _top=True):
    """Yield write targets, UNRESOLVED, or outermost-mode UNPARSEABLE."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        toks = list(lexer)
    except ValueError:
        # Unbalanced quoting is unknowable, stronger than a parsed unresolved target.
        return [UNPARSEABLE if (_top and not in_place) else UNRESOLVED]

    found, head, operands, i, in_test = [], None, [], 0, False

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
                    found.extend(targets(operands[j + 1], in_place, _top=False))
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
        if tok == "[[":
            in_test = True
        elif tok == "]]":
            in_test = False
        # `[[ > ]]` compares strings; single-bracket test has no grammar we can narrow.
        if tok in WRITE_REDIR and not in_test:
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
    # Keep mixed targets: `?` matches no ownership glob and independently blocks.
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
    # Hook payloads keep $CB_DIR literal; normalize it before ownership matching.
        for var in ("${CB_DIR}", "$CB_DIR"):
            if t.startswith(var):
                t = "/cereblnk" + t[len(var):]
        print(t)
    return 0


if __name__ == "__main__":
    sys.exit(main())
