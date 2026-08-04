---
name: nuxt-security
genre: constraint
category: frameworks
paths:
  - "**/server/api/**/*.ts"
  - "**/server/middleware/**/*.ts"
  - "**/nuxt.config.*"
---

# Nuxt Security

Judgment lives in `skills/frameworks/nuxt/`.
The wider surface lives in [`../../security/threat-surface.md`](../../security/threat-surface.md).

## Runtime configuration

- Private values live in `runtimeConfig`; public values live under `public`
- A value's placement decides whether the bundle carries it

```ts
export default defineNuxtConfig({
    runtimeConfig: {
        paymentApiKey: "",
        public: { apiBase: "" },
    },
});
```

Avoid: a secret placed under `public`. A key read from `process.env`
inside a component.

## Server handlers

- Handlers authorise before they act, on every call
- Session is read from the server session, not from a request body

```ts
export default defineEventHandler(async (event) => {
    const session = await requireUserSession(event);
    const body = await readValidatedBody(event, schema.parse);
    return capture(session.tenantId, body);
});
```

Avoid: a handler trusting an identifier the client supplied. Validation
applied only on the page that calls the route.

## Rendered output

- Server-rendered payloads carry only what the page renders
- Untrusted HTML is sanitised on the server before it is sent

```ts
return {
    order: pick(order, ["id", "total", "status"]),
};
```

Avoid: a full record serialised into the page state. Sanitising in the
component that happens to render the value.

## Headers and middleware

- Security headers are set once, in server middleware
- A route that relaxes a header states why, next to the change

```ts
export default defineEventHandler((event) => {
    setResponseHeaders(event, {
        "X-Content-Type-Options": "nosniff",
        "Referrer-Policy": "same-origin",
    });
});
```

Avoid: headers set per handler and drifting apart. A relaxed policy
applied globally to satisfy one route.

## Trigger table

| Seen in the diff | Section |
|---|---|
| runtimeConfig or an env value | Runtime configuration |
| a file under server/api/ | Server handlers |
| data returned to a page | Rendered output |
| a response header or middleware | Headers and middleware |
