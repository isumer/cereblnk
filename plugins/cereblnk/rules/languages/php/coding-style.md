---
name: php-coding-style
genre: constraint
category: languages
paths:
  - "**/*.php"
---

# PHP Coding Style

Extends [`common/coding-style.md`](../../common/coding-style.md) and
[`common/naming.md`](../../common/naming.md). Judgment lives in
`skills/languages/php/`.

## Layout

- A published style standard, enforced by a formatter in the repo
- Static analysis at a stated level, raised over time never lowered
- Imports declared for every referenced class, interface and trait

Avoid: a style argument in review. An analyser baseline that only
grows. A fully qualified name used to avoid an import.

## Types

- Strict types declared in every file
- Parameters, returns and properties typed wherever the version allows

```php
<?php

declare(strict_types=1);

final class Money
{
    public function __construct(
        public readonly int $minorUnits,
        public readonly string $currency,
    ) {
        if ($minorUnits < 0) {
            throw new InvalidArgumentException('minorUnits must not be negative');
        }
    }
}
```

Avoid: an untyped parameter in new code. A docblock type with no
declared type beside it. An array where a value object belongs.

## Comparison and absence

- Strict comparison, unless coercion is the stated point
- Absence is modelled, not defaulted away

```php
if ($order->settledAt === null) {
    return SettlementState::Pending;
}
```

Avoid: loose comparison on request data. A null coalesce over a
required value. A falsy check where zero or an empty string is data.

## Errors

- Domain failures throw a domain exception carrying the identifier
- The cause travels with every rethrow

```php
try {
    return $this->gateway->capture($order->total());
} catch (GatewayException $e) {
    throw new SettlementFailed("order {$order->id}", previous: $e);
}
```

Avoid: a catch of the base throwable in a service. A message with no
identifier. An error suppressed with the silencing operator.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a file or import is added | Layout |
| a signature or property | Types |
| a comparison or a default | Comparison and absence |
| an exception is thrown or caught | Errors |
