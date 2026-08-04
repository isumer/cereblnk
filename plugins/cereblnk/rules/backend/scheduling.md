---
name: backend-scheduling
genre: constraint
category: backend
density: neutral
paths:
  - "**/*Job.*"
  - "**/*Scheduler*.*"
  - "**/jobs/**/*"
---

# Scheduled and Background Work

Extends [`common/patterns.md`](../common/patterns.md).

## Running once

- A scheduled job runs once across the fleet, not once per instance
- Overlap is prevented, and a missed run has a stated behavior

```text
guarded    a lock, a lease, or a scheduler that owns election
overlap    prevented, with a stated timeout on the guard
missed     skipped, or caught up — decided in advance
```

Avoid: a job running on every replica. A guard with no expiry, so one
crash stops the job forever. A missed run nobody notices.

## Idempotence

- A job can be re-run over the same window without doubling its effect
- Progress is recorded, so a failed run resumes rather than restarts

Avoid: a nightly job that double-charges on retry. A batch with no
checkpoint. A backfill that cannot be resumed.

## Bounds

- Every job has a maximum duration and a bounded batch size
- A job that grows with the data states how it stays bounded

Avoid: a job whose runtime grows until it overlaps itself. An
unbounded query in a scheduled task.

## Visibility

- Start, end, duration and outcome are recorded for every run
- A job that stops running raises an alert on its own

Avoid: a silent job whose failure is found weeks later. A schedule
nobody can list. Success measured by absence of complaints.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a schedule is defined | Running once |
| a job writes data | Idempotence |
| a job processes a set | Bounds |
| a job is added or changed | Visibility |
