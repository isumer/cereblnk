---
name: electron-testing
genre: constraint
category: frameworks
paths:
  - "**/main/**/*.test.ts"
  - "**/preload/**/*.test.ts"
  - "**/e2e/**/*.spec.ts"
---

# Electron Testing

Judgment lives in `skills/frameworks/electron/`.
Security constraints live in [`security.md`](security.md).

## Main process

- Main process logic is extracted and tested without a window
- Window creation is asserted through its options, not by launching

```ts
const options = buildWindowOptions();

expect(options.webPreferences.contextIsolation).toBe(true);
expect(options.webPreferences.nodeIntegration).toBeUndefined();
```

Avoid: main logic reachable only by starting the app. A security
preference asserted by reading a running window.

## The bridge

- Every exposed function has a test naming its channel
- The surface is asserted as a whole, so additions are visible

```ts
expect(Object.keys(exposedApi).sort())
    .toEqual(["capture", "refund"]);

expect(invoke).toHaveBeenCalledWith("payments:capture", "ref-1");
```

Avoid: a bridge function added with no test. A channel string asserted
by substring.

## Handlers

- Handlers are tested as input to output, with a faked event
- Input validation is asserted on the rejection path

```ts
const event = { sender: { id: 1 } } as IpcMainInvokeEvent;

await expect(handleCapture(event, { reference: "" }))
    .rejects.toThrow(/reference/);

await expect(handleCapture(event, { reference: "ref-1" }))
    .resolves.toMatchObject({ status: "settled" });
```

Avoid: a handler tested through the renderer. A validation branch no
test reaches.

## End-to-end

- End-to-end runs drive the packaged application
- Each run starts from a clean user data directory

```ts
const app = await electron.launch({
    args: ["."],
    env: { USER_DATA: tempDir },
});
```

Avoid: an end-to-end run reusing local application state. A suite that
passes only on the developer's machine.

## Trigger table

| Seen in the diff | Section |
|---|---|
| main process logic or window options | Main process |
| contextBridge exposure | The bridge |
| an ipcMain handler | Handlers |
| a packaged-app scenario | End-to-end |
