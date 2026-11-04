# Sessions, Tokens and API Security

A session identifier is temporarily equivalent to the strongest credential the user presented. Treat
every one of them as a password with a short life.

## Model the boundaries first

| Question | Wrong answer | Right answer |
| --- | --- | --- |
| Who is this? | The `?user_id=` in the URL | A validated session or token claim |
| May they do this? | The token says `admin` | The server checks the object ownership for this action |
| What if the token leaks? | Nothing, it expires | It is short-lived, revocable and detected on reuse |
| What if the browser is shared? | Logout clears a cookie | Logout revokes the session server-side |

## Authentication

- Prefer federated or passwordless login over a password you store; if you store one, use Argon2id
  (or bcrypt/scrypt with a sane cost) and never a fast hash.
- Rate-limit and lock out by account and by source, with a generic error: "invalid credentials" for
  both wrong user and wrong password.
- Compare secrets with a constant-time function.
- Require MFA for anything holding production data, and re-authenticate for sensitive changes.
- Email verification is an authorization boundary for anything that can be invited into a tenant.

## Sessions

- Server-side sessions are the default. The client holds an opaque identifier, the server holds the
  record and can revoke it.
- Identifier entropy of at least 64 bits from a CSPRNG; store only a hash of it server-side.
- Rotate the identifier on login and on any privilege change; never accept a pre-login identifier as
  authenticated (session fixation).
- Two timeouts: absolute (hours) and idle (minutes). Both enforced server-side.
- Logout invalidates the record server-side and clears the cookie; "delete the cookie client-side" is
  not a logout.
- Revoke everywhere on password change, role change, or suspected compromise.
- Do not bind a session to an IP address (mobile networks break) and do not trust a client-provided
  device fingerprint as proof.

## Cookies

- `HttpOnly`, `Secure`, `SameSite=Lax` at minimum, `Strict` for admin surfaces.
- Use the `__Host-` prefix where the cookie is host-only and path `/`; it makes subdomain injection
  and shadowing impossible.
- Scope `Path` and `Domain` as narrowly as the application allows.
- Session cookie name that does not fingerprint the stack (`PHPSESSID`, `JSESSIONID`, `ASP.NET_SessionId`).
- No personal data inside the cookie: it is a lookup key, not a profile.
- CSRF: `SameSite` is a mitigation, not a solution. Keep an origin check and a synchronizer or
  double-submit token for state-changing requests.

## Tokens (JWT and opaque)

- Access tokens live minutes, not days. Short life is the revocation strategy for stateless tokens.
- Refresh tokens: rotation on every use, reuse detection that revokes the whole family, bound to the
  client, stored as a hash.
- Validate everything: signature against current JWKS, `iss`, `aud`, `exp`, `nbf`, `iat`, with a small
  clock skew. Allowlist the algorithm; never accept `none` or the token's own `alg` header.
- Keep the signing key out of the application process where the platform allows (KMS), publish `kid`
  and rotate with overlap.
- Include a session identifier claim so a stateless token can still be revoked.
- Never put a token in a URL, a referrer, a log line or an error message.
- Browser storage: refresh token in an `HttpOnly` cookie, access token in memory. `localStorage` is
  readable by any XSS and survives the tab.

## SSO

- Prefer OIDC with the authorization code flow plus PKCE, even for confidential clients.
- `state` to bind the request, `nonce` to bind the ID token; reject a mismatch.
- Redirect URI: exact string allowlist per client, no wildcards, no open redirect through a `next`
  parameter.
- Validate `iss`, `aud`, `azp`, signature, JWKS freshness, `email_verified`, and the tenant/domain
  claim (`hd` for Google, `tid` for Microsoft) before trusting an email address.
- SAML: require signed assertions, validate recipient, audience, `InResponseTo` and the digest, and
  use a hardened XML parser against signature wrapping.
- Map groups to roles with an explicit allowlist; an unknown group grants nothing.
- Provisioning and deprovisioning: SCIM or a scheduled reconciliation, because a person who left must
  lose access automatically, and single logout is worth configuring if the IdP supports it.
- Log the identity provider, subject and decision for every SSO login; a silent failure here looks
  like "randomly logged out".

## REST API surface

- Authorize per object and per action on every request. An ID in the body or path is user input, not
  a permission.
- Validate and type every input at the boundary; reject unknown fields where mass assignment is
  possible.
- Errors: generic to the caller, specific to the log. No stack traces, no SQL, no internal hostnames,
  no distinction between "no such user" and "wrong password".
- Rate-limit per identity and per source, with `429` and `Retry-After`; protect expensive reads too.
- Pagination with a hard cap and a stable sort; never an unbounded `SELECT` behind an endpoint.
- Idempotency keys for creating resources that a client may retry; `ETag`/`If-Match` for updates.
- Method semantics: `GET`/`HEAD` are safe and cacheable and never mutate. No state change on `GET`, no
  token in the query string, no destructive action behind a link.
- CORS: explicit origins, no `*` with credentials, preflight handled deliberately.
- Version before you break: additive changes first, deprecation window, then removal.
- Audit log: authentication, authorization failures, admin actions, exports and deletions, with actor,
  target, decision, timestamp and request id.

## Checklist

- [ ] Credentials: slow hash, constant-time compare, rate limit, generic errors
- [ ] Session: 64-bit CSPRNG id, hashed at rest, rotated on login, absolute and idle timeouts, server-side logout
- [ ] Cookie: `HttpOnly`, `Secure`, `SameSite`, `__Host-` where possible, CSRF defence on writes
- [ ] Tokens: minutes-long access, rotating refresh with reuse detection, full claim validation, revocable
- [ ] SSO: code+PKCE, `state`/`nonce`, exact redirect allowlist, claims validated, group allowlist, deprovisioning
- [ ] API: object-level authorization, input validation, rate limits, safe errors, no mutation on `GET`
- [ ] Audit: auth and admin events logged with actor, target, decision and request id
