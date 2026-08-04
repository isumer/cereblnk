---
name: php-security
genre: constraint
category: languages
paths:
  - "**/*.php"
  - "**/composer.json"
---

# PHP Security

Extends [`common/security.md`](../../common/security.md).

## Input

- Request data is validated once, into a typed object
- Superglobals are read at one boundary, never in business code

```php
$request = OrderRequest::fromArray($validator->validated());
return $this->service->create($request->toDomain());

// the boundary reads the superglobal; nothing inward does
final class HttpRequestFactory
{
    public static function fromGlobals(): OrderRequest
    {
        return OrderRequest::fromArray($_POST);
    }
}
```

Avoid: a superglobal read inside a service. A request array spread
into a query. A path or filename taken from input unchecked.

## Queries and commands

- Values bind as parameters; identifiers come from an allow-list
- Shell arguments are escaped, or the call is replaced

```php
$statement = $pdo->prepare(
    'select id, total from orders where tenant = :tenant and id = :id'
);
$statement->execute(['tenant' => $tenant, 'id' => $orderId]);
```

Avoid: a query built by concatenation. A table name from a request. A
shell call assembled from user input.

## Output

- Values are escaped for the context that renders them
- Serialization of untrusted input never reconstructs objects

```php
echo htmlspecialchars($comment->body, ENT_QUOTES, 'UTF-8');

$payload = json_decode($body, true, flags: JSON_THROW_ON_ERROR);
```

Avoid: unescaped output in a template. Native unserialization of
external data. A response echoing an internal message.

## Dependencies

- The lock file is committed; the tree is audited on change

```json
{
  "config": { "allow-plugins": false },
  "scripts": { "audit": "composer audit --locked" }
}
```

Avoid: an unpinned production requirement. A package added to silence
an autoload error.

## Trigger table

| Seen in the diff | Section |
|---|---|
| request data is used | Input |
| a query or command is built | Queries and commands |
| a value is rendered or serialized | Output |
| a package changes | Dependencies |
