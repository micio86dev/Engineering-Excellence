# Code Review

Code review maintains and improves the long-term health of the codebase. Following the core principle of [Google's Code Review Standard](https://google.github.io/eng-practices/review/reviewer/standard.html), the primary objective is ensuring overall code health improves over time: code does not have to be perfect to be merged, but it must make the system better and maintainable.

## Sequence

1. **Author preparation**: Author writes small, focused changes, self-reviews the diff, ensures tests pass, and provides context using `templates/pull-request.md`.
2. **Automated gate verification**: CI runs linters, type checks, security scanners, and test suites (see `references/quality-gates.md`). Reviewers do not review code with failing automated checks.
3. **High-level architectural review**: Reviewer examines the overall approach, design fit, and public interface contracts before line-by-line reading.
4. **Detailed inspection**: Reviewer checks correctness, security risks, test efficacy, edge case handling, and clarity.
5. **Resolution and sign-off**: Author addresses feedback, updates code, and explains tradeoffs; reviewer approves when all blocking items are resolved.

## Author Duties

Per [The CL Author's Guide](https://google.github.io/eng-practices/review/developer/), the author owns the quality and presentation of the submission:

- **Keep changes small and atomic**: Cap pull requests to a single logical change (ideally under 400 lines). Split large refactorings from functional additions.
- **Provide context**: Use `templates/pull-request.md` to summarize what changed, why, and how it was verified. Link relevant specifications (`templates/openspec.md`) and issues.
- **Run local quality gates first**: Verify formatting, linting, and tests pass locally before requesting peer review.
- **Self-review before handoff**: Read the pull request diff in the repository web UI to catch stray debugging statements, unintended whitespace, or commented code.
- **Respond constructively**: Treat comments as inquiries into code clarity. If a reviewer misunderstood the code, improve the code or comments rather than just explaining in the review thread.

## Reviewer Duties

Per [How to Do a Code Review](https://google.github.io/eng-practices/review/reviewer/), the reviewer safeguards codebase integrity while enabling team velocity:

- **Review design before details**: If the fundamental architecture is flawed, do not spend time nitpicking variable names; address the design first.
- **Distinguish blockers from suggestions**: Explicitly label comments:
  - `blocking:`: Must be resolved before merge (correctness bugs, missing tests, security risks, broken conventions).
  - `suggestion:`: Recommended alternative that improves clarity or efficiency; author may exercise judgment.
  - `question:`: Request for clarification to understand intent.
  - `nit:`: Trivial polish (spelling, optional formatting); must not block merge.
- **Verify test efficacy**: Confirm tests actually fail when logic is altered and that edge cases are exercised, not merely that line coverage percentages increased.
- **Apply the code health standard**: Approve changes that leave the system strictly better than before, even if the implementation differs from how the reviewer would have written it.
- **Review speed**: Aim to provide review feedback within one business day to avoid stalling development.

## Artefacts Produced

- **Pull request description**: Clear summary of changes, test proofs, and checklist status (`templates/pull-request.md`).
- **Structured review comments**: Actionable feedback labeled by severity.
- **Approved changeset**: Clean, rebased or squashed commit ready for merge.

## Failure Modes Prevented

- **Knowledge silos**: Distributes system understanding across multiple team members.
- **Subjective bikeshedding**: Prevents endless debates over personal styling preferences by deferring formatting to automated linters.
- **Defect leakage**: Catches race conditions, memory leaks, and unhandled boundary conditions before production deployment.

## AI Agent in the Loop

When an AI agent participates as author or reviewer:

1. **Agent as author**: The agent must generate a complete pull request description following `templates/pull-request.md`, self-audit its own diff against unintended file edits, and run all test gates before presenting the PR.
2. **Agent as reviewer**: The agent checks for subtle concurrency issues, missing error handling, input validation bypasses, and adherence to repository conventions. It must avoid commenting on formatting rules already handled by linters.
3. **No circular debating**: When receiving human review comments, the agent must address the underlying requirement directly rather than defending the initial code generation.

## Checklist

- [ ] Change is small, atomic, and focused on a single concern (< 400 lines where practical).
- [ ] Pull request description completed using `templates/pull-request.md` with test evidence.
- [ ] All automated CI checks (linting, tests, quality gates) pass prior to review.
- [ ] Review comments use clear severity labels (`blocking:`, `suggestion:`, `question:`, `nit:`).
- [ ] Tests verify behavior and edge cases, not merely happy-path lines.
- [ ] Review verified against [Google's Code Review Standard](https://google.github.io/eng-practices/review/reviewer/standard.html) (overall code health improved).
- [ ] All blocking review comments resolved and verified before merge approval.
