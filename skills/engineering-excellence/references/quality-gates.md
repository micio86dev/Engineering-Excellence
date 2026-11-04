# Quality Gates

Quality gates enforce automated and objective thresholds that every change must satisfy before promotion. Rather than relying on subjective judgment, quality gates stop defective code at defined checkpoints, guaranteeing that technical debt is halted at the point of introduction.

## Sequence

Quality gates are evaluated sequentially across four progression tiers:

1. **Local pre-commit gate**: Fast, developer-side checks. Executes formatting, fast linters, and unit tests before code is committed.
2. **Continuous Integration (CI) build gate**: Comprehensive server-side build. Compiles code, runs type checks, executes full unit and integration test suites, and evaluates static analysis.
3. **Static analysis & quality gate**: Applies differential analysis to incoming code. Evaluates coverage, duplication, complexity, and security vulnerabilities against baseline thresholds.
4. **Pre-release & deployment gate**: Executes end-to-end smoke tests, environment health checks, and domain-specific audits (accessibility, performance, SEO) before routing live traffic.

## Gate Thresholds and Criteria

Following the industry-standard Clean as You Code model defined in the [SonarQube Quality Gates Documentation](https://docs.sonarsource.com/sonarqube-server/10.8/instance-administration/analysis-functions/quality-gates), pull requests must satisfy explicit differential thresholds on new or modified code:

| Metric | Target Threshold | Scope | Rationale |
| :--- | :--- | :--- | :--- |
| **New Bugs & Vulnerabilities** | 0 | New code | Eliminates regression leaks immediately. |
| **Security Hotspots** | 100% reviewed | New code | Ensures sensitive patterns (auth, crypto, SQL) are manually audited. |
| **Test Coverage** | >= 80.0% | New code | Guarantees all new branches and logic have automated verification. |
| **Duplicated Lines** | <= 3.0% | New code | Enforces DRY (`references/dry.md`) and prevents copy-paste sprawl. |
| **Build & Linter Status** | 0 errors, 0 unhandled warnings | Entire repo | Zero tolerance for broken compilation or lint failures. |
| **Dead Code** | 0 unused exports / uncalled methods | New code | Prevents cognitive overhead and stale logic accumulation. |

## Specialized Domain Gates (When Applicable)

For projects with frontend, public web, or multi-tenant surfaces, verify:

- **Accessibility**: WCAG 2.2 AA compliance; zero automated Axe/Lighthouse accessibility violations (see `references/accessibility.md`).
- **Performance**: Core Web Vitals within targets (LCP <= 2.5s, INP <= 200ms, CLS <= 0.1) under throttled mobile audit (see `references/performance.md`).
- **Internationalization (i18n)**: Zero hardcoded user-facing strings; strings extracted to translation keys (see `references/i18n.md`).
- **SEO & Discoverability**: Meta tags, canonical links, and OpenGraph headers validated; staging indexing disabled (see `references/seo.md` and `references/environments.md`).
- **W3C Standards**: Generated HTML and CSS validate cleanly without structural markup errors.

## Artefacts Produced

- **CI build logs**: Machine-verifiable build output proving successful compilation and test execution.
- **Coverage reports**: Machine-readable coverage data (e.g. lcov, Cobertura, JaCoCo) displaying diff coverage.
- **Static analysis triage**: Security scanner and linter reports confirming zero newly introduced issues.
- **Engineering report**: Dimensional summary matching `templates/engineering-report.md`.

## Failure Modes Prevented

- **Broken trunk**: Halts uncompilable or failing code before merging to main branches.
- **Creeping technical debt**: Enforcing differential checks ensures old debt is isolated while new code remains pristine.
- **Silent security regressions**: Catches insecure dependencies and OWASP top-10 vulnerabilities in the pipeline.

## AI Agent in the Loop

When an AI agent writes or modifies code:

1. **Autonomous verification**: The agent must run all local gates (build, lint, test, format) and verify green output before reporting task completion.
2. **Zero bypass tolerance**: The agent is strictly prohibited from bypassing gates using `--no-verify`, disabling linter rules (`eslint-disable`, `@ts-ignore`, `# noqa`), or silencing failing assertions.
3. **Fix the root cause**: When a gate fails, the agent must inspect the failure report, correct the implementation or test, and re-run the gate from scratch.

## What a Reviewer Checks

| Area | Reviewer Check |
| :--- | :--- |
| **Pipeline status** | Are all CI checks green without manual overrides or skipped stages? |
| **Coverage validity** | Is the 80% coverage driven by meaningful assertions or empty tests? |
| **Rule suppressions** | Are there any new linter/compiler suppression comments added to the diff? |
| **Domain compliance** | If user-facing UI changed, were accessibility and performance audits executed? |

## Gate checklist

- [ ] Specification document (`templates/openspec.md`) updated and approved.
- [ ] Clean build: 0 compilation errors and 0 unhandled compiler warnings.
- [ ] Clean lint: linter and type-checker pass with 0 errors.
- [ ] All automated unit, integration, and contract tests pass.
- [ ] New code achieves >= 80.0% test coverage with 0 new bugs or vulnerabilities.
- [ ] Code duplication on new code is <= 3.0%.
- [ ] Zero dead code, unused dependencies, or commented-out blocks introduced.
- [ ] Secrets and credentials scanned; none committed to repository (see `references/security.md`).
- [ ] When applicable: Accessibility, Performance, i18n, and SEO criteria satisfied.
