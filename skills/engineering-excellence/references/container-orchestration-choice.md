# Container Orchestration: Compose, Swarm, Kubernetes

Pick the smallest thing that survives your failure mode. Most teams adopt Kubernetes for a scheduling
problem they do not have, and then spend the budget on operating it.

## The decision

| Situation | Choose | Because |
| --- | --- | --- |
| One host, a handful of services, one team | Docker Compose | Declarative enough, no control plane, `restart` and healthchecks cover most failures |
| One host, but you want rolling updates and secrets without files | Compose plus an external secret store | Still one host: Swarm or Kubernetes adds cost without adding redundancy |
| Two to five nodes, need rescheduling, HA and one deploy API | k3s (lightweight Kubernetes) | Certified Kubernetes, single binary, small footprint, the ecosystem works |
| Two to five nodes, team knows Docker and nothing else, minimal change | Docker Swarm mode | Docker-native and stable, but treat it as a frozen runtime: development is slow, so plan an exit |
| Multiple teams, tenancy, policy, autoscaling, GPU scheduling | Kubernetes (managed if possible) | The control plane is the product; pay someone else to run it |
| Edge or IoT per-site nodes | k3s | Small, tolerant of poor networks |

Two honest notes:

- Docker's own documentation frames Swarm mode as an advanced production feature and points Compose at
  deployments that do not use Swarm. Swarm mode is not deprecated, but it is not where new investment
  lands; choosing it is choosing stability over trajectory.
- Kubernetes is not "more production". It is a control plane you now own: datastore, upgrades, ingress,
  certificates, storage, RBAC, monitoring. A badly run k3s is worse than a well-run Compose host.

## Compose, done properly

- Pin image digests or exact tags. `latest` makes a restart a silent deploy.
- `healthcheck` per service, and let the proxy depend on healthy, not merely started:
  `depends_on` says "started", not "ready".
- `restart: unless-stopped` plus resource `limits` (memory at least), or one runaway container takes the
  host.
- Secrets from files or an external store, never `environment:` in a committed compose file.
- Named volumes with a documented backup path; a bind mount into `/var/lib` is not a backup plan.
- Log rotation configured per service (`max-size`, `max-file`), or the disk fills during an incident.
- Profiles for optional services; one compose file per environment with an override, not per developer.
- `docker compose up -d` is not a deploy: wrap it in a pipeline that pulls first, checks health after,
  and can roll back to the previous digest.
- Separate the data plane (database, queue) from the app in the same file, and note which service is
  stateful, because that is what makes the move to an orchestrator hard later.

## k3s for a few nodes

- Three server nodes for HA (embedded etcd or an external datastore). One server is a single point of
  failure, whatever the marketing says.
- Turn off what you do not use: bundled Traefik if you bring your own ingress, ServiceLB if you use
  MetalLB or kube-vip. Every enabled component is an unpatched edge you now own.
- A stable virtual IP for the API and for ingress (kube-vip, MetalLB in L2 mode) so clients never learn
  node IPs.
- Storage: `local-path` is honest for single-node-style workloads; Longhorn when you need replication
  and accept its cost. Never put the only copy of data on `local-path` with a PodDisruptionBudget
  pointing at the node that holds it.
- Every workload gets `requests` and `limits`, `readinessProbe` and `livenessProbe` (different
  questions: ready to receive, or alive), and a `PodDisruptionBudget` for anything you care about during
  drains.
- `NetworkPolicy` on by default where the CNI supports it; a flat pod network is a breach multiplier.
- Backups: snapshot the datastore (etcd/SQLite) on a schedule AND verify restore. A cluster whose
  datastore is gone is a new cluster.
- Upgrades: drain, upgrade one server at a time, watch the API, then agents. Pin versions and read the
  release notes; a Kubernetes minor upgrade is a maintenance window.
- GitOps without a platform: `kubectl apply -k` from a pipeline is enough at this size; add Flux or
  Argo only when drift becomes real.

## kubectl, the ten commands that matter

```
kubectl get pods -o wide          # what is running, and where
kubectl describe pod <p>          # why it is not starting (events at the bottom)
kubectl logs <p> --previous       # the crash before the restart
kubectl exec -it <p> -- sh        # inside, to inspect reality
kubectl rollout status deploy/<d> # did the deploy actually finish
kubectl rollout undo deploy/<d>   # the rollback, without re-running CI
kubectl scale deploy/<d> --replicas=N
kubectl port-forward svc/<s> 8080:80
kubectl apply -k <dir>            # declarative change
kubectl get events --sort-by=.lastTimestamp
```

Add `-n <namespace>` always, or learn to debug the wrong environment.

## When to move up, in triggers

- Two teams need separate deploy authority or separate namespaces with quotas.
- A deploy must be zero-downtime across replicas, and Compose restarts are visibly disruptive.
- You need scheduling constraints (GPU, node affinity, taints) or autoscaling on real signals.
- Drift between what is in git and what is running has already caused an incident.
- Secret and certificate management has outgrown files on disk.

If none of those is true, the honest answer is: stay, and make the current setup boring.

## Checklist

- [ ] Choice justified by a written failure mode, not by fashion
- [ ] Images pinned; healthchecks and resource limits everywhere
- [ ] Secrets outside the repository, rotation path documented
- [ ] Backups of state (volumes or datastore) with a tested restore
- [ ] If Kubernetes: 3 servers, HA VIP, probes, PDBs, NetworkPolicy, pinned versions
- [ ] Deploy is a pipeline, not a command typed on a host
- [ ] An exit path written down (from Compose to k3s, or from Swarm to anything)
