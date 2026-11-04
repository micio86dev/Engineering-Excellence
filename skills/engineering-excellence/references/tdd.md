# Tdd

Test-Driven Development (TDD) enforces that automated test assertions precede the production code that satisfies them. Writing tests first verifies that the test runner can detect failure, prevents over-engineering by constraining scope to the current test, and guarantees that every branch is covered by design.

## Sequence

TDD operates strictly through the canonical Red-Green-Refactor cycle:

1. **Red (Write a failing test)**:
   - Identify the smallest next unit of behavior from the specification (see `references/sdd.md`).
   - Write a single focused automated test asserting this behavior.
   - Execute the test runner and verify the test **fails**. The failure must occur for the expected assertion reason, not an unhandled compilation or environment crash.
2. **Green (Make it pass)**:
   - Write the absolute minimum production code required to satisfy the failing test.
   - Resist adding speculative logic, extra parameters, or error branches not yet asserted (see `references/yagni.md` and `references/kiss.md`).
   - Execute the test suite and confirm all tests pass.
3. **Refactor (Clean without changing behavior)**:
   - Remove code duplication (see `references/dry.md`).
   - Improve naming, extract helper methods, and enforce SOLID boundaries (see `references/solid.md`).
   - Re-run the entire test suite after each micro-refactoring to ensure no regressions occur.

## Artefacts Produced

- **Failing test baseline**: Executable assertions proving the absence of the desired behavior prior to implementation.
- **Minimal production code**: Lean implementation containing zero dead code or unexercised branches.
- **Regression test suite**: A permanent safety net documenting business requirements as living code.
- **Atomic commits**: Git history reflecting granular `test:` and `feat:` increments that isolate failures to single logical steps.

## Failure Modes Prevented

- **False-positive tests**: Tests written after implementation frequently pass unconditionally because they mirror existing code quirks or fail to assert the actual invariant.
- **Untestable architectures**: Writing tests first forces dependency injection, decoupled modules, and clear interface boundaries.
- **Over-engineering**: Implementing code only in response to a failing test prevents premature abstractions and unneeded configuration options.
- **Undetected regressions**: Every production behavior has an associated test assertion that guards future edits.

## AI Agent in the Loop

AI agents possess a strong default bias toward writing production code and test suites simultaneously, or authoring tests that pass vacuously. When an AI agent executes TDD:

1. **Strict phase separation**: The agent must generate the test file first, execute the test runner, and verify the red state before writing a single line of application code.
2. **Assertion integrity**: The agent must never alter or weaken an existing test assertion to turn a failing test green. The fix belongs in production code.
3. **No mock hallucination**: The agent must not mock the unit under test. Mocks and stubs are reserved strictly for external boundaries (network I/O, database, third-party APIs).
4. **Minimal diff discipline**: When writing the implementation to pass the test, the agent must write the shortest code that satisfies the assertion without anticipating future requirements.
5. **Execution proof**: The agent must capture test runner stdout/stderr demonstrating the transition from failure (`Red`) to success (`Green`).

## What a Reviewer Checks

| Dimension | Reviewer Check |
| :--- | :--- |
| **Failure proof** | Is there evidence that the test failed before the implementation was committed? |
| **Behavior vs. implementation** | Does the test assert externally observable outputs or state, rather than private methods? |
| **No tautological asserts** | Does the test contain meaningful assertions rather than `assert(true)` or tautologies? |
| **Code proportionality** | Does the production code contain branches, flags, or methods that have no corresponding test? |
| **Refactor safety** | Can the internal implementation be swapped without breaking the test suite? |

## Checklist

- [ ] A failing test was written and executed before writing production code.
- [ ] The test failed for the expected reason (assertion failure against the target behavior).
- [ ] Production code contains only the minimum logic required to pass the test.
- [ ] All existing and new tests pass with zero warnings or deprecation notices.
- [ ] Refactoring was performed with green tests to clean up structure without modifying behavior.
- [ ] Tests assert public interfaces, inputs, and outputs rather than internal private state.
- [ ] No test assertions were weakened, commented out, or bypassed to achieve a green build.
