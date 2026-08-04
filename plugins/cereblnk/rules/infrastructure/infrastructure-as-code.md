---
name: infrastructure-infrastructure-as-code
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
---

# Infrastructure as Code

Judgment lives in `skills/infrastructure/terraform/`.

## The plan is the change

- Every change is judged from its plan, never from the diff
- Each replacement and destruction in the plan is traced to an intent

```text
read first    replacements, then destructions, then updates
traced        every one, to a stated intention
verified      an empty plan follows a successful apply
```

Avoid: a change approved from the source. A replacement noticed after
it ran. An apply with no verifying plan afterwards.

## State

- State is remote, locked, and never edited to resolve a disagreement
- Drift is reconciled in reality, not in the ledger

Avoid: state edited to hide drift. Concurrent applies with no lock. A
secret stored in clear text inside state.

## Change scope

- A rename declares its move; otherwise it destroys and recreates
- Targeted application is an exception, and it states what it skipped

Avoid: a resource recreated by a label change. Routine use of targeted
applies. A provider upgraded with no before-and-after plan.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a resource changes | The plan is the change |
| state or locking changes | State |
| a rename or a targeted apply | Change scope |
