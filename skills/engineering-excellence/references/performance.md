# Performance

Performance is a non-negotiable functional requirement. Unmeasured performance claims are
fiction: slow systems degrade usability, increase infrastructure cost, and fail under load.

## Performance budgets

Establish explicit, enforceable budgets before writing code. A budget is a hard ceiling that
breaks CI when breached, not an aspirational guideline.

| Dimension | Metric / Target | Enforcement Mechanism |
| --- | --- | --- |
| Web Frontend | Total JS bundle <= 170 KB gzip; Initial load <= 50 KB | Bundle analyzer in CI build step |
| Core Web Vitals | LCP <= 2.5s, INP <= 200ms, CLS <= 0.1 at 75th percentile | [web.dev Core Web Vitals](https://web.dev/articles/vitals) & Lighthouse CI |
| Native / Client | UI frame render <= 16.6ms (60 fps); Heap RSS <= 150 MB | Frame pacing monitors & heap allocation tests |
| Backend / API | P95 latency <= 200ms, P99 <= 500ms; Max DB queries/req <= 10 | Load tests (k6/Locust) & ORM query interceptors |
| Server Resources | CPU utilization <= 70% at peak load; Zero memory growth | Continuous metric probes under soak testing |

## Measurement method: lab vs field

Evaluate performance across two distinct, complementary regimes:

1. **Lab (Synthetic) Testing**: Automated, reproducible environments (e.g. Lighthouse, k6, memory profilers).
   Always control network throttling (simulate slow 4G), CPU throttling (4x/6x slowdown for mobile), and
   cache state (measure both cold-cache and warm-cache runs independently). Lab testing catches regressions
   before code merges.
2. **Field (Real-User Monitoring / RUM)**: Telemetry collected from real end users across diverse hardware
   and real-world networks (e.g. Chrome User Experience Report / CrUX, OpenTelemetry). Field metrics reflect
   actual user experience.

Always report statistical distributions: **median (P50)**, **75th percentile (P75)**, and **99th percentile (P99)**.
Arithmetic averages hide catastrophic tail latency and long-tail device degradation.

## Metrics that matter

### Web applications
- **Largest Contentful Paint (LCP)**: Time to render the primary visual block. Target: <= 2.5s.
- **Interaction to Next Paint (INP)**: Responsiveness to user input throughout the page lifecycle. Target: <= 200ms.
- **Cumulative Layout Shift (CLS)**: Unexpected layout shifts without user gesture. Target: <= 0.1.
- **Time to First Byte (TTFB)**: Server latency and network roundtrip time. Target: <= 800ms.
- **Total Blocking Time (TBT)**: Lab proxy for main-thread CPU blocking before interactivity. Target: <= 200ms.

### On-device and system runtimes
- **Frame pacing and dropped frames**: Maintain consistent 16.6ms frame intervals (or 8.3ms for 120Hz displays).
  Any frame computation exceeding 16.6ms introduces visible stutter (jank).
- **Resident Set Size (RSS) and heap allocations**: Measure memory before, during, and after sustained workloads.
  Memory that does not return to baseline indicates an allocation leak or uncollected reference cycles.
- **Battery and energy impact**: Background wake locks, excessive polling, and unthrottled timers drain battery
  and trigger OS thermal throttling.
- **Cold start vs warm start**: Measure startup latency from cold launch (process spawn to first interactive frame)
  separately from background resume.

## Diagnostic profiling workflow

When a budget is breached, follow a systematic profiling sequence:
1. **Reproduce with trace**: Capture a CPU flamegraph or network waterfall under reproducible load.
2. **Isolate the hot path**: Identify the exact function, query, or DOM reflow causing > 20% of execution time.
3. **Check query volume**: Identify N+1 database queries, unindexed filters, or missing connection pooling.
4. **Benchmark the fix**: Isolate the bottleneck into an isolated benchmark (minimum N = 30 runs, warm JIT).
5. **Verify under soak**: Run the fix under sustained load to confirm memory stability and tail latency.

## Refusing performance claims without numbers

Reject statements such as "we optimized the algorithm", "it feels much faster", or "compilers will inline this".
Enforce the **No Numbers, No Merge** rule:

1. **Require a baseline profile**: Demand benchmark data of the existing code under controlled conditions.
2. **Demand reproducible benchmarks**: Microbenchmarks must account for compiler dead-code elimination, JIT
   warm-up cycles, garbage collection pauses, and sample size.
3. **Inspect profiling artifacts**: Require an accompanying flamegraph, CPU profile trace, or heap diff showing
   the exact bottleneck eliminated.
4. **Weigh maintainability**: If an optimization adds structural complexity or bypasses type safety, demand proof
   that the targeted bottleneck accounts for >= 20% of total runtime budget.

## Checklist

- [ ] Explicit performance budgets documented for bundle size, network payloads, latency, and memory
- [ ] Core Web Vitals targets meet official thresholds (LCP <= 2.5s, INP <= 200ms, CLS <= 0.1 at P75)
- [ ] Cold-cache and warm-cache scenarios tested and reported independently
- [ ] Latency reported using percentiles (P50, P75, P95/P99), never arithmetic averages
- [ ] Simulated mobile constraints applied in lab runs (CPU throttling, network throttling)
- [ ] Database query volume bounded per transaction; zero N+1 queries detected
- [ ] UI frame rendering budget verified (<= 16.6ms per frame) on resource-constrained devices
- [ ] Heap RSS measured before and after soak testing to prove zero memory leaks
- [ ] Every optimization PR includes before-and-after benchmark numbers and profiling artifacts
