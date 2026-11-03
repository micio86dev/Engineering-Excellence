# Git, Commits and Pull Requests

History is a product artifact. A reviewer, a bisect, a release note and a future agent all read it
without you in the room. Work so each of them gets the truth from the history alone.

Grounded on: Conventional Commits 1.0.0 (conventionalcommits.org), Google eng-practices
"Small CLs", and the review policies that repositories publish for agents.

## One unit, one commit

A commit is the smallest change that stands on its own: it builds, it tests, it makes sense alone,
and reverting it does not revert anything else.

| Rule | Why |
| --- | --- |
| Code, its tests and its docs travel together | A commit that breaks or half-documents the tree is not a unit |
| Split by topic, not by file type | "tests here, implementation there" makes a bisect land on a broken tree |
| Aim for one self-contained change, roughly 100-400 authored lines | Google: 100 lines is reasonable, 1000 is usually too large, and file spread matters as much as line count |
| A change that names a high-risk item (data, security, contracts, concurrency, delivery) gets its own commit | It can then be reviewed and reverted alone |
| Never mix a chore journal, a format sweep or an unrelated fix into a feature commit | The reviewer cannot tell signal from noise, and the revert takes both |

A delivery that depends on an earlier one is not independent: keep it sequential and say so.

## Commit messages

```
<type>[optional scope][!]: <description>

[body: why, and what a reader cannot see in the diff]

[footer(s)]
```

- `type` is a noun: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`.
  `feat` adds a feature, `fix` patches a bug; they map to MINOR and PATCH.
- `scope` is the area of the codebase, in parenthesis: `fix(parser):`, `tools:`, `Launcher:`.
  A repository with its own convention wins over this one; match the neighbours, do not invent a
  third style.
- `!` or a `BREAKING CHANGE: <what changed for the consumer>` footer marks an incompatible change.
  State the migration, not the mood.
- Description: imperative, lowercase after the colon, no trailing period, short enough to survive a
  `git log --oneline` column. It says what changed, not "fixes issue".
- Body: the reason, the measurement, the alternative you rejected, the limit you accepted. If the
  diff already says it, the body adds nothing and should not exist.
- Footers: `Fixes #N` / `Closes #N` when the commit resolves an issue, `Refs #N` when it is part of
  one, `Reviewed-by:` for humans. Trailers are machine-read: keep the exact token spelling.
- Author identity is the human's, not the runner's. Before the first commit in a fresh clone:
  `git config user.name` / `user.email`; a commit authored `root@host` on a public PR is a defect.

## Branches

- `type/description`, the same vocabulary as commits: `tools/settings-sync`,
  `launcher/library-pin`, `fix/adb-closed-wifi-drop`.
- Branch from the branch you will merge into, not from whatever is checked out.
- One topic per branch. A branch that carries two topics produces a pull request nobody can review
  and a squash nobody can describe.

## Pull request descriptions

The description is written for a reviewer who was not in the session. Keep the order, drop the
sections that do not apply:

| Part | Content |
| --- | --- |
| Why | The problem, the symptom, or the issue. One or two sentences. |
| What | The change, in behaviour terms. A bullet per file group only when the shape is not obvious. |
| How to read it | The two or three places a reviewer should start, and what to ignore. Worth its weight on new code. |
| Evidence | The measurement, not the adjective: numbers, sizes, exit codes, a table of before/after. |
| Test plan | The exact commands run and their result. Say which TV, image tag, OS, framework version. |
| What was NOT run | Mandatory and never empty in practice. A silent gap reads as verification you did not do. |
| Risk | `<file>:line` for each finding, or `Risk: none`. Acknowledge the blast radius you did not verify. |
| Rollback | One line when the change is reversible only with effort. |

What belongs in the description and not in the repository: screenshots, benchmark dumps, logs,
one-off transcripts. Link an artifact, do not commit it. No device identifiers, IP addresses, Wi-Fi
names, account emails or tokens, ever.

For a UI change: a screenshot from the real target. For a performance claim: before and after with
the same harness. For a cross-platform script: the matrix you ran, per distribution and shell.

## Splitting a branch that grew too large

