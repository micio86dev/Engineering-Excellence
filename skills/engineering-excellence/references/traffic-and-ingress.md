# Traffic: Reverse Proxies and Ingress

Every request enters through one component: the proxy. Get its defaults right once, or debug the same
six settings for a year.

## Choose the proxy by configuration model

| Proxy | Strength | Cost |
| --- | --- | --- |
| Caddy | Automatic TLS, tiny config, HTTP/2 and 3 by default | Fewer advanced knobs; dynamic clustering is not its job |
| Traefik | Native Docker labels and Kubernetes CRDs, ACME built in, good middleware set | A second configuration language to learn |
| nginx / ingress-nginx | Ubiquitous, predictable performance, every problem already answered somewhere | Config sprawl, ACME and dynamic backends need extra pieces |
| Envoy / Gateway API | The forwarding plane everything else is compared against, L7 policy at scale | You are now writing a platform |

Before standardising on a Kubernetes controller, check its support status: a retired controller is an
unpatched edge. `kubernetes/ingress-nginx` is the worked example, its repository archived by the owner on
24 March 2026 and read-only since (https://github.com/kubernetes/ingress-nginx): an archived controller still
runs, but its CVEs stop being fixed. Start new work on Gateway API, and treat any migration off a retired
controller as a release-sized project with two proxies running side by side, not as a chart bump.

Pick one, write down why, and stop running a second one "temporarily" in the same path.

## TLS, the part that breaks at 03:00

- ACME HTTP-01 for single hosts, DNS-01 for wildcards and for anything behind a private network. Use the
  DNS provider's API token scoped to the zone, and keep it in the secret store, not in the proxy config.
- Use the staging ACME endpoint in every test environment; production rate limits are per hostname and
  are not friendly to a loop of redeploys.
- Store certificates where they survive a container restart (a volume or a secret), or accept a burst of
  issuance after each deploy.
- Minimum TLS 1.2, prefer 1.3; modern ciphers only; disable TLS compression and renegotiation; OCSP
  stapling where supported.
- HSTS: start with `max-age=300`, raise to a year once verified, and add `includeSubDomains` only when
  every subdomain is HTTPS. Preload is a one-way door.
- Redirect HTTP to HTTPS at the proxy, and make sure the app knows it is behind TLS (`X-Forwarded-Proto`)
  or it will emit insecure redirects and drop secure cookies.

## Defaults worth copying

| Setting | Starting value | Why |
| --- | --- | --- |
| Connect timeout | 5 s | Fail fast to a dead backend instead of hanging |
| Read/send timeout | 60 s, longer per route where a job needs it | Default infinite timeouts pin workers forever |
| Body size limit | 10 MB global, explicit per upload route | Prevents memory exhaustion by default |
| Request rate | 20 r/s per IP, burst 40; stricter on auth | Blunt but catches the obvious abuse |
| Connections per IP | 50 | Cheap protection against one client starving the rest |
| Header buffer | 16 KB | Large cookies are the usual cause of 400/431 |
| Keepalive to backend | on, 60 s | Reconnection cost dominates small requests |
| Compression | gzip/brotli for text, off for images and already-compressed payloads | Saves bandwidth, wastes CPU on the wrong types |
| Real client IP | trusted proxy list only | Trusting `X-Forwarded-For` from the internet makes logs and rate limits fiction |
| Server tokens | off | Version banners are free reconnaissance |
| Security headers | `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options`/frame-ancestors, CSP per app | The proxy is the cheapest place to add them to everything |
| Access log | structured, with request id, latency, upstream, status | The first thing you read in an incident |

Do not enable HTTP/3 until you have confirmed UDP is open along the whole path; a half-enabled QUIC
looks like a random slow network.

## Routing and health

- Route by hostname first, then path; ambiguous path rules are how `/api` ends up served by the admin app.
- Prefer `Prefix` matches in Gateway semantics: `/api` matching `/apiary` is a real bug class.
- Health checks against a shallow endpoint that proves the process answers, not a deep one that hits the
  database and turns a slow query into a fleet-wide outage.
- Weighted routes give you canary with no extra components; keep the weights in git.
- `retry` on idempotent methods only; retrying a `POST` duplicates data.

## Docker specifics

- `providers.docker.exposedByDefault=false`: opt in per container, so a stray service never gets a route.
- Labels are the contract: route, TLS resolver, middleware chain, and one label per concern.
- Ports published on `0.0.0.0` are routes you did not review; bind to the proxy's network instead.
- `forwardedHeaders.insecure=false` and an explicit `trustedIPs` for the proxy hop.
- Filesystem or Docker provider, not both, for the same router name.

## Kubernetes specifics

- Choose Ingress or Gateway API. Gateway API is where new work goes; Ingress is fine if your controller
  and your needs are simple. Do not mix both for the same hostname.
- One `IngressClass` per controller, explicit in every manifest; the default class is a footgun in a
  cluster with more than one.
- TLS via a `Secret` managed by cert-manager; DNS-01 for wildcards. Watch the renewal path, not just the
  first issuance.
- Give the controller two replicas, a `PodDisruptionBudget` and anti-affinity, otherwise it is a
  single point of failure for everything.
- A stable ingress IP: MetalLB L2, or kube-vip for a floating VIP on a few nodes.
- Keep admin hosts and internal services out of the public ingress class; a second internal class costs
  nothing and shrinks the attack surface.
- Avoid annotation-only configuration that differs per environment: it becomes invisible config drift.

## Verify it, do not assume it

- Test the exact behaviours you configured: body limit returns `413`, rate limit returns `429` with
  `Retry-After`, timeout returns `504`, TLS rejects 1.1, HTTP redirects to HTTPS with the right status.
- Load the proxy under the expected concurrency before believing the defaults; watch the file descriptor
  and worker limits, which are the real ceilings.
- Keep dashboards for p50/p95/p99 latency, 5xx rate, upstream health and certificate expiry.
- Upgrade the proxy like an application: two replicas, drain, then replace. A proxy restart is an outage
  if it is a singleton.

## Checklist

- [ ] One proxy, documented choice, no shadow second path
- [ ] ACME working with the right challenge type, staging in tests, certificates persisted
- [ ] Timeouts, body size, rate limits and connection limits set explicitly
- [ ] Real client IP trusted only from the proxy hop; logs structured with request ids
- [ ] Canary weights in git; retries limited to idempotent methods
- [ ] Kubernetes: explicit ingress class, two replicas, PDB, stable VIP, internal class for admin
- [ ] Configured behaviours proven by tests, dashboards live, upgrade path rehearsed
