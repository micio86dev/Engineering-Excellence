# API Design

An API is a contract with callers you cannot refactor: identifiers, error semantics and compatibility policy are
expensive to reverse, everything else is cheap. Auth and sessions: [references/api-and-session-security.md](references/api-and-session-security.md).

## Resources and identifiers

- Nouns, plural, lowercase; nest only for genuine containment (`/orders/{id}/lines`), one level deep. Deeper paths are
  joins wearing a URL.
- IDs are opaque: no auto-increment integers on a public API, they leak volume and invite enumeration. UUIDv7/ULID or
  prefixed IDs (`ord_...`). *Opposite:* an admin API behind auth is fine with sequential IDs.
- No verbs in paths: an operation with its own lifecycle is a sub-resource. `POST /orders/{id}/refunds` → `201` +
  `Location`. The same rule, not an exception.

## The happy path

| Intent | Request | Success | Rule |
| --- | --- | --- | --- |
| Create, server assigns ID | `POST /orders` | `201` + `Location: /orders/{id}` | RFC 9110 §15.3.2: `Location` names the created resource |
| Create or full replace, client picks ID | `PUT /orders/{id}` | `201` on create, `200`/`204` on replace | RFC 9110 §9.3.4 mandates this split; the body is the whole representation |
| Partial update | `PATCH` + `If-Match` | `200` or `204` | Declare the format: `merge-patch+json` (RFC 7396) or `json-patch+json` (RFC 6902) |
| Delete | `DELETE /orders/{id}` | `204` | Repeats return `204` or `404` — pick one, document it |
| Accepted for later | `POST /exports` | `202` + an operation URL to poll | RFC 9110 §15.3.3: HTTP cannot resend a status for work not yet done |

