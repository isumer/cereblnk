---
name: angular-security
genre: constraint
category: frameworks
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.interceptor.ts"
  - "**/*.guard.ts"
---

# Angular Security

Extends [`languages/typescript/security.md`](../../languages/typescript/security.md).

## Templates

- Interpolation escapes; bypassing it needs a sanitiser and a reason
- A URL or resource bound from input is validated before binding

```typescript
// escaped by the framework
<p>{{ comment.body }}</p>

// raw insertion is sanitised first, and the reason is stated
this.safeHtml = this.sanitizer.bypassSecurityTrustHtml(sanitize(raw))
```

Avoid: raw HTML bound from user input. A trust call used to silence a
warning. A style or script URL built from a parameter.

## Interceptors

- One interceptor attaches credentials, and it checks the destination
- A token never travels to an origin outside the allow-list

```typescript
intercept(req: HttpRequest<unknown>, next: HttpHandler) {
  if (!this.isTrustedOrigin(req.url)) {
    return next.handle(req)
  }
  return next.handle(req.clone({ setHeaders: { Authorization: this.token() } }))
}
```

Avoid: an authorization header added to every outbound request. A
retry that replays a credential to a redirected host.

## Guards

- A guard improves the experience; the server makes the decision
- A guarded route resolves its permission before it renders

```typescript
export const adminGuard: CanActivateFn = () =>
  inject(SessionService).hasRole('ADMIN') || inject(Router).parseUrl('/orders')
```

Avoid: authorisation enforced only in the router. A component rendered
then hidden. A guard whose failure leaves the user in a loop.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a template binds a value | Templates |
| an interceptor is added | Interceptors |
| a route is guarded | Guards |
