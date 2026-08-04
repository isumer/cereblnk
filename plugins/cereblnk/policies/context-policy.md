# Context Policy — CTX Bundle Construction

Governs CTX bundle construction: the Tree of Context, evidence-preserving
compression, and role-scoped retrieval. Retrieval today is
orchestrator-guided explicit file lists; a semantic/dependency graph
remains F-class (no shippable mechanism yet). Class: D, checkers named.

## 1. How CTX bundles are built (Phase 2.5 reality)

1. The orchestrator selects candidate files per the task's objective
   and the role-scoped retrieval table — explicit path lists,
   no repository-wide loading.
2. `${CLAUDE_PLUGIN_ROOT}/scripts/repo-map` output (M-class, CB-045) is attachable as a
   CTX bundle to sharpen that selection with real signals:
   - **hotspots** → prioritize frequently-changed files inside the
     task's surface (risk concentrates where change concentrates —
     09 Procedure 3);
   - **ownership** → route "ask the owner" unknowns and inform
     review context;
   - **imports** → follow one static dependency hop from the touched
     files when slicing chunks (the honest, git-based subset of the
     F-class dependency graph — NOT a semantic index).
3. EvidenceCollectorAgent extracts labeled facts from the chunks;
   compression happens only after extraction.

## 2. Rules and checkers

- R-1: a repo-map bundle carries its `generated_at_commit`; the
  orchestrator regenerates when HEAD moved. **Checker:**
  ConsistencyAgent flags evidence citing a stale-map bundle when the
  cited paths changed since that commit.
- R-2: the imports listing may guide selection but is never itself
  evidence of runtime behavior (static ≠ dynamic). Facts derived from
  it are at most `derived`, with the limitation stated. **Checker:**
  VerifierAgent (re-derivation catches import-list overreach).
- R-3: bundle size discipline stands — chunks target 5–10K tokens per
  agent regardless of map size. **Checker:** budget reports
  (budget-policy.md rule 2).
- R-4: project standards bundles. If
  `.claude/cereblnk/memory/repository/standards/` contains a file matching a
  code-touching task's surface, the orchestrator attaches it as a CTX
  bundle to every specialist spawned for that surface (format:
  `examples/standards/`; consumption discipline:
  `skills/practices/coding-standards`). If no matching file exists,
  the executing agent records "no declared standards for <surface>" as
  an `assumed` fact — never silently applies general taste as if it
  were project convention. **Checker:** VerifierAgent rejects any
  convention-violation finding that does not carry the dual reference
  (standard's section + code line, coding-standards gate 1);
  PRReviewWorkflow's Principle 10 check catches standards-motivated
  edits outside the task's changed lines.
- R-5: run artifacts never live under temporary directories. Anything
  a later step reads — plans, Response Blocks, briefs, specs, evidence
  bundles, generated files awaiting review — is written under the
  project's `.claude/cereblnk/` (ledger or memory), never under
  `/tmp`, `$TMPDIR`, `%TEMP%`, or a `mktemp` path. Temp scratch is
  permitted ONLY for byproducts nothing later reads (an intermediate
  compile, a throwaway diff); the test is consumption, not intent. The
  failure mode this prevents: temp is wiped between sessions and
  differs per subagent environment, so a resumed or gated run cannot
  find what an earlier step "saved". **Checker:** ConsistencyAgent
  rejects any `context_refs` or evidence reference resolving under a
  temp path; the orchestrator treats a Task Block pointing into temp
  as malformed (02 §7 class) and re-issues it.

