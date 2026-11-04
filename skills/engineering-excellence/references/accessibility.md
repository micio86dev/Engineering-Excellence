# Accessibility

Accessibility is a non-negotiable engineering baseline for digital products, guaranteeing equal access regardless of visual, motor, auditory, or cognitive abilities.

## Standards Baseline: WCAG 2.2 AA

All user-facing web applications must conform to [WCAG 2.2 Level AA](https://www.w3.org/TR/WCAG22/). Note that WCAG 2.2 marked criterion 4.1.1 (Parsing) obsolete while introducing critical new AA requirements.

Key WCAG 2.2 AA requirements by principle:

### Perceivable
- **Text alternatives (1.1.1):** Every non-text element must have a text alternative. Informative images use concise, context-rich `alt` text; complex diagrams require descriptive captions or `aria-describedby`; decorative images must explicitly use `alt=""` or `aria-hidden="true"`.
- **Color contrast (1.4.3 & 1.4.11):** Normal body text requires at least a 4.5:1 contrast ratio against its background. Large text (>= 18pt / 24px, or >= 14pt / 18.66px bold) requires 3:1. Non-text UI components (input borders, icons, radio button circles) and focus indicators require at least 3:1 contrast against adjacent colors.
- **Reflow (1.4.10):** Content must reflow without loss of information or functionality down to a width of 320 CSS pixels (equivalent to 400% zoom on a 1280px viewport) without requiring two-dimensional scrolling.
- **Visual hierarchy:** Heading tags (`<h1>` through `<h6>`) must reflect a logical outline without skipping levels (e.g., jumping from `<h2>` directly to `<h4>`).

### Operable
- **Keyboard navigation (2.1.1 & 2.1.2):** All functionality must be operable via keyboard alone (`Tab`, `Shift+Tab`, `Enter`, `Space`, Arrows). Keyboard traps are strictly forbidden.
- **Focus visible & not obscured (2.4.7 & 2.4.11):** Keyboard focus indicators must be clearly visible. Under WCAG 2.2 criterion 2.4.11 (Focus Not Obscured - Minimum), focused elements must not be fully obscured by sticky headers, footers, cookie banners, or non-modal floating overlays.
- **Dragging movements (2.5.7):** Any functionality requiring a dragging motion (e.g., reordering lists, kanban boards, sliders) must provide a single-pointer alternative (such as up/down buttons or tap-to-move menus).
- **Target size (2.5.8):** Pointer targets must be at least [24×24 CSS pixels](https://www.w3.org/TR/WCAG22/#target-size-minimum) or provide equivalent spacing around the target, unless inline within text or determined by user agent defaults.

### Understandable
- **Page language (3.1.1):** Every HTML document must declare a valid primary language via `<html lang="...">` at the root. Multilingual passages must declare inline `lang` attributes.
- **Form validation & error recovery (3.3.1 & 3.3.3):** Form fields must have programmatic labels via `<label for="...">`. Errors must be identified in text, referenced via `aria-describedby`, and marked with `aria-invalid="true"`.
- **Redundant entry (3.3.7):** Information entered by the user in a multi-step checkout or application flow must be auto-populated or available for selection in subsequent steps.
- **Accessible authentication (3.3.8):** Authentication flows must not rely solely on cognitive function tests (e.g., memorizing passwords or solving puzzles) without providing a password-manager autofill mechanism, WebAuthn/passkeys, or copy-paste support.

### Robust
- **First Rule of ARIA:** Use native semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<dialog>`) instead of custom elements with ARIA roles whenever possible.
- **Dynamic updates:** Announce dynamic DOM changes (search results, alerts, toasts) using ARIA live regions (`aria-live="polite"` or `aria-live="assertive"`) with `aria-atomic="true"`.
- **APG conformance:** Custom interactive controls (comboboxes, tabs, accordions) must follow the WAI-ARIA Authoring Practices Guide ([APG](https://www.w3.org/WAI/ARIA/apg/)).

## Automated vs. Manual Testing

Automated testing tools catch roughly 30% to 40% of accessibility defects. Full WCAG 2.2 AA conformance requires a disciplined split between automated CI checks and structured manual reviews.

| Testing Scope | Automated Tooling (axe-core, Lighthouse, Pa11y) | Manual Review |
| :--- | :--- | :--- |
| **Markup & Semantics** | Missing `alt`, missing form `<label>`, invalid ARIA roles, duplicate `id`s | Contextual appropriateness of alt text, correct landmark hierarchy |
| **Color & Contrast** | Text vs. solid background color contrast ratios | Contrast over gradients/images, focus ring contrast against adjacent colors |
| **Keyboard & Focus** | Presence of `tabindex > 0` | Logical tab order, modal focus trapping, focus restoration after closing overlays |
| **Dynamic UI** | Static DOM states | Screen reader announcements (live regions), expandable drawers, toast dismissals |
| **Responsiveness** | Viewport meta tag configuration | 400% zoom reflow, target size hit areas, absence of content obscured by banners |

See references/interaction.md for detailed focus and keyboard state implementations.

## Checklist

- [ ] Automated accessibility audits (e.g., axe-core or Lighthouse) run in CI with zero high/critical violations.
- [ ] Document root declares a valid language attribute (e.g., `<html lang="en">`).
- [ ] Contrast ratios meet minimums: 4.5:1 for body text, 3:1 for large text, and 3:1 for interactive borders and focus rings.
- [ ] Heading hierarchy starts with a single `<h1>` and descends sequentially without skipping levels.
- [ ] Every non-decorative image has descriptive `alt` text; decorative images use `alt=""` or `aria-hidden="true"`.
- [ ] Complete UI is navigable via keyboard alone without keyboard traps (`Tab`, `Shift+Tab`, `Escape`, `Enter`, `Space`).
- [ ] Focused elements have a visible focus indicator and remain visible when scrolling under sticky navigation bars.
- [ ] Touch and click targets meet the minimum [24×24 CSS pixel](https://www.w3.org/TR/WCAG22/#target-size-minimum) threshold or have sufficient offset spacing.
- [ ] Drag-and-drop interactions provide a single-pointer alternative (buttons or menus).
- [ ] Page scales to 400% zoom (320 CSS px width) without horizontal scroll or truncated text.
- [ ] Modal dialogs trap focus while open and return focus to the triggering element upon dismissal.
- [ ] Form inputs have associated `<label>` elements; error messages are linked via `aria-describedby` and flagged with `aria-invalid="true"`.
- [ ] Dynamic updates (alerts, toasts, live results) announce via appropriate `aria-live` regions.
- [ ] Authentication flows allow copy-paste and password manager autofill.
