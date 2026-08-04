# Cereblnk Protocols

The Agent Communication Protocol (ACP) is the **only** format in which
Cereblnk agents exchange information. Files here are the working
templates agents copy from; each contains one fully worked example.

| Template | Direction |
|---|---|
| `acp-task-block.template.yaml` | Runtime → Agent |
| `acp-response-block.template.yaml` | Agent → Runtime |
| `acp-verification-block.template.yaml` | Gate agent → Runtime |
| `acp-synthesis-block.template.md` | Runtime → User |

## Hard violations

The orchestrator discards the block and re-issues the task on any of:

1. Free-form output between agents.
2. Unlabeled claims.
3. `known` claim without an evidence reference.
4. Decision resting on `speculative` facts.
5. Budget overrun without `blocked` status.
6. Conclusion accepted from another agent without its evidence.

Checkers: the orchestrator (`/cb-orchestrate`) rejects malformed blocks;
the ConsistencyAgent detects cross-block contradictions and label drift.
