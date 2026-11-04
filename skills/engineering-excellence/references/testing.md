# Testing

Automated testing proves that software behaves correctly, meets specification requirements, and withstands regression. A rigorous test suite provides rapid, deterministic feedback across distinct levels of granularity, preventing broken deployments and brittle maintenance cycles.

## Test Pyramid and Levels

Follow the [Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) and categorize suites by execution scope and resource isolation, adhering to [Google Test Sizes](https://testing.googleblog.com/2010/12/test-sizes.html):

| Level | Scope & Isolation | What to Test | Speed Target |
| :--- | :--- | :--- | :--- |
| **Unit (Small)** | In-memory, single process, zero network or disk I/O. External dependencies replaced with simple fakes. | Pure business logic, state transitions, mathematical calculations, validation routines, algorithmic edge cases. | < 50ms per test; suite runs in seconds. |
| **Integration (Medium)** | Single host / localhost. Involves real database, file system, or containerized service (e.g. Testcontainers). | Repository queries, schema migrations, HTTP routing and serialization, caching layers, queue consumers. | < 2s per test; suite runs under 5 minutes. |
| **End-to-End (Large)** | Multi-host or full-stack environment. Real infrastructure, services, and optional headless browser. | Critical user journeys (login, checkout, billing), cross-service workflows, deployment smoke checks. | < 30s per test; small, targeted suite. |

Push tests as far down the pyramid as possible. If an integration or E2E test reveals an edge-case failure, write a unit test to cover that specific condition before resolving it.

## What a Test Must Assert

Every test must follow the Arrange-Act-Assert (AAA) pattern and assert observable behavioral contracts:

1. **State changes and return values**: Assert exact outputs, data mutations, or emitted domain events.
2. **Explicit error states**: Assert that invalid inputs raise specific exception classes or structured error codes, rather than generic failure.
3. **Behavior over implementation**: Assert what the unit does, not how it does it. Avoid asserting private methods, internal variable states, or call counts on internal helper classes.
4. **Reserve spy/mock assertions for real side-effects**: Call verification (`expect(fn).toHaveBeenCalled()`) is reserved strictly for external boundaries that produce outside side effects (e.g. dispatching an email, publishing a message to a Kafka broker, charging a payment gateway).
5. **One logical concept per test**: A test should focus on a single behavioral scenario with a descriptive name explaining the condition and expected outcome.

## Artefacts Produced

- **Automated test suites**: Executable unit, integration, and E2E specifications maintained in version control alongside production code.
- **Coverage reports**: Line, branch, and mutation coverage metrics identifying untested pathways.
- **Deterministic fixtures**: Reusable factories and seeded datasets that produce predictable test states without relying on persistent external environments.

## Failure Modes Prevented

- **Flaky tests**: Banning arbitrary sleep calls, external network dependencies, and race conditions guarantees reproducible test outcomes.
- **Mock drift**: Over-reliance on mocks causes tests to pass while production fails; using real containerized databases or contract tests prevents divergence.
- **Undetected regressions**: Automated CI verification ensures existing features remain unbroken as new changes land.

## AI Agent in the Loop

When directing an AI agent to author or execute tests:

1. **Sandboxed execution**: Demand that the agent runs the test runner locally and verifies stdout before presenting changes.
2. **Prohibit mock hallucination**: Forbid the agent from mocking the system under test or generating trivial assertions (e.g. testing that a mock returns what the mock was configured to return).
3. **Preserve existing coverage**: Strictly forbid the agent from deleting, commenting out, or marking failing tests as skipped (`skip`, `@Ignore`, `xit`) to achieve a green build.
4. **Boundary testing**: Instruct the agent to explicitly test boundary conditions: `null`/`undefined`, empty collections, zero values, maximum integer sizes, and malformed UTF-8 payloads.

## What a Reviewer Checks

| Dimension | Reviewer Check |
| :--- | :--- |
| **Pyramid balance** | Are edge cases covered at the unit level rather than redundantly tested at the E2E level? |
| **Assertion strength** | Are assertions concrete and strict, or do they allow loose truthy matches? |
| **Determinism** | Are tests independent of execution order, system clock time zones, and shared mutable state? |
| **Error clarity** | Does a test failure produce an explanatory error message pinpointing the defect? |

## Checklist

- [ ] Tests structured into Unit (Small), Integration (Medium), and E2E (Large) levels.
- [ ] Business logic and algorithmic branches covered by fast, in-memory unit tests.
- [ ] Integration tests verify actual persistence and serialization against local/containerized services.
- [ ] Tests adhere to the Arrange-Act-Assert (AAA) structure with one logical scenario per test.
- [ ] Assertions verify outputs, state changes, or explicit errors rather than internal implementation details.
- [ ] Zero arbitrary sleep or timeout pauses used; asynchronous operations rely on explicit synchronization.
- [ ] All tests execute deterministically and run cleanly in CI without flaky retries.
