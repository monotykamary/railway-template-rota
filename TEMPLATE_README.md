# Deploy and Host Rota on Railway

## About Hosting Rota

Rota is an open-source proxy rotation platform with a high-performance Go proxy engine, a real-time Next.js dashboard, automatic upstream health checks, proxy sources and pools, per-user routing, and TimescaleDB-backed analytics. This template pins Rota `v2.2.1` and exposes the dashboard and API through one Railway HTTPS domain while exposing the proxy engine through a separate authenticated Railway TCP endpoint.

The Gateway service owns the public web domain. On first deployment, the Core service seeds the administrator from `ROTA_ADMIN_USER` and the generated `ROTA_ADMIN_PASSWORD`. The Railway adapter also enables incoming proxy authentication from generated `ROTA_PROXY_USER` and `ROTA_PROXY_PASSWORD` variables.

## Common Use Cases

- Rotate authorized datacenter or residential proxy pools for scraping workloads.
- Monitor upstream proxy availability and response quality.
- Group upstream proxies by geography, ISP, or tags.
- Provide authenticated users with primary and fallback proxy pools.
- Track proxy request health and time-series usage metrics.

## Dependencies for Rota Hosting

### Deployment Dependencies

- Gateway: a small Caddy adapter built from this repository.
- Dashboard: the pinned official Rota dashboard image.
- Core: the pinned official Rota core image plus a small database-wait and authentication adapter.
- TimescaleDB: the pinned `2.22.1-pg17` image with a persistent Railway volume.
- Railway HTTPS domain on Gateway and a Railway TCP proxy on Core.

### Implementation Details

Gateway routes `/api`, `/ws`, `/docs`, and `/health` to Core over Railway private networking and routes all other paths to Dashboard. Railway terminates public TLS, so Caddy does not manage certificates or require a volume.

Core connects to TimescaleDB through its private Railway domain, applies Rota's built-in migrations, runs recurring source, pool-health, alert, cleanup, and GeoIP tasks, and listens on API port `8001` and proxy port `8000`. TimescaleDB alone owns the persistent volume.

Railway generates the database, administrator, and incoming-proxy passwords. Do not replace cross-service reference variables such as the database host or password with literal values. To rotate incoming-proxy credentials, change the Core `ROTA_PROXY_USER` or `ROTA_PROXY_PASSWORD` variable and redeploy Core.

After deployment, use the TCP host and port shown under Core networking. Rota's dashboard assumes the proxy shares the web hostname and port `8000`, so its copied proxy URL is not correct for Railway. Upstream providers that require source-IP allowlisting may also require Railway Static Outbound IPs.

Add only proxies you own or are authorized to use. Keep incoming authentication enabled and test every pool before production use.

### Why Deploy Rota on Railway?

Railway provides managed service orchestration, private service networking, persistent TimescaleDB storage, HTTPS for the dashboard, a raw TCP endpoint for proxy clients, generated secrets, logs, metrics, and straightforward redeploys. This template preserves Rota's same-origin web architecture while adapting its separate proxy listener honestly to Railway's TCP networking model.
