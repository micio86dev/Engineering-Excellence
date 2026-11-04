# SEO & Agentic Discoverability

Public web applications require structured, machine-readable markup to ensure discoverability, correct indexing, and rich snippet extraction by traditional search engines and autonomous AI agents.

## Core Ranking & Crawlability Fundamentals

Search engines rank content based on relevance, quality, and domain trust. Technical SEO cannot guarantee #1 rankings, but technical failures will actively suppress indexing. Conform to [Google Search Essentials](https://developers.google.com/search/docs/essentials) standards:

### Crawlability & Indexing Directives
- **HTTP Status Codes:** Return accurate HTTP codes: `200` for valid content, `301` for permanent redirects, `404` or `410` for deleted pages, and `503` during maintenance. Never serve error pages with a `200` status (soft-404).
- **`robots.txt` Configuration:** Place `robots.txt` at the site root. Never disallow CSS, JavaScript, or image assets needed by search engine rendering engines. Always declare the XML sitemap location: `Sitemap: https://example.com/sitemap.xml`.
- **XML Sitemaps:** Generate standards-compliant XML sitemaps containing canonical, indexable URLs with accurate `<lastmod>` timestamps. Exclude redirect chains, error endpoints, and `noindex` pages.
- **Canonical URLs:** Every indexable page must contain a self-referential or consolidating `<link rel="canonical" href="...">` tag to prevent duplicate content penalties arising from query parameters, session tokens, trailing slashes, or HTTP/HTTPS variations.

### Core Web Vitals (Real-User Experience)
Google includes Core Web Vitals in its page experience ranking evaluation. Maintain 75th percentile thresholds across field traffic:
- **[LCP (Largest Contentful Paint)](https://web.dev/articles/lcp):** <= 2.5 seconds (measures perceived loading speed).
- **[INP (Interaction to Next Paint)](https://web.dev/articles/inp):** <= 200 milliseconds (measures interaction responsiveness; officially replaced FID in March 2024).
- **[CLS (Cumulative Layout Shift)](https://web.dev/articles/cls):** <= 0.1 (measures visual stability).

### Document Hierarchy & Structured Data
- **Metadata:** Unique, intent-focused `<title>` (under 60 characters) and `<meta name="description">` (120–160 characters) per page.
- **Semantic Outline:** Exactly one `<h1>` per page capturing the main topic, supported by sequential `<h2>` and `<h3>` tags. Avoid empty heading tags used solely for visual styling.
- **Internal Linking:** Use crawlable `<a href="...">` links with meaningful anchor text. Avoid generic labels like "click here" or JavaScript-only navigation handlers.
- **Schema.org Structured Data:** Embed valid JSON-LD (`<script type="application/ld+json">`) schemas for rich snippets (e.g., `Article`, `Product`, `BreadcrumbList`, `Organization`, `FAQPage`). Validate using the Google Rich Results Test.

## Agentic Discoverability (AI Crawlers & LLMs)

AI systems (ChatGPT, Perplexity, Claude, Copilot) read and synthesize public content both in batch indexers and real-time retrieval agents:

- **Server-Rendered HTML:** AI retrieval agents frequently do not execute complex JavaScript hydration pipelines. Critical content, documentation, and metadata must be present in the initial server response (via SSR or static pre-rendering).
- **The `/llms.txt` Standard:** Provide an `/llms.txt` file at the root conforming to the [llmstxt.org](https://llmstxt.org/) standard. Use concise Markdown with an H1 title, summary blockquote, and curated links to canonical documentation. For complete documentation sets, provide `/llms-full.txt`.
- **AI Bot Governance:** Explicitly declare crawler rules in `robots.txt` for AI-specific agents (`GPTBot`, `ClaudeBot`, `PerplexityBot`, `Bytespider`) to allow discovery or protect proprietary material according to project policy.
- **Open Graph & Social Graph Tags:** Include standard Open Graph (`og:title`, `og:description`, `og:image`, `og:url`) and Twitter card tags. Real-time chat agents and messaging platforms render rich previews directly from these tags.

## Environment Isolation

Non-production environments (staging, QA, preview deployments) must never be indexed. Accidental indexing causes domain duplicate penalties and exposes pre-release data:
- Emit HTTP response header `X-Robots-Tag: noindex, nofollow` on all non-production servers.
- Protect staging deployments with HTTP Basic Authentication or network firewalls.
- See references/environments.md for deployment environment tiering.

## Checklist

- [ ] `robots.txt` is present at the domain root, links to the sitemap, and does not block critical rendering assets.
- [ ] Automated XML sitemap generates valid URLs with accurate `<lastmod>` timestamps and no redirected or error URLs.
- [ ] Every indexable page defines a valid self-referential or consolidated `<link rel="canonical">` tag.
- [ ] Pages return proper HTTP status codes (`200`, `301`, `404`, `410`, `503`) without soft-404 patterns.
- [ ] Core Web Vitals target <= 2.5s LCP, <= 200ms INP, and <= 0.1 CLS at the 75th percentile.
- [ ] Each page features a unique `<title>` (< 60 chars) and descriptive `<meta name="description">` (120–160 chars).
- [ ] Document outline uses a single `<h1>` matching the page title followed by logical `<h2>` and `<h3>` headings.
- [ ] Structured data is implemented using Schema.org JSON-LD and passes validation in the Rich Results Test.
- [ ] Content is server-rendered or statically generated so bots and AI agents do not require client-side JS execution.
- [ ] Root provides `/llms.txt` following the llmstxt.org format for agentic documentation discovery.
- [ ] Open Graph tags (`og:title`, `og:description`, `og:image`, `og:url`) are present and verified.
- [ ] Staging and preview environments enforce `X-Robots-Tag: noindex, nofollow` headers or HTTP authentication.
