# Yagni

Speculative engineering is the single largest sink of developer velocity and codebase health. Coined
by Kent Beck and Chet Hendrickson on the Chrysler Comprehensive Compensation (C3) project and articulated
by Martin Fowler, You Aren't Gonna Need It (YAGNI) dictates that capabilities must never be added for
presumptive future requirements.

## The four costs of presumptive features

Building code ahead of actual need is never "free" or "ahead of schedule." It incurs four distinct penalties:

| Cost category | Direct impact |
| --- | --- |
| **Cost of Build** | Time and effort spent designing, writing, and testing speculative logic that may never be used |
| **Cost of Delay** | Postpones deploying the core feature that delivers immediate user value and generates feedback |
| **Cost of Carry** | Ongoing tax on the codebase; every subsequent refactor and test run must navigate the extra complexity |
| **Cost of Repair** | By the time the capability is needed, assumptions are invalidated; the code must be rewritten anyway |

Empirical research confirms the risk: [Kohavi et al. (2009)](http://ai.stanford.edu/~ronnyk/ExPThinkWeek2009Public.pdf)
analyzed controlled software experiments at Microsoft and found that roughly **two-thirds** (≈66%) of planned
features failed to improve their target metrics. Speculative features are overwhelmingly likely to be wasted effort.

## The critical boundary: capability versus malleability

Engineers frequently misuse YAGNI to justify sloppy code. The distinction is strict:
- **YAGNI applies to capabilities**: Extra configuration options, unused database columns, theoretical plugin hooks,
  support for multiple database engines, or premature multi-tenancy before the first tenant exists.
- **YAGNI does NOT apply to malleability**: Refactoring, comprehensive test suites, clear module boundaries,
  and automated deployment pipelines are not speculative features. They are enabling practices that make
  deferring decisions possible. Without a malleable codebase, YAGNI degrades into technical debt.

## The "Zero, One, Many" guideline

When deciding whether to build an abstraction, apply the standard progression:
- **Zero**: Do not write any code, interfaces, or tables for scenarios that do not exist today.
- **One**: Write a clean, concrete implementation directly solving the immediate problem. Avoid interfaces,
  factories, and abstraction layers that have only a single consumer.
- **Many**: When the second or third concrete requirement emerges, refactor the existing concrete implementation
  into an abstraction. You will now design that abstraction against verified requirements, not guesses.

## Reviewer heuristics

Audit pull requests for these concrete warning signs:

- **The "Imagine the Refactoring" test**: When an author defends speculative code with "it will be harder to add later,"
  walk through the future refactoring step by step. In a clean codebase, introducing an abstraction later rarely takes
  longer than building and carrying it prematurely.
- **The Single-Implementation Abstraction**: Generic factory classes, plugin registries, or abstract base
  interfaces that have only one concrete implementation in production.
- **Speculative configuration**: Setting flags or environment variables for switches that have never been toggled
  in any deployed environment. Hardcode the value as a constant until dynamic switching is required.
- **Uncalled parameters**: Functions accepting optional parameters or context fields that every existing caller
  passes as `null`, `undefined`, or a default literal.

## Irreversible decisions: when upfront design is mandatory

Distinguish between reversible (Type 2) and irreversible (Type 1) architectural decisions:

- **Strict YAGNI applies (Reversible)**: Internal algorithms, component structures, library choices, caching layers,
  and background worker pools. Build the simplest version; swap or refactor when real load dictates.
- **Upfront design required (Irreversible)**: Foundational database schema choices (e.g., using 64-bit IDs over
  32-bit integers), audit trail log structures, encryption algorithms, tenant isolation boundaries, and public API
  versioning semantics. Retrofitting these later carries massive migration and downtime costs.

## Checklist

- [ ] Every class, function, and parameter in the PR solves an immediate, verified requirement
- [ ] No abstract interfaces or factories exist with only one concrete implementation
- [ ] Configuration options correspond to active environment requirements, not theoretical future toggles
- [ ] No database columns or migration tables are added without active reading or writing code
- [ ] Code health and automated tests were not skipped under the false pretext of YAGNI
- [ ] Irreversible decisions (data types, tenant isolation, public contracts) have explicit architectural justification
