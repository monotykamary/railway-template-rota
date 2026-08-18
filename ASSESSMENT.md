# Rota Railway Feasibility Assessment

Decision: **publish-with-documented-limit**

Assessed upstream: Rota `v2.2.1`, released 2026-08-03, commit `775e6d5af52c4e30753d767956ad74a2f96f8b2c`.

## Evidence

- Stable release: `v2.2.1`; not a prerelease or branch build.
- License: Apache License 2.0.
- Official images: `ghcr.io/alpkeskin/rota:2.2.1` and `ghcr.io/alpkeskin/rota-dashboard:2.2.1`.
- Image provenance: both release images pass GitHub artifact-attestation verification for `alpkeskin/rota`.
- Architectures: both Rota images and TimescaleDB include `linux/amd64` and `linux/arm64` manifests.
- Persistence: application state, credentials, proxy definitions, pools, schedules, and metrics reside in TimescaleDB. The database owns one Railway volume.
- Migrations: Core applies ordered PostgreSQL/TimescaleDB migrations during startup.
- Readiness: Core exposes `GET /health`; startup reaches the listener only after the initial database connection and migrations.
- Marketplace overlap: Railway searches for `rota` and `proxy rotation` found no existing Rota or general-purpose proxy-rotation template.

The GitHub release itself is not marked immutable. This wrapper therefore pins the source commit and OCI index digests rather than trusting a movable tag.

## Platform matrix

| Area | Finding | Decision |
|---|---|---|
| Public web | Dashboard, API, docs, health, and WebSockets need one origin. | Gateway owns one Railway HTTPS domain and routes privately to Core and Dashboard. |
| Private networking | Core, Dashboard, Gateway, and TimescaleDB communicate over Railway private DNS. | Supported; no IPv4-only library requirement was found. |
| TCP | Rota exposes one HTTP proxy listener on port `8000`. | Core receives one Railway TCP proxy. |
| UDP | Rota's incoming and upstream proxy paths use TCP. SOCKS support refers to TCP upstream proxies. | No UDP dependency. |
| Nested Docker | No Docker daemon or executor is used at runtime. | Supported. |
| Host devices | No GPU, USB, `/dev/dri`, or arbitrary host mount is required. | Supported. |
| Privileged/kernel control | The container runs as a non-root user and requires no privileged mode or host sysctls. Linux `splice(2)` is an optimization with a portable fallback. | Supported. |
| Volumes | Only TimescaleDB requires persistent default state. | One database volume; no cross-service filesystem. |
| LAN access | The product manages externally reachable upstream proxies, not LAN-only devices. | Supported; private/LAN upstreams need an operator-provided tunnel and are not promised. |
| Shared memory | No configurable `/dev/shm` requirement was found. | Supported. |
| Resources | Upstream publishes no hard minimum. The four-service stack includes TimescaleDB and is not a free-tier micro workload. | Measure locally and live; document observed steady state before publication. |

## Adaptations and limits

1. Railway's TCP proxy has a different public hostname and port from the Gateway web domain. Rota's dashboard-generated proxy URL assumes the web hostname and port `8000`, so operators must use the Core networking endpoint.
2. The Core adapter enables generated incoming-proxy authentication before normal startup. This prevents a cloud deployment from becoming an open proxy after upstream proxies are added.
3. Railway terminates HTTPS. The Gateway keeps Rota's same-origin routing but does not run Caddy certificate automation or persist Caddy state.
4. Credential-authenticated upstream proxies work normally. Providers that require source-IP allowlisting may require Railway Static Outbound IPs.
5. The optional MaxMind file provider is not enabled; the default remote GeoIP provider remains functional.

No privileged containers, UDP ingress, nested Docker, shared volumes, or host devices block the core product. The separate Railway TCP endpoint is visible and supportable, but it must be documented, so the honest classification is `publish-with-documented-limit`.
