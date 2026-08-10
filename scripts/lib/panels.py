#!/usr/bin/env python3
"""Panels for the generated diagrams.

Every panel is a function of the same shape:

    panel(facts..., cols=N) -> (elements, width, height)

Elements are emitted with the panel's top-left at (0, 0). That single
convention lets one definition serve two outputs: wrapped in an <svg>
it is a standalone asset, wrapped in a <g transform> it is a region of
the composite. The two cannot disagree about content because they are
the same call.

`cols` is how a panel becomes readable on a phone. A README scales an
image to its container — roughly 390px on a phone — so a wide panel
does not merely look small, its type drops below legibility and no
export setting recovers it. Narrow variants are laid out at a natural
width close to that container, so they render about one-to-one instead
of being shrunk.

What is derived and what is authored is deliberate. Which hooks exist,
which event fires them, whether they refuse, which commands ship, how
requests route, and the gate levels are all read from the tree by
facts.py — those cannot drift. The sentences describing them are keyed
by name here, so adding a hook or a command without describing it fails
the build rather than shipping a blank row.
"""
import svgkit as k

# ---------------------------------------------------------------- copy

HOOK_BLURB = {
    "delegation-guard": "File edits in the conducting conversation while a run is active",
    "edit-boundary": "Writes outside the declared directory",
    "destructive-command": "Irreversible shell operations, once /cb-careful is on",
    "secret-guard": "Writes whose content looks like a credential",
    "scratch-guard": "Working notes written to the repository root",
    "doc-floor": "Unbounded reads of an indexed document",
    "post-edit-test": "A failing test after an edit at gate level 3",
    "exec-floor": "Edited a surface and never ran it",
    "reach-floor": "Declared a symbol nothing references",
    "contract-floor": "Closed one side of a cross-surface contract",
    "skill-floor": "Finished without the craft the task required",
    "digest-cap": "Returned more than ten lines of digest",
    "context-monitor": "Tracks window occupancy each turn",
    "skill-ledger": "Records which skills a run loaded",
    "exec-ledger": "Records surface edits and executions",
    "history-archive": "Archives detail before a compaction discards it",
    "run-guard": "Prevents concurrent runs",
    "env-teardown": "Reclaims an environment a run left up",
}

WHEN = {
    "UserPromptSubmit": "as your turn arrives",
    "PreToolUse": "before a tool runs",
    "PostToolUse": "after a tool runs",
    "PreCompact": "before context is compacted",
    "Stop": "before the turn ends",
    "SubagentStop": "before a specialist finishes",
    "SessionEnd": "when the session ends",
}

# Entry points are grouped for the reader. A command absent from every
# group fails the build, so a new one cannot arrive unclassified.
COMMAND_GROUPS = [
    ("Routing", ["cb-dispatch", "cb-orchestrate"]),
    ("Deciding", ["cb-think", "cb-frame", "cb-requirements", "cb-design"]),
    ("Building", ["cb-do", "cb-implement", "cb-refactor"]),
    ("Checking", ["cb-pr-review", "cb-bug", "cb-qa", "cb-security-audit",
                  "cb-docs"]),
    ("Session guards", ["cb-careful", "cb-boundary"]),
]

COMMAND_BLURB = {
    "cb-dispatch": "Routes plain language. Fires on description match \u2014 a convenience, not a contract",
    "cb-orchestrate": "The routing decision, made explicitly and shown",
    "cb-think": "Reason a problem through. No code comes out",
    "cb-frame": "Challenge the literal ask; produce a design brief",
    "cb-requirements": "Numbered, testable requirements with acceptance criteria",
    "cb-design": "A brief becomes an executable spec",
    "cb-do": "Build a stated, bounded change. No spec, no plan to approve",
    "cb-implement": "Build from an approved spec, slice by verified slice",
    "cb-refactor": "Structure changes, behaviour does not",
    "cb-pr-review": "Hunt production incidents across a diff",
    "cb-bug": "No fix without a demonstrated root cause",
    "cb-qa": "Test the surfaces the branch actually touched",
    "cb-security-audit": "Trust boundaries and secrets, always at gate level 3",
    "cb-docs": "Find every statement the diff made stale",
    "cb-careful": "Block irreversible shell operations until turned off",
    "cb-boundary": "Confine writes to one directory",
}

PAD = 16


