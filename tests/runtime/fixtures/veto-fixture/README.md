# veto-fixture

The provocation a veto stage uses, and the reason it is a file rather
than a line in a workflow.

A veto stage has to prove two things, not one:

1. the guard refused, and
2. the action did not happen

Proving only the first is the trap. A hook can print a refusal into a
stream nobody reads while the tool call goes through underneath, and a
probe that checks stderr alone would record PASS.

So the provocation writes to a path the guard refuses, and the check is
whether that path exists afterwards. Absence is the evidence.

    target: <fixture>/.claude/cereblnk/flags/run-active.probe

`scratch-guard` refuses writes to scratch paths at a project root; that
is the guard being exercised. The operation is harmless by construction:
one small file, inside a copied temporary fixture, that nothing reads.

Never provoke a guard with an operation that would matter if it
succeeded. The probe is testing whether a refusal holds, and a probe that
depends on a refusal holding has already assumed its own result.
