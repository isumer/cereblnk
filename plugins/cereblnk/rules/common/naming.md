---
name: common-naming
genre: constraint
category: common
applies_when: any code-touching task — this is the floor every other rule extends
---

# Naming

Technology-neutral. Language rules decide the case; this decides the
word.

## Words

- Name the role in the domain, never the type
- Booleans read as an assertion: is, has, can, requires, was
- Collections plural, elements singular
- Units belong in the name

```text
customerEmail · pendingInvoices · retryBudget · settlementDeadline
isExpired · hasPendingCharge · canRetry · requiresApproval
timeoutMillis · sizeBytes · priceMinorUnits · retentionDays
orders / order · ordersByTenant
```

Avoid: a type suffix on a domain value · a negated boolean producing
double negatives · a plural name holding one value · a bare duration,
size, or amount.

## Abbreviations

- The domain's own abbreviations stay; invented ones expand

```text
vatRate · ibanPrefix · httpStatusCode
customerRepository · maximumAttempts · temporaryCredential
```

Avoid: vowel-dropping · per-author shortenings · two conventions in
one module.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a new identifier, boolean, or collection | Words |
| a number carrying a unit | Words |
| a shortened word | Abbreviations |
