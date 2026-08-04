---
name: cb-think
description: Deliberate on a design, architecture, bug theory, or tradeoff with the relevant domain specialists — divergent thinking, no mechanical solution, no code. Use when the user wants to think a problem through rather than get it built. Do NOT use when the decision is already made and work should start.
---

# Cereblnk Deliberation

Entry point for divergent work. Every other Cereblnk workflow
converges: it gates, it verdicts, it forces a decision. This one does
not. It exists because the question that has not stabilized yet is
answered by thinking, and a workflow that rushes to a verdict answers
the wrong question fluently.

## The deliberation rule — read this first

You are convening a discussion, not solving a problem.

- **No implementation proposals until the question stabilizes.**
  Agreeing quickly and starting immediately is a false-competence trap
  (09 Part II #6). The first job is asking the question correctly.
- **No code, no edits, no patches.** DelegationGuard applies here as
  everywhere. Deliberation produces understanding and a ledger.
- **Depth is produced in specialist windows, never in yours.** You
  hold the ledger and the digests. Reading a file to "get context"
  floods the conductor and buys nothing a specialist cannot buy better.
- **Every voice brings its objection.** A specialist that returns only
  agreement has not deliberated. The ask is: your view AND the
  strongest case against it.
- **The user decides.** Specialists advise, architect integrates,
  challenger attacks. Nothing here overrides Law 1, and no verdict
  is issued in the user's place.

## Step 1 — State the question, then attack the framing

Read at three levels (literal · operational · constraint). Then ask
what the question assumes. A question resting on a false premise
cannot be answered well — say so first, before convening anyone.

## Step 2 — Convene

Route through `scripts/select-agents` on the surfaces the question
touches. Standing participants regardless of surface:

- **challenger-agent** — always. Its job is the counter-case.
- **architect-agent** — integrates positions, adjudicates structure,
  never substitutes for a domain owner.

Each specialist receives a Task Block asking for: position, strongest
objection to its own position, and what evidence would settle it.
Each returns one ACP block; you hold the digest.

## Step 3 — Keep the ledger

The deliberation lives in
`$CB_DIR/memory/deliberations/<slug>.md`, not in this conversation.
Structure (protocols/deliberation.template.md):

- **Question** — current form. Sharpened means REWRITTEN, not appended.
- **Positions** — who holds it, the case for, the strongest case
  against, and what would settle it.
- **Open threads** — maximum five. Opening a sixth requires closing
  one with a rationale. An unbounded thread list is how deliberation
  becomes drift.
- **Closed threads** — with the reason they closed. This is what stops
  the same argument from reopening every session.

Every statement carries its epistemic label. The ledger is
reconstructed like any artifact (memory-policy R-1/R-2): the loss gate
applies, old versions go to `history/`.

## Step 4 — Know when to stop

Deliberation is a feeder, not a destination. Hand off when:

| The question has become… | Exit to |
|---|---|
| a choice between sized paths | /cb-frame |
| a decision worth recording | /cb-adr |
| a shape ready to specify | /cb-design |
| a testable hypothesis about a defect | /cb-bug |

Say which exit and why. "Let us keep thinking" is a valid answer only
when a named open thread justifies it.

## Step 5 — Context discipline

The conversation is disposable; the ledger is not. Write it before any
turn that ends awaiting the user (context-policy R-5). A `/compact`
mid-deliberation must lose nothing but prose — reopening the ledger
restores the question, the positions, and the open threads exactly.

## Failure Modes

- A solution proposed in turn two, before the question stabilized.
- Specialists returning agreement without an objection: no
  deliberation happened, only a poll.
- The ledger growing by append, so every reader re-reconciles the
  question with its corrections.
- Open threads past five: the discussion is drifting, not deepening.
- The conductor reading source files to "have an opinion" — the
  opinion belongs to the specialist that owns the surface.
- Deliberating a decision that was already made, which is procrastination
  wearing the costume of rigor.
