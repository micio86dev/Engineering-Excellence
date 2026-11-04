# Engineering Principles

Software principles are heuristics for managing complexity and change over time, not dogmatic laws.
Applying them mechanically without understanding their trade-offs produces over-engineered architectures
that paralyze development velocity. This document maps the core engineering principles and establishes
the rules for resolving tensions when they conflict.

## Core principles map

Load the individual reference document for deep implementation rules, smells, and checklists:

| Principle | Core question | Primary benefit | Reference guide |
| --- | --- | --- | --- |
| **SOLID** | Are change boundaries and polymorphic contracts well-isolated? | Prevents cascading breakages across unrelated modules | `references/solid.md` |
| **DRY** | Is business knowledge represented in a single authoritative place? | Prevents divergence and data corruption across duplicate rules | `references/dry.md` |
| **KISS** | Is this the simplest design that completely solves the problem? | Lowers cognitive load, reduces MTTR, speeds onboarding | `references/kiss.md` |
| **YAGNI** | Are we building speculative features for unverified future needs? | Eliminates build, delay, carry, and repair costs | `references/yagni.md` |
| **SoC** | Are technical and domain concerns separated cleanly? | Allows changing UI or database without touching business core | `references/architecture.md` |
| **Tech Debt** | Is architectural compromise recorded with an explicit payoff path? | Prevents invisible decay while enabling pragmatic trade-offs | `references/technical-debt.md` |

## Separation of Concerns, Cohesion, and Coupling

Three foundational concepts govern how the named principles interact:

1. **Separation of Concerns (SoC)**: Segregate distinct facets of the software (e.g., user interaction,
   domain business logic, data persistence, network transport). Business rules should execute without
   knowing whether input arrived via an HTTP REST endpoint, a CLI command, or a background queue worker.
2. **High Cohesion**: Elements that change together for the same business reason must belong together.
   High cohesion within a module minimizes cross-module coordination.
3. **Loose Coupling**: Modules should depend only on the minimal public contracts of adjacent modules.
   Evaluate coupling via **Connascence** (Meilir Page-Jones): prefer weak static connascence (Name, Type)
   over dangerous dynamic connascence (Execution order, Timing, Value conventions).

## The Tension Matrix: resolving principle conflicts

Principles regularly contradict one another. When they collide, apply this priority hierarchy:

| Conflict | The tension | Resolution rule |
| --- | --- | --- |
| **DRY vs KISS** | DRY urges extracting a shared helper; KISS urges keeping callers flat and readable | Favor duplication over a complex, flag-laden abstraction. Extract only when three identical use cases share business knowledge. |
| **SOLID vs YAGNI** | SOLID encourages interfaces and dependency inversion; YAGNI warns against speculative abstractions | Write the concrete implementation first. Introduce interfaces only when multiple implementations exist or an external boundary is crossed. |
| **KISS vs Correctness** | KISS tempts developers to skip edge cases, timeouts, or concurrency controls | Simplistic is not simple. Correctness, security, and error handling are non-negotiable prerequisites. |
| **SoC vs Performance** | Layered separation adds object allocations and stack traversals | Isolate performance-critical code in a dedicated, profiled boundary (see `references/performance.md`). |

## Lifecycle-aware application

Adjust principle weight based on the software lifecycle stage:

- **Prototype / Spike**: Prioritize KISS and YAGNI. Write direct, procedural code to validate product hypothesis.
  Avoid speculative interfaces and configuration frameworks.
- **Production Core**: Apply SOLID, DRY, and SoC strictly. Enforce bounded contexts, inward dependency direction,
  and automated unit test coverage before shipping.
- **Public API / Shared Library**: Enforce LSP, ISP, and backward compatibility rigidly. Changes to public
  contracts break external consumers; stability supersedes internal simplicity.

## Agent workflow rule

When executing engineering tasks as an agent:
1. Do not load all principle references simultaneously into context. Load only the specific reference
   relevant to the active problem (e.g., `references/solid.md` during refactoring or `references/yagni.md` during scoping).
2. Cite the specific principle and rule when challenging or rejecting speculative code in review diffs.

## Checklist

- [ ] Sibling reference documents are loaded and applied based on the specific engineering task
- [ ] No speculative abstractions were introduced ahead of proven multiple requirements (YAGNI / KISS)
- [ ] Business logic is decoupled from transport protocols and storage mechanisms (SoC / SOLID)
- [ ] Code duplication is analyzed: duplicated knowledge is extracted; incidental similarity is left alone (DRY)
- [ ] PR diffs can be explained simply without diagrams or home-grown architectural meta-frameworks (KISS)
- [ ] Any intentional compromise of architectural standards is documented in `references/technical-debt.md`
