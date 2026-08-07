"""surfaces — reader for policies/surface-map.yaml (CB-113, shared CB-116).

Parses the restricted schema documented at the top of the map file, not
general YAML: no dependency may be added to a plugin the user installs,
and stdlib carries no YAML reader.

Shared by ExecLedgerHook and scripts/contract-check for cbmap's reason:
a checker that reads the map differently from the recorder will disagree
with it eventually, and the disagreement will look like a bug in the
project being checked rather than in Cereblnk.
"""
import os
import pathlib
import re

SKIP_DIRS = {".git", "node_modules", "dist", "build", "target", "out",
             ".venv", "venv", "__pycache__", ".next", ".nuxt", ".gradle",
             ".idea", ".claude", "vendor", "coverage"}
MAX_FILE = 512 * 1024
MAX_FILES = 4000


def map_path(root=None):
    here = pathlib.Path(__file__).resolve().parent.parent
    return (pathlib.Path(root) if root else here.parent) / "policies/surface-map.yaml"


def load(path=None):
    """surface -> {"path_contains": [...], "extensions": [...]}"""
    p = pathlib.Path(path) if path else map_path()
    out, surface, key = {}, None, None
    try:
        lines = p.read_text(encoding="utf-8").splitlines()
    except OSError:
        return out
    for line in lines:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^  ([\w-]+):\s*$", line)
        if m:
            surface, key = m.group(1), None
            out.setdefault(surface, {"path_contains": [], "extensions": []})
            continue
        m = re.match(r"^    (path_contains|extensions):\s*$", line)
        if m and surface:
            key = m.group(1)
            continue
        m = re.match(r"^      -\s*(\S+)\s*$", line)
        if m and surface and key:
            out[surface][key].append(m.group(1).lower())
    return out


def surface_of(path, smap):
    """Path segments decide first, extensions only when nothing matched.
    A file that resolves to no surface is not this layer's business."""
    p = str(path).replace("\\", "/").lower()
    if not p.startswith("/"):
        p = "/" + p
    for surface, rules in smap.items():
        for seg in rules["path_contains"]:
            if seg in p:
                return surface
    for surface, rules in smap.items():
        for ext in rules["extensions"]:
            if p.endswith(ext):
                return surface
    return ""


def files_for(root, surface, smap):
    """Every file in the project that belongs to one surface."""
    root = pathlib.Path(root)
    found, n = [], 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            p = pathlib.Path(dirpath) / fn
            try:
                rel = p.relative_to(root)
            except ValueError:
                continue
            if surface_of(rel, smap) != surface:
                continue
            try:
                if p.stat().st_size > MAX_FILE:
                    continue
            except OSError:
                continue
            n += 1
            if n > MAX_FILES:
                return found
            found.append(p)
    return found
