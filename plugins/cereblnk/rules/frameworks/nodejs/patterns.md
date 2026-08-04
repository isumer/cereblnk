---
name: nodejs-patterns
genre: constraint
category: frameworks
paths:
  - "**/server/**/*.ts"
  - "**/server/**/*.js"
  - "**/src/**/*.server.ts"
  - "**/api/**/*.ts"
  - "**/*.route.ts"
---

# Node.js Patterns

Extends [`languages/javascript/patterns.md`](../../languages/javascript/patterns.md).
Judgment lives in `skills/frameworks/nodejs/`.

## The event loop

- Nothing blocking runs on the request path
- Computation moves to a worker or a queue

```javascript
const contents = await fs.promises.readFile(path, 'utf8')

const digest = await new Promise((resolve, reject) => {
  crypto.pbkdf2(password, salt, 100000, 64, 'sha512', (error, key) =>
    error ? reject(error) : resolve(key),
  )
})
```

Avoid: a synchronous file, crypto, or compression call in a handler. A
loop over a large array on the request path. A JSON parse of an
unbounded body.

## Streams

- A pipeline handles errors and respects backpressure
- Large payloads stream; they are not buffered

```javascript
await pipeline(
  createReadStream(source),
  createGzip(),
  createWriteStream(target),
)
```

Avoid: a pipe with no error listener. A read faster than the write
behind it. A whole file loaded to transform it.

## Lifecycle

- Shutdown drains in-flight work, then exits
- Unhandled rejections are surfaced, never suppressed

```javascript
process.on('SIGTERM', async () => {
  server.close()
  await pool.end()
  process.exit(0)
})
```

Avoid: an abrupt exit dropping accepted requests. A rejection handler
that logs and continues. A health endpoint reporting ready during
shutdown.

## Trigger table

| Seen in the diff | Section |
|---|---|
| work happens in a handler | The event loop |
| data is piped or buffered | Streams |
| a signal or process event | Lifecycle |
