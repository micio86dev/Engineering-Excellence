# 🚀 Engineering Excellence

> **A framework-agnostic software engineering standard for AI agents.**

Engineering Excellence is a reusable AI skill that teaches coding agents to think and act like experienced software engineers instead of code generators.

Rather than focusing on producing code as quickly as possible, this skill enforces a disciplined engineering workflow that prioritizes quality, maintainability, correctness, security, testing, and long-term sustainability.

It is designed to work with **any programming language**, **any framework**, and **any technology stack**.

---

# 📥 Installation

Engineering Excellence is a standard agent **skill**, so it installs wherever
your coding agent looks for skills. Pick whichever method fits your setup.

## 1. `npx skills` (recommended — any agent)

The [`skills`](https://www.npmjs.com/package/skills) CLI copies the skill into
the target agent's global skills directory. Works for pi, Claude Code, Gemini
CLI, Cursor, Antigravity, and any agent `skills` supports:

```bash
npx skills@latest add micio86dev/Engineering-Excellence --skill engineering-excellence --global --agent pi --copy --yes
```

Keep it on **one line** — the `\` line-continuation is bash-only and breaks in
PowerShell. Swap `--agent pi` for `claude`, `gemini`, `cursor`, or `antigravity`
(repeat per agent). Same mechanism as, e.g., `npx skills@latest add mattpocock/skills`.

## 2. As a pi.dev plugin

For [pi](https://pi.dev), the command above installs the skill into
`~/.pi/agent/skills/engineering-excellence`, where pi loads it automatically on
the next session. Verify with `pi list` (skills section). No extra registration
is needed — dropping the skill directory in place is how pi enables it.

## 3. Universal installer script

Clone this repo and run the bundled installer, which mirrors the skill into
every agent detected on your machine (idempotent):

```bash
./install.sh            # install into all detected agents
./install.sh --list     # preview target paths, write nothing
./install.sh --agents pi,claude
```

---

# ✨ Features

* 📋 **Spec-Driven Development (SDD)**
* 🧪 **Test-Driven Development (TDD)**
* 🏗️ SOLID Architecture
* 🧩 Modular Design
* 🧹 Clean Code
* 🔄 DRY
* 🎯 KISS
* 🚫 YAGNI
* 🔒 Security by Design
* ⚡ Performance by Design
* ♿ Accessibility by Design
* 🌐 Internationalization (i18n)
* 🔎 SEO & Agentic Discoverability
* 🧭 Environment-aware behavior
* ✅ W3C Compliance
* 🚀 Production Readiness
* 📚 Documentation-first workflow
* 🐳 Docker best practices
* 📦 Dependency management
* 🔍 Code review guidelines
* 🚦 Quality Gates
* 📊 Engineering Score

---

# 🎯 Philosophy

Writing code is easy.

Building software that is maintainable, testable, secure, scalable and understandable years later is much harder.

Engineering Excellence exists to help AI agents consistently make engineering decisions that experienced software developers would make.

The goal is not simply to generate working code.

The goal is to engineer software that can confidently reach production.

---

# 🌍 Framework Agnostic

Engineering Excellence is intentionally independent of any language or framework.

It works equally well with:

* TypeScript
* JavaScript
* Python
* Go
* Rust
* Java
* Kotlin
* C#
* PHP
* Ruby

and frameworks such as:

* Nuxt
* Vue
* React
* Angular
* Laravel
* Symfony
* Spring Boot
* ASP.NET
* FastAPI
* Express
* NestJS

or any other technology stack.

---

# 🛠 Core Engineering Principles

This skill encourages AI agents to consistently apply:

* SOLID
* DRY
* KISS
* YAGNI
* Separation of Concerns
* Composition over Inheritance
* High Cohesion
* Loose Coupling
* Clean Architecture (when appropriate)

---

# 📋 Standard Workflow

Every implementation follows the same engineering process:

1. Understand requirements
2. Produce or update the specification
3. Ask questions if information is missing
4. Wait for approval
5. Write failing tests first (TDD)
6. Implement the smallest possible solution
7. Refactor
8. Execute quality gates
9. Update documentation
10. Produce an Engineering Report

---

# 🧪 Testing

Testing is considered mandatory.

Recommended minimum quality targets:

| Metric             | Target |
| ------------------ | ------ |
| Line Coverage      | 95%    |
| Function Coverage  | 95%    |
| Statement Coverage | 95%    |
| Branch Coverage    | 90%    |

A task is not considered complete while tests are failing.

---

# 🔒 Security

The skill promotes secure software development by encouraging:

* Input validation
* Secure defaults
* Secret management
* Principle of least privilege
* Safe dependency usage
* Defensive programming

---

# ⚡ Performance

Performance is treated as a functional requirement.

The skill encourages AI agents to:

* Measure before optimizing
* Optimize Core Web Vitals and Lighthouse scores
* Minimize allocations
* Reduce unnecessary rendering
* Optimize bundle size and prefer lazy loading when beneficial
* Eliminate performance bottlenecks

It aims for the highest realistically achievable scores — never sacrificing
maintainability just to move a benchmark.

---

# ♿ Accessibility

Accessibility is a first-class requirement, never traded away for aesthetics.
Whenever applicable, the generated software should target:

* WCAG 2.2 AA
* Semantic HTML
* Keyboard navigation
* Accessible forms
* Proper focus management
* ARIA only when necessary
* W3C-compliant HTML and CSS

---

# 🌐 Internationalization

Whenever applicable, applications are designed with internationalization in mind:

* No hardcoded user-facing strings
* Copy separated from logic
* An architecture that allows future localization without major refactoring

---

# 🔎 SEO & Agentic Discoverability

For public-facing applications, the skill generates the artifacts that make content
discoverable by both search engines and AI agents:

* Metadata, canonical URLs, and structured metadata
* `sitemap.xml` and `robots.txt`
* `llms.txt` / `llms-full.txt` for AI consumption
* Semantic HTML and no duplicate content

---

# 🧭 Environment Awareness

Behavior adapts automatically to the deployment environment:

* Development and staging → `noindex`, `nofollow`
* Production → indexing enabled
* Administration panels, dashboards, and authenticated areas are never indexed

---

# 🚀 Production Readiness

Production-ready software, when applicable, ships with i18n, accessibility, SEO and
agentic SEO, `robots.txt` / `sitemap.xml` / `llms.txt`, security headers and CSP,
compression, caching, health endpoints, structured logging, monitoring hooks, Docker,
CI/CD, and environment-specific configuration.

---

# 🐳 Development Environment

Engineering Excellence recommends reproducible development environments.

Docker should be used whenever it improves consistency and developer experience, while avoiding unnecessary complexity for simple projects.

---

# 📦 Dependencies

Every dependency should have a clear justification.

The skill encourages:

* Native APIs whenever practical
* Well-maintained libraries
* Minimal dependency footprint
* Regular updates
* Avoiding unnecessary vendor lock-in

---

# 🚦 Quality Gates

Before completing any task, the following checks should pass:

* ✅ Specification updated
* ✅ Tests passing
* ✅ Coverage requirements satisfied
* ✅ Lint passing
* ✅ Build successful
* ✅ Documentation updated
* ✅ No duplicated code
* ✅ No dead code
* ✅ Security reviewed
* ✅ Performance reviewed
* ✅ Accessibility reviewed

---

# 📊 Engineering Report

At the end of every implementation, AI agents are encouraged to produce a final report summarizing:

* Specification
* Architecture
* Testing
* Coverage
* Security
* Performance
* Accessibility
* Maintainability
* Technical Debt
* Overall Engineering Score

---

# 🤝 Contributing

Contributions are welcome.

Ideas, improvements, corrections and new engineering guidelines are encouraged through Issues and Pull Requests.

---

# 📄 License

MIT License.

---

**Build software.
Engineer excellence.**
