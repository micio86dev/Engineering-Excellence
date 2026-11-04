# Environment Awareness

Software must adapt its behavior deterministically to its deployment environment through explicit
configuration, never hardcoded conditionals or manual toggles.

## Environment topology

Organize delivery into four standard environment tiers with unambiguous lifecycles:

| Environment | Purpose | Lifecycle | Data Source |
| --- | --- | --- | --- |
| **Development** | Local implementation and unit/integration tests | Ephemeral or local host | Synthetic fixtures / seed data |
| **Preview** | Isolated pull request validation and visual review | Ephemeral (tied to PR life) | Sanitized mock or scrubbed seed data |
| **Staging** | Production-like integration, smoke tests, and soak | Persistent pre-production | Scrubbed snapshot or synthetic scale data |
| **Production** | Live end-user traffic and mission-critical state | Persistent high availability | Authoritative live database |

## Dev/prod parity

Violations of parity between development and production cause subtle deployment failures and data corruption.
Apply the principles of [12-Factor Dev/Prod Parity](https://12factor.net/dev-prod-parity):

- **Backing service engine parity**: Use identical datastores across all environments. Never substitute SQLite
  in development for PostgreSQL in production; semantic differences in locking, typing, and dialect cause
  production outages that tests cannot catch.
- **Engine version parity**: Pin major and minor versions of databases, caches, message brokers, and runtime
  interpreters across every environment.
- **Runtime operating system parity**: Execute workloads in containerized environments matching the target
  production architecture (Linux x86_64 or arm64), avoiding host OS path or filesystem drift.

## Configuration and fail-closed defaults

Separate code from configuration according to [12-Factor Configuration](https://12factor.net/config):

- **Environment variables as source of truth**: Inject environment-specific parameters via environment variables
  or mounted configuration secrets, never checked-in files.
- **Boot-time schema validation**: Validate all required configuration at process boot using an explicit schema
  (e.g., Zod, Pydantic, or native struct validation). Crash immediately on startup if any required variable is
  missing, unparseable, or invalid.
- **Fail closed by default**: An unconfigured environment variable must default to the most restrictive posture:
  fail to start, reject incoming connections, or default to private (`noindex`). Never assume production mode or
  fall back to insecure defaults.

## Secrets isolation per environment

Never reuse credentials across environment boundaries:
- **Dedicated secret vaults**: Development, staging, and production must use isolated secret stores or namespaces.
- **Zero credential sharing**: Production API keys, third-party webhook secrets, and database credentials must
  never exist on staging or developer machines.
- **No production data in non-production**: Never restore raw production database dumps into staging or development.
  Always run automated PII scrubbing and anonymization before populating pre-production datastores.
- **Short-lived credentials**: Prefer IAM roles, OIDC identity federation, and rotating tokens over long-lived static keys.

## What must never differ across environments

Certain behaviors must remain completely invariant regardless of where the application runs:
1. **Database migrations**: Run the identical schema migration scripts in dev, staging, and prod.
2. **Business domain rules**: Core calculations, entity validation, and domain logic must be identical.
3. **Authentication & authorization enforcement**: Never disable authentication checks or bypass RBAC in staging.
4. **Input validation**: Request sanitization, payload size limits, and security headers must not be disabled.
5. **Cryptographic primitives**: Never downgrade password hashing rounds or encryption ciphers for "speed" in dev.

## Search indexing and discoverability

Only public production surfaces should ever be discoverable by search engines or AI crawlers.

| Environment | HTTP Header | `robots.txt` |
| --- | --- | --- |
| Development | `X-Robots-Tag: noindex, nofollow` | `Disallow: /` |
| Preview (PRs) | `X-Robots-Tag: noindex, nofollow` | `Disallow: /` |
| Staging | `X-Robots-Tag: noindex, nofollow` | `Disallow: /` |
| Production (Public) | Indexing permitted per page meta | Selective `Disallow` (e.g. `/api/`, `/admin/`) |
| Production (Admin/Auth) | `X-Robots-Tag: noindex, nofollow` | `Disallow: /admin/` |

Admin surfaces, authenticated consoles, and private tenant spaces must return `noindex, nofollow` headers
in every environment, including production (see `references/seo.md`).

## Checklist

- [ ] Topology clearly separated into Development, Preview, Staging, and Production tiers
- [ ] Database engine and major version match across local development, CI, staging, and production
- [ ] Configuration defined via environment variables and validated against a schema at startup
- [ ] Application fails closed (aborts boot) when mandatory environment variables are missing
- [ ] Staging and development secrets strictly isolated from production credentials
- [ ] Non-production datastores populated with synthetic or thoroughly scrubbed data, never raw PII
- [ ] Business logic, schema migrations, and auth enforcement identical across all environments
- [ ] `X-Robots-Tag: noindex, nofollow` sent on all responses in dev, preview, and staging environments
- [ ] Authenticated dashboards and admin areas set to `noindex, nofollow` across all environments
