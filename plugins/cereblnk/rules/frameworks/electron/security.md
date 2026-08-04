---
name: electron-security
genre: constraint
category: frameworks
paths:
  - "**/main.ts"
  - "**/main.js"
  - "**/preload.ts"
  - "**/preload.js"
  - "**/preload.cjs"
  - "**/electron/**/*.ts"
---

# Electron Security

Extends [`frameworks/nodejs/security.md`](../nodejs/security.md).
Judgment lives in `skills/frameworks/electron/`.

## Window preferences

- Context isolation on, node integration off, sandbox on, web security on
- These are the modern defaults; any departure is documented with what
  it unblocks
- Disabling context isolation also disables the process sandbox,
  whatever the sandbox setting says

```ts
const window = new BrowserWindow({
  webPreferences: {
    preload: path.join(__dirname, 'preload.cjs'),
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
    webSecurity: true,
  },
})
```

Avoid: node integration enabled to make a library work. Web security
disabled to load a local file. A webview tag whose preferences differ
from the window's. Experimental features enabled to work around a bug.

## The bridge

- One exposed function per operation, on a fixed channel
- The bridge changes how the renderer asks, never what it may reach

```ts
contextBridge.exposeInMainWorld('preferences', {
  load: () => ipcRenderer.invoke('preferences:load'),
  save: (value: Preferences) => ipcRenderer.invoke('preferences:save', value),
})
```

Avoid: a general send or invoke function exposed. A Node module handed
to the renderer. A channel name taken from renderer input. An object
exposed whose methods the renderer can walk.

## Messages

- Arguments are validated in the main process, by schema
- The sender is checked before privileged work

```ts
ipcMain.handle('preferences:save', (event, raw) => {
  assertTrustedSender(event.senderFrame)
  const value = PreferencesSchema.parse(raw)

  return store.save(value)
})
```

Avoid: a handler trusting its payload. A handler that answers any
frame. A path or command built from a message argument.

## Navigation and shell

- Navigation and window opening are decided by allow-list in the main process
- An external target is validated before it reaches the shell

```ts
window.webContents.setWindowOpenHandler(({ url }) =>
  isAllowed(url) ? { action: 'allow' } : { action: 'deny' },
)
```

Avoid: an external URL opened unchecked. A redirect target from
content. A new window created with the parent's privileges by default.

## Permissions and content

- Permissions are denied by default and granted per feature
- A content security policy is set, and it is restrictive

Avoid: a permission handler that grants everything. A policy absent
because the app loads only local files today.

## Updates

- Artefacts are signed and verified; the staging path is user-owned

Avoid: an unsigned update accepted. A writable staging directory. An
update source over an unverified connection.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a window or webview is created | Window preferences |
| the preload exposes something | The bridge |
| a message handler is added | Messages |
| navigation or an external link | Navigation and shell |
| a permission or policy changes | Permissions and content |
| update configuration changes | Updates |
