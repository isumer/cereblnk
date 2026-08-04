---
name: electron-patterns
genre: constraint
category: frameworks
paths:
  - "**/main.ts"
  - "**/main.js"
  - "**/preload.ts"
  - "**/electron/**/*.ts"
---

# Electron Patterns

Extends [`common/patterns.md`](../../common/patterns.md).

## Process responsibilities

- The main process owns privilege, state that must persist, and secrets
- The renderer owns presentation and nothing privileged

```ts
// main: owns the token, exposes an operation
ipcMain.handle('orders:list', async (event) => {
  assertTrustedSender(event.senderFrame)
  return api.listOrders(await credentials.token())
})
```

Avoid: a credential held in renderer state. Business rules split
across both processes. The main process rendering, or the renderer
deciding.

## Long work

- Work longer than a frame leaves the renderer, and reports progress
- Heavy computation goes to a utility process, not the main one

```ts
const worker = utilityProcess.fork(path.join(__dirname, 'indexer.js'))
worker.postMessage({ kind: 'reindex', root })
worker.on('message', (progress) => window.webContents.send('index:progress', progress))
```

Avoid: a blocking call in the main process, which freezes every
window. A long task in the renderer, which freezes its own.

## Lifecycle

- Window creation waits for the app to be ready
- Every listener, watcher and timer is removed when its window closes

```ts
app.whenReady().then(createWindow)

window.on('closed', () => {
  watcher.close()
  clearInterval(timer)
})
```

Avoid: a watcher outliving its window. A quit path that skips
draining. State assumed to survive a relaunch with no store behind it.

## Platform differences

- A platform difference sits behind one boundary, not inside features
- Menus, shortcuts and window behavior differ, and each is stated

```ts
const accelerator = process.platform === 'darwin' ? 'Cmd+,' : 'Ctrl+,'
const userData = app.getPath('userData')
```

Avoid: a platform check spread through three modules. A shortcut that
collides with a system one. A path assembled by string concatenation.

## Trigger table

| Seen in the diff | Section |
|---|---|
| privileged work or state is placed | Process responsibilities |
| a task may exceed a frame | Long work |
| a window, listener, or quit path | Lifecycle |
| a platform branch appears | Platform differences |