def _require(have, described, what):
    missing = sorted(set(have) - set(described))
    if missing:
        raise SystemExit(
            f"panels: no description for {what}: {', '.join(missing)}.\n"
            f"Something was added to the tree and the diagram was not told "
            f"what it does. Describe it rather than shipping a blank row.")


def _plate(width, height, title, note, accent):
    return [
        k.rect(0, 0, width, height, k.PLATE, accent, 1.5),
        k.text(PAD, 28, title, 14, k.TXT, "700", 2),
        k.text(PAD, 44, note, 9.5, k.MUTED),
    ]


# ----------------------------------------------------------- enforcement

def enforcement(hooks, cols=7, width=None):
    _require([h["name"] for v in hooks.values() for h in v], HOOK_BLURB, "hooks")
    _require(hooks.keys(), WHEN, "hook events")

    gap = 14
    col_w = ((width - PAD * 2 - (cols - 1) * gap) / cols
             if width else (250 if cols > 1 else 388))
    top = 62
    events = list(hooks.items())
    rows = [events[i:i + cols] for i in range(0, len(events), cols)]

    els, y = [], top
    for row in rows:
        tallest = 0
        for i, (event, items) in enumerate(row):
            refuses = sum(1 for h in items if h["refuses"])
            accent = k.RED if refuses else k.MUTED
            col = [
                k.text(0, 0, event, 12, k.TXT if refuses else k.MUTED, "700", 0.5),
                k.text(0, 15, WHEN[event], 9.5, k.DIM),
                k.line(0, 24, col_w - 18, 24, accent, 1),
            ]
            yy = 42
            for h in items:
                glyph = "\u25a0" if h["refuses"] else "\u25a1"
                colour = k.RED if h["refuses"] else k.MUTED
                col.append(k.text(0, yy, f"{glyph} {h['name']}", 10.5, colour,
                                  "700" if h["refuses"] else "400"))
                for ln in k.wrap(HOOK_BLURB[h["name"]], 40 if cols == 1 else 34):
                    yy += 12
                    col.append(k.text(13, yy, ln, 9, k.DIM))
                yy += 16
            tallest = max(tallest, yy)
            els.append(k.group(f"event-{event}", col, PAD + i * (col_w + gap), y))
        y += tallest + 18

    width = PAD * 2 + cols * col_w + (cols - 1) * gap
    height = y + 34

    total = sum(len(v) for v in hooks.values())
    refusing = sum(1 for v in hooks.values() for h in v if h["refuses"])
    legend = ("\u25a0 refuses \u00b7 \u25a1 records \u2014 a refused stop "
              "returns the specialist to work, exit code 2.")
    wrapped = k.wrap(legend, int((width - PAD * 2) / (9 * 0.62)))
    height += (len(wrapped) - 1) * 11
    chrome = _plate(width, height, "ENFORCEMENT",
                    f"{total} hooks across {len(hooks)} events \u00b7 "
                    f"{refusing} refuse, {total - refusing} record", k.RED)
    for i, ln in enumerate(wrapped):
        chrome.append(k.text(PAD, height - 14 - (len(wrapped) - 1 - i) * 11,
                             ln, 9, k.DIM))
    return chrome + els, width, height


# -------------------------------------------------------------- commands

def commands(entry_points, cols=2, width=None):
    names = [e["name"] for e in entry_points]
    _require(names, COMMAND_BLURB, "entry points")
    grouped = [n for _, g in COMMAND_GROUPS for n in g]
    ungrouped = sorted(set(names) - set(grouped))
    if ungrouped:
        raise SystemExit(
            f"panels: entry point(s) in no group: {', '.join(ungrouped)}.\n"
            f"Add to COMMAND_GROUPS so the panel cannot omit a shipped "
            f"command silently.")
    stale = sorted(set(grouped) - set(names))
    if stale:
        raise SystemExit(
            f"panels: group names a command that does not ship: "
            f"{', '.join(stale)}.")

    gap = 16
    col_w = ((width - PAD * 2 - (cols - 1) * gap) / cols
             if width else (440 if cols > 1 else 388))
    els = []
    columns = [[] for _ in range(cols)]
    for i, (label, members) in enumerate(COMMAND_GROUPS):
        columns[i % cols].append((label, members))

    tallest = 0
    for ci, groups in enumerate(columns):
        yy = 0
        block = []
        for label, members in groups:
            block.append(k.text(0, yy, label.upper(), 10, k.STEEL, "700", 2))
            block.append(k.line(0, yy + 7, col_w - 18, yy + 7, k.EDGE, 1))
            yy += 24
            for name in members:
                block.append(k.text(0, yy, "/" + name, 11, k.TXT, "700"))
                for ln in k.wrap(COMMAND_BLURB[name], 46 if cols == 1 else 52):
                    yy += 12
                    block.append(k.text(10, yy, ln, 9, k.MUTED))
                yy += 18
            yy += 10
        tallest = max(tallest, yy)
        els.append(k.group(f"command-column-{ci}", block,
                           PAD + ci * (col_w + gap), 62))

    width = PAD * 2 + cols * col_w + (cols - 1) * gap
    height = 62 + tallest + 20
    chrome = _plate(width, height, "ENTRY POINTS",
                    f"{len(names)} commands \u00b7 type one when it matters",
                    k.STEEL)
    return chrome + els, width, height


