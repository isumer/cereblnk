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
    """Path to the detect-stack cache, or None when there is no runtime."""
    base = cb_dir(start)
    if base is None:
        return None
    p = base / "context" / "stack-profile.yaml"
    return p if p.is_file() else None
