# Model Tiering Policy

Class: **D** (this guidance) + **M** when the user applies it (agent
frontmatter `model:` is platform-enforced once set). The plugin ships
NO model names: names age with the platform's lineup, and cost belongs
to the user, not to a vendored default. What ships is the seating
plan; the user supplies the models.

## 1. Why tiering exists

Law 5: context is expensive, reasoning is more expensive, wrong
reasoning is the most expensive of all. When the session runs on a
smaller model, the platform's thinking quality is decided by WHERE the
strongest available model is spent — not by prompt quality. Prompts
degrade with the model; a pinned frontmatter field does not.

## 2. The seating plan (tiers, not names)

| Agent | Recommended tier | Why this seat |
|---|---|---|
| planner-agent | strongest available | Decomposition quality bounds everything downstream: a bad Task Graph is executed faithfully by every cheaper agent after it |
| verifier-agent | strongest available | Re-derivation is the anti-confabulation gate; a weak verifier nods along (trap #1) |
| challenger-agent | strongest available | Constructing a concrete counter-scenario is the hardest cognitive act in the pipeline |
| synthesizer-agent | strongest available | Confidence discipline + the five-question self-test; the last chance to catch everything |
| consistency-agent | lightest available | Mechanical label/ID comparison by design (04 §3.3) — intelligence here is wasted budget |
| all specialists | session default (inherit) | Builders run at the session's model; their output is caught by the tiered gates |

The pattern: **spend the strong tier where being wrong is
unrecoverable (plan, gates, synthesis); let execution be cheap because
the gates are not.** This is Principle 3 applied to model selection.

## 3. Applying it (user configuration, one line per agent)

Add a `model:` field to the agent's frontmatter in your installed
copy, using whatever identifier your Claude Code version accepts for
the tier you mean, e.g.:

```yaml
---
name: verifier-agent
model: <your strongest tier's identifier>
---
```

Omit the field (shipped default) and every agent inherits the session
model. Downgrading a GATE agent below the session model is the one
configuration this policy names as unsupported: it silently re-opens
the fluency-equals-truth failure the gates exist to close.

## 4. Weak-conductor topology rule

A weaker session model does not only build worse — it CONDUCTS worse:
every additional agent is a coordination-error multiplier (mis-filled
Task Block, dropped digest, forgotten gate). Therefore, when the
session model is below your strongest tier:

- Prefer FEWER, LARGER slices over fine-grained parallel meshes.
- Cap parallel specialists per stage at what the risk actually
  requires (`scripts/select-agents` emits the floor; do not exceed it
  without a named signal).
- Lean on the mechanical rails instead of judgment: `plan-lint`,
  `acp-lint`, `select-agents`, `plan-status`, and the hooks. A rule a
  weak model must remember is a wish; a script it must run is a fact.

This narrows the catalog's mesh ambitions at the weak tier —
deliberately. Specialization amplifies a strong conductor and drowns a
weak one; topology scales with the tier or the tier fails.
