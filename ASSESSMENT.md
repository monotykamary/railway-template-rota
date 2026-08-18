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
| Resources | Upstream publishes no hard minimum. The four-service stack includes TimescaleDB and is not a free-tier micro workload. | Live validation observed about 344 MB total memory at idle/validation load; see below. |

## Validation evidence

Validation completed on 2026-08-18 against the pinned wrapper revision and image digests.

- All four production services reached `SUCCESS` with one running replica. Gateway and Core passed Railway health checks; the TimescaleDB volume was `READY` at `/var/lib/postgresql/data`.
- Gateway returned structured healthy status, the Rota dashboard title and static assets, API documentation, and the OpenAPI document. Plain HTTP redirected to managed HTTPS.
- Missing JWTs, an invalid administrator password, missing proxy credentials, and invalid proxy credentials all failed safely. Generated validation credentials successfully authenticated the dashboard API and public proxy endpoint.
- A controlled private source imported one HTTP upstream proxy. Rota marked it active, forwarded HTTP traffic, completed HTTPS `CONNECT`, and carried authenticated dashboard WebSocket traffic.
- A 262-second post-redeploy soak completed 18 health and proxy probes without failure and observed three recurring source fetches. Deployment IDs and replica counts remained stable.
- A source, proxy, and pool survived a Core redeploy. The same records and authenticated traffic then survived a TimescaleDB redeploy; restart logs reported that the existing database directory was reused and initialization was skipped.
- Exact current-deployment logs contained no unexplained DNS, database, scheduler, restart, OOM, panic, permission, or migration errors after the soak. TimescaleDB emitted only its expected first-initialization worker shutdown messages before the final server start.
- Validation-only state and the controlled fixture were removed. The retained project contains only Gateway, Dashboard, Core, and TimescaleDB and remains healthy.

Observed current memory after product traffic and redeploy testing was approximately 250 MB for TimescaleDB, 54 MB for Gateway, 31 MB for Dashboard, and 9 MB for Core. CPU was effectively idle at the observation point. These values are evidence from one low-load run, not resource guarantees or sizing limits.

## Adaptations and limits

1. Railway's TCP proxy has a different public hostname and port from the Gateway web domain. Rota's dashboard-generated proxy URL assumes the web hostname and port `8000`, so operators must use the Core networking endpoint.
2. The Core adapter enables generated incoming-proxy authentication before normal startup. This prevents a cloud deployment from becoming an open proxy after upstream proxies are added.
3. Railway terminates HTTPS. The Gateway keeps Rota's same-origin routing but does not run Caddy certificate automation or persist Caddy state.
4. Credential-authenticated upstream proxies work normally. Providers that require source-IP allowlisting may require Railway Static Outbound IPs.
5. The optional MaxMind file provider is not enabled; the default remote GeoIP provider remains functional.

No privileged containers, UDP ingress, nested Docker, shared volumes, or host devices block the core product. The separate Railway TCP endpoint is visible and supportable, but it must be documented, so the honest classification is `publish-with-documented-limit`.
