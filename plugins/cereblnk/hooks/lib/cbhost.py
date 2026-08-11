"""cbhost — the refusal, expressed once (CB-128).

The bash counterpart is hooks/lib/hostio.sh; this exists because three
guards reach their verdict inside a Python heredoc and would otherwise
carry their own copy of the host's refusal form.

    from cbhost import block
    block("Cereblnk SecretGuardHook: ...")

block() does not return. CB_HOST selects the form and defaults to claude;
an unknown value takes the Claude form, because a refusal spoken in the
wrong dialect is better than a refusal silently dropped.

Nothing here decides anything. Conditions about paths, agents or run
state belong in the hook that called this.
"""
import json
import os
import sys


def _host():
    return os.environ.get("CB_HOST", "claude") or "claude"


def block(message):
    """Refuse a tool call or a subagent stop, in the host's own form."""
    host = _host()
    if host == "cursor":
        sys.stdout.write(json.dumps({
            "continue": False,
            "permission": "deny",
            "agentMessage": message,
        }) + "\n")
        sys.exit(0)
    if host == "codex":
        sys.stdout.write(json.dumps({
            "decision": "block",
            "reason": message,
        }) + "\n")
        sys.exit(0)
    print(message, file=sys.stderr)
    sys.exit(2)
