# Kiss

Complexity is the primary obstacle to software reliability and velocity. Coined by aeronautical engineer
Kelly Johnson at the Lockheed Skunk Works in 1960, the Keep It Simple, Stupid (KISS) principle asserts
that systems perform best when designed with the minimum required moving parts.

## What simplicity actually buys

| Property | Simple design | Clever / complex design |
| --- | --- | --- |
| **Mean Time to Recovery (MTTR)** | Stack traces point directly to failing logic; on-call engineer fixes it quickly | Stack traces route through 8 levels of reflection, middleware, and dynamic proxies |
| **System evolution (Gall's Law)** | Grows predictably from working small components to larger capabilities | Designed as an all-encompassing system upfront; fails under real production loads |
| **Onboarding speed** | New engineers contribute safely on day one | Requires weeks to learn home-grown architectural frameworks and meta-abstractions |
| **Defect surface** | Few interactions between components; edge cases are visible and testable | Combinatorial explosion of state transitions and implicit side effects |

As John Gall formulated in *Systemantics* (1975):
> "A complex system that works is invariably found to have evolved from a simple system that worked.
> A complex system designed from scratch never works and cannot be patched up to make it work."

## Simple versus easy: the engineering distinction

Do not confuse *simple* with *easy*:
- **Easy** means familiar, close at hand, or convenient in the moment (e.g., throwing everything into a shared
  mutable dictionary, copy-pasting an unvetted library, or using dynamic reflection).
- **Simple** means unentangled. A simple component has one concept, one lifecycle, and zero unnecessary
  connections to adjacent systems, even if designing it takes careful thought.

In *A Philosophy of Software Design*, John Ousterhout categorizes this as **deep versus shallow modules**:
- A **deep module** provides a simple, narrow interface that conceals significant internal mechanics (e.g., POSIX `read()`/`write()`).
- A **shallow module** has an interface nearly as complex as its implementation, creating cognitive baggage without encapsulation.
KISS demands deep modules: powerful, simple interfaces hiding necessary work.

## State management and configuration simplicity

- **Immutability by default**: Unchanging values cannot suffer race conditions, unexpected mutations, or
  temporal coupling. Confine mutable variables to small local scopes.
- **Code over configuration files**: Avoid creating dynamic JSON/YAML configuration engines for logic that changes
  only during deployments. Boring code with type safety is simpler to maintain and validate than custom DSLs.
- **Explicit parameters over thread-locals**: Pass dependencies and contexts explicitly through function
  arguments. Global variables, singletons, and thread-local contexts make simple functions deceptively complex.

## Where KISS is misapplied

- **Simplistic code masquerading as simple**: Skipping error handling, omitting rate limits, or ignoring
  concurrent race conditions is not KISS—it is negligence. Simplicity must solve the actual problem completely.
- **Clever one-liners**: Writing 120-character nested ternary operators, dense regex golf, or multi-stage
  point-free stream pipelines reduces line count while destroying readability. If a junior engineer cannot parse
  the logic in 60 seconds, it violates KISS.
- **The "God Function" antipattern**: Keeping 600 lines of procedural mutation in a single function under
  the claim of "avoiding indirection" is not simple. It binds hundreds of mutable variables into a single entangled scope.

## Reviewer heuristics

Review diffs against these concrete rules:

- **Max nesting depth**: Enforce a strict ceiling of three indentation levels. Replace nested `if/else`
  trees with guard clauses and early returns.
- **Call-stack hop count**: Trace a standard request from entry point to persistence. If it traverses more
  than 4 layers of internal wrappers before doing real work, demand flattening.
- **Standard library over dependency**: Check if imported libraries duplicate platform capabilities. A 5-line
  native helper beats importing a third-party package with 30 transitive dependencies (see `references/dependencies.md`).
- **Data flow clarity**: State transformations must flow linearly in one direction. Eliminate bi-directional
  event-listeners or circular object graphs.

## When sophisticated solutions are justified

- **Non-trivial domain complexity**: Distributed consensus (Raft), financial accounting ledgers, compilers,
  and encryption cannot be simplified beyond the mathematical rules governing their domains.
- **High-throughput performance**: Zero-copy buffer pools, lock-free queues, or SIMD vectorization introduce
  code complexity to hit strict latency or memory targets (see `references/performance.md`).

## Checklist

- [ ] Control flow uses guard clauses and early returns; nesting depth never exceeds 3 levels
- [ ] No clever one-liners: logic is readable without mental translation or regex deciphering
- [ ] Solutions use standard library capabilities before introducing external dependencies
- [ ] Modules are deep: simple public interface hiding cohesive internal operations
- [ ] State is immutable by default; mutable variables are tightly scoped
- [ ] Error handling and edge cases are explicitly handled, not skipped in the name of simplicity
- [ ] Request paths can be traced from entry point to datastore in under 4 layer hops
