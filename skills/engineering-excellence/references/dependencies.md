# Dependencies

Every dependency must be justified and maintained.
Adding a third-party package is not free: it introduces maintenance overhead, expands the security attack surface, and adds a point of failure to the build pipeline.

## The adoption bar

Before running `npm install`, `cargo add`, or `pip install`, evaluate whether the dependency justifies its long-term cost:

- **The standard library first**: Prefer language standard libraries or existing codebase helpers over single-purpose external packages. If a function takes fewer than 50 lines to write and test cleanly, do not import a dependency.
- **Maintenance velocity**: Verify active maintenance within the past six months, steady release cadence, and active maintainer responsiveness to bug reports.
- **Bus factor and community**: Avoid single-maintainer critical packages. Favor projects backed by multiple active maintainers or established foundations.
- **Transitive weight**: Inspect the dependency tree before importing. A simple utility pulling 40 transitive packages introduces 40 additional attack vectors.
- **Security posture**: Check the project's health using [OpenSSF Scorecard](https://scorecard.dev/) to verify automated testing, branch protection, vulnerability management, and absence of known unpatched vulnerabilities.

## Lockfiles and deterministic resolution

Never allow floating version resolution in CI or production environments:

- **Commit lockfiles**: Check all lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `go.sum`) directly into source control.
- **Strict installation commands**: Enforce lockfile-only installations in CI pipelines. Prohibit commands that update lockfiles during build:
  - Node.js: `npm ci` or `pnpm install --frozen-lockfile`
  - Python: `poetry install --no-root --sync` or `pip install --require-hashes -r requirements.txt`
  - Rust: `cargo check --locked`
  - Go: `go mod verify`
- **Manual lockfile changes prohibited**: Treat lockfiles as compiled build artifacts. Never hand-edit hashes, URLs, or version specs.

## Vulnerability scanning and remediation SLAs

Automate vulnerability detection across direct and transitive dependencies:

- **Continuous CI scanning**: Run automated dependency vulnerability scans in every pull request and on a daily schedule using tools like OSV-Scanner, Trivy, Dependabot, or Renovate.
- **Enforce remediation SLAs**: Establish strict response windows based on CVSS severity thresholds:
  - **Critical (CVSS 9.0+)**: Mitigate or patch within 48 hours. If upstream has no patch, isolate or vendor with a local fix.
  - **High (CVSS 7.0–8.9)**: Patch within 14 calendar days.
  - **Medium / Low**: Resolve during standard dependency update cycles.
- **Lockfile poisoning and typosquatting**: Verify package scopes (`@org/pkg`), verify package URLs against canonical registries, and disallow untrusted third-party registries.

## License compliance

Dependencies introduce legal obligations for distribution and deployment:

| License category | Examples | Permissible usage |
| --- | --- | --- |
| **Permissive** | MIT, Apache-2.0, BSD-2/3-Clause, ISC | Approved for internal, proprietary, and commercial distribution |
| **Weak copyleft** | LGPL-2.1/3.0, MPL-2.0 | Permissible if dynamically linked and unmodified; requires review |
| **Strong copyleft** | GPL-2.0/3.0, AGPL-3.0 | Prohibited in proprietary closed-source products without legal sign-off |
| **Non-commercial / Ambiguous** | SSPL, BSL, Commons Clause | Prohibited without explicit organizational and commercial licensing clearance |

Incorporate automated license scanning in CI to fail immediately when an unapproved license enters the dependency manifest.

## Pruning and lifecycle maintenance

- **Audit dependency trees**: Regularly audit direct and indirect dependencies (`npm ls`, `cargo tree`, `pipdeptree`) to spot duplicate versions, dead code, and bloated trees.
- **Keep dependencies current**: Schedule small, frequent automated updates via Dependabot or Renovate. Upgrading across five minor versions is routine; upgrading across three neglected major versions is an emergency.
- **Decommission obsolete packages**: When an upstream repository is archived, unmaintained, or superseded, open a debt ticket (see [references/technical-debt.md](references/technical-debt.md)) to replace it before it breaks your build.

## Checklist

- [ ] New dependency justified: problem cannot be solved cleanly in <50 lines using standard libraries
- [ ] Maintainer health and [OpenSSF Scorecard](https://scorecard.dev/) checked for active maintenance and security hygiene
- [ ] Transitive dependency footprint inspected before adding the package
- [ ] Lockfiles committed to git and strictly enforced in CI (`npm ci`, `frozen-lockfile`, etc.)
- [ ] Automated vulnerability scanning (CVE / OSV / Trivy) runs on every PR and on a recurring schedule
- [ ] Vulnerability remediation SLAs enforced: Critical < 48 hours, High < 14 days
- [ ] Automated license scanner verifies all dependencies against approved organizational licenses
- [ ] Dependency trees audited for bloat, duplicate versions, and unmaintained packages
- [ ] Routine dependency updates scheduled to avoid multi-year version drift
