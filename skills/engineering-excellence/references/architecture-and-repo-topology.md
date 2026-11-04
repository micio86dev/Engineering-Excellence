# Architecture and Repo Topology

Shape (how many deployables), repository layout (how many repos), and data ownership (who may read which
table) are one decision, not three: the repo decides how fast a boundary moves, the database decides whether
the boundary is real. A modular monolith spread over five repositories is a distributed monolith with worse
tooling. `references/architecture.md` covers styles and dependency direction; this document covers the
topology and integration contracts that follow from them. Framing borrowed from MicioDev, ["No More
Monoliths! How to Architect Serious Software in the AI Era"](https://www.youtube.com/watch?v=dqFkd_ipnNk) —
title and description only, transcript not obtainable, so no claim below is attributed to it.

## The shape decision

| Shape | Justified by | Ops cost | Test cost | The opposite choice is right when |
| --- | --- | --- | --- | --- |
| Single-process monolith | One team, one deploy, unknown domain | Lowest: one binary, one DB, one log stream | One suite, real transactions | Only under deadline pressure — and then record it as debt |
| Modular monolith | Default: 1–5 teams, boundaries still moving | Same, plus boundary enforcement | Fast per-module tests plus a few end-to-end | Modules change for genuinely different reasons — that signals a split, not a hedge |
| Microservices | Independent scaling, or teams blocked on each other's release cadence | High: tracing, retries, rota, per-service infra | Contract and consumer-driven tests; end-to-end stops being cheap | Boundaries are guesswork: premature splits buy network hops and pay in availability |

- A boundary is real only when something fails the build on violation: Nx module tags, `import-linter`,
  `dependency-cruiser`, separate packages. A folder named `modules/` is documentation.
- Price the split per service: one network hop, one timeout policy, one retry policy, one dashboard, one
  alert route, one restore drill, one versioning contract.
- Distribution needs an axis: independent scaling, failure isolation, a compliance boundary, or a team that
  must ship without coordinating. "Cleaner code" is not an axis — extract a module instead, and split only
  after its interface has survived two or three real changes.

## Repository topology

| Layout | Buys | Real cost | Required contract | The opposite is right when |
| --- | --- | --- | --- | --- |
| One monorepo, affected-only builds | Atomic cross-cutting refactors, one CI config, one dependency graph | Impact analysis must be correct or it rebuilds everything; access control is directory-level | Correct affected graph, merge queue, cached task outputs | Many unrelated services with separate compliance scopes |
| Core repo + service repos on released core artifacts | Small services, one owner for core, a real release process | No atomic change: a core change is N coordinated PRs | SemVer (`MAJOR` on breaking, [semver.org](https://semver.org/)), exact pins, changelog, deprecation window, contract tests | Core is shared by independent products with their own cadence |
| One repo per service | Team independence, per-service access control | Duplicated pipeline config, no cheap cross-service refactor, sharing becomes package publishing | Reproducible from scratch: lockfile, pinned toolchain, generated clients | There is exactly one team — then one repo is strictly cheaper |

Affected-only builds are only as good as their base commit: Nx `affected` takes `--base`/`--head` and
recommends basing on the last successful commit on `main` ([nx.dev](https://nx.dev/ci/features/affected));
Turborepo's `--affected` compares against `main`, and a shallow clone makes **every** package look changed,
so `--filter=blob:none --depth=0` is correctness, not optimisation
([turborepo.com](https://turborepo.com/docs/reference/run)).

- Pin exact versions in production manifests. Ranges let two services run different core behaviour under the
  same version label. Opposite: a library consumed only inside one monorepo needs no published version.
- Publish consumer-facing contract tests (schemas, golden fixtures) in the core pipeline, and deprecate with
  a removal version in the changelog. Opposite: a pre-1.0 internal core may break freely — say so in its README.
- Never let the core call back into a service (plugin loading, callback registration, shared mutable
  globals): that inverts the dependency the split was meant to create.

## Data topology

| Pattern | Use when | Cost and failure mode | The opposite is right when |
| --- | --- | --- | --- |
| Database per service — private tables, schema-per-service, or server-per-service ([microservices.io](https://microservices.io/patterns/data/database-per-service.html)) | Boundaries must be enforced and teams own migrations | Every former join becomes an API, event, or read model | One service, one schema: do not create per-service schemas inside a monolith |
| Shared database | Single team, one deployable, reporting joins | Every schema change is a cross-team negotiation; one bad migration stops everyone | Reporting replicas, read-only by construction |
| Replicated read model (CDC, logical replication, event-fed projection) | The read path must not call five services per request | Staleness, ordering, rebuild cost, drift from the owner's schema | Query volume is trivial: call the owner and cache for seconds |

- **A service never reads another service's tables.** Enforce with per-service database roles and
  credentials. A view or foreign table owned elsewhere is a shared database under another name — if you
  accept it, accept it in an ADR rather than in a code review. Only the owner runs migrations on its objects.
- Logical replication is a legitimate read-model feed — PostgreSQL's publisher/subscriber model exists for
  it ([postgresql.org](https://www.postgresql.org/docs/current/logical-replication.html)) — but a projection
  is a cache: it needs a rebuild procedure and a lag metric or it silently becomes the source of truth.
- Cross-service reporting goes to a warehouse fed by CDC, never to production tables with a `SELECT` join.
  Opposite: a genuinely single-service system keeps its joins.

## Synchronous versus asynchronous integration

| Interaction | Use when | What it costs | The opposite is right when |
| --- | --- | --- | --- |
| REST / GraphQL / gRPC / tRPC | The caller cannot proceed without the answer | Availability coupling: caller uptime ≤ callee uptime; needs deadlines, retry budgets, backoff, circuit breaking | Nobody needs the answer in-request — then the call is a latency tax and a fake coupling |
| Events | Fan-out, slow consumers, workflows across services | At-least-once, ordering, duplicates, no return value, harder debugging | The interaction is a read: query an owned read model instead of doing an event round-trip |
| tRPC specifically | TypeScript end-to-end inside one monorepo ([trpc.io](https://trpc.io/docs/concepts)) | Client coupled to server types; assumes a shared TS codebase | Polyglot or external consumers: publish OpenAPI or protobuf, not internal types |

- **Assume at-least-once.** Consumers must be idempotent — record processed message IDs or make the write
  idempotent on a business key; a consumer that publishes before recording the fact republishes on restart
  ([outbox](https://microservices.io/patterns/data/transactional-outbox.html)).
- **Never dual-write.** Commit the state change and the outgoing message in one transaction (outbox table,
  relayed by log tailing or a polling publisher); publishing after commit loses the event if the process dies.
- Multi-service transactions are sagas with explicit compensating actions, choreographed or orchestrated;
  there is no automatic rollback ([microservices.io](https://microservices.io/patterns/data/saga.html)).
  Opposite: one service's local ACID transaction stays a transaction — do not build sagas for single-DB work.
- Retried mutating HTTP calls take an `Idempotency-Key`. It is still an Internet-Draft
  (`draft-ietf-httpapi-idempotency-key-header-08`), not an RFC
  ([datatracker](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)), so storage,
  expiry and conflict semantics are yours to define and document.
- Event schemas are contracts: additive changes within a version, a new topic or type for breaking ones,
  consumers tolerant of unknown fields.

## How the front end talks to all of it

- One BFF per distinct UI, so each UI's needs do not leak into a general-purpose API
  ([samnewman.io](https://samnewman.io/patterns/architectural/bff/)). Opposite: identical clients (one SPA)
  want one API; two BFFs with the same logic are duplication with extra deploys.
- Auth propagation: the browser holds an HttpOnly session cookie at the edge; the BFF exchanges it for a
  short-lived, narrowly scoped downstream token (OAuth 2.0 Token Exchange, RFC 8693,
  [rfc-editor.org](https://www.rfc-editor.org/rfc/rfc8693.html)) instead of forwarding one broad user token
  to every service, which lets any service act as the user on any API with no attributable audit trail.
- Direct browser-to-service calls are fine with few services, per-service audiences, and CORS as a conscious
  decision. More than a couple of services pushes the boundary back to a BFF.
- Put generic perimeter concerns (auth, request logging) in one shared edge layer rather than per BFF —
  Newman is explicitly sceptical of duplicating them. Opposite: a single-client system folds them into the BFF.

## Migrating out of a monolith

- Strangler fig: intercept at the edge, route one slice at a time, and **delete the old path** once traffic is
  dry ([martinfowler.com](https://martinfowler.com/bliki/StranglerFigApplication.html)); a migration with no
  deletion date is a second system you maintain forever.
- **"Extract the highest-churn module first" is usually wrong.** High churn means the module collaborates with
  everything: it has the most inbound dependencies, so extraction needs the most shims, the largest data
  migration, the most dual-write windows — and its downtime hurts most. Churn measures pain, not separability.
- Extract along *data* seams: a slice that already owns its tables and has few inbound callers, even if
  unglamorous. Measure coupling with co-change analysis (which files commit together) — Code Maat's temporal
  coupling exists for this ([github.com/adamtornhill/code-maat](https://github.com/adamtornhill/code-maat)).
- The exception that proves the rule: extract the high-churn module first only when the churn comes from one
  team's deploy cadence *and* the module has few co-changing neighbours — verify with co-change data.

## Failure modes

- **Distributed monolith**: services must deploy together (shared library lockstep, shared DB, coordinated
  releases). Merge them back or cut the shared dependency; more tooling will not help.
- **Boundary theatre**: `modules/` folders nothing enforces; imports cross until nothing can move.
- **Shared database by accretion**: cross-service views appear one PR at a time. Only grants stop this.
- **Dual writes losing events**, then exactly-once heroics. Outbox plus idempotent consumers is cheaper.
- **Stale read model treated as truth**: projections with no lag metric and no rebuild runbook.
- **Eventual consistency hidden from the user**: the UI shows success that has not happened. Make pending
  states explicit.

## Checklist

- [ ] Shape chosen against a named axis (scaling, failure isolation, compliance, deploy cadence) and recorded in an ADR
- [ ] Module boundaries enforced by a linter or build rule that fails the pipeline, not by convention
- [ ] Repository layout stated with its versioning contract: SemVer, exact pins, changelog, deprecation window, contract tests
- [ ] Affected-only CI uses a correct base commit and a non-shallow checkout
- [ ] Every service holds its own database credentials; no cross-service table reads or migrations
- [ ] Every consumer is idempotent: dedupe store or naturally idempotent business key
- [ ] State change and its outgoing event commit in one transaction (outbox); no dual writes anywhere
- [ ] Retried mutating endpoints accept `Idempotency-Key` with documented storage, expiry and conflict semantics
- [ ] Multi-service transactions have compensating actions and a documented failure path
- [ ] Event schemas versioned additively; consumers ignore unknown fields
- [ ] Front end authenticates at one edge; downstream calls use exchanged, scoped, short-lived tokens
- [ ] Migration slices chosen by data ownership and co-change data, not churn; each slice has a deletion date
