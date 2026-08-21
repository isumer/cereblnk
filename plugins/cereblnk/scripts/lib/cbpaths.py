"""cbpaths — where the runtime directory is, answered once.

`detect-stack` writes its cache to `$CB_DIR/context/stack-profile.yaml`.
Two scripts read it. `select-agents` resolved `$CB_DIR` from the
environment and found the file. `select-rules` hand-rolled its own
resolution, looked for `.claude/cereblnk/stack-profile.yaml` without
the `context/` segment, and never found it — so it printed
`stack_profile: absent — no gate applied` on every invocation and
returned every glob match. The stack gate CB-109 exists to apply had
not applied once.

Two copies of a path convention drift for the same reason two copies of
a policy table drift, which is the lesson CB-122 cost. So both readers
call this.

Resolution order, and why:

1. `$CB_DIR` — set by `lib/cbenv.sh`, which every lifecycle script
   sources. Authoritative when present.
2. `.claude/cereblnk` found by walking up from the working directory.
   `select-rules` is called directly by agents, from anywhere in the
   tree, often without a sourced environment. Dropping this would trade
   one broken resolution for another.
3. Nothing. Callers treat absence as "no evidence", never as a licence
   to guess — an absent profile means the stack gate does not apply,
   which returns more rules rather than fewer. A missing constraint is
   worse than an extra one.
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
    """Path to the detect-stack cache, or None when there is no runtime."""
    base = cb_dir(start)
    if base is None:
        return None
    p = base / "context" / "stack-profile.yaml"
    return p if p.is_file() else None
