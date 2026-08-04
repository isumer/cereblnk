"""cbmap — reader for policies/skill-selection.yaml (CB-097).

Deliberately parses the restricted schema documented at the top of the
map file, not general YAML: no dependency may be added to a plugin the
user installs, and stdlib carries no YAML reader. The schema is a flat
list of blocks with scalar and inline-list values, which a dozen lines
handle exactly and predictably.

Shared by scripts/select-agents and scripts/check-agent-skills so that
selection and its checker can never drift onto different readings of
the same file.
"""
import pathlib
import re

FIELDS = ("skill", "roles", "paths", "stack", "topics", "discovery")


def map_path(root=None):
    here = pathlib.Path(__file__).resolve().parent.parent
    return (pathlib.Path(root) if root else here.parent) / "policies/skill-selection.yaml"


def _inline_list(raw):
    raw = raw.strip()
    if raw.startswith("[") and raw.endswith("]"):
        raw = raw[1:-1]
    out = []
    for part in re.split(r",(?=(?:[^']*'[^']*')*[^']*$)", raw):
        part = part.strip().strip("'").strip()
        if part:
            out.append(part)
    return out


def load(path=None):
    """Return (rules, errors). A rule is a dict with parsed fields."""
    path = pathlib.Path(path) if path else map_path()
    rules, errors, cur = [], [], None
    if not path.exists():
        return [], ["skill-selection.yaml not found at %s" % path]
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^(version|rules):", line):
            continue
        m = re.match(r"^\s*-\s*skill:\s*(\S+)\s*$", line)
        if m:
            cur = {"skill": m.group(1), "roles": [], "paths": [],
                   "stack": None, "topics": [], "discovery": [], "line": n}
            rules.append(cur)
            continue
        m = re.match(r"^\s+(\w+):\s*(.+?)\s*$", line)
        if not m:
            errors.append("line %d: unparsed: %s" % (n, line.strip()))
            continue
        key, val = m.group(1), m.group(2)
        if cur is None:
            errors.append("line %d: %s before any skill block" % (n, key))
            continue
        if key not in FIELDS:
            errors.append("line %d: unknown field %r" % (n, key))
            continue
        cur[key] = val.strip() if key == "stack" else _inline_list(val)
    for r in rules:
        if not r["roles"]:
            errors.append("%s: roles is required" % r["skill"])
        if not r["topics"]:
            errors.append("%s: topics is required (text routing needs it)" % r["skill"])
    return rules, errors


def discovery_pairs(rule):
    """['token -> skill', ...] -> [(token, skill), ...]"""
    out = []
    for entry in rule.get("discovery", []):
        if "->" not in entry:
            continue
        token, target = entry.rsplit("->", 1)
        out.append((token.strip(), target.strip()))
    return out
