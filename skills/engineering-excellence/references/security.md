# Security

Security is built in, not bolted on. Use secure defaults and fail closed.
This reference establishes universal secure-by-default system controls.
For API authentication, token handling, session lifecycles, and authorization flows, see [references/api-and-session-security.md](references/api-and-session-security.md).

## Core security principles

Every system boundary must enforce four baseline invariants:

1. **Fail closed (default deny)**: When an authorization check, parser, or security filter fails or errors, deny access by default. Never allow unexpected exceptions to default to permissive execution.
2. **Least privilege**: Grant components, processes, and service accounts only the minimum privileges required to perform their discrete function. Never run production processes as root or cluster administrator.
3. **Validate at the boundary**: Treat all data entering from outside the execution context (HTTP requests, message queues, webhook payloads, CLI arguments) as untrusted.
4. **Defense in depth**: Layer controls so that the failure of any single barrier (for example, a firewall or an input validator) does not result in total system compromise.

## Input validation and data sanitization

Never trust client-provided data or downstream third-party feeds:

- **Strict schema validation**: Parse and validate incoming payloads against strict typed schemas (such as Zod, Pydantic, or JSON Schema) before processing. Reject unrecognized keys (`strip` or fail on unknown properties).
- **Parameterized database queries**: Always use parameterized queries or prepared statements for SQL execution. String interpolation or manual concatenation in SQL queries is strictly prohibited.
- **Context-aware output encoding**: Encode untrusted data before rendering it into HTML, JavaScript, SQL, XML, or command-line contexts to prevent injection attacks (XSS, SQLi, command injection).

## Secret management and credential protection

- **Zero secrets in source code**: Never commit API keys, private certificates, database passwords, or webhook tokens to git.
- **Environment and vault injection**: Load secrets exclusively at runtime via environment variables or external secret managers (see [references/environments.md](references/environments.md)).
- **Automated secret scanning**: Run automated scanning tools (Trufflehog, Gitleaks) in pre-commit hooks and CI pipelines to block secret leaks before commits merge.
- **Credential rotation**: Ensure every external secret and service token has a documented, tested rotation mechanism that does not require downtime.

## HTTP security response headers

For web-facing applications, enforce proven security response headers recommended by the [OWASP HTTP Headers Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html):

| Header | Recommended value | Purpose |
| --- | --- | --- |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Enforces HTTPS connections for two years, including all subdomains |
| `X-Content-Type-Options` | `nosniff` | Prevents browsers from MIME-sniffing responses away from declared Content-Type |
| `X-Frame-Options` | `DENY` | Mitigates clickjacking by preventing rendering inside frames or iframes |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limits cross-origin referrer leakage while preserving origin data |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Disables high-risk hardware and browser APIs unless explicitly required |

### Content Security Policy (CSP)

Define an explicit Content Security Policy to prevent cross-site scripting and unauthorized resource loading:

- Establish a restrictive baseline: `default-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'`.
- Disallow `'unsafe-inline'` and `'unsafe-eval'` for JavaScript execution; use cryptographic nonces or hashes for legitimate inline scripts.
- Test policies in staging using `Content-Security-Policy-Report-Only` before promoting to strict enforcement in production.

### Cookie hardening

Every HTTP cookie carrying authentication, session state, or CSRF tokens must include defensive flags:

- `Secure`: Ensures cookies are transmitted solely over encrypted HTTPS connections.
- `HttpOnly`: Prevents client-side scripts from reading session cookies, neutralizing XSS credential theft.
- `SameSite=Lax` or `SameSite=Strict`: Protects against cross-site request forgery (CSRF) by bounding cross-origin transmission.

## Error handling and information disclosure

Leaking internal system state provides attackers with exploitation roadmaps:

- **Generic client errors**: Return generic, actionable error messages to API consumers (for example, `404 Not Found` or `400 Bad Request` with a safe validation error message).
- **Suppress framework headers**: Disable or remove `Server`, `X-Powered-By`, and `X-AspNet-Version` response headers to prevent automated technology fingerprinting.
- **Sanitize server logs**: Log full stack traces and diagnostic details internally, but redact personally identifiable information (PII), credit card numbers, passwords, and authorization tokens before writing to disk.

## Checklist

- [ ] All system entry points enforce fail-closed default-deny authorization logic
- [ ] Incoming inputs validated against strict schemas; unknown fields rejected or stripped
- [ ] Database queries parameterized using prepared statements; zero SQL string concatenation
- [ ] No secrets, credentials, or private keys committed in version control or container layers
- [ ] Automated secret scanning (Gitleaks, Trufflehog) active in CI pipeline
- [ ] Security headers (`Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`) configured
- [ ] Restrictive Content Security Policy (CSP) enforced; `'unsafe-inline'` avoided
- [ ] Cookies set with `Secure`, `HttpOnly`, and appropriate `SameSite` flags
- [ ] Framework identity headers (`Server`, `X-Powered-By`) stripped from HTTP responses
- [ ] Application errors return generic client responses without leaking internal stack traces or PII
