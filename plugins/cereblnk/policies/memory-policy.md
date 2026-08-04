# Working Memory Policy

Governs persistent memory: evidence-preserving compression, real files
plus discipline-class promotion rules, and the rule that runtime
directories are created in the user's project and never shipped with
content. Class: M (real files) + D (rules — every rule
names its checker).

## 1. Hierarchy

Created at runtime under the user project's `.claude/cereblnk/memory/`:

```
.claude/cereblnk/memory/
├── working/       # per-run scratch knowledge (shortest-lived)
├── evidence/      # persistent evidence index entries
├── session/       # end-of-session state snapshots
├── compressed/    # evidence-preserving compressed bundles (CTX-*)
├── repository/    # stable, promoted knowledge about THIS repo
└── briefs/        # /cb-frame briefs and /cb-design specs
```

## 2. Write rules (who may write what, in which format)

| Directory | Written by | Format | Lifetime |
|---|---|---|---|
| `working/` | any agent via orchestrator, during its run | ACP fact fragments (YAML), named `R-<run>/<role>.yaml` | until run ends; promotable |
| `evidence/` | MergeAgent (entries), ConsistencyAgent (verdict fields) | `evidence-index.template.yaml` entries (protocols/) | persistent |
| `session/` | ContextArchivistAgent only | ACP response-block snapshot + open unknowns | until next session resume |
| `compressed/` | CompressionAgent / ContextArchivistAgent | CTX bundle: labeled facts + refs format | reusable; ID-stable |
| `repository/` | MemoryBuilderAgent only | promoted fact records | long-lived |
| `briefs/` | /cb-frame, /cb-design workflows | brief/spec markdown per their command specs | until superseded |
| `specs/` | architect-agent via `scripts/spec-assemble` only | seven-section spec, W-2 header + `spec_version` | head only; predecessors in `history/` |
| `plans/` | planner-agent | plan-format tasks, W-2 header + `derived_from_spec` | head only; predecessors in `history/` |
| `history/` | `spec-assemble` (specs), planner-agent (plans) | superseded artifact, name `<kind>-<slug>-v<N>.md` | head's immediate predecessor ALWAYS kept; older prunable at run close |
| `deliberations/` | architect-agent via /cb-think | deliberation ledger (`protocols/deliberation.template.md`), W-2 header + `ledger_version` | head only; predecessors in `history/` |
| `state.md` (at `$CB_DIR` root) | conductor, at every stage boundary | W-2 header + `stage`, `spec`, `plan`, `awaiting` fields (consumed by `scripts/run-status`) | single file, overwritten in place, never versioned |

Rule W-1: no agent writes outside its row. **Checker:**
ConsistencyAgent flags any memory artifact whose header's
`written_by` role contradicts this table; the orchestrator refuses to
consume unattributed memory files.

Rule W-2: every memory file starts with a header: `written_by`,
`run_id`, `date`, `acp_version`. **Checker:** MemoryBuilderAgent
rejects promotion of headerless files; orchestrator skips them as
context sources.

## 3. Promotion rules (knowledge moves upward)

```
working/ ──(fact survived its run's gates)──▶ evidence/ index entry
evidence/ ──(stable across ≥2 runs, no contradiction)──▶ repository/
```

Rule P-1: promotion NEVER rewrites content — labels, fact IDs, and
evidence references survive verbatim (: compression may drop
reasoning prose, never labels/refs/unknowns/risks). **Checker:**
MemoryBuilderAgent — a promotion that drops or changes any epistemic
label or evidence reference is rejected with the violation named.

Rule P-2: only gate-surviving facts promote to `evidence/`
(Verifier `confirmed`, or level-1 self-verified for fast-path runs,
recorded as such). **Checker:** MemoryBuilderAgent verifies the gate
verdict field is present in the source; ConsistencyAgent cross-checks
verdict claims against the run's verification blocks.

Rule P-3: promotion to `repository/` requires: the fact appeared in
≥2 distinct runs' evidence entries AND no open contradiction involving
it exists in `evidence/`. **Checker:** MemoryBuilderAgent (run-count
and contradiction query against the evidence index).

