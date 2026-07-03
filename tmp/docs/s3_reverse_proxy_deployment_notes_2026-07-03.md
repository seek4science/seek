# S3 Storage Behind a Reverse Proxy — Production Deployment Notes

**Date:** 2026-07-03 · **Applies to:** `Seek::Storage::S3Adapter` (`lib/seek/storage/s3_adapter.rb`), `config/seek_storage.yml`

## The problem

SEEK talks to the S3-compatible store (AWS S3, MinIO, SeaweedFS) using `endpoint`, and this same
client is used to generate presigned download URLs. In a typical deployment the app reaches the
store over an internal address — a docker-network hostname (`seaweedfs:8333`), a Kubernetes service
DNS name, or an internal-only load balancer. Presigned URLs are handed to the *browser*, though,
which can't resolve or route to that internal address. Without a fix, downloads redirect to a host
the user's machine can't reach.

## The fix: `public_endpoint`

`S3Adapter` accepts an optional `public_endpoint` config key. When set, a second client is built
against it and used **only** for signing presigned URLs (`Aws::S3::Presigner`); the original client
(built from `endpoint`) still handles all internal traffic (`write`, `open`, `stream`, `head_object`,
etc.). If `public_endpoint` is absent, presigning falls back to `endpoint` — so a setup where the two
are already the same (e.g. talking directly to real AWS S3) needs no extra config.

Config keys (`config/seek_storage.yml`, production section, env-driven):

| Env var | Purpose | Example |
|---|---|---|
| `SEEK_STORAGE_ENDPOINT` | Internal address SEEK uses for all S3 API calls | `http://seaweedfs:8333` |
| `SEEK_STORAGE_PUBLIC_ENDPOINT` | Externally-reachable address used only for signing presigned URLs | `https://s3.example.org` |
| `SEEK_STORAGE_FORCE_PATH_STYLE` | Required `true` for MinIO/SeaweedFS; not needed for real AWS S3 | `true` |

## Recommended production topology

Put the S3-compatible store behind the same reverse proxy that fronts SEEK, on its own subdomain
(avoids any path collision with SEEK's own routes, since path-style URLs look like
`https://s3.example.org/<bucket>/<key>?X-Amz-...`):

```
Internet ── HTTPS ── reverse proxy ──┬── SEEK app        (seek.example.org)
                                     └── S3-compatible store (s3.example.org → seaweedfs)
```

- `SEEK_STORAGE_ENDPOINT` — the address SEEK (inside the compose network) uses for all S3 API calls.
- `SEEK_STORAGE_PUBLIC_ENDPOINT` — the public, TLS-terminated address the reverse proxy exposes for
  the same store, used only to sign presigned URLs.

**What the reverse proxy's upstream address should be depends on where the proxy itself runs:**

| Where the reverse proxy runs | Upstream (`proxy_pass`) target | Why |
|---|---|---|
| A container joined to the *same* docker-compose network as `seaweedfs` (e.g. added as a service in `docker-compose-s3.yml`) | `http://seaweedfs:8333` | It can resolve the compose service's internal DNS name directly — no host port needs to be published at all. |
| Outside that network — host-level nginx/Traefik, a separate compose project, an external load balancer (the common case for a docker-compose deployment) | `http://localhost:9000` (or whatever host/port the container's S3 port is published to) | `seaweedfs` isn't resolvable outside its compose network; the proxy can only reach the container through the port docker published to the host. |

Most single-VM docker-compose deployments fall into the second case — an existing host-level proxy
that also fronts other services — so the upstream is the **published host port**, not the internal
compose service name. `SEEK_STORAGE_ENDPOINT` (used by the *SEEK app container*, which is on the
compose network) and the *reverse proxy's* upstream address are two different things and don't need
to match: SEEK reaches SeaweedFS via `seaweedfs:8333` internally; the proxy reaches it via
`localhost:9000` externally.

## Critical gotcha: the `Host` header must survive the proxy unchanged

AWS SigV4 presigned URLs sign the `Host` header as part of the canonical request. The SDK signs
against the host in `public_endpoint` (`s3.example.org`); when the browser follows the link it sends
`Host: s3.example.org`. The S3-compatible server recomputes the signature from the request it
actually receives — if the reverse proxy rewrites `Host` to the internal upstream name (a common
default with `proxy_pass`), signature verification fails with `SignatureDoesNotMatch`.

nginx example (host-level proxy, published-port upstream) — the `proxy_set_header Host $host` line
is not optional:

```nginx
server {
    listen 443 ssl;
    server_name s3.example.org;

    location / {
        proxy_pass http://localhost:9000;   # docker-published port, not the compose service name
        proxy_set_header Host $host;        # preserve the public hostname used to sign the URL
    }
}
```

The same principle applies to any reverse proxy (Traefik, HAProxy, an ALB/ingress) — whatever sits
between the browser and the store must forward the original `Host` header untouched.

## Checklist

- [ ] S3-compatible store reachable internally by SEEK at `SEEK_STORAGE_ENDPOINT`
- [ ] Store also reachable externally (via reverse proxy, ideally a dedicated subdomain) at `SEEK_STORAGE_PUBLIC_ENDPOINT`
- [ ] Reverse proxy preserves the `Host` header on requests to that subdomain
- [ ] `SEEK_STORAGE_PUBLIC_ENDPOINT` uses `https://` if SEEK itself is served over HTTPS (avoids mixed-content warnings)
- [ ] `SEEK_STORAGE_FORCE_PATH_STYLE=true` set for MinIO/SeaweedFS

## Local reference implementation

`docker-compose-s3.yml` demonstrates the same pattern for local development: SEEK reaches SeaweedFS
internally at `http://seaweedfs:8333` (`docker/s3.env`), while `SEEK_STORAGE_PUBLIC_ENDPOINT` points
at the host-mapped port `http://localhost:9000` so presigned URLs work from a browser on the host.
There's no reverse proxy in that setup because the port is mapped directly — the `Host` header
concern only applies once a proxy sits in between.
