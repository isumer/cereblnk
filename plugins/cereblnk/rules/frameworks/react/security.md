---
name: react-security
genre: constraint
category: frameworks
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**/*.tsx"
  - "**/app/**/*.tsx"
  - "**/pages/**/*.tsx"
---

# React Security

Extends [`languages/typescript/security.md`](../../languages/typescript/security.md).

## Rendering

- The framework escapes by default; raw insertion needs a sanitiser
- A URL bound to a link or a source is validated first

```tsx
// escaped by the framework
<span>{comment.body}</span>

// raw insertion is sanitised, and the reason is stated
<article dangerouslySetInnerHTML={{ __html: sanitize(article.html) }} />
```

Avoid: raw HTML from user input. A link target taken from a payload
unchecked. A style value built from a parameter.

## Client state

- Nothing secret lives in client state, storage, or the bundle
- A token in the browser is assumed readable by anything on the page

```tsx
// the session cookie is set by the server, http-only
const session = useSession()

// only what the view renders crosses to the client
const viewer = { id: session.userId, displayName: session.displayName }
```

Avoid: a credential in local storage. An API key shipped to render one
widget. A user object carrying fields the client never needs.

## Effects and requests

- A request from a component carries no privilege the user lacks
- Server-issued identifiers are used; client-supplied ones are checked

```tsx
const orders = useQuery({
  queryKey: ['orders'],
  queryFn: () => api.listOrders(),
})
```

Avoid: an authorisation decision made in a component. A tenant
identifier read from a prop and trusted by the server.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a value reaches markup | Rendering |
| data is held in the client | Client state |
| a component calls an API | Effects and requests |
