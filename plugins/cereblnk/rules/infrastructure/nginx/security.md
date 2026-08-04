---
name: nginx-security
genre: constraint
category: infrastructure
density: neutral
paths:
  - "**/nginx.conf"
  - "**/nginx/**/*.conf"
  - "**/conf.d/**/*.conf"
  - "**/sites-available/**"
  - "**/sites-enabled/**"
---

# Nginx Security

Judgment lives in `skills/infrastructure/nginx/`.

## Exposure

- The server announces no version and serves no directory listing
- A default server answers unknown hosts with a refusal, not the app

```nginx
server_tokens off;
autoindex off;

server {
    listen 80 default_server;
    return 444;
}
```

Avoid: an `autoindex on` left from debugging a static path. A status or
stub endpoint reachable from outside the cluster. An unmatched host
falling through to the first server block by accident.

## Transport

- TLS terminates with a modern protocol set and no downgrade
- Proxied requests carry the original scheme and client address

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
add_header Strict-Transport-Security "max-age=31536000" always;

proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

Avoid: TLSv1.0 or TLSv1.1 retained for one legacy client. An
`X-Forwarded-For` appended without trusting the upstream, which lets a
caller forge its own address.

## Limits

- Request body and header sizes are bounded per location
- Timeouts are set, so a slow client cannot hold a worker

```nginx
client_max_body_size 8m;
client_body_timeout 10s;
send_timeout 10s;

limit_req_zone $binary_remote_addr zone=api:10m rate=20r/s;
location /api/ {
    limit_req zone=api burst=40 nodelay;
}
```

Avoid: an unbounded body size on an upload path. A rate limit zone
declared but never applied in a location. A read timeout longer than
the upstream's own.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a server or location block is added | Exposure |
| TLS or a proxy header changes | Transport |
| a size, timeout, or rate limit changes | Limits |