Rule P-4: `assumed` and `speculative` facts never reach `repository/`.
They may live in `evidence/` only as flagged open items. **Checker:**
MemoryBuilderAgent rejects; ConsistencyAgent audits `repository/` for
label violations during cross-run checks.

Rule P-5: demotion/pruning — a `repository/` fact contradicted by new
evidence is not edited; it is marked `superseded_by: <fact-id>` and a
fresh entry is written. History is immutable. **Checker:**
MemoryBuilderAgent; ConsistencyAgent treats an edited-in-place record
as a violation.

## 4. Evidence index

The persistent traceability chain (Claim → Evidence → Verification →
Confidence) lives in `evidence/` using
`protocols/evidence-index.template.yaml`. Field semantics are ACP — no new ontology. ConsistencyAgent consumes this index for
cross-run contradiction checks required by ("output does not
contradict prior decisions recorded in .claude/cereblnk/memory/").

Rule E-1: one entry per gate-surviving fact; entry fields populate
ONLY from existing ACP fields (task/response/verification blocks) —
inventing data at index time is a violation. **Checker:**
ConsistencyAgent compares entry fields to the source blocks on audit.

Rule E-2: entries are append-only; corrections follow P-5 semantics.
**Checker:** MemoryBuilderAgent.

## 5. What memory is NOT

- Not raw context storage: no file dumps, no conversation logs
  (the context-isolation rule — knowledge is shared, context is not).
- Not shipped: the plugin never contains `.claude/cereblnk/memory/` content; the orchestrator creates empty directories on first run.
- Not authoritative over reality: on conflict with current repo
  evidence, current evidence wins and P-5 records the supersession.

## Path anchoring

All paths in this policy resolve against the project root
(`CLAUDE_PROJECT_DIR`, the repo root) — never `$HOME`, never the
current working directory of the moment. Checker: MemoryBuilderAgent
rejects promotion into any `.claude/cereblnk/` path that is not under
the project root; nested runtime directories (e.g.
`src/.claude/cereblnk/`) are flagged for cleanup, never silently used.

## Artifact versioning & reconstruction (CB-086)

Chat is disposable; artifacts are the truth. Enrichment therefore
never appends to an artifact — the artifact is RECONSTRUCTED
(07 §6: a file needing revision is regenerated whole).

**R-1 — Section-scoped reconstruction.** A spec is reconstructed by
its sections' owners, each in its own window; assembly is
`scripts/spec-assemble`, never an agent. No window ever holds the
whole spec.

**R-2 — Loss gate.** Every labeled fact and constraint in v(n) either
appears in v(n+1) or is marked `superseded_by` with a rationale
(evidence-index semantics — no new ontology). Silent drops are the
summary-drift trap (09 Part II #9) at the worst possible layer.
**Checker (mechanical, CB-091):** `scripts/artifact-gate spec
<history/spec-<slug>-v<N>.md> <head>` — G-1 unaccounted drop, G-2
version not increased, G-3 vanished section. ConsistencyAgent runs it
after every spec reconstruction and rejects on nonzero exit.
This is why `history/` keeps the head's immediate predecessor
unconditionally — pruning it would blind the checker.

**R-3 — Plan reconstruction preserves history.** Checked tasks are
never rewritten (they happened). Only unstarted tasks are re-derived.
A decision that invalidates a checked task surfaces as REWORK in the
plan and the progress output — never silently absorbed.
**Checker (mechanical, CB-091):** `scripts/artifact-gate plan <old>
<new>` — G-4 checked task deleted, G-5 checked task rewritten, G-6
silently unchecked without a REWORK annotation. A REWORK line
annotates history rather than editing it, so the honest path passes.

**R-4 — Staleness gate.** Every reconstruction bumps `spec_version`;
the plan header records `derived_from_spec: <path>@v<N>`. Before its
first task, /cb-implement compares the two: plan behind spec head →
HALT with both versions named; the fix is plan reconstruction, not
proceeding. **Checker:** the halt rule in /cb-implement; VerifierAgent
treats a run that proceeded on a stale plan as a protocol violation.

**R-5 — Pruning floor.** MemoryBuilderAgent prunes `history/` at run
close only, and never the head's immediate predecessor (R-2's input).
