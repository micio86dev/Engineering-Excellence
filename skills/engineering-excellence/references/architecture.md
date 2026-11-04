# Architecture

Architecture represents the set of decisions that are expensive or irreversible to change once built.
A sound architecture isolates core business logic from operational mechanisms, optimizes for fast,
independent automated test suites, and prevents implementation details from dictating domain design.

## Foundational architectural properties

| Property | Core principle | Direct benefit | Warning smell |
| --- | --- | --- | --- |
| **Modularity** | Code is partitioned into distinct units with explicit boundaries | Teams work concurrently without merge conflicts or unexpected side effects | Global state, circular dependencies between folders, god classes |
| **High Cohesion** | Components that change for the same business reason reside together | A feature change touches files in one module rather than ten scattered folders | "Feature" changes requiring simultaneous edits in `controllers/`, `services/`, `models/`, and `views/` |
| **Loose Coupling** | Modules communicate only through minimal, stable public contracts | Internal refactorings do not break external consumers | Calling internal private methods across module borders; direct access to foreign tables |
| **Inward Dependency** | Dependencies point toward high-level policy, away from infrastructure | Core domain logic runs in memory under test without databases or network | Domain entity imports ORM annotations, HTTP status codes, or AWS SDK packages |

## Architectural styles: pragmatic selection

Pick the simplest architectural style that satisfies team structure and operational reality:

| Style | Best suited for | Operational cost | Common failure mode |
| --- | --- | --- | --- |
| **Modular Monolith** | Default choice for 95% of applications; 1–5 teams | Single deployable binary; zero distributed network failure modes | Lazy engineers bypass module boundaries without lint/build enforcement |
| **Hexagonal / Ports & Adapters** | Applications with complex domain rules and multiple delivery mechanisms (CLI, Web, Queue) | Requires mapping layers between adapters and domain models | Over-ceremonial DTO mapping for trivial CRUD passes |
| **Microservices** | Independent scaling needs or multiple autonomous teams with distinct deploy cycles | High: distributed tracing, eventual consistency, network latency, cluster ops | Distributed monolith: services must deploy in lockstep; cascading outages |

## Evolution over big-bang rewrites

- **Strangler Fig pattern**: When modernizing a legacy system, never schedule a "ground-up rewrite."
  Instead, intercept traffic at the edge or ingress proxy and route specific slices to the new module
  until the old implementation atrophies and can be safely deleted.
- **Fitness functions**: Automate architectural assertions in CI (e.g., ArchUnit in Java, `import-linter`
  in Python, or dependency-cruiser in Node) so architecture degrades only when a conscious policy change is approved.

## Over-engineering traps

- **Enterprise Astronauting**: Creating 5 layers of object translation (HTTP DTO → Application Command →
  Domain Entity → Persistence Entity → SQL Row) for simple database writes adds ceremony without architectural benefit.
- **Premature distributed systems**: Splitting a system into microservices before understanding the domain
  boundaries creates network overhead, eventual consistency bugs, and distributed transaction nightmares.
  Start with a modular monolith; split services only when team autonomy or scaling demands it.
- **Premature caching**: Introducing Redis or distributed caches before profiling slow database queries
  or creating proper database indexes introduces stale-cache bugs and cache-invalidation complexity.

## Reviewer heuristics

Audit architectural changes against these concrete rules:

- **The Dependency Direction Check**: Inspect package/module imports. Domain layers must never import
  infrastructure packages (SQL drivers, HTTP frameworks, message broker clients).
- **Enforced Module Boundaries**: Ensure intra-monolith boundaries are protected by compiler visibility,
  package managers, or lint rules (e.g., Nx, ArchUnit, or TypeScript project references).
- **ADR Requirement**: Any structural change (introducing a new database, adopting an event bus, splitting a service)
  must be accompanied by an Architecture Decision Record (ADR) documenting context, alternatives, and consequences.
- **Conway's Law Check**: Service boundaries must align with team ownership. A service shared by two separate
  teams with different roadmaps becomes a deployment bottleneck.

## When bypasses are justified

- **CQRS Read Paths**: Bypassing heavy domain model hydration for read-only queries. Executing direct,
  optimized SQL queries into lightweight DTOs avoids performance overhead on read-heavy views.
- **Batch Processing & ETL**: High-volume ingestion pipelines may bypass domain layers to stream raw records
  directly to columnar storage or bulk loaders.

## Checklist

- [ ] System adopts the simplest viable style (Modular Monolith preferred before Microservices)
- [ ] Dependencies point inward: domain logic has zero imports of infrastructure or transport frameworks
- [ ] Module boundaries are enforced by automated tooling, linters, or compiler controls
- [ ] Domain models contain no persistence-specific annotations or network serialization tags
- [ ] Significant structural decisions are documented in an Architecture Decision Record (ADR)
- [ ] Read-only query paths are separated from transactional mutation paths where performance requires it
