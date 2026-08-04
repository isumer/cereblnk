---
name: react-native-testing
genre: constraint
category: frameworks
paths:
  - "**/*.native.test.tsx"
  - "**/screens/**/*.test.tsx"
  - "**/e2e/**/*.e2e.ts"
---

# React Native Testing

Judgment lives in `skills/frameworks/react-native/`.
Patterns live in [`patterns.md`](patterns.md).

## Component tests

- Queries address accessibility labels and roles
- Interaction is driven through fired events, not handler calls

```tsx
const { getByLabelText } = render(<PaymentRow payment={payment} />);

fireEvent.press(getByLabelText("Capture payment"));

expect(onCapture).toHaveBeenCalledWith("ref-1");
```

Avoid: a query on a test identifier that styling can move. A handler
invoked directly instead of through the element.

## Native modules

- Native modules are faked at their module boundary, once
- The fake declares every method the code calls

```ts
jest.mock("react-native-keychain", () => ({
    setGenericPassword: jest.fn(),
    getGenericPassword: jest.fn(async () => null),
}));
```

Avoid: a partial fake that returns undefined for an unmocked method. A
native call left real in a unit test.

## Platform coverage

- A platform difference is covered on both platforms
- The platform under test is set explicitly

```ts
describe.each(["ios", "android"])("%s header", (os) => {
    beforeEach(() => (Platform.OS = os));
    it("uses the platform inset", () => { ... });
});
```

Avoid: a platform branch tested only on the default platform. A suite
whose result depends on the host machine.

## Device runs

- Device runs cover flows a user completes end to end
- Each run installs a fresh build with seeded data

```ts
await device.launchApp({ delete: true });
await element(by.id("pay")).tap();
await expect(element(by.text("Settled"))).toBeVisible();
```

Avoid: a device suite repeating unit coverage. A run depending on state
left by the last one.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a screen or component test | Component tests |
| a native module import | Native modules |
| Platform.select or a platform file | Platform coverage |
| a user flow | Device runs |
