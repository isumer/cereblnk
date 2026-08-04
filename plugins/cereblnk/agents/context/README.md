# agents/context — Context OS micro-agents

Context OS micro-agents per the platform catalog (08 §4.4) and
03_CONTEXT_OS.md §7.

Shipped here:

| Agent | Owns |
|---|---|
| `evidencecollector-agent` | extracts labeled facts from chunks |
| `merge-agent` | merges fact sets into the run's Evidence Graph |
| `compression-agent` | evidence-preserving compression (03 §5) with label/reference/unknown conservation gates |
| `memorybuilder-agent` | promotes stable knowledge into persistent memory |
| `contextarchivist-agent` | stores reusable CTX bundles under `.claude/cereblnk/memory/` |

Not yet shipped: `contextplanner` and `chunkbuilder`. Their function
is deciding what each task needs, and cutting slices. The
orchestrator performs that today, against
`policies/context-policy.md` and
`policies/agent-selection-policy.md`. They become separate agents when that inline logic outgrows the
orchestrator. Not before (Principle 9).
