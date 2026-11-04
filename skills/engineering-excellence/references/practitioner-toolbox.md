# The Practitioner's Toolbox

Three roles share one substrate. Give each role the tool that removes its bottleneck, and refuse the
tool that only looks professional.

## The substrate everyone depends on

| Concern | Minimum viable | Why not more, yet |
| --- | --- | --- |
| Identity | One IdP with MFA, SSO into everything | Per-tool local accounts are the audit hole every incident report mentions |
| Secrets | One store (Vault, SOPS+age, cloud secret manager), injected at runtime | Secrets in `.env` files on disk spread through backups and shell history |
| Compute | Compose on one host, k3s on a few, managed Kubernetes beyond that | See `container-orchestration-choice.md` |
| Ingress | One proxy with ACME and explicit limits | See `traffic-and-ingress.md` |
| Storage | S3-compatible object store for blobs, a database for facts | See `object-storage-selection.md` |
| Backups | Scheduled, off-host, immutable, restore tested quarterly | Replication is not backup |
| Observability | Metrics, structured logs, one alert route | Three dashboards nobody opens is worse than one that pages |
| IaC | Terraform/OpenTofu for infrastructure, git for everything else | Click-ops is a state file you cannot read |
| CI/CD | One pipeline per repository, artifacts by digest | See `ci-cd-and-publishing.md` |
| Registry | Private registry for images and packages, retention policy | Rebuilding on the host is not a deploy |
| DNS | Zone as code, DNSSEC considered | See `dns-and-email-delivery.md` |

## Data scientist

| Need | Tool | Note |
| --- | --- | --- |
| Reproducible environments | `uv` or `pixi` with a lockfile (conda only when CUDA wheels demand it) | "Works on my notebook" is an environment bug, not a personality |
| Data versioning | DVC or a lakehouse (Iceberg/Delta) on the object store | A `data/final_v7.csv` in git LFS is not lineage |
| Experiments | MLflow or Weights & Biases, with a run per training | Reproducibility means the commit, the data hash, the params and the metrics together |
| Model registry | MLflow registry or the artifact store plus a manifest | Promotion is a decision with a record, not a filename |
| Notebooks | Notebook for exploration; a module plus a job for anything scheduled | Notebooks in cron are how silent wrong numbers get produced |
| Compute | GPU node pool with the device plugin, MIG for sharing, quotas per team | One team holding all the GPUs is a scheduling incident |
| Feature/quality checks | `pandera`, `pydantic`, `great_expectations` at the boundary | A model trained on malformed input is a data bug wearing a model |
| Serving | An API (FastAPI) or a batch job, never the notebook | Same artifact for training and serving, or the skew is invisible |

Two rules worth more than the tool list: every result carries its inputs (commit, data snapshot, params,
environment hash), and every dataset has an owner and a retention rule.

## IT manager

| Need | Deliverable | Note |
| --- | --- | --- |
| Access control | SSO + SCIM, role matrix, quarterly review | Offboarding is a process with a test, not an intention |
| Audit | Log retention, who did what, exports and admin actions | Plan limits on retention is a budget question, decide it early |
| Cost visibility | Tagging policy enforced, monthly spend by service | Untagged resources are unattributable spend |
| Vendor risk | Data processing agreements, exit plan per vendor | The exit plan is the part everyone skips |
| Incident process | Severity ladder, on-call rotation, postmortem template | An incident without a postmortem repeats on schedule |
| Change control | Change log derived from git and pipelines, not from memory | Auditors accept a repository, not a spreadsheet |
| Continuity | RTO/RPO written down, restore rehearsal calendared | Numbers nobody has tested are aspirations |
| Licence/compliance | SBOM per release, dependency policy, copyleft review | An SBOM you never read is a PDF, not a control |

## DevOps and developer

| Need | Tool | Note |
| --- | --- | --- |
| Infrastructure as code | Terraform/OpenTofu, modules per environment, remote state locked | State is data; treat it as such |
| Configuration | Ansible for hosts that remain, cloud-init for what is created | Two config systems over the same host is a race |
| Continuous delivery | One pipeline, environment gates, artifact promotion by digest | See `ci-cd-and-publishing.md` |
| Progressive delivery | Weighted routes or flags before a full rollout | Rollback rehearsal beats a rollback document |
| Runtime security | Non-root, read-only root FS, seccomp/apparmor where it costs nothing | A container that can write its own binary is a persistence mechanism |
| Policy | A few OPA/Kyverno rules that block the real mistakes | Policy nobody can explain is disabled during the first incident |
| Dependency hygiene | Renovate/Dependabot grouped, auto-merge only patch + green | Ungrouped PRs train people to ignore them |
| Debugging | Structured logs, request ids, traces on the slow path only | Tracing everything is a bill, not an observability strategy |

## What not to adopt yet

- A service mesh before you have more than a handful of services: the mTLS win is real, the operational
  surface is larger than the app.
- A platform team's internal developer platform, when three services exist.
- A second orchestrator "for experiments".
- Multi-region anything before a single region is boring.
- A data catalog before the datasets have owners.
- A SIEM before the logs are structured.

Adopt the next tool when a specific, named failure has happened or is documented as imminent. Write the
trigger down in the repository, so the decision is reviewable later.

## Role boundaries that keep the stack small

- The data scientist owns the model and its inputs, not the cluster.
- The DevOps engineer owns the substrate and the delivery path, not the model's accuracy.
- The IT manager owns access, audit, cost and continuity, and does not hand-edit production.
- Every shared tool has one owner, one runbook and one upgrade cadence.

## Checklist

- [ ] Substrate table: each row has a tool, an owner and a documented gap
- [ ] Per role, the bottleneck is named and the tool chosen for it
- [ ] No tool adopted without a written trigger and a rollback
- [ ] Every dataset and model has an owner, a retention rule and inputs recorded
- [ ] Every shared tool has a runbook; every credential has a rotation path
