# CI/CD: Pipelines, Images and Publishing

A pipeline is the only thing that ships. Everything below exists to make what ships reproducible,
attributable and reversible.

## Pipeline shape

- **Fail closed.** A check that cannot run is a failure, not a skip, unless the repository states
  otherwise. Report `NOT RUN` explicitly instead of letting a green build lie.
- **Fast first.** Format and lint, then unit tests, then integration, then the multi-platform matrix,
  then publish. A pipeline that takes forty minutes to report a missing semicolon is a pipeline
  people route around.
- **One job, one responsibility.** A job that tests and publishes cannot be re-run safely.
- **Cache dependencies, never cache build output** that a downstream gate is supposed to verify.
- **Cancel superseded runs** on the same ref; never cancel a run that is deploying.
- **Matrix what the claim covers**: every OS, runtime and architecture the project promises, including
  the ones it reaches indirectly. Name the rows that no runner could execute.
- **Required checks on the default branch**, defined in the repository, not in someone's habit.
- **Deterministic inputs**: lockfiles committed, tool versions pinned, base images by digest.

## Build once, promote the artifact

The artifact that passed the tests is the artifact that reaches production. Rebuilding between
stages reintroduces everything the tests did not see.

```
build → test → scan → sign → push by immutable digest → deploy that digest
```

- Tag by digest in production. `latest` is a convenience alias for humans, never a deployment input.
- Keep a deploy record: digest, commit, pipeline run, approver, timestamp.
- Rollback is "deploy the previous digest", not "rebuild the previous tag".

## Container images

- Multi-stage builds; the runtime stage carries the runtime and nothing else.
- Pin the base image by digest; a floating tag is an unreviewed upgrade.
- Run as a non-root user with a read-only root filesystem where the app allows it.
- `.dockerignore` everything that is not needed, `.git` and secrets first.
- No secrets in layers: an `ARG` or `ENV` secret stays in the image history forever. Mount at runtime.
- Add OCI labels (source, revision, version, created) and generate an SBOM.
- Scan the image and gate on severity; state the threshold and the exceptions with an expiry.
- Sign the image and publish an attestation (Sigstore/cosign, SLSA provenance); verify at admission if
  the platform supports it.
- Healthcheck and a graceful shutdown path; a container that ignores `SIGTERM` turns every deploy into
  a timeout.

## Publishing packages

- Publish from CI only. A laptop publish has no provenance and no reviewer.
- Version from the tag or the changeset, and fail the run if the version already exists: a publish is
  idempotent or it is an accident.
- `npm ci`, never `npm install`, in a publishing job.
- Run the suite and the build in `prepublishOnly` (or the equivalent lifecycle hook), so `publish`
  cannot ship something untested.
- Prefer OIDC trusted publishing to a long-lived `NPM_TOKEN`: a registry token in repository secrets
  is a credential that outlives the run that needed it.
- Emit provenance (`--provenance`, `publishConfig.provenance`) and verify it after the fact.
- Pre-releases go to a dist-tag (`next`), never to `latest`. `latest` moves once, on a release commit.
- Scope and access are explicit: `--access public` for a public scoped package, npm org 2FA enforced.
- After publishing, verify from a clean environment (`npm view`, install in a temp dir) and record the
  version in the release notes.

## Deploy and rollback

- Migrations first, backwards compatible, and deployable before the code that needs them.
- Canary or blue-green when the platform allows; otherwise a staged rollout with an error-budget gate.
- Feature flags decouple deploy from release; a flag without an owner and an expiry becomes debt.
- Post-deploy smoke test against the deployed artifact, not against the previous one.
- Rollback plan in the pull request: which digest, which migration is irreversible, what data is lost.
- Never deploy on a red matrix and never mark a deploy "done" without the smoke test output.

## Secrets and credentials in pipelines

- Prefer short-lived OIDC federation over stored credentials: cloud roles, registries, and package
  registries all support it.
- Scope per job and per environment; production credentials never reach a test job.
- Environment protection: manual approval, branch restriction, no secrets for pull requests from forks.
- Never echo a secret; mask it, and remember masks fail on transformed values.
- Rotate on suspicion, not on incident only, and record where each credential lives.

## Auditability

- Retain pipeline logs, artifacts and attestations for as long as the release they belong to matters.
- Record approvals with identity, not just "approved".
- Generate release notes from commits and pull requests; the changelog is not written by memory.
- Dependency and secret scanning run on a schedule as well as on push: a new advisory targets code
  that never changed.
- DORA's four keys (lead time, deployment frequency, change failure rate, time to restore) are the
  health metric; vanity counts are not.

## Gate checklist

- [ ] Build reproducible and pinned (lockfiles, digests, tool versions)
- [ ] Tests, lint and type checks required on the default branch
- [ ] Matrix covers every claimed platform, with `NOT RUN` named for the rest
- [ ] Image: non-root, minimal, scanned, signed, SBOM, digest-tagged
- [ ] Publish: CI-only, version-checked, provenance, dist-tag for pre-releases
- [ ] Deploy: migrations ordered, canary or staged, smoke test, rollback digest recorded
- [ ] Credentials: OIDC where possible, scoped per job, no long-lived tokens
- [ ] Audit: logs, attestations and approvals retained; scheduled scans enabled
