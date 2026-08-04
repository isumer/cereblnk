---
name: helm-patterns
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/Chart.yaml"
  - "**/values*.y*ml"
  - "**/templates/**/*.y*ml"
  - "**/templates/**/*.tpl"
  - "**/charts/**"
---

# Helm Patterns

Judgment lives in `skills/infrastructure/helm/`.

## Values

- Every value a template reads has a default in `values.yaml`
- A required value fails the render with a message, not a blank field

```yaml
image:
  repository: acme/settlement
  tag: ""
resources:
  requests: { cpu: 250m, memory: 512Mi }
```

```text
{{ required "image.tag is required" .Values.image.tag }}
```

Avoid: a template reading a key absent from `values.yaml`, which
renders empty and deploys something unintended. A default pointing at a
production registry. `latest` as a default tag.

## Change safety

- A chart is rendered and diffed against the release, before upgrade
- The chart version moves when templates move, the app version when
  the image does

```bash
helm template settlement ./charts/settlement -f values.prod.yaml
helm diff upgrade settlement ./charts/settlement -f values.prod.yaml
```

Avoid: an upgrade judged from the source rather than the rendered diff.
A chart shipped without bumping `version`, which leaves the release
history unable to distinguish two deployments.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a template reads a value | Values |
| a chart or template is upgraded | Change safety |
