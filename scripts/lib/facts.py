#!/usr/bin/env python3
"""facts — read the poster's derivable content out of the tree.

A diagram that restates the repository will disagree with it eventually.
Nothing here is transcribed: hook names, their events, whether each one
blocks or observes, the entry points and their descriptions, and the
routing table are all read from the files that define them, so the
picture cannot drift from the thing it describes. Only prose and layout
are authored, and those are the parts no checker could cover anyway.

Used by scripts/build-diagrams to generate, and by scripts/check-diagram
to assert what was generated.

Deterministic by contract: every collection returned is sorted, so the
generated SVG is byte-stable across runs and a diff against the
committed file means a real change.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
PLUGIN = ROOT / "plugins/cereblnk"
HOOKS_DIR = PLUGIN / "hooks/scripts"
HOOKS_JSON = PLUGIN / "hooks/hooks.json"
SKILLS = PLUGIN / "skills"
AGENTS = PLUGIN / "agents"
DISPATCH = SKILLS / "dispatch/SKILL.md"
GATES_DOC = ROOT / "docs/04_QUALITY_GATES.md"

# A hook refuses when it exits 2, or denies through the permission API.
# Both spellings matter: several hooks reach exit 2 through sys.exit(2)
# inside embedded Python, and a pattern that only knows the shell form
# misclassifies them in both directions.
_REFUSES = re.compile(r'(?:^|[^a-z])exit 2|sys\.exit\(2\)|"deny"')

# Event order is firing order over a turn, not the order in hooks.json.
EVENT_ORDER = [
    "UserPromptSubmit", "PreToolUse", "PostToolUse", "PreCompact",
    "Stop", "SubagentStop", "SessionEnd",
]


def _frontmatter(path):
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        return {}, text
    block, body = m.group(1), text[m.end():]
    fields, key = {}, None
    for line in block.split("\n"):
        m2 = re.match(r"^([a-z][a-z-]*):\s*(.*)$", line)
        if m2:
            key = m2.group(1)
            fields[key] = m2.group(2).strip()
        elif key and line.startswith((" ", "\t")):
            fields[key] += " " + line.strip()
    return fields, body


def hooks():
    """Every hook, with the event that fires it and whether it refuses.

    Returns {event: [ {name, refuses, purpose}, ... ]} in firing order,
    each event's hooks sorted by name.
    """
    wiring = json.loads(HOOKS_JSON.read_text(encoding="utf-8"))
    wiring = wiring.get("hooks", wiring)

    out = {}
    for event, entries in wiring.items():
        names = set()
        for entry in entries:
            for hook in entry.get("hooks", []):
                m = re.search(r"([a-z0-9-]+)\.sh", hook.get("command", ""))
                if m:
                    names.add(m.group(1))
        out[event] = [
            {
                "name": n,
                "refuses": bool(_REFUSES.search(
                    (HOOKS_DIR / f"{n}.sh").read_text(encoding="utf-8"))),
                "purpose": _hook_purpose(n),
            }
            for n in sorted(names)
        ]

    unknown = set(out) - set(EVENT_ORDER)
    if unknown:
        raise SystemExit(
            f"facts: hooks.json names events this module does not order: "
            f"{sorted(unknown)}. Add them to EVENT_ORDER deliberately "
            f"rather than letting the diagram guess.")
    return {e: out[e] for e in EVENT_ORDER if e in out}


def _hook_purpose(name):
    """The hook's own header line, trimmed. Authored, but authored once,
    in the file the hook lives in — so it moves when the hook moves."""
    path = HOOKS_DIR / f"{name}.sh"
    for line in path.read_text(encoding="utf-8").split("\n")[1:8]:
        stripped = line.lstrip("# ").strip()
        if stripped and not stripped.startswith(("!", "-", "shellcheck")):
            return stripped
    return ""


def shipped_hooks():
    return sorted(p.stem for p in HOOKS_DIR.glob("*.sh"))


def entry_points():
    """The /cb-* commands, from their own frontmatter."""
    out = []
    for skill in sorted(SKILLS.glob("*/SKILL.md")):
        fields, _ = _frontmatter(skill)
        name = fields.get("name", "")
        if name.startswith("cb-"):
            out.append({
                "name": name,
                "description": fields.get("description", ""),
                "argument_hint": fields.get("argument-hint", ""),
            })
    return out


def routing_table():
    """The dispatch routing table, read from the skill that owns it."""
    _, body = _frontmatter(DISPATCH)
    rows, seen_header = [], False
    for line in body.split("\n"):
        if not line.startswith("|"):
            if seen_header and rows:
                break
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != 2:
            continue
        if set(cells[1]) <= set("-: "):
            seen_header = True
            continue
        if not seen_header:
            continue
        rows.append({"asks_to": cells[0], "route": cells[1]})
    return rows


def agent_groups():
    out = {}
    for group in sorted(p for p in AGENTS.iterdir() if p.is_dir()):
        names = sorted(p.stem for p in group.glob("*-agent.md"))
        if names:
            out[group.name] = names
    return out


def gate_levels():
    """Risk levels and their reviewers, from 04."""
    rows = []
    for line in GATES_DOC.read_text(encoding="utf-8").split("\n"):
        m = re.match(r"^\|\s*\*\*Level (\d)\*\*\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|", line)
        if m:
            rows.append({
                "level": int(m.group(1)),
                "risk": m.group(2).strip(),
                "reviewers": m.group(3).strip(),
            })
    return sorted(rows, key=lambda r: r["level"])


def counts():
    return {
        "agents": len(list(AGENTS.rglob("*-agent.md"))),
        "skills": len(list(SKILLS.rglob("SKILL.md"))),
        "entry_points": len(entry_points()),
        "rules": sum(1 for p in (PLUGIN / "rules").rglob("*") if p.is_file()),
        "hooks": len(shipped_hooks()),
    }


if __name__ == "__main__":
    h = hooks()
    refusing = sorted(x["name"] for v in h.values() for x in v if x["refuses"])
    observing = sorted(x["name"] for v in h.values() for x in v if not x["refuses"])
    print(f"events        {len(h)}: {', '.join(h)}")
    print(f"hooks         {sum(len(v) for v in h.values())} wired, "
          f"{len(shipped_hooks())} shipped")
    print(f"  refuses     {len(refusing)}: {', '.join(refusing)}")
    print(f"  observes    {len(observing)}: {', '.join(observing)}")
    print(f"entry points  {len(entry_points())}")
    print(f"routing rows  {len(routing_table())}")
    print(f"agent groups  " + ", ".join(
        f"{g}={len(n)}" for g, n in agent_groups().items()))
    print(f"gate levels   {len(gate_levels())}")
    print(f"counts        {counts()}")
