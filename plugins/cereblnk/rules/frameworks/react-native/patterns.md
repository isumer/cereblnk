---
name: react-native-patterns
genre: constraint
category: frameworks
paths:
  - "**/*.native.tsx"
  - "**/*.ios.tsx"
  - "**/*.android.tsx"
  - "**/screens/**/*.tsx"
  - "**/navigation/**/*.tsx"
---

# React Native Patterns

Extends [`frameworks/react/patterns.md`](../react/patterns.md).
Judgment lives in `skills/frameworks/react-native/`.

## Platform differences

- A difference lives behind one boundary, not inside components
- Both platforms are exercised before the difference is called done

```tsx
export const spacing = Platform.select({
  ios: { header: 44 },
  android: { header: 56 },
})!
```

Avoid: a platform check inside three components. A branch that leaves
one platform untested. A shared component whose behavior silently
diverges.

## Lists

- Every growable list is virtualised, with a key identifying the item

```tsx
<FlatList
  data={orders}
  keyExtractor={(order) => order.id}
  renderItem={({ item }) => <OrderRow order={item} />}
/>
```

Avoid: a mapped array rendering every row. An index used as a key. A
list proven on twenty rows.

## Bridge cost

- Work crossing to native is batched, not repeated per item
- Animation is driven natively where the API allows

```tsx
Animated.timing(opacity, {
  toValue: 1,
  duration: 200,
  useNativeDriver: true,
}).start()
```

Avoid: a native call inside a render loop. A frame-by-frame update
from JavaScript. A measurement taken per item during scroll.

## Device reality

- A performance claim names its platform and device class
- Permissions handle the denied and revoked cases

```tsx
const status = await requestCameraPermission()
if (status !== 'granted') {
  return <PermissionExplainer onRetry={openSettings} />
}
```

Avoid: a simulator result reported as a device claim. A granted-only
permission path. A secret in the bundle treated as hidden.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a platform branch appears | Platform differences |
| a collection is rendered | Lists |
| native work or animation | Bridge cost |
| a measurement or a permission | Device reality |
