---
name: infrastructure-operations
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/*.service"
  - "**/*.timer"
  - "**/crontab"
  - "**/cron.d/**"
  - "**/systemd/**"
  - "**/runbook*.md"
---

# Operations

Judgment lives in `skills/infrastructure/linux-ops/` and
`skills/practices/performance-engineering/`.

## Diagnosis before action

- Evidence is gathered before anything is restarted
- A diagnosis names the layer and the reading that supports it

```text
processor   load against core count
memory      pressure, and what the kernel killed
storage     wait time, capacity, and index exhaustion
network     connection states, retransmits
```

Avoid: a restart performed before evidence, destroying the cause. A
single metric read as the whole picture. A theory offered with no
reading behind it.

## Irreversible commands

- A destructive command is rehearsed without effect first
- The narrowest command that could work is preferred

Avoid: a recursive delete on a path built from a variable. A broad
ownership change made under pressure. A disk operation with no
rehearsal.

## Capacity

- Every resource has a headroom target and an alert before exhaustion
- Growth is projected, so exhaustion is scheduled work, not an incident

Avoid: a disk filling with no warning. A connection pool sized by a
default. Capacity discovered at peak.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a system misbehaves | Diagnosis before action |
| a destructive command appears | Irreversible commands |
| a limit or pool is configured | Capacity |