When a reviewer asks for a split, do not cherry-pick the mixed history: rebuild each topic from the
base with only its own paths, and make each branch one reviewable commit.

```bash
git fetch upstream
git switch -c tools/settings-sync --no-track upstream/main
git checkout feat/mixed-branch -- tools/settings_sync.py tests/test_settings_sync_import.py docs/workflows/app-settings.md
# hand-apply the shared-file hunks (README row, index line) that belong to this topic only
git commit
```

Then open one pull request per branch, close the mixed one with a comment that lists the
replacements, and keep the reasoning in that comment. Stacked pull requests are the other valid
answer when parts genuinely depend on each other: declare the base branch of each.

## CI/CD gates

A pipeline is a contract, not a decoration:

- **Fail closed.** A gate that cannot run is a failure, not a skip, unless the repository says
  otherwise. Report `unavailable` explicitly.
- **Fast first.** Unit tests before integration, lint and type checks in parallel, the expensive
  matrix after. A pipeline that takes 40 minutes to say "missing semicolon" is not used.
- **Matrix what the claim covers.** Every distribution, OS and toolchain the project claims, plus
  the derivatives it resolves through. The project's own entrypoints, not only its test suite.
- **Ratio gates over absolute gates** wherever possible. An absolute byte limit on a build artifact
  goes red for reasons unrelated to the change; when you must use one, measure the baseline in the
  same run and report both numbers.
- **Invariants in code, not in prose.** Generated tables, counts, formatting, translation
  completeness and protected lists belong in a test, so the gate holds after everyone forgets.
- **Never bypass a hook with `--no-verify`.** If the hook's ruleset is wrong for the repository, fix
  the ruleset (a project-level config), or get the maintainer's explicit agreement and say so in the
  report. Silently disabling the gate converts a reviewable change into an unverified one.
- **Do not push a pull request whose gate you already know fails.** Fix it, or open it as a draft
  that states the failure and the number.

## Contributing to a repository you do not own

1. Measure the permission, do not assume it:
   `gh api repos/<owner>/<repo> --jq .permissions` -> `push:false` means a direct push returns 403.
2. Push the branch to your fork, then open the cross-repository pull request:
   `gh pr create --repo <owner>/<repo> --base main --head <you>:<branch>`.
3. Respect the repository's own rules before its reviewers have to: one topic, no internal journal
   files, no self-promotion rows, no changes to safety logic, no workflow edits.
4. Answer review findings with the change, the test that pins it, and the number. "Should be fine"
   costs you the review.
5. If a requested change is a design decision (who owns a step, which tool does the work), implement
   the safety half immediately and say plainly which half is the maintainer's call.

## Amending history

- `--force-with-lease`, never bare `--force`. Confirm the branch is yours and unreviewed before
  rewriting it, and say in the report that you rewrote it.
- Re-authoring commits (`git filter-branch --env-filter` or `git rebase --exec 'git commit --amend
  --no-edit --reset-author'`) keeps the diff and changes attribution; do it before the reviewer
  spends time on the branch.
- Do not rebase a branch that a reviewer is actively reading without telling them.

## Anti-patterns

| Anti-pattern | Cost |
| --- | --- |
| Mixed-topic pull request | Unreviewable, un-revertable, and the first thing a bot rejects |
| Commit body that repeats the diff | Noise that ages badly |
| Internal task journals in a public branch | They are not the project's artifacts |
| Machine-translated strings without review | Wrong in public, hard to notice, harder to fix |
| "Tested locally" with no command | Not evidence |
| Force-push onto a branch under review | The reviewer's line comments detach |
| Green suite claimed while a gate was skipped | The one thing that destroys trust in the pipeline |

## Before you push

- [ ] One topic; the title says what changed, in the repository's own style
- [ ] Code, tests and docs for that behaviour in the same unit
- [ ] Suite run, result quoted with the count
- [ ] Every gate that could run, run; the rest named as not run
- [ ] Author identity is the human's
- [ ] No secrets, identifiers, screenshots or journals in the tree
- [ ] The description answers why, how to read it, evidence, test plan, what was not run, risk
