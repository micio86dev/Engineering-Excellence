# Technical Debt

Record intentional debt with rationale and follow-up.
Technical debt is not sloppy engineering; it is an explicit tactical trade-off where a team accepts short-term suboptimal design to deliver immediate learning or meet an urgent deadline, with a deliberate plan to pay it down later.

## Intentional vs accidental debt

Distinguish between disciplined trade-offs and poor craftsmanship:

| Dimension | Intentional debt | Accidental debt |
| --- | --- | --- |
| **Origin** | Deliberate, conscious choice agreed upon during design or review | Sloppiness, lack of discipline, hasty coding, or missing tests |
| **Documentation** | Recorded in the codebase with a linked tracking issue and rationale | Naked `TODO` or `FIXME` comments with no owner, date, or context |
| **Testing** | Covered by regression tests verifying behavior under current limits | Untested or poorly tested code prone to silent breakage |
| **Payoff path** | Explicit sunset trigger, replacement architecture, and budget | Ignored until an incident or complete development stall forces action |

Prevent accidental debt at the gate: enforce code reviews (see [references/code-review.md](references/code-review.md)) and standard quality gates (see [references/quality-gates.md](references/quality-gates.md)).

## The debt register and in-code annotations

Never allow debt to live as tribal knowledge. Every piece of intentional debt must be visible at its point of impact:

- **Structured code comments**: Format all intentional shortcuts with an issue reference, clear rationale, and planned remediation:
  ```
  // DEBT(ENG-1284): Using in-memory cache pending Redis cluster provisioning.
  // Bound to max 500 keys; replace before traffic exceeds 100 req/s.
  ```
- **Ban naked TODOs**: A comment like `// TODO: fix this later` is technical debt without accountability. CI linters should reject unlinked `TODO` or `FIXME` comments in production code.
- **Issue tracker labeling**: Maintain a dedicated `tech-debt` label in your issue tracker. Categorize debt items by estimated payoff effort and operational friction.

## Debt budgeting and repayment cadence

Technical debt accrues compound interest in the form of slower delivery, fragile deployments, and degraded developer velocity:

- **Recurring debt budget**: Allocate a fixed proportion of engineering capacity (typically 15% to 20% per development cycle) explicitly to debt reduction, toolchain upgrades, and architectural cleanup.
- **The Boy Scout Rule**: Leave touched files cleaner than you found them, but keep opportunistic cleanup strictly bounded to the immediate scope of the change.
- **Avoid "The Great Rewrite"**: Massive, all-or-nothing rewrites usually fail. Pay down debt incrementally through Strangler Fig patterns, extracting small modules while keeping tests green.

## Friction signals and triggers to pay down

Do not prioritize debt based on aesthetic distaste. Prioritize based on measured operational friction:

1. **Churn hotspots**: Modules that change frequently and have high cyclomatic complexity are prime regression sources. Refactor these first.
2. **Test suite duration creep**: When test runs exceed target budgets, prioritize test suite refactoring, test parallelization, and database fixture pruning.
3. **Repeated defect clusters**: Subsystems that generate recurring bugs indicate architectural mismatch or hidden coupling.
4. **Developer hesitation**: Modules that engineers fear touching or reviewing require architectural simplification and test hardening.

## Refactoring discipline

Refactoring changes internal structure without altering observable behavior:

- **Separate refactoring from functional changes**: Never mix structural refactoring and feature delivery in the same pull request. A refactoring PR must make zero behavioral changes; a feature PR must build cleanly on the existing or refactored structure.
- **Rely on regression safety**: Never refactor code without automated test coverage. If tests are missing, write characterization tests first (see [references/tdd.md](references/tdd.md) and [references/testing.md](references/testing.md)), verify they pass, and only then refactor.

## Decommissioning and sunsetting

Code that is never deleted becomes permanent debt:

- **Feature flag lifecycles**: Feature flags are temporary debt. When creating a feature flag, create a companion cleanup ticket to remove the flag, toggle checks, and obsolete execution branches once rollout completes.
- **API and endpoint deprecation**: Follow an explicit deprecation lifecycle: mark with deprecation headers, emit deprecation logs, observe zero traffic in production metrics, and finally delete the dead code and endpoints.

## Checklist

- [ ] Technical debt is intentional, justified, and linked to a tracked issue (`DEBT(ticket): ...`)
- [ ] No naked, untracked `TODO` or `FIXME` comments committed to production branches
- [ ] Dedicated engineering capacity (15–20%) reserved each cycle for debt paydown and upgrades
- [ ] High-churn and high-defect hotspots identified and prioritized for refactoring
- [ ] Structural refactoring separated from functional changes into distinct pull requests
- [ ] Full regression test suite green before initiating structural refactorings
- [ ] Temporary feature flags tracked with scheduled removal and cleanup tasks
- [ ] Deprecated APIs, dead code, and unused endpoints removed after verifying zero production usage
