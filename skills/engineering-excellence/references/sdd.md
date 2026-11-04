# Sdd

Specification-Driven Development (SDD) establishes an agreed contract before writing production code or test suites. Designing software against an explicit, reviewed specification prevents building the wrong feature, drifting from system architecture, and discovering unhandled edge cases late in the release cycle.

## Sequence

1. **Problem definition**: Document the user need, business requirement, or system bottleneck along with operational constraints.
2. **Specification drafting**: Author an OpenSpec document (`templates/openspec.md`) defining functional requirements, architectural constraints, and testable acceptance criteria.
3. **Interface and schema definition**: Define public types, API endpoints, database schemas, and external event formats before starting implementation.
4. **Architectural review**: If the change introduces structural changes or new third-party dependencies, record the rationale in an ADR (`templates/adr.md`).
5. **Human review and approval**: A human engineer reviews and signs off on the specification. No implementation code is written until approval is granted.
6. **Implementation via TDD**: Translate each acceptance criterion directly into failing automated tests (see `references/tdd.md`).
7. **Verification**: Confirm the delivered solution satisfies every specified requirement and complies with all constraints.

## Specification Lifecycle

Every specification progresses through five explicit states:

- `DRAFT`: Requirements, interfaces, and acceptance criteria are being collected and structured.
- `IN_REVIEW`: Shared with reviewers; feedback and edge cases are actively addressed.
- `APPROVED`: Frozen and signed off by the engineering owner. Implementation may begin.
- `IMPLEMENTED`: Code and tests are delivered, quality gates pass, and behavior is verified.
- `SUPERSEDED`: Replaced by a newer specification or deprecated with an ADR link.

## Artefacts Produced

- **OpenSpec document**: Stored in the repository or task tracking system, specifying requirements using [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) keywords (`MUST`, `SHOULD`, `MAY`).
- **Architectural Decision Record (ADR)**: Generated when architectural patterns, dependencies, or storage models change (`templates/adr.md`).
- **Interface contracts**: Typed interfaces, OpenAPI/JSON schemas, Protobuf files, or database migration definitions.
- **Traceability matrix**: Mapping showing how each requirement maps to its corresponding unit, integration, or contract test.

## Failure Modes Prevented

- **Semantic drift**: Prevents AI agents and engineers from implementing unrequested functionality or misunderstanding requirements.
- **Architectural fragmentation**: Preempts ad-hoc data models and inconsistent API signatures.
- **Untestable requirements**: Eliminates vague acceptance criteria (e.g. "system must be fast") by requiring measurable criteria before coding.
- **Scope creep**: Bounds the task to explicit inputs, outputs, and behaviors.

## AI Agent in the Loop

When an AI agent executes work under SDD:

1. **Agent drafts the specification**: The agent analyzes existing repository patterns, dependencies, and requirements to generate the OpenSpec draft.
2. **Explicit pause**: The agent must halt immediately after publishing the spec draft. It is strictly forbidden from writing implementation code or test suites without explicit human confirmation.
3. **Boundary enforcement**: Requirements must state both what the system must do and what it must not do (`MUST NOT`).
4. **Drift protocol**: If the agent discovers unforeseen technical constraints during coding, it must not improvise a workaround. It must pause, update the spec draft, and request approval for the change.
5. **No silent omissions**: If a requirement cannot be fulfilled within existing architecture, the agent reports the trade-off explicitly rather than ignoring the requirement.

## What a Reviewer Checks

| Criterion | Review Question |
| :--- | :--- |
| **Ambiguity** | Can every requirement be verified by an automated test or a binary check? |
| **Boundaries** | Are error conditions, timeouts, rate limits, and invalid inputs explicitly defined? |
| **Compatibility** | Does the design maintain backward compatibility for existing consumers and databases? |
| **Simplicity** | Does the specification avoid speculative features and adhere to YAGNI (`references/yagni.md`)? |
| **Dependencies** | Are any new libraries or services justified per `references/dependencies.md`? |
| **Non-Functional** | Are latency budgets, throughput targets, and resource footprints bounded? |

## Checklist

- [ ] OpenSpec document drafted using `templates/openspec.md`.
- [ ] Requirements specified using [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) keywords.
- [ ] Interface types, payloads, and error responses defined before code implementation.
- [ ] New dependencies or architecture shifts documented in an ADR (`templates/adr.md`).
- [ ] Edge cases, boundary inputs, and security constraints explicitly documented.
- [ ] Non-functional constraints (timeouts, performance, memory) quantified with measurable targets.
- [ ] Specification reviewed and approved by a human engineer before writing code.
- [ ] Acceptance criteria mapped 1:1 to automated test cases during TDD.
