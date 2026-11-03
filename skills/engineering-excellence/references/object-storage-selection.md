# Choosing Object Storage

S3 became the interface, not the product. The question is not "S3 or not" but which implementation,
and what you give up in exchange for running it yourself.

## Decide by constraint, not by benchmark

| Constraint | Answer |
| --- | --- |
| You already run Ceph for block/file | Ceph RADOS Gateway: full S3 surface, one cluster to operate, heavyweight by design |
| Small or mid cluster, geo-distributed, minimal ops | Garage: Rust, simple, replicates across sites, deliberately narrow feature set |
| You already run OpenStack | Swift, with its S3 middleware; core API covered, advanced features partial |
| You need filesystem semantics and S3 access | Do not. Keep a filesystem and expose S3 only for the objects that need it |
| Public cloud acceptable | The provider's S3, and spend the effort on lifecycle and access policy instead |
| You are evaluating MinIO | Check its current community-edition status and licence before committing; the project has narrowed its open offering and moved toward its commercial product, so pin a version and plan an exit |

Whatever you pick, **verify the operation matrix against the exact version you deploy**. "S3-compatible"
means "implements enough of the API for the vendor's test suite", and your client library will use
something outside it. Test: multipart upload with many parts, `ListObjectsV2` with prefixes and
delimiters, presigned `PUT`/`GET`, `CopyObject` above 5 GB, conditional writes (`If-None-Match`),
versioning, object lock, lifecycle expiry, tagging, and the exact error codes on a missing key.

## What each implementation is really good at

Ceph RADOS Gateway

- Full S3 API with the fewest surprises, plus Swift API, multi-site replication and an ecosystem of
  operators who have run it at scale.
- Cost: MON/MGR/OSD cluster, dedicated hardware planning, and an operations team. A single-node Ceph is
  mostly a learning exercise.
- Choose it when Ceph already exists or when the S3 surface must be complete.

Garage

- Designed for self-hosted clusters of modest size across sites: consistent hashing, layout-based
  placement, no external metadata store, small binary.
- Narrow on purpose: object storage only, no POSIX, no block. Confirm versioning, object lock and the
  multipart behaviour your client needs (and the current minimum cluster size) rather than assuming.
- Choose it for backups, media, and internal object storage when you want three nodes and an afternoon,
  not a storage team.

OpenStack Swift

- Object storage with strong operational tooling when OpenStack already runs; S3 arrives through
  middleware, with the core object/bucket/multipart operations covered and provider-specific gaps.
- Consistency and account/container layout are strengths; S3 feature parity is not the goal.
- Choose it inside an OpenStack estate, not as a standalone S3 replacement.

Filesystem-backed S3 gateways (and "just mount a bucket")

- Useful for migration and for legacy apps that only speak files.
- A bad primary store: no atomic rename, no POSIX locks, latency of an HTTP call per syscall, and every
  database-on-object-storage story ends the same way.

## Design rules that outlive the choice

- A bucket is a tenancy boundary: one bucket per customer or per environment, not one bucket for
  everything with prefixes.
- Prefix design matters for listing performance and for lifecycle rules; a monotonically increasing
  prefix (`2026/11/03/...`) lists and expires cleanly, a random one does not.
- Never put predictable hot keys in one prefix if the implementation shards by prefix.
- Lifecycle policy from day one: transition to cold storage, expire temp uploads, abort incomplete
  multipart uploads after N days (an un-aborted multipart upload is invisible storage you pay for).
- Versioning on for anything a person can overwrite; object lock or a separate bucket for backups.
- Encryption: SSE with a managed key, or client-side for the highest tier. A bucket policy that allows
  anonymous `GetObject` is a public data breach with a nice API.
- Presigned URLs are the way to serve private objects: minutes of TTL, one object, one method, never a
  URL that also grants list or delete.
- Least privilege by key: an application key that can `PutObject` into its prefix and read it back does
  not need `CreateBucket` or `DeleteBucket`.
- CORS configured explicitly for browser uploads, with the exact origins and methods.
- Quotas and per-tenant limits before a customer fills the cluster; object count, not only bytes.
- Replication is not backup: an accidental delete replicates. Keep an independent, immutable copy.
- Know the consistency model for the operations you depend on, especially listing after write and
  overwrite visibility.
- Measure the operations that hurt: `LIST` with huge prefixes, small-object request rates, and the
  latency of a cold read after a node loss.

## Migration between implementations

- Speak S3 at the client and keep the endpoint configurable; the tooling (`rclone`, `mc`, vendor CLIs)
  can move data but not semantics.
- Rehearse with the real object count and a real client, then diff the inventory and re-hash a sample.
- Cutover plan: freeze writes, final sync, switch the endpoint, verify presigned URLs and background
  jobs, keep the old store read-only for a week.
- The failure mode nobody plans for is lifecycle rules and policies that did not travel with the data.
  Export them as code and re-apply them.

## Checklist

- [ ] Constraint table applied; the operational cost is priced, not just the disk
- [ ] Operation matrix tested with your client and your workload, on the version you will run
- [ ] Bucket, prefix and tenancy layout documented
- [ ] Lifecycle, versioning, object lock, multipart abort configured
- [ ] Encryption and bucket policy reviewed; no anonymous read
- [ ] Presigned URL TTLs and key scopes minimal
- [ ] Quotas, monitoring and an independent immutable backup copy
- [ ] Migration path rehearsed, with policies and lifecycle exported as code
