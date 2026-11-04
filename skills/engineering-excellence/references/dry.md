# Dry

Duplication becomes dangerous when it duplicates *knowledge*, not merely lines of syntax. Formulated
by Andy Hunt and Dave Thomas in *The Pragmatic Programmer* (1999), the Don't Repeat Yourself (DRY)
principle states: "Every piece of knowledge must have a single, unambiguous, authoritative representation
within a system."

## Knowledge duplication versus incidental similarity

Every codebase contains two distinct forms of repetition:

| Type | Definition | Consequence | Correct response |
| --- | --- | --- | --- |
| **Knowledge duplication** | A single business rule or system invariant appears in multiple places | When the rule changes, developers miss one copy; data corrupts or behavior diverges | Extract to a single authoritative source or generate secondary representations from primary schema |
| **Incidental duplication** | Two code blocks share identical syntax today by coincidence | Merging them couples two independent concepts; future requirements require conditional flags | Leave duplicated; let them evolve independently |

A concrete example: validation rules for a customer's shipping address and billing address might look
identical at launch. However, shipping addresses diverge when logistics adds postal hub codes, while
billing addresses diverge when payment gateways mandate tax jurisdiction IDs. Unifying them into a single
shared address model creates an unnatural coupling that resists future business changes.

## Authoritative sources: DRY through code generation

The cleanest way to satisfy DRY without introducing runtime coupling is generating code from an authoritative source:

- **API contracts**: Write OpenAPI or Protocol Buffer specifications once; generate server routes, client SDKs,
  and documentation automatically. Hand-written client types that mirror backend models violate DRY.
- **Database schemas**: Define database migrations as the single source of truth; generate domain types
  and query builders from the live schema using tools like Prisma or sqlc.
- **Configuration invariants**: Define environment variable schemas once (e.g., using Zod or JSON Schema);
  derive application configuration types and startup validation logic from that single definition.

## The wrong abstraction trap

In [The Wrong Abstraction (2016)](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction), Sandi Metz
demonstrated why premature DRYing causes worse systemic failure than duplication:

> "Duplication is far cheaper than the wrong abstraction."

The typical degradation path follows a predictable cycle:
1. An engineer notices two 10-line routines that look similar and extracts a shared function.
2. A new feature arrives that requires slightly different behavior in one caller.
3. Rather than splitting the code, the engineer adds a boolean flag (`isExport`, `skipValidation`).
4. Subsequent features add more parameters and branching conditionals until the shared helper becomes
   an unmaintainable multi-path monster.
5. **The remediation**: Inline the shared abstraction back into every caller, delete the conditionals
   not needed by each caller, and re-evaluate only when the true invariant becomes clear.

## Reviewer heuristics

Apply these checks when reviewing code diffs:

- **The Rule of Three**: Never extract a shared abstraction on the second instance. Two occurrences
  are often accidental similarity. Wait for the third occurrence to reveal the actual common abstraction.
- **The Flag Argument test**: If an extracted helper requires flags (`mode: 'admin'`, `dryRun: boolean`)
  to switch internal behavior based on who called it, reject the abstraction. The callers have different responsibilities.
- **Bounded Context boundaries**: Never share domain entities or database models across microservices or
  independent modules via shared libraries. Shared library models create distributed lockstep deployments.
  Duplicate DTOs across boundary contracts instead.
- **DAMP over DRY in tests**: Tests must be Descriptive And Meaningful Phrases (DAMP). Refactoring test
  fixtures into shared global setup or inheritance hierarchies hides what is being tested. Explicit, slightly
  repetitive test setup is superior to opaque shared state.

## When the opposite choice is correct

- **Boundary contracts**: Public API request/response schemas, inter-service messaging schemas, and
  database migrations should intentionally duplicate shapes to guarantee independent deployability and versioning.
- **Pipeline isolation**: In data or machine learning pipelines, duplicating pre-processing logic per pipeline
  prevents changes in model A from accidentally breaking model B in production.
- **Performance optimization**: Inlining code to eliminate call overhead, loop unrolling, or caching computed
  values duplicates data to satisfy hard latency budgets.

## Checklist

- [ ] Extracted abstractions represent true business invariants, not coincidental syntactic similarity
- [ ] No shared function accepts boolean flags to vary behavior for specific callers
- [ ] Abstractions are deferred until at least three concrete call sites exist (Rule of Three)
- [ ] Cross-service or cross-module boundaries do not share domain entity classes
- [ ] Unit tests remain readable without jumping through deep shared setup helpers (DAMP over DRY)
- [ ] Single source of truth is established for core invariants (e.g., database schema generates client types)
