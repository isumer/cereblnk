---
name: dart-coding-style
genre: constraint
category: languages
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---

# Dart Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/dart/`.

## Layout

- Formatting by the standard formatter; analyser strictness stated in
  the repository and raised over time
- Generated files are never edited; the generator's input is

Avoid: a style argument in review. An analyser rule disabled per file.
A correction applied inside a generated artefact.

## Null safety

- Absence is modelled in the type and narrowed at use
- `late` is for initialisation order, never for optional values

```dart
Customer? find(CustomerId id) => _index[id];

CustomerResponse fetch(CustomerId id) {
  final customer = find(id);
  if (customer == null) {
    throw CustomerNotFoundException(id);
  }
  return CustomerResponse.from(customer);
}
```

Avoid: the assertion operator used to satisfy the analyser. A `late`
field where null is a legal state. A default that hides an absent value.

## Closed sets

- A finite set of outcomes is sealed and matched exhaustively

```dart
sealed class SettlementResult {}

final class Captured extends SettlementResult {
  const Captured(this.amount);
  final Money amount;
}

String describe(SettlementResult result) => switch (result) {
      Captured(:final amount) => 'captured $amount',
      Declined(:final code) => 'declined $code',
      Deferred() => 'deferred',
    };
```

Avoid: a default branch on a sealed type. An enum beside nullable
detail fields. A status string with no constraint.

## Async and disposal

- Every subscription and controller is disposed where it was created
- An awaited future guards against a disposed owner

```dart
@override
void dispose() {
  _subscription.cancel();
  _controller.close();
  super.dispose();
}
```

Avoid: a subscription with no cancellation. A future writing state
after disposal. A timer surviving its owner.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file or analyser setting | Layout |
| a nullable value or a `late` field | Null safety |
| a closed set of outcomes | Closed sets |
| a subscription, controller, or future | Async and disposal |
