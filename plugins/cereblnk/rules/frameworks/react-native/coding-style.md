---
name: react-native-coding-style
genre: constraint
category: frameworks
paths:
  - "**/*.native.tsx"
  - "**/screens/**/*.tsx"
  - "**/components/**/*.native.*"
---

# React Native Coding Style

Judgment lives in `skills/frameworks/react-native/`.
Patterns live in [`patterns.md`](patterns.md).

## Styles

- Styles are created once, outside the component
- A style object is named for what it styles

```tsx
const styles = StyleSheet.create({
    row: { flexDirection: "row", alignItems: "center" },
    amount: { fontVariant: ["tabular-nums"] },
});
```

Avoid: an inline object literal rebuilt on every render. A style name
describing its properties rather than its subject.

## Platform differences

- A difference is expressed once, at the value
- Platform files carry the extension, not a runtime branch

```tsx
const spacing = Platform.select({ ios: 12, android: 8 });

const styles = StyleSheet.create({
    header: {
        paddingTop: Platform.select({ ios: 44, android: 24 }),
    },
});
```

Avoid: `if (Platform.OS === ...)` scattered through a component tree.
Two components that differ only in a constant.

## Lists

- Long lists use a virtualised list with a stable key extractor
- Row components are memoised and take primitive props

```tsx
<FlatList
    data={payments}
    keyExtractor={(item) => item.reference}
    renderItem={renderPaymentRow}
/>
```

Avoid: a mapped array rendering hundreds of rows. A key taken from the
array index.

## Native boundaries

- Native module access sits behind one typed wrapper
- Permissions are requested at the point of use

```tsx
export async function readClipboard(): Promise<string> {
    return Clipboard.getString();
}

export async function withCameraAccess<T>(run: () => Promise<T>) {
    const granted = await requestCameraPermission();
    return granted ? run() : null;
}
```

Avoid: a native call made directly from a screen. A permission
requested at app start for a feature used rarely.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a style object | Styles |
| Platform or an .ios/.android file | Platform differences |
| a list render | Lists |
| a native module or permission | Native boundaries |
