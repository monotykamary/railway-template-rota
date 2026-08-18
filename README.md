# Rota on Railway

A production-oriented Railway template for [Rota](https://github.com/alpkeskin/rota), a proxy rotation platform with a Go proxy engine, Next.js dashboard, and TimescaleDB analytics.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/rota)

![Rota](assets/rota-icon.png)

## What this deploys

| Service | Role | Public access |
|---|---|---|
| Gateway | Caddy same-origin router for the dashboard, API, docs, health, and WebSockets | Railway HTTPS domain |
| Dashboard | Rota Next.js dashboard | Private, through Gateway |
| Core | Rota API, schedulers, health checks, and HTTP proxy engine | Private API plus Railway TCP proxy |
| TimescaleDB | Persistent PostgreSQL/TimescaleDB data | Private only |

The Core adapter waits for TimescaleDB, lets Rota apply its first-run migrations, and enables incoming proxy authentication with generated Railway credentials before the long-lived server starts.

## Pinned versions

- Rota `v2.2.1`, commit [`775e6d5af52c4e30753d767956ad74a2f96f8b2c`](https://github.com/alpkeskin/rota/commit/775e6d5af52c4e30753d767956ad74a2f96f8b2c)
- Core image index digest `sha256:098bb83a9e316ed75fbeeed4d350e57c60621aa4b1b52abfbb9d26a261bffe62`
- Dashboard image index digest `sha256:912c38c0db2e6e8d6e336e24a99b34b59c26b1ad275d9deb181c66734d2eb5a3`
- TimescaleDB `2.22.1-pg17`, image index digest `sha256:fba60021a224479e174ae1ec577c1a0576d5185b09fe9e622f1d19e4bf5bab0d`
- Caddy `2.10.2-alpine`, image index digest `sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d`

All application and dependency images are pinned by immutable digest. Updating this repository does not automatically update Rota.

## Post-deploy setup

1. Open the Gateway HTTPS domain.
2. Sign in with `ROTA_ADMIN_USER` and the generated `ROTA_ADMIN_PASSWORD` from the Core service variables.
3. Add only upstream proxies you own or are authorized to use.
4. In Core networking, copy the Railway TCP proxy host and port. Connect clients with `ROTA_PROXY_USER` and the generated `ROTA_PROXY_PASSWORD`.
5. Create proxy pools and test upstream health before routing production traffic.

Example client configuration:

```text
http://<ROTA_PROXY_USER>:<ROTA_PROXY_PASSWORD>@<RAILWAY_TCP_PROXY_HOST>:<RAILWAY_TCP_PROXY_PORT>
```

## Railway-specific limitations

- Railway assigns the Core service a separate TCP hostname and port. Rota's dashboard currently displays the web hostname with port `8000`; that copied address is not the Railway TCP endpoint. Use the endpoint shown under Core networking.
- The template exposes one incoming HTTP proxy listener. Rota can route through HTTP, HTTPS, SOCKS4, SOCKS4A, and SOCKS5 upstream proxies, but it does not expose a SOCKS server to clients.
- Upstream proxy providers that require source-IP allowlisting may require Railway Static Outbound IPs. Credential-authenticated upstream proxies work without that feature.
- Rota's optional local MaxMind database is not enabled. The default `ip-api.com` provider requires no persistent Core filesystem.
- The generated incoming-proxy credentials are reapplied from Core variables on restart. Change `ROTA_PROXY_USER` or `ROTA_PROXY_PASSWORD` in Railway rather than only in Rota's Settings page.

Do not run an unauthenticated public proxy. The adapter enables authentication by default, but operators remain responsible for access control, upstream authorization, and acceptable use.

## Updating

1. Review the new stable upstream release and security notes.
2. Verify both Rota OCI images and `linux/amd64` manifests.
3. Update the pinned source revision and image digests together.
4. Rebuild the adapter and run local plus live Railway tests, including proxy traffic, scheduler behavior, persistence, redeploy, and log scans.
5. Update the template only after all checks pass.

## Upstream and license

- Source: https://github.com/alpkeskin/rota
- Documentation: https://github.com/alpkeskin/rota/blob/v2.2.1/README.md
- Release: https://github.com/alpkeskin/rota/releases/tag/v2.2.1
- License: Apache License 2.0

The Gateway configuration and icon are adapted from Rota at the pinned commit. See [`NOTICE`](NOTICE) and [`assets/ATTRIBUTION.md`](assets/ATTRIBUTION.md).
