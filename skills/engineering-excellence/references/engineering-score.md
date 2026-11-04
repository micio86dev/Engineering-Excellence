# Engineering Score

The engineering score provides an objective, quantified measurement of software quality across architectural integrity, test rigor, security posture, and maintainability. It converts qualitative engineering standards into a verifiable 100-point composite score reported in `templates/engineering-report.md`, establishing clear criteria for production readiness.

## Scoring Rubric

The 100-point score is divided into six core dimensions. Each dimension must be backed by verifiable automated checks or code artifacts:

| Dimension | Max Points | Evaluation Criteria |
| :--- | :--- | :--- |
| **Specification & Scope** | 15 | Approved OpenSpec document (`templates/openspec.md`) exists; requirements use [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) keywords; zero unstated scope creep. |
| **Architecture & Design** | 20 | Adheres to SOLID, DRY, and KISS principles; modular separation of concerns; ADR (`templates/adr.md`) filed for structural or dependency changes. |
| **Testing & Verification** | 25 | Balanced test pyramid (Unit, Integration, E2E); new code test coverage >= 80.0%; meaningful assertions verifying state and error paths without mock abuse. |
| **Security & Safety** | 20 | Strict input validation; zero unhandled injection/sanitization vulnerabilities; no hardcoded secrets; defensive error handling without leaking internals. |
| **Maintainability & Hygiene** | 10 | Code duplication <= 3.0%; zero dead code; zero linter/compiler errors or unapproved suppressions; clean, descriptive naming conventions. |
| **Documentation & Domain** | 10 | Updated documentation (`templates/engineering-report.md`); applicable domain gates satisfied (WCAG 2.2 AA accessibility, Core Web Vitals, i18n, SEO). If a domain gate is genuinely not applicable, redistribute points proportionately. |

## Thresholds and Actions

- **90 – 100 (Production Ready)**: The change meets all engineering standards. Approved for unconditional production deployment.
- **80 – 89 (Conditional Acceptance)**: Minor non-critical gaps identified. Approved for merge only if identified issues are formally documented in the technical debt log (see `references/technical-debt.md`).
- **< 80 (Gate Failure)**: The submission fails engineering quality standards. Blocked from merge; author must remediate deficiencies and resubmit for evaluation.

## Sequence

1. **Implementation & Gate Execution**: Author completes code, tests, and runs CI quality gates (see `references/quality-gates.md`).
2. **Dimension Evaluation**: Author audits the change against the six rubric dimensions, collecting concrete metrics and file citations.
3. **Report Generation**: Author fills out `templates/engineering-report.md`, recording individual dimension scores, justifications, and overall total.
4. **Peer/Reviewer Audit**: Reviewer inspects the report against the actual code diff and automated test artifacts.
5. **Disposition**: If score >= 90, approve; if 80-89, verify technical debt tickets exist; if < 80, reject with remediation requirements.

## Artefacts Produced

- **Engineering Report**: A completed `templates/engineering-report.md` documenting dimension scores, metric evidence, and technical debt declarations.
- **Technical Debt Backlog Entries**: Issues or tickets tracking remediations required for points deducted during scoring (see `references/technical-debt.md`).

## Failure Modes Prevented

- **Subjective reviews**: Prevents debates rooted in developer seniority or taste by establishing explicit scoring criteria.
- **Hidden technical debt**: Quantifies compromises and ensures debt is visible and tracked rather than forgotten.
- **False confidence**: Ensures high test coverage alone cannot mask architectural decay, poor input validation, or missing documentation.

## AI Agent in the Loop

When an AI agent evaluates or reports an engineering score:

1. **Mandatory evidence citation**: The agent must cite exact file paths, line numbers, test outputs, or tool metrics for every point awarded or deducted.
2. **Prohibition of automatic perfect scores**: The agent is forbidden from reporting 100/100 without verifying every dimension against primary tool output.
3. **Mandatory debt logging**: If the agent assigns a score between 80 and 89, it must automatically generate a technical debt entry detailing the exact remediation plan.
4. **Honest N/A handling**: If a dimension does not apply (e.g. accessibility for a headless backend daemon), the agent must explicitly state why the dimension is N/A rather than silently skipping it.

## What a Reviewer Checks

| Item | Reviewer Check |
| :--- | :--- |
| **Evidence verification** | Do the claimed coverage, linting, and duplication figures match the CI build logs? |
| **Justification rigor** | Are point deductions justified with actionable remediation items? |
| **N/A validity** | Is the omission of specialized domains (accessibility, i18n, SEO) genuinely appropriate for the repository type? |
| **Score threshold compliance** | Is any PR under 80 points blocked from merging without exception? |

## Checklist

- [ ] All six dimensions evaluated with explicit numeric points assigned.
- [ ] Claimed test coverage, duplication, and lint figures match CI tool artifacts.
- [ ] Specification and ADR references included for requirements and architectural changes.
- [ ] Any score deduction is accompanied by an actionable remediation item.
- [ ] Scores between 80 and 89 have corresponding technical debt logged in `references/technical-debt.md`.
- [ ] Engineering report completed using `templates/engineering-report.md` and attached to the pull request.
- [ ] Overall score meets or exceeds the minimum release threshold (>= 90 for production ready, >= 80 with debt).
