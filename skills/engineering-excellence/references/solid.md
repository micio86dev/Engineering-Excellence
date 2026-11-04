# Solid

Software rots when changes cascade across unrelated modules. The SOLID principles, codified by
Robert C. Martin, establish boundaries that isolate change, preserve existing behavior, and keep
units independently testable.

## The five principles in practice

| Principle | Core rule | What it buys | Violation smell |
| --- | --- | --- | --- |
| **SRP** (Single Responsibility) | A module answers to one actor and has one reason to change | Changes to persistence or UI never break business calculations | One class imports database drivers, formats HTML, and computes billing |
| **OCP** (Open/Closed) | Open for extension, closed for modification | New variants added via polymorphism without modifying tested paths | `switch(type)` blocks scattered across callers that grow a branch per feature |
| **LSP** (Liskov Substitution) | Subtypes must satisfy all behavioral contracts of the base type | Callers use abstractions without type checks or special-case handling | Subclass throws `UnsupportedOperationException`, weakens preconditions, or requires `instanceof` |
| **ISP** (Interface Segregation) | Clients must not be forced to depend on methods they do not use | Callers remain decoupled from changes to uncalled operations | Interfaces with 10+ methods where implementers write no-op stubs for half |
| **DIP** (Dependency Inversion) | High-level policy depends on abstractions; details depend on abstractions | Core domain logic runs in memory under tests without real infrastructure | Domain entity imports an ORM package, an AWS SDK, or an HTTP client |

## Formal rules and invariants

1. **SRP (Actor Cohesion)**: A module is cohesive when its public functions serve the same stakeholder.
   If accounting demands a change to tax calculation and customer support demands a change to invoice layout,
   those requirements must live in separate modules. Cohesion groups things that change for the same reason.
2. **OCP (Protected Variation)**: Design interfaces at points of predictable volatility (e.g., payment gateways,
   export formats, cloud providers). New features should arrive as new classes implementing an existing interface,
   wired through configuration or factory lookup, never by mutating existing production branching.
3. **LSP (Behavioral Subtyping)**: Formulated by Barbara Liskov and Jeannette Wing (1994):
   - Preconditions cannot be strengthened in a subtype (cannot require stricter inputs).
   - Postconditions cannot be weakened in a subtype (cannot guarantee less output or omit side effects).
   - Invariants of the supertype must be preserved.
   - History rule: subtypes cannot modify state fields in ways the supertype disallowed.
4. **ISP (Role Interfaces)**: Prefer small, client-specific role interfaces over monolithic fat interfaces.
   A consumer that only reads data should receive a `Reader` interface, not a combined `ReadWriteAdminRepository`.
5. **DIP (Inversion of Ownership)**: Do not confuse Dependency Inversion (the architectural rule) with
   Dependency Injection (a mechanism). DIP states that the interface is owned by the *caller* (high-level policy),
   not by the callee (low-level mechanism). The domain layer defines `PaymentGateway`; the infrastructure layer implements it.

## Reviewer heuristics

Look for these concrete indicators during code reviews:

- **SRP check**: Identify the business actor who owns each requested change. If a single commit modifies
  pricing rules and PDF rendering in the same file, reject the PR and split them.
- **OCP check**: Count edits in existing files when adding a new payment provider or notification channel.
  If adding a provider edits existing caller logic rather than registering a new implementation, extract a strategy.
- **LSP check**: Search for type-casting or type-checking (`instanceof`, `isinstance`) on an injected interface.
  If the caller checks concrete types, the abstraction contract is broken.
- **ISP check**: Inspect interface implementers. If test doubles or secondary implementations stub out
  methods with `throw new NotImplementedException()` or empty returns, split the interface into role-based contracts.
- **DIP check**: Trace import directions. Domain entities and business use cases must import only domain
  interfaces, never concrete database drivers, HTTP clients, or framework controllers.

## Where SOLID is misapplied

- **Interface-per-class boilerplate**: Creating an `IOrderService` with exactly one implementation `OrderService`
  adds navigation friction without decoupling value. Introduce an interface only when multiple implementations exist
  or when an infrastructure boundary must be crossed.
- **Micro-class explosion**: Splitting a cohesive 40-line function into five classes to satisfy an extreme
  interpretation of SRP hurts readability. Cohesion means things that change together stay together.
- **Premature DIP**: Wrapping every third-party utility or standard library function in custom adapter interfaces
  before any testing or swapping need arises.

## When the opposite choice is correct

- **Internal utilities and migration scripts**: Linear scripts where direct procedural execution is clearer
  and easier to audit than polymorphic dispatch.
- **Performance hot paths**: Virtual dispatch, interface lookups, and heap-allocated wrapper objects introduce
  indirection and cache misses in performance-critical loops.
- **Early-stage exploration**: During prototype spikes, hardcoding concrete implementations accelerates learning;
  refactor to SOLID boundaries only once requirements stabilize (see `references/tdd.md`).

## Checklist

- [ ] Every class or module has a single business actor driving its changes
- [ ] New variants (providers, handlers, formats) can be added without modifying existing caller branching
- [ ] Subtypes uphold all base contracts: no weakened preconditions, strengthened postconditions, or dummy stub methods
- [ ] Interfaces contain only methods called by the consuming client; no mandatory no-op stubs
- [ ] Core business logic imports zero infrastructure dependencies (databases, external APIs, frameworks)
- [ ] Every interface either has multiple implementations or crosses an external/infrastructure boundary
