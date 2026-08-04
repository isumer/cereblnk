---
name: nodejs-security
genre: constraint
category: frameworks
paths:
  - "**/server/**/*.ts"
  - "**/server/**/*.js"
  - "**/src/**/*.server.ts"
  - "**/api/**/*.ts"
  - "**/*.route.ts"
---

# Node.js Security

Extends [`languages/javascript/security.md`](../../languages/javascript/security.md).

## Boundaries

- Request bodies are size-limited and schema-parsed before use
- Paths and commands never take an unvalidated value

```javascript
app.use(express.json({ limit: '100kb' }))

const file = path.resolve(uploadDir, path.basename(name))
if (!file.startsWith(uploadDir)) {
  throw new Error('path outside upload directory')
}
```

Avoid: an unbounded body parser. A path joined from a parameter. A
shell string built from input.

## Transport

- Outbound calls carry a timeout; servers carry read and idle timeouts
- Certificate verification is never disabled to make something work

```javascript
const response = await fetch(url, {
  signal: AbortSignal.timeout(5_000),
})

const server = http.createServer(app)
server.headersTimeout = 10_000
server.requestTimeout = 15_000
```

Avoid: a fetch with no timeout. A request retried without a ceiling. A
verification flag disabled for a local test that shipped.

## Supply chain

- Lock file committed; install scripts of new packages reviewed
- Production installs run without development dependencies

Avoid: an unaudited transitive addition. A postinstall script accepted
unread.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a request payload or path is used | Boundaries |
| a client or server is configured | Transport |
| a package is added | Supply chain |