`PATCH` is neither safe nor idempotent, and concurrent patches corrupt data more readily than `PUT` collisions because
they need a known base point (<https://www.rfc-editor.org/rfc/rfc5789>), so `PATCH` without `If-Match` is a data-loss bug.
`DELETE` severs the URI's association with its functionality, not the bytes: soft delete is legal only if `GET` then answers `404`/`410`.

## Status codes and errors

| Code | Means | Not for |
| --- | --- | --- |
| `201` / `202` | Created; queued with a way to check | Anything already finished |
| `204` / `304` | Nothing to return; conditional `GET` unchanged | Mutations |
| `400` / `422` | Unparseable request / valid syntax, invalid semantics (§15.5.21) | Crashes |
| `401` / `403` | No or bad credentials / authenticated but not permitted | Hiding existence — use `404` |
| `409` | Conflicts with current state, caller can resolve and resubmit (§15.5.10) | Retryable contention — use `429`/`503` |
| `412` / `428` | `If-Match` failed / server requires a conditional request (RFC 6585 §3) | Optional preconditions |
| `415` / `429` | Unsupported media type; rate limited — `429` always carries `Retry-After` | Client mistakes |

Errors use RFC 9457 problem details, `application/problem+json` (July 2023), obsoleting RFC 7807
(<https://www.rfc-editor.org/rfc/rfc9457>): `type` is the permanent machine identifier clients branch on, `title` and
`detail` serve humans, and nothing leaks stack traces or SQL. *Opposite:* a single-consumer internal API may return raw
domain codes — still one envelope, never `200` with `{"success": false}`, because every retry, cache and dashboard in the path reads the status line.

## Lists, retries, conditionals

- **Cursor pagination, always.** `{ "data": [...], "has_more": true, "next_cursor": "..." }`, or `Link: <...>;
  rel="next"` (RFC 8288). The opaque cursor is the sort key plus a unique tiebreaker, so concurrent inserts cannot skip
  or repeat rows; Stripe uses this shape (<https://docs.stripe.com/api/pagination>). *Opposite:* offset paging is right for small admin tables where users jump to page 7.
- **Idempotency keys for unsafe retries.** Accept `Idempotency-Key` on `POST`/`PATCH`, store key, request fingerprint
  and response, replay on retry, reject a reused key with a different body. Still an IETF httpapi Internet-Draft
  (<https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/>), so pin the rules yourself. *Opposite:* `PUT` and `DELETE` are already idempotent.
- **Conditional requests.** Every `GET` returns a strong `ETag`; `If-None-Match` → `304`. Mutations take `If-Match` →
  `412`; where correctness depends on it, *require* the header and answer `428`, so a lost update becomes impossible
  rather than unlikely. *Opposite:* last-write-wins suits low-value preferences — document it, do not imply safety.

## Contract-first

Write the OpenAPI document first, or generate it from typed handlers — one source of truth, never both edited by hand.
Current version 3.2.1 (10 September 2026); 3.1+ align schemas with JSON Schema 2020-12
(<https://spec.openapis.org/oas/latest.html>). Generate clients and docs from it; hand-written per-endpoint `fetch`
wrappers drift within a sprint. Gate it in CI: `oasdiff breaking base.yaml head.yaml --fail-on-diff` exits non-zero on
`ERR`/`WARN` findings (<https://github.com/tufin/oasdiff>). Additive-only is the default — optional fields, new
endpoints, widened enums, the last only if you published which enums are open, as Stripe does
(<https://docs.stripe.com/api/enums>). *Opposite:* two internal services owned by one team need neither; the spec file still beats any wiki.

## Versioning and deprecation

| Strategy | Choose when | Cost |
| --- | --- | --- |
| URL prefix `/v1` | Public API, third parties, mixed client generations | Encourages `/v2` rewrites over fixes; two APIs live forever |
| Version header, pinned per request | Per-client migration without URL churn — Stripe ships monthly non-breaking releases and twice-yearly breaking majors, pinned by `Stripe-Version` (<https://docs.stripe.com/api/versioning>) | Invisible in logs and curl; one translation layer per version |
| Media-type negotiation | Strict HTTP, few consumers | Every tool, CDN and codegen fights you |
| No version, additive forever | Feeds and contracts you can never break | One unavoidable fix and you ship `/v2` anyway |

Deprecate before you sunset. `Deprecation: @1688169599` (RFC 9745, March 2025, structured-field date) marks a resource
as discouraged while it still works, with `Link: <policy>; rel="deprecation"` to the migration note; `Sunset: Sat, 31
Dec 2028 23:59:59 GMT` (RFC 8594) marks only the date the URI stops responding — RFC 8594 says Sunset is explicitly
*not* for the merely-discouraged stage. Watch per-version traffic before deleting: a version still serving at sunset is a failed migration. *Opposite:* a live security hole justifies breaking now, with direct outreach.

## Choosing the style

| Requirement | REST+JSON | GraphQL | gRPC | tRPC |
| --- | --- | --- | --- | --- |
| Consumers you do not control | Best: cacheable, curl-able | Viable, with schema-use and cost policy | Poor: proxies, schema distribution, codegen per consumer | No: TypeScript only |
| Diverse field needs from one graph | Over-fetching, chatty | Best | Not expressive | Fits, if all consumers are yours |
| HTTP caching | Free (`ETag`, `Cache-Control`) | Lost — one `POST` endpoint, so you build persisted queries | Not applicable | Not applicable |
| Streaming | SSE one-way, else a socket | Subscriptions over a persistent transport | Best: all four stream shapes | Subscriptions only |
| Authorization | Per route, auditable | **Per field** — route-level checks leak sibling fields | Per method, from metadata | Per procedure |
| Schema evolution | Additive fields; clients must tolerate unknowns | Schema diffing; removing a field is breaking | Protobuf tags, wire-compatible if numbers are never reused (<https://protobuf.dev/programming-guides/proto3/#updating>) | Compile-time only, no runtime contract |
| Known trap | Chatty clients | Resolver N+1; batch with DataLoader | grpc-web: unary and server-streaming only, no client or bidi streaming | Server types leak into the client bundle |

GraphQL N+1 is fixed by batching in a DataLoader (<https://github.com/graphql/dataloader>); gRPC's browser limits are in
grpc-web's README (<https://github.com/grpc/grpc-web>). tRPC is RPC for TypeScript monorepos where you "ignore details
like HTTP verbs" (<https://trpc.io/docs/concepts>): a good trade while one team ships both sides, a liability the day an independent consumer appears.

## Async and webhooks

- **At-least-once is the only honest guarantee.** Consumers dedupe on your event ID; claiming exactly-once moves the bug.
- **Retry with exponential backoff plus jitter over hours, then park in a dead-letter queue** with a replay endpoint;
  Standard Webhooks recommends multi-day schedules with jitter to avoid retry storms
  (<https://github.com/standard-webhooks/standard-webhooks/blob/main/spec/standard-webhooks.md>). *Opposite:* fire-and-forget is fine for analytics pings.
- **Sign everything.** Standard Webhooks: HMAC-SHA256 over `id.timestamp.body` in `webhook-id`, `webhook-timestamp`,
  `webhook-signature`; verify before parsing, reject stale timestamps, compare in constant time. RFC 9421 signs requests.
- **Ordering is not delivery.** Ship a monotonic `sequence`; never infer state from arrival order.
- **Outbox, not dual writes.** Write the event in the same transaction as the state change and let a relay publish it
  (<https://microservices.io/patterns/data/transactional-outbox.html>). Sending after commit loses events on crash; sending inside the request duplicates them on retry.

## The front-end contract

- **BFF when** clients differ in shape, sessions live in cookies, or the browser must not see internal services;
  **public API when** third parties integrate. Need both, build both — never let the public API acquire page shapes.
- **Token propagation:** the browser holds a session, the BFF holds tokens and calls services with them. Never forward
  browser tokens inward, and never trust caller-supplied identity claims.
- **Caching:** explicit `Cache-Control` on every `GET` (`no-store` by default, `max-age` or `stale-while-revalidate`
  for public reads), `Vary` on anything that changes the body, `private` for authenticated responses — a shared cache holding a user-specific body (RFC 9111) is an incident.
- **CORS is a browser permission, not authorization:** exact origin allowlist, credentials only with a specific origin (never `*`), and `Access-Control-Max-Age` so preflights are not paid repeatedly.
- **Consumers you do not control are the product:** contract tests, a changelog, a status page and rate limits with `Retry-After`, or you learn about breakage from their tickets.

## Failure modes

- `200 OK` with an error body — retries, caching and alerting silently disabled; a closed enum gained a value and every client `switch` fell through.
- Offset pagination on a live feed — rows skipped or repeated, and finance notices first.
- A retried `POST` charged twice; a webhook sent inline after commit vanished on the first crash; `/v2` cut to tidy names, so both versions run forever.

## Checklist

- [ ] Every collection lists via cursor pagination with an opaque cursor and a unique tiebreaker
- [ ] Create returns `201` + `Location`; replace returns `201`/`200`/`204`; delete is consistently `204` or `404`
- [ ] Mutations that can lose data require `If-Match` and answer `412`, or `428` when mandatory
- [ ] Unsafe retryable operations accept an `Idempotency-Key` and replay the original response
- [ ] One error envelope with documented, stable machine codes; no `200`-with-error anywhere
- [ ] The OpenAPI document is authored or generated in exactly one place and drives clients and docs
- [ ] CI fails on a breaking contract diff against the last release
- [ ] `Deprecation` and `Sunset` headers, a policy link and a published retirement window precede removal
- [ ] Webhooks are signed, retried with backoff and jitter, deduplicated by event ID, and emitted from an outbox
- [ ] The style choice and versioning strategy are recorded in an ADR, with per-version traffic monitored
