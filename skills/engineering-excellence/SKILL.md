---
name: engineering-excellence
description: Framework-agnostic software engineering standard for AI agents — SDD/TDD workflow, architecture principles, security, performance, accessibility, i18n, SEO, and production readiness. Load when implementing, reviewing, or hardening software in any language or stack.
---

# Engineering Excellence

Engineer software, don't just generate code. This skill is technology-agnostic:
the principles apply to any language, framework, or stack. Framework-specific
guidance appears only as clearly marked examples.

## Always

- Follow SDD, then TDD.
- Ask for clarification when requirements are incomplete — wait for approval before building.
- Build the smallest correct solution, then refactor.
- Apply quality gates before considering work complete.
- Load the relevant reference documents below based on the current task. Do not load
  everything — load what the task needs.

## References

Load a reference when its concern is in scope for the current task.

### Principles & architecture
- `references/engineering-principles.md` — SOLID, DRY, KISS, YAGNI, SoC overview
- `references/solid.md`, `references/dry.md`, `references/kiss.md`, `references/yagni.md` — individual principles
- `references/architecture.md` — modular, cohesive, loosely coupled design
- `references/technical-debt.md` — recording intentional debt

### Workflow & quality
- `references/sdd.md` — spec-driven development
- `references/tdd.md` — test-driven development
- `references/testing.md` — testing expectations
- `references/quality-gates.md` — checks required before completion
- `references/cross-platform-testing.md` — verifying a change on every platform it claims, with containers and multi-platform toolchains
- `references/code-review.md` — review dimensions
- `references/engineering-score.md` — final quality reporting
- `references/documentation.md` — keeping docs current

### Frontend & web
- `references/interaction.md` — frontend UX: cursor, hover/focus/disabled states, semantic HTML, touch targets
- `references/accessibility.md` — WCAG 2.2 AA, keyboard nav, ARIA, and W3C compliance
- `references/i18n.md` — internationalization
- `references/seo.md` — SEO and agentic (AI) discoverability
- `references/environments.md` — environment-aware behavior and indexing
- `references/performance.md` — Core Web Vitals, Lighthouse, and performance as a functional requirement

### Delivery & operations
- `references/security.md` — secure defaults, secrets, headers, CSP
- `references/dependencies.md` — justified, maintained dependencies
- `references/docker.md` — reproducible environments
- `references/ci.md` — continuous integration
- `references/production-readiness.md` — the checklist for shipping to production

## Frontend guidelines

When generating UI, load `references/interaction.md`, `references/accessibility.md`,
and — for public-facing surfaces — `references/seo.md` and `references/environments.md`.

## Templates & examples

- `templates/` — reusable skeletons (ADR, architecture, OpenSpec, pull request, engineering report)
- `examples/` — stack-specific illustrations (generic, React, Nuxt, Laravel, Spring, Go).
  These are examples only; the standard itself stays framework-agnostic.
