# Documentation

Keep README, ADRs and specifications updated.
Documentation is not an afterthought produced at the end of a release; it is an engineering artifact maintained alongside source code with equal rigor.

## The docs-as-code contract

Treat documentation with the same engineering discipline as executable code:

- **Colocated in version control**: Documentation lives in the same repository as the implementation it describes, versioned atomically across branches and commits.
- **Atomic pull requests**: Every functional change that alters public interfaces, environment variables, configuration schemas, or operational workflows must update the corresponding documentation in the same PR.
- **Reviewed as code**: Documentation changes undergo the same peer review standards as software logic (see [references/code-review.md](references/code-review.md)). PRs with missing, outdated, or misleading docs must not pass quality gates.

## Documentation hierarchy

A well-structured repository organizes documentation into distinct layers with unambiguous purposes:

| Artifact | Location | Target audience | Core contents |
| --- | --- | --- | --- |
| **README** | `/README.md` | New developers, AI agents, operators | 5-minute setup, prerequisites, build/test commands, configuration overview |
| **Architecture** | `/docs/architecture/` or root | System architects, maintainers | Topology, component boundaries, data flows (see [templates/architecture.md](templates/architecture.md)) |
| **ADRs** | `/docs/adr/` | Future maintainers, review teams | Architectural decisions, evaluated alternatives, consequences (see [templates/adr.md](templates/adr.md)) |
| **API Specs** | `/docs/api/` or schemas | API consumers, client generators | Machine-readable OpenAPI, AsyncAPI, or Protobuf schemas (see [references/sdd.md](references/sdd.md)) |
| **Runbooks** | `/docs/runbooks/` | On-call engineers, incident responders | Alert response procedures, manual failover, database recovery, rollback steps |

## Architecture Decision Records (ADRs)

Capture significant architectural choices when they occur so future teams understand the reasoning:

- **When to write an ADR**: Language or framework adoption, database selection, protocol changes, security architecture shifts, major dependency replacements, or structural refactorings.
- **Essential structure**: Every ADR must document four elements:
  1. **Context**: What problem or business driver forced the decision?
  2. **Options considered**: What alternatives were evaluated, and why were they rejected?
  3. **Decision**: What specific approach was chosen?
  4. **Consequences**: What trade-offs, operational burdens, or technical debt were accepted?
- **Immutability**: ADRs are historical records. When an earlier architectural choice is superseded, write a new ADR that references and supersedes the predecessor; never edit past decisions.

## Machine-readable specifications and runbooks

- **API contracts as source of truth**: Author API contracts in machine-readable formats (OpenAPI 3.1, AsyncAPI, Protobuf). Validate request/response implementations against these specifications in CI to prevent contract drift.
- **Actionable runbooks**: An operational runbook must be unambiguous under stress. Every alert emitted by monitoring systems must link directly to an explicit runbook containing:
  - Symptoms and alert triggering thresholds
  - Verification commands to diagnose the blast radius
  - Immediate mitigation steps (restart, scale, circuit-break, feature-flag toggle)
  - Rollback commands and escalation paths

## Freshness and anti-rot strategies

Stale documentation is actively harmful: it causes production outages, misleads AI agents, and slows developer onboarding.

- **Automated CI validation**: Run automated checks in CI to lint markdown, detect broken internal and external links, and validate schema integrity.
- **Testable code samples**: Extract code snippets from documentation into testable fixtures or verify them with documentation testing tools to guarantee examples compile and execute.
- **Aggressive deletion**: When a system, feature, or tool is decommissioned, immediately delete its documentation. Never leave obsolete wiki pages or abandoned markdown guides in the repository.

## Checklist

- [ ] `README.md` enables a new engineer or agent to bootstrap, test, and run the project in under 5 minutes
- [ ] Documentation updated atomically within the same PR as the functional or architectural change
- [ ] Significant technical, storage, or protocol decisions documented as ADRs using [templates/adr.md](templates/adr.md)
- [ ] Superseded ADRs marked as superseded rather than modified in place
- [ ] API interfaces backed by machine-readable contracts (OpenAPI, Protobuf) validated in CI
- [ ] Critical production alerts link directly to documented, step-by-step operational runbooks
- [ ] CI pipeline validates documentation for syntax errors, broken markdown links, and valid schemas
- [ ] Decommissioned features and deprecated workflows purged from documentation
