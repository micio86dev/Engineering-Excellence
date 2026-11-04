# API Design

An API is an unalterable contract with external and internal callers: wire identifiers, error semantics, and compatibility guarantees are costly to reverse, whereas internal implementation details remain cheap. Point at identity and authentication decisions rather than re-architecting security per endpoint. Every public and internal interface must be governed by an explicit schema, an immutable error envelope, and deterministic versioning from day one.

## Resources and identifiers

- Resource paths: Use lowercase plural nouns; nest only for true parent-child containment (/orders/{id}/lines) capped at one level deep. Avoid nested joins disguised as URIs.
- Opaque identifiers: Never expose auto-increment database integer keys on public or inter-service APIs to prevent enumeration attacks and volume leakage. Use UUIDv7, ULID, or type-prefixed strings (ord_123).
- Sub-resources over verbs: Model distinct state lifecycle operations as sub-resources rather than embedding verbs in URIs (for example, POST /orders/{id}/refunds returning 201 Created and a Location header).
Name resources strictly as nouns with opaque identifiers; declare operation lifecycles as explicit sub-resources.

## The happy path and HTTP semantics

| Intent | Request | Success | Rule |
| --- | --- | --- | --- |
| Create (server ID) | POST /orders | 201 + Location: /orders/{id} | RFC 9110: Location header identifies the newly created resource URI |
| Replace or create | PUT /orders/{id} | 201 on create, 200/204 on replace | RFC 9110: Request payload represents the complete resource state |
| Partial update | PATCH + If-Match | 200 or 204 | Specify merge-patch+json (RFC 7396) or json-patch+json (RFC 6902) |
| Delete resource | DELETE /orders/{id} | 204 No Content | Subsequent requests must consistently return 204 or 404 Not Found |
| Asynchronous queue | POST /exports | 202 Accepted + Location /tasks/{id} | RFC 9110: Return an operation URI for client status polling |