# --------------------------------------------------------------- routing

def routing(rows, cols=1, width=None):
    width = width or (420 if cols == 1 else 700)
    els, y = [], 66
    left = PAD
    ask_w = 40 if cols == 1 else 46
    for i, row in enumerate(rows):
        lines = k.wrap(row["asks_to"], ask_w)
        block = [k.text(0, 0, ln, 10, k.TXT) for ln in [lines[0]]]
        for j, ln in enumerate(lines[1:], 1):
            block.append(k.text(0, j * 12, ln, 10, k.TXT))
        h = len(lines) * 12
        block.append(k.text(0, h + 2, "\u2192 " + row["route"], 10, k.AMBER, "700"))
        els.append(k.group(f"route-{i}", block, left, y))
        y += h + 24
        if i < len(rows) - 1:
            els.append(k.line(left, y - 10, width - PAD, y - 10, k.EDGE, 1))
    height = y + 8
    chrome = _plate(width, height, "ROUTING",
                    f"{len(rows)} routes \u00b7 read from the dispatch skill",
                    k.AMBER)
    return chrome + els, width, height


# ----------------------------------------------------------------- gates

def gates(levels, cols=1, width=None):
    width = width or (420 if cols == 1 else 640)
    els, y = [], 66
    for lv in levels:
        block = [
            k.text(0, 0, f"L{lv['level']}", 13, k.GREEN, "700"),
            k.text(28, 0, lv["risk"], 11, k.TXT, "700"),
        ]
        yy = 0
        for j, ln in enumerate(k.wrap(lv["reviewers"], 44 if cols == 1 else 60)):
            yy = 14 + j * 12
            block.append(k.text(28, yy, ln, 9.5, k.MUTED))
        els.append(k.group(f"gate-level-{lv['level']}", block, PAD, y))
        y += yy + 24
    always = ("Security-surface, auth, data-deletion, migration, money and "
              "production-config work is always level 3, regardless of "
              "apparent simplicity. Risk is never silently downgraded.")
    body, y2 = k.para(PAD, y + 4, always, 46 if cols == 1 else 66, 9, k.DIM, 12)
    els += body
    height = y2 + 12
    chrome = _plate(width, height, "VERIFICATION GATES",
                    "depth is dynamic \u2014 set by risk, raisable by any agent",
                    k.GREEN)
    return chrome + els, width, height


# ---------------------------------------------------------------- agents

GROUP_NOTE = {
    "core": "reasoning and gate roles",
    "engineering": "domain specialists",
    "lifecycle": "requirements and documentation intake",
    "context": "compression, evidence, archiving",
}


def agents(groups, cols=1, width=None):
    _require(groups.keys(), GROUP_NOTE, "agent groups")
    width = width or (420 if cols == 1 else 700)
    els, y = [], 66
    for name in sorted(groups):
        members = [m.replace("-agent", "") for m in groups[name]]
        block = [
            k.text(0, 0, f"{name}/", 11, k.TXT, "700"),
            k.text(0, 13, GROUP_NOTE[name], 9, k.DIM),
        ]
        yy = 13
        for j, ln in enumerate(k.wrap(" \u00b7 ".join(members),
                                      44 if cols == 1 else 74)):
            yy = 28 + j * 12
            block.append(k.text(0, yy, ln, 9.5, k.MUTED))
        els.append(k.group(f"agent-group-{name}", block, PAD, y))
        y += yy + 22
    height = y + 6
    total = sum(len(v) for v in groups.values())
    chrome = _plate(width, height, "AGENTS",
                    f"{total} specialists \u00b7 each in its own context window",
                    k.STEEL)
    return chrome + els, width, height
