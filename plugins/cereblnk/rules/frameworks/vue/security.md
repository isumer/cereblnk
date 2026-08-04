---
name: vue-security
genre: constraint
category: frameworks
paths:
  - "**/*.vue"
  - "**/router/**/*.ts"
---

# Vue Security

Judgment lives in `skills/frameworks/vue/`.
The wider surface lives in [`../../security/threat-surface.md`](../../security/threat-surface.md).

## Rendering untrusted values

- Interpolation is the default; it escapes
- Raw HTML is rendered only from a sanitised, server-owned value

```vue
<template>
    <p>{{ comment.body }}</p>
    <div v-html="sanitised(article.body)" />
</template>
```

Avoid: `v-html` bound to user input. A sanitiser applied in the
template of one component and forgotten in another.

## Attribute and URL binding

- URLs are validated against an allowed scheme before binding
- Dynamic attribute names come from a fixed set

```ts
const ALLOWED = /^https?:\/\//;

const safeHref = computed(() =>
    ALLOWED.test(props.url) ? props.url : "#");

const attrs = computed(() => ({
    href: safeHref.value,
    rel: "noopener noreferrer",
}));
```

Avoid: an href bound straight from data. An attribute name taken from a
response body.

## Route guards

- A guard decides navigation; the server decides access
- Guards read a resolved session, not a token they parse themselves

```ts
router.beforeEach((to) =>
    to.meta.requiresAuth && !session.isAuthenticated
        ? { name: "login" }
        : true);
```

Avoid: authorisation enforced only in the router. A guard decoding a
token to read claims.

## Client-held data

- Only what the view needs reaches the client
- Secrets never enter build-time configuration

```ts
export const config = {
    apiBase: import.meta.env.VITE_API_BASE,
};

export function toBadge(user: User): Badge {
    return { initials: user.initials, colour: user.colour };
}
```

Avoid: a full user record cached for a name badge. An API key placed in
a variable the bundler inlines.

## Trigger table

| Seen in the diff | Section |
|---|---|
| v-html or an interpolated HTML string | Rendering untrusted values |
| :href, :src, or a dynamic attribute | Attribute and URL binding |
| a router guard | Route guards |
| an env variable or cached response | Client-held data |
