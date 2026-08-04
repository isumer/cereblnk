---
name: electron-coding-style
genre: constraint
category: frameworks
paths:
  - "**/main/**/*.ts"
  - "**/preload/**/*.ts"
  - "**/electron/**/*.ts"
---

# Electron Coding Style

Judgment lives in `skills/frameworks/electron/`.
Security constraints live in [`security.md`](security.md).

## Process separation

- Main, preload, and renderer live in separate directories
- A file states which process it runs in, by its location

```text
    main/        window lifecycle, native menus, updates
    preload/     the bridge, and nothing else
    renderer/    UI only, no node built-ins
```

Avoid: a shared module imported by both main and renderer. Node
built-ins reached from renderer code.

## The bridge

- The preload exposes named functions, never objects with behaviour
- Each exposed function maps to one channel

```ts
contextBridge.exposeInMainWorld("payments", {
    capture: (reference: string) =>
        ipcRenderer.invoke("payments:capture", reference),
});
```

Avoid: exposing `ipcRenderer` itself. A bridge function that accepts a
channel name from the caller.

## Channels

- Channel names are namespaced constants, declared once
- One handler per channel, registered at startup

```ts
export const CHANNELS = {
    capture: "payments:capture",
    refund: "payments:refund",
} as const;
```

Avoid: a channel string written twice. A handler registered inside a
window event.

## Window creation

- Window options are declared in one factory
- Every window is created through it

```ts
function createWindow(): BrowserWindow {
    return new BrowserWindow({
        webPreferences: { preload, contextIsolation: true },
    });
}
```

Avoid: window options copied between call sites. A second window built
with different preferences by accident.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file under main/, preload/, renderer/ | Process separation |
| contextBridge or ipcRenderer | The bridge |
| an IPC channel string | Channels |
| new BrowserWindow | Window creation |
