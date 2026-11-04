# CI

Continuous integration verifies every change against an automated pipeline before merge.
The pipeline is an immutable quality gate: if any stage fails, the change does not ship.
For deployment pipelines, packaging, and release automation, see [references/ci-cd-and-publishing.md](references/ci-cd-and-publishing.md).

## The pipeline contract

A reliable CI pipeline conforms to four invariants:

1. **Fast feedback**: Pull request validation completes in under 10 minutes. Slow pipelines incentivize batching changes and skipping tests.
2. **Determinism**: The same commit run against the same pipeline produces identical results. Flaky tests are treated as blocking bugs.
3. **Hermetic isolation**: Every job executes in an ephemeral, clean runner. No mutable state leaks across pipeline runs.
4. **Local parity**: Every CI stage runs locally with a single matching command (for example, `npm run lint` or `make test`).

## Pipeline stages

Order stages by execution speed and cost. Fail as early as possible to preserve runner compute and developer focus:

| Stage | Purpose | Typical tools | Failure policy |
| --- | --- | --- | --- |
| 1. Static analysis | Formatting, linting, typechecking, secret scanning | ESLint, Ruff, ShellCheck, Trufflehog | Fail immediately on any violation |
| 2. Unit tests | Fast in-memory business logic verification with coverage | Vitest, pytest, Go test, JUnit | Blocks merge if coverage drops below threshold |
| 3. Integration tests | Subsystem interaction with isolated dependencies | Testcontainers, ephemeral Postgres/Redis | Fail on deadlocks, race conditions, or timeouts |
| 4. Build & packaging | Compilation, bundle analysis, container build check | esbuild, tsc, docker buildx | Enforce zero compile errors and artifact size budgets |
| 5. End-to-end (E2E) | Critical user journey validation | Playwright, Cypress | Run on PR or merge; quarantine flakiness immediately |

## Deterministic dependencies and caching

Unpinned dependencies or unverified packages break pipeline reproducibility and expose supply chains to tampering.

- **Lockfile enforcement**: Always install strictly from committed lockfiles without resolving new package versions.
  Use `npm ci`, `pnpm install --frozen-lockfile`, `poetry install --no-root --sync`, `go mod verify`, or `cargo check --locked`.
- **Cache key hashing**: Key dependency caches strictly on content hashes of lockfiles (for example, `hashFiles('**/package-lock.json')`).
  Never key caches solely on OS or branch names, which risks poisoning caches with stale artifacts.
- **Cache miss resilience**: The pipeline must build and pass cleanly from scratch on a complete cache miss.
- **Matrix testing**: When supporting multiple runtimes or operating systems, test against explicit matrix targets rather than implicit runner defaults.

## Concurrency and queue hygiene

Shared runner capacity is a constrained engineering resource. Protect queues from unnecessary execution:

- **Cancel obsolete runs**: When new commits are pushed to an open pull request, cancel in-progress runs immediately using [GitHub Actions concurrency](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#concurrency) (`cancel-in-progress: true`).
- **Enforce job timeouts**: Declare explicit timeouts on every job (`timeout-minutes: 10`). A deadlocked test or stalled network fetch must not block runner pools.
- **Fail fast in matrices**: Configure multi-job matrices to abort remaining jobs on the first detected failure (`fail-fast: true`).

## Flake management and diagnostics

- **No blind retries**: Do not configure automated step retries (`retry: 3`) to mask test failures. Retries obscure race conditions and leaky test fixtures.
- **Quarantine protocol**: Intermittent failures must be quarantined immediately into tracked issues with clear ownership.
- **Diagnostic artifacts**: On test failure, capture structured test reports (JUnit XML), browser traces, and container logs with a bounded retention policy (7 to 14 days).
- **Masked secrets**: Ensure secrets and runner tokens are masked in output logs. Never execute `env` or print unmasked configurations in diagnostic steps.

## Checklist

- [ ] Pipeline completes all pull request verification stages in under 10 minutes
- [ ] Every CI stage can be executed locally with a documented command
- [ ] Dependencies installed strictly using frozen lockfiles (`npm ci`, `frozen-lockfile`, etc.)
- [ ] Dependency cache keyed on content hash of lockfile; builds successfully on cache miss
- [ ] Obsolete pull request runs canceled automatically on new commit pushes
- [ ] Explicit job execution timeouts (`timeout-minutes`) declared on all jobs
- [ ] Flaky tests quarantined to tracked issues rather than masked with automated retries
- [ ] Diagnostic artifacts (test reports, traces, failure logs) captured on failure
- [ ] Secret masking verified; no credentials or private tokens printed in pipeline logs
- [ ] Quality gates (see [references/quality-gates.md](references/quality-gates.md)) enforced before merge approval
