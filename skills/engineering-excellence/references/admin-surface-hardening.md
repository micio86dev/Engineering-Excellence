# Hardening an Admin Surface

The admin panel is the highest-value target in most applications: it holds the data, the users and the
switch that turns everything off. Harden it as a separate product, not as a page inside the app.

## Remove it from the public path first

- Separate hostname (`admin.example.com`) or separate path behind its own ingress, so it can be
  firewalled, rate-limited and monitored independently.
- Network restriction where the audience allows it: VPN, Zero Trust proxy, IP allowlist, or mTLS. An
  admin panel that answers the whole internet with a login form is one credential-stuffing run away
  from compromise.
- No indexing, no public links, no sitemap entries, `X-Robots-Tag: noindex`; obscurity is not a
  control, but discovery does not need to be free.
- A separate deploy pipeline from the customer-facing app, so an admin change cannot break checkout.

## Identity for admins

- SSO through the company IdP with MFA, not a local password table. Local accounts only as a documented
  break-glass path, with credentials sealed and every use alerted.
- Step-up authentication for destructive actions (impersonation, exports, deletes, payment changes):
  re-authenticate or require a second factor within the session.
- Role model that is explicit and small: `support`, `billing`, `ops`, `superadmin`. Every privilege
  names the actions it unlocks; no wildcard roles.
- Least privilege by default and time-bounded elevation for the rare superadmin task.
- Offboarding path: SSO deprovisioning removes access, sessions are revoked, API tokens are listed and
  revoked. Test it once with a real person, not on paper.

## Session and request hardening

- Short absolute session lifetime (hours, not weeks) and a short idle timeout; both enforced server-side.
- Rotate the session identifier on login and on any privilege change.
- Bind the CSRF defence to the session and keep origin checks; `SameSite` alone is not enough.
- Rate-limit login, password reset, OTP verification and every destructive endpoint, per identity and
  per source.
- Generic authentication errors, constant-time comparisons, no user enumeration in reset flows.
- Every state-changing request logged with actor, target, before/after, decision and request id.

## Application-level specifics

Laravel and PHP:

- `APP_DEBUG=false` in production, and fail startup if it is true. The debug page is a credential and
  schema leak.
- `APP_KEY` set per environment, rotated deliberately (it invalidates encrypted columns and sessions);
  never a shared key between environments.
- Session and cookie config: `Secure`, `HttpOnly`, `SameSite`, a non-default cookie name, database or
  Redis sessions in multi-node deployments.
- Mass assignment: `$fillable` allowlists, never `$guarded = []`. Validation at the controller boundary,
  FormRequest classes for anything bigger than a couple of fields.
- `.env` outside the document root; no `.env.example` reachable over HTTP; `config:cache` and
  `route:cache` in the deploy, so a stray `env()` call fails at build time rather than silently.
- Trusted proxies configured for the real ingress, otherwise TLS-terminated requests look like HTTP and
  secure cookies are dropped.
- Telescope, Horizon and debug toolbars gated to local or to an explicit allowlist, never open by
  omission.
- `storage:link` symlinks served by the web server: verify no directory listing and no path traversal.
- Queues and the scheduler run as their own user, separate from the web process; the admin panel must
  not become a shell by letting an operator enqueue a job with arbitrary parameters.
- Dependency and framework versions supported; an unsupported minor is an unpatched admin panel.

TypeScript and Node:

- Security headers (`helmet` or equivalent): CSP with nonces rather than `unsafe-inline`, HSTS, frame
  ancestors, `Referrer-Policy`.
- Validate every input with a schema (zod, valibot) at the boundary, and never trust a typed interface
  as runtime validation.
- Cookies set server-side with `httpOnly`, `secure`, `sameSite`, `path`; never store an admin token in
  `localStorage`.
- CSRF: per-session token with origin check for cookie-authenticated admin requests; bearer-token APIs
  are exempt only when the token is not ambient.
- No `eval`, no `new Function`, no dynamic `require` of user-supplied paths.

QuickJS or any embedded sandbox:

- Untrusted code runs with an explicit capability list: only the host functions you inject, nothing
  ambient.
- Memory and time limits per invocation; a loop without a timeout is a denial of service with extra
  steps.
- No filesystem, network or environment access unless handed in as a narrow function.
- Serialize results as plain data; never pass host objects that expose their prototype chain.
- Treat it as a parser boundary: validate both what goes in and what comes out.

## Data protections the panel needs

- Exports (CSV/JSON) are an exfiltration path: rate-limit, log, watermark with the actor, and never
  include more columns than the role needs.
- Impersonation ("log in as user") needs a loud banner, an audit record and a time limit.
- Deletes are soft by default, with retention and a restore path; a hard delete is a separate
  permission.
- Secrets displayed once, never readable again (API keys show a prefix only).
- PII masked in list views, revealed on demand and logged when revealed.

## Verify it

- A test that the admin hostname refuses unauthenticated requests, returns `401` not a redirect loop,
  and never leaks a stack trace in production mode.
- A test that every admin route is covered by the role matrix: an authenticated low-privilege user gets
  `403` on each privileged action.
- A test that the audit log records a destructive action with actor and target.
- An external scan of the admin surface as part of the release gate, plus a periodic manual review of
  the role matrix against reality.
- Dependency and container scanning on the same schedule as the app: the admin panel is not exempt.

## Checklist

- [ ] Not on the public internet, or behind an explicit network control
- [ ] SSO with MFA, break-glass path sealed and alerted, deprovisioning tested
- [ ] Step-up auth on destructive actions; small explicit role model
- [ ] Session lifetime, rotation, CSRF and rate limits enforced server-side
- [ ] Debug/profiler off in production and asserted at startup
- [ ] Framework specifics reviewed (Laravel/Node/sandbox items above)
- [ ] Exports, impersonation, deletes and PII reveals logged and limited
- [ ] Role-matrix tests and a scan in the release gate
