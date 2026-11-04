# Production Readiness

"It works on my machine" is not the bar. Production-ready software behaves correctly
and safely under real conditions, across real environments, for real users.
Operational readiness requires explicit guarantees across service lifecycles, observability, resilience, and deploy safety.

## Lifecycle and runtime resilience

Production services must survive restarts, node rescheduling, and traffic spikes without dropping user requests:

- **Graceful shutdown**: Listen for `SIGTERM`. When received, fail the readiness probe to stop incoming ingress traffic, finish inflight requests within a defined grace period (typically 15 to 30 seconds), close database connections, and exit cleanly before `SIGKILL`.
- **Distinct health probes**:
  - **Liveness (`/healthz`)**: Verifies the process is alive and not deadlocked. Does not check downstream dependencies; failing this triggers a container restart.
  - **Readiness (`/readyz`)**: Verifies the service has completed initialization (warm caches, established connection pools) and is ready to accept traffic. Failing this removes the instance from the load balancer without killing the process.
- **Outbound call protection**: Every external network call (HTTP, RPC, database) must have an explicit timeout. Configure retries exclusively with exponential backoff and randomized jitter to prevent thundering herds. Use circuit breakers for fragile downstream dependencies.
- **Traffic and ingress controls**: Protect entry points with rate limiting, connection bounds, and TLS termination (see [references/traffic-and-ingress.md](references/traffic-and-ingress.md)).

## Observability and telemetry

You cannot operate what you cannot inspect. Instrument systems to emit standard operational signals:

- **Structured JSON logging**: Emit machine-parseable JSON logs to stdout/stderr. Every log record should include `timestamp`, `level`, `message`, `service`, and distributed tracing context (`trace_id`, `span_id`). Redact sensitive user data and credentials.
- **Standardized metrics**:
  - **RED metrics for requests**: Rate (requests/sec), Errors (failed requests/sec), and Duration (latency percentiles: p50, p95, p99).
  - **USE metrics for resources**: Utilization, Saturation, and Errors for CPU, memory, connection pools, and disks.
- **Distributed tracing**: Instrument cross-service calls with OpenTelemetry headers (`traceparent`) to enable end-to-end distributed latency analysis.
- **Alerting and runbooks**: Every automated alert must have a linked, actionable runbook with clear verification and mitigation steps (see [references/documentation.md](references/documentation.md)).

## Deployment safety and data migrations

Deploying software must be a routine, non-disruptive operation:

- **Zero-downtime deploys**: Support rolling updates or blue/green deployments where new replicas pass readiness checks before old replicas are decommissioned.
- **Decoupled database migrations**: Never deploy code that depends on synchronous destructive schema changes. Follow the expand/contract (parallel-run) pattern:
  1. *Expand*: Add new columns or tables as nullable or default-populated.
  2. *Deploy*: Ship code that reads from/writes to the new schema while tolerating the old.
  3. *Backfill*: Migrate historical data in small, bounded batches.
  4. *Contract*: Remove old columns in a subsequent release after verifying zero references.
- **Deterministic rollback**: Every deployment pipeline must provide an automated or 1-command rollback mechanism that restores the previous artifact within minutes.

## Web, discovery, and client readiness

For customer-facing web services and applications, ensure frontend production hygiene:

- **Security headers**: Enforce HSTS, CSP, and defensive cookie attributes (see [references/security.md](references/security.md)).
- **Caching and compression**: Serve static assets with Brotli/Gzip compression and immutable caching headers (`Cache-Control: public, max-age=31536000, immutable`).
- **Accessibility and internationalization**: Comply with WCAG 2.2 AA standards (see [references/accessibility.md](references/accessibility.md)) and isolate user-facing strings (see [references/i18n.md](references/i18n.md)).
- **Search and agentic discovery**: Provide valid `robots.txt`, `sitemap.xml`, and `llms.txt` where discoverability is required (see [references/seo.md](references/seo.md)). Ensure staging environments block indexing (see [references/environments.md](references/environments.md)).

## "When applicable" matters

Not every project needs every item. A CLI tool has no `sitemap.xml`; an internal queue worker has no public ingress; an in-memory utility has no database migration. Apply these standards with engineering judgment: consciously evaluate and record exclusions in an ADR (see [templates/adr.md](templates/adr.md)) rather than silently ignoring operational risks.

## Gate checklist

- [ ] Service handles `SIGTERM` with graceful connection draining and clean termination
- [ ] Separate liveness (`/healthz`) and readiness (`/readyz`) endpoints implemented
- [ ] Outbound network calls enforce mandatory timeouts, retries with backoff/jitter, and circuit breakers
- [ ] Logs emitted in structured JSON with correlated `trace_id` and sanitized of PII
- [ ] RED service metrics (Rate, Errors, Duration percentiles) exposed to monitoring
- [ ] Alerts mapped to documented operational runbooks with escalation paths
- [ ] Zero-downtime deployment strategy verified with tested 1-command rollback procedure
- [ ] Database migrations follow expand/contract pattern; backward and forward compatible
- [ ] External configuration managed via environment variables (see [references/environments.md](references/environments.md))
- [ ] Web hardening (security headers, caching, i18n, accessibility) validated where applicable
