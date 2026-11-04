# Architecture and Repo Topology

Architecture shape, repository layout, and data ownership form one coupled system: repository topology governs change velocity, while persistence boundaries govern isolation. A distributed monolith across multiple repositories adds network failure modes without deployment independence. This reference synthesizes primary architectural research alongside framing from practitioner MicioDev, "Basta Monoliti! Come Progettare Software Seri nell'Era dell'AI" (published 2026-10-29), whose argument is taken from the video's auto-generated caption transcript. Choose the simplest topology that satisfies verified business isolation constraints.

## The shape decision: staged path to extracted services

Systems evolve along a staged path: traditional MVC monolith to modular monolith with enforced boundaries to extracted services.
- Justified split drivers: Divergent hardware scaling (CPU, memory, GPU), independent release cadences, autonomous team ownership under Conway's Law, and hard compliance or fault isolation (PCI-DSS, blast-radius containment; DORA loosely coupled teams, https://dora.dev/capabilities/loosely-coupled-teams/).
- Unjustified drivers: Industry fashion, speculative concurrency, or microservices as an organizational goal. Martin Fowler's MonolithFirst pattern (https://martinfowler.com/bliki/MonolithFirst.html, June 2015) documents that greenfield microservice systems systematically incur high operational drag ("Microservice Premium") without proven domain boundaries. Fowler's operational prerequisites (https://martinfowler.com/bliki/MicroservicePrerequisites.html, August 2014) mandate rapid server provisioning under a few hours, deployment pipelines completing in under two hours, and distributed observability.
- Consolidation evidence: Amazon Prime Video consolidated distributed serverless video inspection microservices back into an in-process monolith in March 2023, eliminating Step Functions state transitions and S3 transfers to reduce infrastructure spend by 90%. Stack Overflow proved monolithic ASP.NET codebases scale to 209 million daily HTTP requests across only 11 IIS servers in February 2016 (https://nickcraver.com/blog/2016/02/17/stack-overflow-the-architecture-2016-edition/). Istio 1.5 collapsed its microservice control plane into a single istiod binary in March 2020 (https://istio.io/latest/blog/2020/tradewinds-2020/) to eliminate diagnostic complexity and cross-service latency.
- Boundary enforcement: Enforce boundaries mechanically inside the monolith before extraction. ArchUnit (Java bytecode assertions, https://www.archunit.org/), Import Linter (Python AST contracts, https://import-linter.readthedocs.io/), and Shopify Packwerk (Ruby packages, https://github.com/Shopify/packwerk) fail CI if modules bypass declared public interfaces.
Default to a modular monolith; extract an out-of-process service only after its public contract has survived multiple cycles.

## Repository topology

| Layout | Dependency fan-out | Version skew | Cross-repo refactors | CI fan-out | Fit (Team size & cadence) |
| --- | --- | --- | --- | --- | --- |
| Monorepo | Low: single lockfile and shared AST | Zero: HEAD is the single source of truth | Atomic across all services in one PR | High: requires Bazel or Nx affected-graph caching | 1 to 50+ teams requiring synchronized releases and atomic contract changes |
| Umbrella core + satellite repos | Bounded: satellites consume published core SDK | Managed: controlled through SemVer pins | Multi-PR: bump core, migrate satellite repos | Isolated: satellite pipelines build independently | 5 to 20 teams where shared contracts change slower than domain features |
| Polyrepo (repo per service) | High: diamond dependency conflicts across libraries | Severe: unbounded version drift across services | High coordination: cascading multi-PR migrations | Multiplied: duplicated pipeline maintenance | Autonomous teams with zero shared business code and distinct deployment stacks |

Polyrepos impose severe maintenance overhead: Twilio Segment abandoned 140+ service repositories for a single monolith in July 2018 (https://www.twilio.com/en-us/blog/developers/best-practices/goodbye-microservices) to eliminate dependency hell and worker blocking that consumed three engineers. Monorepos resolve version skew but require hermetic caching build systems to scale (Google CACM, July 2016, https://cacm.acm.org/research/why-google-stores-billions-of-lines-of-code-in-a-single-repository/). Select an umbrella core with satellite service repos when domain teams require deployment independence without duplicating SDKs.

## The shared-core rule

A shared core provides common infrastructure across satellite repositories without coupling domain lifecycles.
- What belongs in shared core: Technology-agnostic API contracts (OpenAPI/Protobuf), authentication and token validation primitives, shared envelope types, and standard HTTP/RPC client SDK wrappers.
- What must never enter shared core: Business domain logic, persistence entities, workflow orchestration, or mutable callbacks that invert dependencies from core back into services.
- Versioning and consumption: Publish immutable packages to artifact registries (npm, PyPI, Maven Central) using Semantic Versioning 2.0.0 (https://semver.org/). Never use Git submodules: submodules lock to raw commit hashes, introduce detached HEAD states, and lack semantic dependency resolution (https://git-scm.com/book/en/v2/Git-Tools-Submodules). Maintain an explicit changelog, support at most two concurrent major versions, enforce a 180-day deprecation window (DORA, October 2025), and return HTTP 410 Gone upon retiring legacy endpoints.
Reject any shared-core PR containing business rules; distribute cross-cutting tooling strictly as versioned registry artifacts.

## Data ownership decisions

Data topology dictates whether service boundaries are authentic; a shared database reduces services to a distributed monolith.
- Database per service vs. shared database: Dedicated database instances provide hard fault, compute, and security isolation at higher base cloud infrastructure cost. Per-service schemas on a shared database instance reduce operational spend but share connection pools, memory, and blast radius (https://microservices.io/patterns/data/database-per-service.html).
- When one shared database is the right call: Greenfield applications, small teams, and unproven domains must use a single shared database inside a modular monolith (MonolithFirst). Enforce architectural discipline by assigning private schemas per domain module, restricting database roles, and prohibiting cross-module SQL joins and foreign keys (https://docs.aws.amazon.com/prescriptive-guidance/latest/modernization-data-persistence/shared-database.html).
- Outbox and Sagas over distributed transactions: Reject two-phase commit (2PC / XA) distributed transactions due to high latency, CAP network partition vulnerability, and blocking lock contention. Prevent dual writes by writing outgoing events to a transactional outbox table within the local ACID entity transaction, relaying events via transaction log tailing (Debezium CDC, https://debezium.io/). Coordinate workflows across services using Sagas with explicit compensating actions and semantic locks in pending states (https://microservices.io/patterns/data/saga.html). Consumers must enforce idempotence via deduplication tables.
- Read models and replica conflicts: Build denormalized read models with asynchronous CQRS projections (https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs), handling consistency lag through session read-your-writes tokens. Offload analytical queries to a dedicated warehouse via CDC rather than querying PostgreSQL streaming replicas directly, preventing max_standby_streaming_delay replication stalls and query cancellations (https://www.postgresql.org/docs/current/hot-standby.html). Monitor replication slot lag to avoid WAL disk exhaustion.
Assign each entity to one authoritative service datastore; integrate across boundaries strictly through outbox event streams.

## Worked example: splitting a monolith into service repositories

The source for this section is the auto-generated transcript of MicioDev's "Basta Monoliti! Come Progettare Software Seri nell'Era dell'AI" (published 2026-10-29), obtained from the video's caption track. The steps below follow the speaker's own decisions, not a reconstructed outline.

1. Reject the classic MVC monolith, where the front-end is welded to back-end logic, and expose the backend only through REST/GraphQL from the start. The buy is a second client (mobile app, back office vs. customer site) without duplicated backend work; the cost is pushing every capability server-side and gating clients with roles and permissions.
2. Apply the mobile-app test as the forcing function: a mobile client inevitably requires REST APIs, so build them before the app arrives. The buy is one agnostic backend serving many clients; the cost is that roles and permissions, not per-client backends, must carry the differences.
3. Split his avatar product into three services: accounts plus SSO, interviews (data collection and scoring), and the avatar service (what to say plus visual lipsync). The avatar service is reused by the interview app and by another site's chatbot widget, and SSO is shared by both; the cost he names is a bit more server environment (separate nodes).
4. Give each specialized front-end its own app: the Zoom/Meet join page runs on a separate subdomain, and dashboards are separate because the backend pre-elaborates data and caches it in Redis or Valkey. The buy is UI churn isolated from backend changes; the cost is more front-ends and caches to operate.
5. Centralize identity and access in one service acting as mirror, central communicator, and bus through which almost all operations pass. The buy is no duplicated user-account lists or separate logins; the cost he names is a bit more server environment, while the unspoken cost is a new single point of failure.
6. Connect services with API tokens, public/private API keys, or SDKs, and carry SSO sessions in HTTP-only cookies shared across third-level subdomains. The buy is a single session across subdomains; the cost is cross-domain cookie forcing, exactly where cookie risk concentrates.
7. Add a DevOps layer underneath: a load balancer, a clustered real-time replicated database, and SLA awareness as basic knowledge. The buy is surviving a node failure and spreading traffic; the cost is operating and monitoring the nodes he lists as the most likely to fall (Redis, database, backend, frontend).

Verbatim quotes from the transcript:
- "il monolite è il male assoluto." - the monolith is framed as absolute evil, with no qualification.
- "il giorno in cui devo fare un'app mobile, per forza di cose devo fare le API REST" - a mobile app is what forces the REST APIs to exist.
- "vedere gente che faceva l'elaborazione dei dati lato front-end. Ragazzi, è una pazzia." - computing data on the client is called madness.
- "utilizzando ancora cookie HTTP only, che sono quelli più sicuri al momento." - HTTP-only cookies are ranked the most secure session mechanism he knows.
- "non si può evitare al 100% una perdita di dati, al 100% una caduta del servizio" - zero data loss and zero downtime are impossible.

### What the talk leaves out

The absolutes that open and frame the talk (the monolith as absolute evil, a winning move for every project) carry no benchmarks or case studies and skip the modular-monolith middle ground. The AI-era speed claim ignores that generated code still has to be reviewed, integrated, and operated, and microservices multiply that surface. The central bus through which almost all operations pass reintroduces a single point of failure, and the cookie ranking omits SameSite, CSRF, and the bearer-token-in-cookie vs. header trade-off.

## Migrating out of a monolith

Decomposition succeeds through disciplined strangler migrations rather than big-bang rewrites.
- Apply the Strangler Fig pattern (Martin Fowler, August 22, 2024, https://martinfowler.com/bliki/StranglerFigApplication.html): Place an intercepting routing seam at the ingress proxy, divert discrete traffic slices to the new service, and explicitly delete the deprecated monolithic code path once traffic completes migration.
- The high-churn extraction trap: Extracting the highest-churn module first is a failure mode; high churn indicates numerous inbound dependencies, maximizing dual-write friction and blast radius.
- Identify data seams: Extract slices that own distinct database tables and exhibit minimal inbound coupling. Measure co-change patterns using temporal coupling analysis (Code Maat, https://github.com/adamtornhill/code-maat) to verify module independence.
Select extraction candidates by persistence isolation and low temporal coupling; never extract based on churn alone.

## Failure modes

- Distributed monolith: Services require lockstep deployments due to shared database schemas or synchronized library releases. Re-merge into a modular monolith or decouple persistence contracts.
- Boundary theatre: Declaring modules/ directories without build-time linter enforcement; unconstrained imports create coupling.
- Accidental shared database: Cross-service database views and queries introduced incrementally; prevent via restrictive grants.
- Non-atomic dual writes: Committing database changes and publishing message broker events separately; resolve via outbox.
- Unmonitored CDC replication lag: Neglected database replication consumers causing unbounded WAL disk growth and primary outages.
Remediate architectural drift by enforcing build-time linter assertions and dedicated database credentials.

## Decision checklist

- [ ] Is the service extraction justified by divergent scaling, team boundaries, or fault domains rather than microservice trends?
- [ ] Are modular boundaries enforced mechanically in continuous integration using ArchUnit, Import Linter, or Shopify Packwerk?
- [ ] Does repository layout reflect team autonomy requirements, with build caching configured for monorepos or SemVer for satellite repos?
- [ ] Is shared core strictly limited to contracts, identity helpers, and common SDKs, distributed as versioned registry packages?
- [ ] Does each service own its persistence schema, with direct cross-service relational joins and shared database credentials prohibited?
- [ ] Are multi-service mutations coordinated via transactional outbox relays and sagas with idempotent consumer deduplication?
- [ ] Are analytical workloads isolated in a warehouse via CDC rather than executed directly against transactional streaming replicas?
- [ ] Does the migration use a Strangler Fig facade with a scheduled deletion date for the deprecated monolithic implementation?