Unsafe PATCH updates without If-Match preconditions risk silent lost updates (RFC 5789, https://www.rfc-editor.org/rfc/rfc5789). Soft deletions must sever the URI mapping so subsequent GET calls return 404 Not Found or 410 Gone. Require precondition headers on all state mutations.

## Status codes and error envelopes

Standardize on RFC 9457 Problem Details (application/problem+json, https://www.rfc-editor.org/rfc/rfc9457) across every endpoint and service boundary:
- Error structure: Return type (stable URI machine identifier), title (short human-readable summary), status (HTTP status code), and detail (contextual explanation without leaking stack traces or raw database queries).
- Consistent semantics: Use 400 for malformed syntax, 422 for unprocessable business validation, 401 for missing/invalid credentials, 403 for insufficient authorization, 404 for missing resources, 409 for state conflicts, 412 for failed If-Match, 428 for required preconditions, and 429 with a mandatory Retry-After header for rate limits.
Never return HTTP 200 with {"success": false}; status codes must enable intermediate proxies, gateways, and clients to branch.

## Style selection: REST, GraphQL, gRPC, typed RPC, and Events

| Style | Fits when | Cost added | Smallest signal you picked wrong |
| --- | --- | --- | --- |
| REST (JSON over HTTP) | Public APIs, edge caching (RFC 9111 ETag, Cache-Control), polyglot integrations | Chatty sequential round-trips; over-fetching nested models | Mobile screens making 10 chained requests to render one view |
| GraphQL | Heterogeneous frontends, resource aggregation, BFF layers (Thoughtworks Radar) | Breaks standard HTTP caching (needs APQ); N+1 queries (needs DataLoader); query DoS risk | Using GraphQL for inter-service microservice RPC or simple CRUD |
| gRPC (Protobuf over HTTP/2) | High-throughput internal RPC, bi-directional streaming, strict status propagation | Binary format; browsers lack HTTP/2 trailers (needs Envoy gRPC-Web or Connect RPC) | Browser web clients calling raw gRPC services without a proxy |
| Typed RPC (tRPC) | Full-stack TypeScript monorepos with unified client-server codebases (trpc.io) | Zero tech-agnostic schema; runtime locked to TypeScript; leaks server types into bundle | Non-TypeScript or third-party external consumers need to integrate |
| Asynchronous Events | Decoupled workflows, fan-out event notifications, state transfer (Fowler taxonomy) | Eventual consistency window; broker ops; duplicate delivery requiring deduplication | Structuring request-reply RPC commands as passive-aggressive events |

In GraphQL, batch database queries in DataLoader (https://github.com/graphql/dataloader), deploy Automatic Persisted Queries (https://www.apollographql.com/docs/apollo-server/performance/caching), and enforce OWASP query depth limits (https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html). In gRPC, Protocol Buffer field tags are immutable once published; mark deleted tags as reserved (reserved 4, 8; reserved "name"; https://protobuf.dev/programming-guides/proto3/). In event systems, format envelopes using CloudEvents 1.0 (64KB boundary; https://cloudevents.io/) and document asynchronous broker channels using AsyncAPI 3.0 (https://www.asyncapi.com/).
Choose the protocol matching caller boundaries; isolate internal gRPC or tRPC mechanisms behind a REST or BFF edge.

## Contract-first discipline and lifecycle

Write contracts prior to implementation; the schema is the single source of truth driving generated clients and validation.
- Schema standards: Author OpenAPI 3.1 contracts (aligned 100% with JSON Schema 2020-12, https://spec.openapis.org/oas/v3.1.0.html) or OpenAPI 3.2 supporting the HTTP QUERY method (RFC 10008) for safe, cacheable queries with request bodies.
- Automated client generation: Generate client SDKs and mock servers directly from OpenAPI or AsyncAPI schemas; hand-written per-endpoint fetch wrappers drift and cause production runtime regressions.
- Breaking change CI gates: Run contract diffing tools (such as oasdiff or buf breaking) in CI pipelines to fail builds on breaking schema changes, unannounced enum deletions, or protobuf tag renumbering.
- Versioning and deprecation: Expose only major version identifiers in URI paths (Google AIP-185, https://google.aip.dev/185) or run date-based rolling transformations (Stripe, https://stripe.com/blog/api-versioning). Announce deprecation via the Deprecation header (RFC 9745) with a minimum 180-day migration window before terminating endpoints with Sunset (RFC 8594).
Enforce automated contract checks in continuous integration; fail any pull request that introduces an unversioned breaking diff.

## Lists, retries, and conditionals

- Cursor pagination: Paginate active collections using opaque cursors ({ "data": [...], "has_more": true, "next_cursor": "..." }; Stripe, https://docs.stripe.com/api/pagination). The cursor combines sort key and unique tiebreaker; never use offset paging on live data.
- Idempotency keys: Accept Idempotency-Key on mutating POST and PATCH operations (draft-ietf-httpapi-idempotency-key-header). Persist key, request hash, and response in cache/database; replay previous responses on retry, and reject body mismatches.
- Conditional requests: Serve strong ETags on GET responses. Require If-Match on mutating requests and return 428 Precondition Required when omitted, guaranteeing that concurrent writes do not trigger data loss.
Implement cursor pagination, strong ETags, and idempotency key persistence across all stateful collection endpoints.

## The frontend boundary and cross-service auth

- Contract is the interface: API contracts decouple frontends from server frameworks. Deploy a Backend-for-Frontend (BFF) when web, mobile, and third-party consumers require divergent data aggregations or operational latencies.
- Fixed on day one: Cursor pagination, field filtering, idempotency keys, and RFC 9457 error envelopes must be standardized on day one across all endpoints to prevent client fragmentation.
- Edge cookie sessions vs. bearer tokens: Storing bearer access tokens in browser localStorage or sessionStorage is a severe security defect exposing credentials to XSS exfiltration (OWASP / IETF BCP for Browser-Based Apps). The BFF executes OAuth 2.1 Authorization Code flow with mandatory PKCE (RFC 9700 / RFC 7636) and issues HttpOnly, Secure, SameSite=Lax session cookies. Mitigate CSRF using cryptographic anti-CSRF tokens and Fetch Metadata headers (Sec-Fetch-Site: same-origin). Avoid wildcard cookie domains (Domain=.example.com) to limit subdomain compromise blast radius.
- Workload identity and audience scoping: Replace perimeter castle-and-moat models with Zero Trust (NIST SP 800-207). Authenticate service-to-service calls using mTLS with SPIFFE/SPIRE SVIDs (https://spiffe.io/) or cloud Workload Identity Federation (IRSA, GCP WIF). Validate the aud claim on internal JWTs (RFC 9068) to prevent token replay across microservices. Use RFC 8693 Token Exchange (https://www.rfc-editor.org/rfc/rfc8693.html) to trade user session tokens for downscoped, audience-restricted tokens carrying the act delegation claim, preventing Confused Deputy attacks.
Terminate browser sessions at the BFF with HttpOnly cookies; pass audience-scoped workload tokens to internal services.

## Failure modes

- HTTP 200 with error payload: Silently disables client retry policies, edge CDN caching, and monitoring alerts.
- Offset pagination on mutating streams: Causes skipped records and duplicate items during concurrent write activity.
- In-browser token storage: Exposes access credentials to automated extraction via compromised third-party script libraries.
- Unprotected mutating retries: Duplicate financial transactions caused by missing Idempotency-Key headers on POST calls.
- Broad internal token audience: Compromised downstream service replays client bearer tokens against peer administrative APIs.
Audit status codes, token scopes, and idempotency validation continuously to eliminate perimeter failure modes.

## Decision checklist

- [ ] Is API style selected from verified architectural constraints (REST, GraphQL, gRPC, tRPC, Events) rather than habit?
- [ ] Is OpenAPI 3.1/3.2 authored contract-first, with CI diffing (oasdiff) blocking breaking changes before merge?
- [ ] Are all error responses structured under RFC 9457 Problem Details envelopes with explicit machine-readable codes?
- [ ] Do collection endpoints use cursor pagination with opaque cursors and unique tiebreakers instead of offset paging?
- [ ] Do mutating endpoints require If-Match preconditions and accept Idempotency-Key headers for retry safety?
- [ ] Are browser credentials stored exclusively in HttpOnly, Secure, SameSite cookies managed by a BFF or edge gateway?
- [ ] Are service-to-service calls authenticated via mTLS workload identities with strict audience validation (RFC 9068)?
- [ ] Is token delegation downscoped via RFC 8693 Token Exchange to prevent Confused Deputy vulnerabilities?
