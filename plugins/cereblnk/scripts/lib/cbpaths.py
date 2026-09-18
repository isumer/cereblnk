"""cbpaths — where the runtime directory is, answered once.

CB-128: select-rules omitted `context/`, so the profile gate never applied.
Order is $CB_DIR, then a walk up from cwd (agents call select-rules from
anywhere, often without a sourced environment), then None — never a guess.
"""
import os
import pathlib

RUNTIME_DIRNAME = pathlib.Path(".claude") / "cereblnk"


def cb_dir(start=None):
    """The runtime directory, or None when it cannot be established."""
    env = os.environ.get("CB_DIR") or ""
    if env:
        p = pathlib.Path(env)
        if p.is_dir():
            return p
    here = pathlib.Path(start or pathlib.Path.cwd()).resolve()
    for base in (here, *here.parents):
        candidate = base / RUNTIME_DIRNAME
        if candidate.is_dir():
            return candidate
    return None


def stack_profile(start=None):
    """Path to the detect-stack cache, or None when it is not this project's.

    detect-stack records the root it scanned and nothing read it back. That
    matters because `$HOME/.claude/cereblnk` is the last-resort runtime for any
    cwd that cannot host state — a temp directory, the Claude config tree — so
    profiles from unrelated throwaways accumulate in one shared location. One
    found there in practice recorded `root: /tmp/tmp.H2mtU7mS6r` with
    `tokens: [docker]`; a later fallback run would have read those tokens and
    gated out every java, spring-boot and react rule without a word.

    A mismatch returns None, which disables the gate rather than guessing at
    it — the same direction select-rules takes when no profile exists, because
    a missing constraint is worse than an extra one.
    """
    base = cb_dir(start)
    if base is None:
        return None
    p = base / "context" / "stack-profile.yaml"
    if not p.is_file():
        return None
    try:
        for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
            if not line.startswith("root:"):
                continue
            recorded = line.split(":", 1)[1].strip().strip("\"'")
            if not recorded:
                break
            expected = base.parent.parent      # <root>/.claude/cereblnk
            if pathlib.Path(recorded).resolve() != expected.resolve():
                return None
            break
    except OSError:
        return None
    return p
