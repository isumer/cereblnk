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

What is unresolved is delivery, not capability. Hooks are read from
`hooks/hooks.json` inside the extension root and the manifest offers no
field to point elsewhere — and that file is Claude Code's binding. The
reference does leave a way out: project settings outrank extension hooks,
so these could ship as install-time configuration rather than extension
packaging. CB-143 holds that decision.

## Read this if you are on a consumer tier

Gemini CLI stopped serving Google AI Pro, Ultra and free tiers on
18 June 2026. Access continues for Code Assist Standard and Enterprise
licences and for paid API keys. If you are outside those, this extension
is not the file you need — its successor uses a different plugin format,
and CB-143 records the decision of whether Cereblnk follows.
