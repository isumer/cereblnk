---
name: react-native-security
genre: constraint
category: frameworks
paths:
  - "**/screens/**/*.tsx"
  - "**/*.native.tsx"
  - "**/native/**/*.ts"
---

# React Native Security

Judgment lives in `skills/frameworks/react-native/`.
The wider surface lives in [`../../security/threat-surface.md`](../../security/threat-surface.md).

## Stored credentials

- Tokens live in the platform keystore, reached through one module
- Storage writes state their sensitivity at the call site

```ts
export async function storeSession(token: string) {
    await Keychain.setGenericPassword("session", token, {
        accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED,
    });
}
```

Avoid: a token written to async storage. A credential cached in module
state for convenience.

## Transport

- Requests go to pinned hosts over TLS, configured once
- Development exceptions are absent from release configuration

```ts
export const api = createClient({
    baseUrl: config.apiBase,
    timeout: 10_000,
});
```

Avoid: a cleartext exception left in a release build. A base URL that
falls back to a local host.

## Deep links

- Every incoming link is parsed and validated before it routes
- A link never carries an action the session has not authorised

```ts
export function resolveLink(url: string): Route | null {
    const parsed = new URL(url);
    return ROUTES[parsed.pathname] ?? null;
}
```

Avoid: a link parameter passed straight into navigation. A deep link
that performs a state change on arrival.

## Screen content

- Sensitive screens opt out of screenshots and app-switcher previews
- Logs never carry request bodies from authenticated calls

```ts
useEffect(() => {
    ScreenGuard.register();
    return () => ScreenGuard.unregister();
}, []);
```

Avoid: a card number visible in the task switcher. A debug log left
enabled in release.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a token or credential write | Stored credentials |
| a network client or base URL | Transport |
| a deep link or URL scheme | Deep links |
| a sensitive screen or a log call | Screen content |
