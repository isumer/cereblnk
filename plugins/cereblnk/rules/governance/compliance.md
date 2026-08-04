---
name: governance-compliance
genre: constraint
category: governance
density: neutral
applies_when: an obligation, licence, or personal-data question arises
---

# Compliance

Extends [`data/lifecycle.md`](../data/lifecycle.md).

## Obligations are named

- An obligation is recorded with what satisfies it and who owns it
- A control claimed as evidence exists and has been exercised

Avoid: a requirement satisfied by a document nobody follows. A control
described in a policy and absent from the system. An owner who is a
team name.

## Licences

- Every dependency's licence is known, across the transitive tree
- An incompatible licence is a blocking finding, not a note

Avoid: a licence checked on direct dependencies only. An obligation to
publish source discovered after release.

## Personal data

- Personal data is minimised, retained for a stated period, and
  exportable on request
- Deletion reaches every copy, including derived stores

Avoid: a field collected because it was available. A deletion that
leaves rows in an analytics store. An export nobody has run.

## Evidence

- Evidence is produced by the system, not written by hand at audit time

Avoid: an audit trail assembled retrospectively. A log the acting party
can edit. A control whose last proof nobody can date.

## Trigger table

| Seen in the diff | Section |
|---|---|
| an obligation is claimed | Obligations are named |
| a dependency is added | Licences |
| a personal field is stored | Personal data |
| a control is asserted | Evidence |
