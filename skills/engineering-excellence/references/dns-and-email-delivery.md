# DNS and Email Delivery

DNS is the control plane for everything else: mail, certificates, SSO, and whether your users reach
the service at all. Treat the zone as code, and treat email authentication as a product requirement.

## Zone design

- One zone per registrable domain; subdomains are delegated only when a different owner or provider
  needs to change them independently.
- Keep the apex sparse. `A`/`AAAA` at the apex is the one place a `CNAME` cannot go; use `ALIAS`/`ANAME`
  where the provider supports it, or an apex `A` from a health-checked pool.
- Name by function, not by machine: `api`, `admin`, `status`, `mail`, `_dmarc`. The name is a contract
  that outlives the server.
- TTLs: low (300 s) while migrating, then 3600 s for stable records. A low TTL is not a rollback plan.
- `CAA` records pin which CAs may issue; without them any CA can. Include the account/validation
  method (`accounturi`) when the CA supports it.
- Delegation needs glue only when the nameservers live inside the delegated zone. Test the delegation
  before announcing it.

## DNSSEC

- Sign every zone you are authoritative for, and publish the `DS` at the parent. A signed zone without
  a `DS` at the parent, or a `DS` without a signature, is worse than none: validation fails closed.
- Key rollover is a process, not an event: publish the new `DNSKEY`, wait for the TTL plus the negative
  caching window, switch the `DS` at the parent, then retire the old key. Automate it or schedule it.
- Prefer the algorithm family the registry and resolvers agree on; check the current "DNSSEC algorithm
  recommendations" rather than a blog post from a decade ago.
- Monitor: a zone that stops validating fails for every validating resolver, silently, everywhere.
  Alert on `DS`/`DNSKEY` mismatch and on signature expiry, not only on "record changed".
- `NSEC3` if you need to hide zone contents, `NSEC` for simplicity; either way make sure the parent has
  corresponding `DS` records for the exact KSKs in use.

## Split horizon (split DNS)

- Two views of one name: the internal resolver answers private addresses, the public authoritative
  server answers public ones. Implemented as BIND `view`s, separate authoritative servers, or
  provider-side private zones.
- Keep the two zone files generated from one source of truth. Hand-maintained twins drift, and the
  drift shows up as an outage during a migration.
- Publish internal-only names inside a delegated internal zone (`*.internal.example.com`), never as
  public records pointing at RFC 1918 space: those leak the internal topology.
- DNSSEC and split horizon interact badly: the internal view is usually unsigned, and a validating
  client that moves between networks sees the same name with and without signatures. Either keep the
  internal zone unsigned *and* not a child of the signed public zone, or sign both consistently.
- Watch the resolver path: VPN split-tunnel clients often bypass the internal resolver and get the
  public answer. Test from the client, not from the server.
- Search-domain and `ndots` configuration causes more "resolve fails" tickets than the zones do.

## Email: authentication before deliverability

Four mechanisms, in the order that matters to receivers:

| Mechanism | Where | Rule |
| --- | --- | --- |
| SPF | `TXT` at the apex (`v=spf1 ...`) | One record, under the 10-lookup limit, `-all` once you are sure; every `include` counts against that budget |
| DKIM | `TXT` at `<selector>._domainkey` | 2048-bit RSA or Ed25519, selector rotation planned, keep old selectors published while mail is in flight |
| DMARC | `TXT` at `_dmarc` | Start `p=none` with `rua`, read the reports, then `p=quarantine`, then `p=reject`; set `sp=` deliberately; `pct` only as a transition |
| TLS | `MX`, `_mta-sts`, `_smtp._tls` | MTA-STS policy plus `TLS-RPT`, or DANE if your zone is DNSSEC-signed; plaintext SMTP is no longer accepted by major receivers |

- Alignment matters, not just a passing result: a valid DKIM signature for a domain that does not
  align with `From:` does you no good under DMARC.
- PTR/rDNS must match the sending host, and forward-resolve back to the same name. Shared IPs with no
  matching PTR are a delivery problem no SPF record fixes.
- 5,000+ messages a day to Gmail: DMARC is mandatory, one-click unsubscribe (`List-Unsubscribe` and
  `List-Unsubscribe-Post`) is required for bulk, and spam rates above 0.3% in Postmaster Tools mean
  throttling regardless of authentication.
- Subdomains: set `sp=reject` once every subdomain's sending is known; an unprotected subdomain is the
  standard phishing vector against your own brand.
- BIMI only after DMARC enforcement, and only with the required VMC; skip it otherwise.
- Warm up new IPs and domains slowly; reputation is not a DNS record.
- Monitor blocklists and DMARC aggregate reports on a schedule. A silent drop in `rua` volume usually
  means a DNS change broke reporting.

## Operation

- Zone changes go through a pull request with a diff, and are applied by a pipeline that can validate
  (`named-checkzone`, provider dry-run) before publishing.
- Keep records in a git repository even when the provider has its own UI; the repository is the audit
  trail.
- `ZONEMD` where the registry supports it, so a corrupted zone fails loudly.
- Every hostname that serves users has a monitoring probe, and every certificate has an expiry alarm
  tied to its issuance path (ACME DNS-01 needs the API credentials to stay valid).
- Record the who/what/when for nameserver and registrar changes: registrar lock, 2FA and a documented
  recovery contact are part of the control plane.
- Decommissioning: remove the record, keep it in the repository history, and leave a comment explaining
  why it disappeared.

## Checklist

- [ ] Zone as code, reviewed and applied by a pipeline
- [ ] Apex, subdomain and delegation design documented; TTL policy stated
- [ ] `CAA` set, registrar locked, 2FA on the registrar account
- [ ] DNSSEC: `DS` at parent, rollover scheduled, expiry and mismatch monitored
- [ ] Split horizon generated from one source, topology not leaked, resolver path tested from a client
- [ ] SPF within lookup budget, DKIM selectors and rotation, DMARC at enforcement with reports read
- [ ] PTR forward-confirmed, TLS policy published (MTA-STS/TLS-RPT or DANE)
- [ ] Blocklists and DMARC reports monitored; unsubscribe headers on bulk mail
