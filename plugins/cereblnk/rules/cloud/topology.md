---
name: cloud-topology
genre: constraint
category: cloud
density: neutral
paths:
  - "**/*.tf"
  - "**/infra/**/*"
  - "**/terraform/**/*"
---

# Cloud Topology

Judgment lives in `skills/infrastructure/cloud-architecture/`.

## Availability names its failure

- A design survives a named failure: instance, zone, region, dependency
- The claim is proven by exercising the failover, not by configuration

```text
stated     which failure this survives
measured   how long recovery takes, from a real exercise
recorded   what is lost, and what the customer sees
```

Avoid: high availability claimed with no failure named. A standby never
promoted. Multi-region for a workload a restore would satisfy.

## Blast radius

- One account, network or credential holding everything is the real
  availability number
- Isolation boundaries are deliberate, and stated

Avoid: production and development sharing a boundary. One credential
reaching every environment. A shared component nobody counted as a
single point.

## Cost shape

- Cost is projected at expected volume, including transfer and requests
- A design that is cheap at demo scale states what it costs at target

Avoid: an estimate from compute hours alone. Transfer discovered on the
first full month's bill. A design whose cost grows faster than usage.

## Trigger table

| Seen in the diff | Section |
|---|---|
| redundancy is configured | Availability names its failure |
| an account, network or role is created | Blast radius |
| a service is chosen | Cost shape |
