# Frontend UX & Interaction

Interactive UI elements must communicate clear affordances and behave predictably across mouse, keyboard, touch, and assistive inputs.

## State Management for Interactive Elements

Every interactive component (`<button>`, `<a>`, `<input>`, custom widgets) must support distinct visual and programmatic states:

1. **Default:** Visual styling clearly conveys interactivity without relying on subtle guesswork.
2. **Hover:** Immediate visual feedback on pointer hover (`:hover`). Wrap hover effects in `@media (hover: hover)` to prevent sticky hover states on touch screens.
3. **Focus-Visible:** Prominent focus indicators using `:focus-visible` rather than `:focus` so mouse clicks do not leave lingering rings. Never set `outline: none` without providing an accessible alternative with at least 3:1 contrast against the background and 2px minimum width.
4. **Focus-Within:** Use `:focus-within` on compound controls (search inputs with attached dropdowns, table rows with actions) so ancestor containers indicate when a child retains focus.
5. **Active / Pressed:** Visual tactile depression upon mouse click or tap (`:active`). Toggle controls must reflect pressed state programmatically via `aria-pressed="true|false"` or `aria-expanded="true|false"`.
6. **Disabled:** Clearly dimmed appearance (typically 40–50% opacity or designated muted tokens). Set the native `disabled` attribute, or `aria-disabled="true"` if the control remains focusable for discoverability. Suppress click handlers and pointer events.
7. **Loading / Pending:** Triggered during asynchronous actions. Display a visual spinner or progress bar, set `aria-busy="true"`, provide an accessible label (e.g. `aria-live="polite"`), and disable subsequent submissions to prevent duplicate requests.

## Keyboard Interaction & Focus Orchestration

Reviewers must be able to operate the interface without touching a mouse or screen:

- **Semantic Controls:** Always use native `<button>`, `<a>`, `<input>`, and `<select>`. Never attach click handlers to generic `<div>` or `<span>` elements without re-implementing complete keyboard handling and ARIA semantics.
- **Tab Sequence:** Tab order must mirror visual reading order. Avoid `tabindex > 0`. Use `tabindex="0"` only to add a non-native element to the tab sequence, and `tabindex="-1"` for programmatically focused elements.
- **Standard Key Mappings:**
  - `Enter` and `Space`: Activate buttons.
  - `Enter`: Navigate links.
  - `Space`: Toggle checkboxes and switches.
  - Arrow keys: Navigate composite widgets (radio groups, tabs, select menus, trees) following WAI-ARIA [APG patterns](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/).
  - `Escape`: Dismiss open dialogs, popovers, tooltips, and dropdowns, immediately restoring focus to the trigger element.
- **Modal Focus Trapping:** When a modal or drawer opens, focus must move into the dialog, cycle within the dialog's focusable elements, and restore to the trigger element when closed. If the trigger element was removed from the DOM, return focus to a logical parent or main container.
- **Scroll Margin:** Use CSS `scroll-margin-top` / `scroll-margin-bottom` on scroll targets to prevent fixed headers from obscuring focused inputs (aligning with WCAG 2.4.11).

## Pointer & Touch Behavior

- **Cursor Conventions:** Apply `cursor: pointer` to all clickable elements (buttons, links, clickable rows). Never apply `cursor: pointer` to static text or structural containers. Use `cursor: not-allowed` or `cursor: default` on disabled elements.
- **Touch Target Dimensions:**
  - Minimum WCAG 2.2 AA target size is [24×24 CSS pixels](https://www.w3.org/TR/WCAG22/#target-size-minimum).
  - Recommended minimum on touch platforms is [44×44 pt](https://developer.apple.com/design/human-interface-guidelines/layout#Platform-considerations) for iOS and [48×48 dp](https://m3.material.io/foundations/accessible-design/accessibility-basics) for Android Material Design.
  - Increase the tap bounding box using padding or negative pseudo-element margins (`::after`) when visible icons are compact.
- **Touch Responsiveness:** Ensure `<meta name="viewport" content="width=device-width, initial-scale=1">` is present to eliminate legacy 300ms mobile tap delays. Avoid gesture-only controls.
- **Dragging Alternatives:** Every drag-and-drop interaction (e.g., reordering, sliders) must offer single-click button alternatives per WCAG 2.5.7.

## Motion & Transitions

- **Respect Motion Preferences:** Wrap non-essential transitions and animations in `@media (prefers-reduced-motion: no-preference)`.
- For users requesting reduced motion, replace large animated translations or parallax with simple opacity fades, or disable motion entirely.

See references/accessibility.md for broader compliance standards.

## Checklist

- [ ] All interactive elements display distinct default, hover, focus-visible, active, and disabled states.
- [ ] Hover styles are scoped with `@media (hover: hover)` to prevent sticky artifacts on mobile devices.
- [ ] Focus rings use `:focus-visible`, are never removed without replacement, and have at least 3:1 contrast against backgrounds.
- [ ] All clickable actions use native `<button>` or `<a>` elements, or implement full keyboard and ARIA contracts.
- [ ] Pressing `Tab` and `Shift+Tab` traverses elements in logical visual sequence without `tabindex > 0`.
- [ ] Composite controls (tabs, dropdowns, menus) support Arrow key navigation according to APG patterns.
- [ ] Modals trap keyboard focus while open and restore focus to the trigger element upon `Escape` or close.
- [ ] Fixed or sticky headers do not obscure focused elements (`scroll-margin` applied).
- [ ] Pointer cursors are applied strictly to interactive elements and not static containers.
- [ ] Touch targets measure at least 24×24 CSS pixels (WCAG 2.2 AA) and ideally 44×44px on mobile viewports.
- [ ] Drag-and-drop actions provide clickable or keyboard alternatives.
- [ ] Motion and animations respect `@media (prefers-reduced-motion: reduce)`.
- [ ] Async action buttons display a loading indicator, set `aria-busy="true"`, and block duplicate submissions.
