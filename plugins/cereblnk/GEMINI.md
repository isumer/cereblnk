# Cereblnk

Cereblnk turns engineering discipline into mechanism. This file is the
context Gemini CLI loads for the extension; the host-neutral instructions
every agent works under are in `AGENTS.md` at the repository root, and
that is the file to read first.

## What binds here, and what does not

Skills under `skills/` and sub-agents under `agents/` are discovered by
folder, so they load. The enforcement layer maps further than the first
reading of these docs suggested, and `policies/hosts/gemini.yaml` records
it against the published hook reference.

Six of seven capabilities have an event: `BeforeTool`, `AfterTool`,
`AfterAgent`, `PreCompress`, `SessionStart`, `SessionEnd`. The refusal
contract is the same one Claude Code uses — exit 2 aborts the target
action and stderr carries the reason — so the guards need no translation
to speak here.

`subagent_stop` has no event. This host runs sub-agents but exposes no
sub-agent lifecycle hook, so Cereblnk's five finish floors have nothing
to attach to. They are absent here, not unmeasured, and nothing pretends
otherwise.

Sub-agents are a preview feature on this host. The `agents/` directory
is discovered, but a preview surface is not the promise a stable one is,
and nothing in the capability matrix rests on it.

What is unresolved is delivery, not capability, and the gap is ours
rather than this host's. Gemini supports extension hooks natively, in
`hooks/hooks.json` inside the extension root — which is exactly the
filename Claude Code's binding already occupies in this repository. The
options and the trade between them are in `docs/hosts/gemini.md`;
CB-143 holds the decision.
