# Technology Selection

Stack choice is a hiring, operations and debugging-cost decision long before it is a benchmark result, so
decide it from what the system must actually do. Most bad choices are not wrong languages; they are a
framework chosen for a workload it does not serve, or two runtimes pretending to share one codebase. Pick the
smallest ecosystem that covers today's requirement, and record the exit path in an ADR (`references/architecture.md`).

## Back end: choose by workload shape

| Job the system must do | Right tool | Choosing it is a mistake when |
| --- | --- | --- |
| Content, admin, subscriptions, queues, auth — a product with a UI | PHP 8.4/8.5 + Laravel ([php.net](https://www.php.net/supported-versions.php), [releases](https://laravel.com/docs/releases)) | The service is CPU-bound computation or a latency-critical network daemon: PHP's per-request model and ecosystem are not the asset there |
| I/O-bound JSON APIs where one language across browser and server removes real handoff cost | Node + TypeScript on an Active LTS ([nodejs.org](https://nodejs.org/en/about/previous-releases)) | You need hard realtime, heavy concurrency per core, or a single static binary: the event loop and 100 MB+ images fight you |
| Network services: proxies, gateways, high-connection-count servers, CLIs in one binary | Go | The domain is CRUD with rich admin screens — you will rebuild Laravel in Go, badly, for a year |
| Model- or data-shaped work: notebooks, pipelines, ML serving | Python, kept at the boundary it owns | The product API is plain CRUD and only one endpoint scores a model: put Python behind that endpoint, not under the whole app |
| Large existing JVM estate, complex domain rules, long-lived typed contracts | Java/Kotlin | Greenfield small team with one service: Spring-shaped ceremony per feature is a tax with no counterpart |
| Bun/Deno for a TypeScript service that wants strict-by-default permissions | Bun or Deno ([Deno security model](https://docs.deno.com/runtime/fundamentals/security/)) | You depend on native addons or long-tail Node packages: verify each one runs, do not assume |

Two rules that outrank the table:

- Choose the ecosystem your team can debug at 03:00, not the one with the best landing page. The opposite
  choice is correct when the team is new and the workload is boring: pick the boring stack the market hires for.
- Every runtime has a support window. PHP 8.2 security support ends 31 Dec 2026
  ([php.net](https://www.php.net/supported-versions.php)); Node odd majors die in months and production belongs
  on LTS ([nodejs.org](https://nodejs.org/en/about/previous-releases)). A pinned EOL runtime is a finding, not a preference.

## Laravel, specifically

- Laravel 13 requires PHP 8.3+ and supports 8.3–8.5, with 18 months of bug fixes and 2 years of security fixes
  ([laravel.com/docs/releases](https://laravel.com/docs/releases)). Pin `^13.0`, and pin the runtime to match.
- It is genuinely better at: auth, sessions, queues, scheduling, notifications, storage, an admin surface and
  migrations in one opinionated whole. Reach for it when the product is mostly those concerns.
- Choosing it is a mistake when the deliverable is under ~10 JSON endpoints with no admin, no queue and no
  notification: a micro-framework plus a query builder has less to upgrade. It is also a mistake in a
  TypeScript-only team — the second ecosystem costs more than the framework saves.
- Laravel rewards discipline, not magic: keep business rules out of Eloquent models and controllers, or the
  framework becomes your architecture.

## TypeScript on both sides of the boundary

Share types and pure functions; never share runtime assumptions. Put the shared package behind a lint rule
that forbids `node:*`, `window`, `document` and `Deno.*` imports, or it will silently become Node-only.

| Runtime | What actually breaks |
| --- | --- |
| Node 24/26 | Built-in support is type *stripping* only: no `enum`, no `namespace` with runtime code, no parameter properties, no import aliases, `.tsx` unsupported, `tsconfig.json` ignored so `paths` fail ([nodejs.org/api/typescript.html](https://nodejs.org/api/typescript.html)). Set `erasableSyntaxOnly` + `verbatimModuleSyntax`. |
| Bun / Deno | Transpile, so enums and other transform-requiring syntax work — but `Deno.*` and Bun-specific APIs do not exist in Node, and Node builtins differ per runtime. A shared module touching either is not shared. |
| Browser / bundler | Needs bundling, the DOM lib and polyfills for any Node builtin. Server-only packages imported by a client component are how secrets end up in bundles. |

The opposite choice is correct when the product is genuinely one codebase: a single language across
client and server beats a runtime mismatch, as long as CPU-bound work stays out of the request path.

Framework versions set the floor: Next 16.4.5 requires Node >= 20.9.0
([registry](https://registry.npmjs.org/next/latest)), Nuxt 4.6.4 requires Node `^22.22.3 || ^24.15.0 || >=26`
([registry](https://registry.npmjs.org/nuxt/latest)). Check `engines` before you promise an upgrade.

## Embedded engines for plugin systems

| Engine | Use it for | Cost |
| --- | --- | --- |
| QuickJS | Sandboxed JavaScript: small, embeddable, ES2025, MIT, no host bindings unless you add them ([bellard.org/quickjs](https://bellard.org/quickjs/)) | You own the host API: every capability you expose is a design decision |
| Lua 5.5 | A small scripting surface in C/C++/host code; teams that already speak it ([lua.org](https://www.lua.org/about.html)) | Weaker tooling for web developers; you still write the capability layer |
| Wasm (WASI) | Plugins from third parties, in any source language, with a hard module boundary | ABI design and toolchain per guest language |

Sandboxing rules:

- An engine is one layer, never the only one. Node's permission model is documented as a "seat belt" that
  "does not protect against malicious code" ([nodejs.org/api/permissions.html](https://nodejs.org/api/permissions.html));
  Deno's sandbox is real but `--allow-run` and `--allow-ffi` step outside it
  ([docs.deno.com](https://docs.deno.com/runtime/fundamentals/security/)). Treat both as defence in depth.
- Expose a narrow capability object (typed messages in, typed messages out), never raw `fs`, `net` or host
  objects. Pass serializable values only.
- Budget everything: wall-clock timeout, memory cap, input size cap, output size cap. An engine without a
  deadline is a denial-of-service waiting for one bad plugin.
- Use a separate process when the plugin can loop forever, allocate without bound, or needs network access:
  in-process you cannot reliably kill it, and a supervisor can. Deno's guidance for untrusted code is a
  reduced-permission worker *plus* OS sandboxing or a microVM; follow it.
- Precedent worth copying: Figma runs plugin code in a sandbox that has modern JavaScript but no browser
  APIs, puts the UI in an iframe, and connects the two by message passing, with manifest-declared network
  access enforced as CSP ([developers.figma.com](https://developers.figma.com/docs/plugins/how-plugins-run/)).

## Front end: by requirement, not by preference

| Requirement | Choose | The opposite is correct when |
| --- | --- | --- |
| SEO and first paint on content pages | Server-rendered HTML, with JavaScript islands only where interaction exists | The surface is a logged-in tool no crawler sees |
| Dense interaction, large team, deep hiring pool | React 19.3 ([react.dev/versions](https://react.dev/versions)) on Next 16.4.5 | Three static pages: ship HTML and one script tag |
| Progressive adoption, template-first DX, smaller mental model | Vue 3.5.44 ([registry](https://registry.npmjs.org/vue/latest)) with Nuxt 4.6.4 | You need the widest third-party component catalogue — React's is wider |
| Smallest runtime, compiled output, few dependencies | Svelte/SvelteKit | You need a large pre-built component set or React-specific hires |
| Offline-tolerant, installable, mobile-shaped app | Ionic 9 components ([registry](https://registry.npmjs.org/@ionic/core/latest)) + Capacitor 8 ([capacitorjs.com](https://capacitorjs.com/docs)) | The target is a public marketing site needing crawlable HTML |
| A hard bundle budget | Framework with server rendering and per-route splitting; measure the shipped JS | The budget is theoretical: interactivity wins and users are on fast networks |

Set the budget before choosing: a server-rendered framework still ships hydration JavaScript, and if nobody measures bytes per route the table above is decoration.

## Styling and UI kits

- **Tailwind** when the design is bespoke and the team is small: no runtime, styles die with the markup.
  Tailwind 4.3 ([blog](https://tailwindcss.com/blog)) is built on cascade layers, `@property`,
  `color-mix()` and container queries — so it presumes a modern browser baseline. Supporting old browsers
  is the case where a plain CSS architecture is the correct opposite choice.
- **Component library** when breadth and accessibility *now* beat long-term control, and when a design
  system already exists that you must match. The opposite is right when the brand is the product.
- **Plain CSS** when the surface is small or the CSS is genuinely hand-written design work; adding a build
  step and a class vocabulary for six pages is overhead.
- **Copy-in components** (source you own, e.g. Tailwind Plus blocks, shadcn-style) when you will restyle
  them anyway: no upgrade treadmill, no runtime. **Runtime-heavy libraries** when you need a maintained
  set of complex widgets (data grids, date pickers) and accept theme lock-in and bundle weight.
- Never mix two styling systems in one app; the second one always wins by specificity accident.
- Capability tests, not counts: every kit you adopt must pass keyboard, focus-visible and screen-reader
  checks in `references/accessibility.md` before it is in the dependency list (`references/dependencies.md`).

**Name collisions, resolved instead of guessed.** "Ghost UI" is not a UI framework: Ghost (6.74.0,
[registry](https://registry.npmjs.org/ghost/latest)) is a headless publishing CMS — pick it for content, not
for buttons. If someone meant a React component library, the plausible real name is Geist UI
(`@geist-ui/react`, last published 2.2.5, [registry](https://registry.npmjs.org/@geist-ui/react/latest));
check its last publish date and open issues before adopting. "Ion UI" is Ionic Framework: web components
prefixed `ion-*` shipped as `@ionic/core`, with React/Vue/Angular wrappers. Confirm the intent in writing
before adding either name to a lockfile.

## Failure modes

1. **Resume-driven selection.** The stack is chosen because it is interesting, then the workload is bent to justify it.
2. **Library-level decisions mistaken for stack decisions.** Ten libraries each reasonable, no coherent whole.
3. **Two front-end frameworks in one repository.** Two build pipelines, two design systems, no shared components.
4. **A "shared" package that imports runtime globals.** It compiles everywhere and runs in one place.
5. **Plugin sandbox with no timeout or memory cap.** One plugin takes the host down and you cannot kill it.
6. **Framework and runtime outside supported windows.** Upgrade cost compounds; the fix is a maintenance window, not a rewrite.

## Checklist

- [ ] The stack is justified by a written workload description and a named failure mode, not by preference
- [ ] Runtime and framework versions are supported today, with the support end date recorded
- [ ] `engines` / `require` constraints in the framework match the pinned runtime
- [ ] Shared TypeScript packages contain types and pure functions only, enforced by a lint rule
- [ ] Plugin or extension points expose a narrow serializable capability API, never raw `fs`, `net` or host objects
- [ ] Every embedded engine has a timeout, a memory cap and an input size cap, asserted by a test
- [ ] Untrusted code runs behind at least two layers (engine or worker **and** process/OS isolation)
- [ ] Front-end choice is traceable to a requirement (SEO, interactivity, offline, bundle budget) with the opposite case written down
- [ ] Exactly one styling system and one component source per app
- [ ] Ambiguous technology names ("Ghost UI", "Ion UI") were resolved with the requester and recorded, not guessed
