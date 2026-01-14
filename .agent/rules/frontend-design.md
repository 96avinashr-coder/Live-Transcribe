---
trigger: always_on
---

---

# Frontend Design

## Prime Directive
Frontend design exists to **reduce cognitive load**, not to impress Dribbble.

If it does not improve comprehension, speed, or trust — delete it.

Every pixel, every animation, every color choice must justify its existence through utility. Beauty emerges from clarity, not decoration. The best interface is the one users don't notice because it simply works.

---

## Layout Systems

### Grid First, Flex Second
- CSS Grid was designed for page-level layout. Use it.
- Flexbox excels at component-level arrangement. Know the difference.
- Fixed widths are admissions of defeat. Embrace fluidity.
- Containers define rhythm, not pixels. Think in ratios and proportions.

### Spatial Hierarchy
- Negative space is not wasted space—it's breathing room for cognition.
- Consistent spacing creates predictable patterns. Use a scale: 4px, 8px, 16px, 24px, 32px, 48px, 64px.
- Proximity communicates relationships. Related items cluster; unrelated items separate.
- Density must match task complexity. Dense interfaces for power users; spacious for casual browsing.

### Container Strategy
- Max-width prevents line-length disasters on wide screens.
- Padding scales with viewport to maintain proportional comfort.
- Content dictates container size, never the reverse.
- Nested containers compound margins. Audit ruthlessly.

---

## Responsive Design Truth

**Responsive ≠ shrinking. Responsive = re-prioritizing.**

Design breakpoints around **content collapse**, not device sizes.

### Mobile-First Mindset
- Start with the constraint, expand to luxury.
- Mobile forces prioritization—what truly matters?
- Desktop is not "mobile plus more stuff." It's a different context entirely.

### Breakpoint Philosophy
- Don't target devices. Target **content breakpoints**.
- When layout becomes uncomfortable, break. That's your breakpoint.
- Common trap: Three breakpoints (mobile, tablet, desktop) rarely suffice. Real content needs real breakpoints.

### Progressive Enhancement
- Core experience works without JavaScript.
- Enhancements layer on top, never replace base functionality.
- Feature detection over browser detection.

### Touch vs. Click
- Touch targets minimum 44×44px (Apple) or 48×48px (Android).
- Hover states don't exist on mobile. Design accordingly.
- Swipe gestures must have visual affordances or be optional.

---

## Typography as Infrastructure

**Typography defines hierarchy, not color.**

### Font Selection
- Two fonts maximum. One for headings, one for body. Or just one excellent variable font.
- Variable fonts enable responsive typography without font loading overhead.
- System fonts = instant performance. Custom fonts = brand identity. Choose battles wisely.

### Hierarchy Through Scale
- Modular scale creates harmonious relationships: 1.125 (Major Second), 1.25 (Major Third), 1.5 (Perfect Fifth).
- Scale down, not up. Start with body text at optimal size, derive everything else.
- Never rely on color alone for hierarchy. Size and weight do the heavy lifting.

### Line Length & Readability
- Optimal line length: 45-75 characters (66 is the sweet spot).
- Line height scales inversely with font size: body text 1.5-1.6, headings 1.1-1.3.
- Letter spacing (tracking) for all-caps text prevents visual congestion.

### Loading Strategy
- Font loading affects perceived performance more than actual performance.
- `font-display: swap` prevents invisible text, but causes layout shift.
- `font-display: optional` respects user bandwidth, falls back to system fonts gracefully.
- Preload critical fonts, defer decorative ones.

---

## Color Systems

**Semantic tokens only**: primary, danger, surface, muted.

### Token Architecture
- Name by purpose, not appearance. `text-danger` not `red-500`.
- Maintain consistent contrast ratios across themes: minimum 4.5:1 for body text, 3:1 for large text.
- Neutral palette (grays) should have 8-10 shades. Color accents need 5-7.

### Dark Mode Reality
- Dark mode is **not** inverted light mode.
- Shadows invert to glows. Depth reverses. Contrast ratios shift.
- Pure black (#000) causes halation on OLED. Use near-black (#0a0a0a).
- Desaturate colors in dark mode—vibrant hues burn retinas at night.

### Contrast as Accessibility
- Contrast is accessibility, not aesthetics.
- WCAG AA minimum: 4.5:1 for normal text, 3:1 for large.
- WCAG AAA preferred: 7:1 for normal text, 4.5:1 for large.
- Test with actual color blindness simulators, not just contrast checkers.

### Color Psychology & Culture
- Red means danger in the West, prosperity in the East.
- Context dictates meaning more than color itself.
- Use color as reinforcement, never as sole indicator.

---

## Component Architecture

### Single Responsibility Principle
- Components own layout, **not** page logic.
- Pages compose components, **never** style them.
- One component = one responsibility. Button does one thing. Card does another.

### Composition Over Inheritance
- Prefer slots/children patterns over prop drilling.
- Higher-order components create indirection. Use sparingly.
- Render props enable flexibility without complexity.

### Component API Design
- Props should be obvious. Good: `isDisabled`. Bad: `state="disabled"`.
- Boolean props default to `false`. Presence = true.
- Variants as enums, not strings: `variant="primary" | "secondary"`, not `variant="blue"`.

### Component Boundaries
- Presentational components receive data, render UI. No side effects.
- Container components handle logic, state, and side effects. Minimal markup.
- Smart/dumb split keeps components testable and reusable.

---

## State & UI Coupling

**UI reflects state, never mutates it.**

### State Management Truths
- Derived state is a code smell. Compute on render, don't store.
- Single source of truth. Duplicating state guarantees desync.
- Lift state only as high as necessary, no higher.

### State Machine Thinking
- Every interaction is a transition between defined states.
- Impossible states should be unrepresentable in your data model.
- Loading, error, empty, success—explicit states prevent bugs.

### Loading, Empty, Error States
- **Loading**: Show skeleton screens, not spinners. Preserve layout.
- **Empty**: Explain why empty, offer action to populate.
- **Error**: Explain what happened, why, and how to recover.
- **Success**: Confirm action, offer next steps.

These states are **first-class citizens**, not afterthoughts.

---

## Animation & Motion

**Motion explains change.**

### Purpose-Driven Motion
- No motion for decoration. Every animation must explain a state change.
- Enter/exit animations clarify addition/removal from the DOM.
- Transitions smooth property changes, reducing jarring jumps.

### Easing Functions
- Easing matters more than duration.
- Linear easing feels robotic. Use `ease-out` for entrances, `ease-in` for exits.
- Cubic bezier curves create natural, organic motion.
- Spring physics (react-spring, Framer Motion) mimic real-world behavior.

### Performance Boundaries
- Only animate `transform` and `opacity`—these don't trigger layout/paint.
- Animating `width`, `height`, `top`, `left` destroys performance.
- `will-change` is an optimization hint, not a magic bullet. Use sparingly.

### Respect User Preferences
- `prefers-reduced-motion` is not optional. Honor it.
- Reduce or eliminate animations for users who request it.
- Essential animations (confirming an action) should still occur but subtly.

---

## Performance Doctrine

**Ship less JavaScript.**

### Code Splitting
- Lazy load aggressively. Route-based splitting is baseline.
- Component-level splitting for large, conditional UI.
- Dynamic imports (`import()`) defer non-critical code.

### Asset Optimization
- Images: WebP with JPEG fallback. AVIF where supported.
- SVGs: Optimize with SVGO. Inline small icons, external large illustrations.
- Video: Lazy load, preload metadata only.

### Measurement Discipline
- **Core Web Vitals**: LCP < 2.5s, FID < 100ms, CLS < 0.1.
- Measure on real devices, real networks. Throttle to 3G.
- Lighthouse scores are guidelines, not gospel. Real User Monitoring (RUM) reveals truth.

### CSS Before JS
- CSS handles layout, visibility, simple interactions.
- JavaScript for complex state, async operations, dynamic content.
- Progressive enhancement: CSS baseline, JS enhancement.

### Bundle Optimization
- Tree-shaking eliminates dead code. Configure properly.
- Code splitting by route and component.
- Polyfills only for browsers you support.

---

## Accessibility (Non-Optional)

**ARIA only when necessary. Semantic HTML first.**

### Semantic HTML
- `<button>` not `<div role="button">`.
- `<nav>`, `<main>`, `<article>`, `<aside>` structure pages logically.
- Heading hierarchy (`<h1>` through `<h6>`) must never skip levels.

### ARIA Roles & Attributes
- ARIA fills gaps where HTML semantics fall short.
- `aria-label` describes elements without visible text.
- `aria-describedby` links elements to descriptive text.
- `aria-live` announces dynamic content to screen readers.

### Keyboard Navigation
- Every interactive element must be reachable via Tab.
- Focus indicators must be visible. Never `outline: none` without custom alternative.
- Logical tab order follows visual order.
- Escape closes modals. Enter activates buttons.

### Screen Reader Considerations
- Screen readers are users, not edge cases.
- Alt text describes images functionally, not poetically.
- Empty alt (`alt=""`) for decorative images hides them from assistive tech.
- Complex images need longer descriptions via `aria-describedby` or adjacent text.

### Color Blindness
- 8% of men, 0.5% of women have color vision deficiency.
- Never rely on color alone to convey information.
- Use icons, labels, patterns in addition to color.

---

## Forms & Inputs

**Labels always visible. Validation is guidance, not punishment.**

### Label Strategy
- Placeholder text is not a label. Disappears on focus.
- Floating labels acceptable if implemented accessibly.
- Labels describe purpose; help text provides context.

### Validation Philosophy
- Inline validation on blur, not on keystroke (too aggressive).
- Errors must explain recovery: "Password must contain 8 characters" not "Invalid password."
- Success states confirm correctness, reduce anxiety.

### Input Types
- Use semantic input types: `email`, `tel`, `url`, `number`, `date`.
- Mobile keyboards adapt to input type, improving speed and accuracy.
- Autocomplete attributes hint expected values, enabling autofill.

### Error Handling
- Errors appear near the input, not just at form top.
- Focus management: On submit error, focus first invalid field.
- Group related errors: "Shipping address incomplete" rather than three separate errors.

---

## Visual Hierarchy

**Size > Weight > Color.**

### Hierarchy Through Scale
- Size difference must be significant (1.5× minimum) to register as hierarchy.
- Weight (regular, medium, bold) reinforces but doesn't establish hierarchy.
- Color is the weakest hierarchy signal. Rely on size and weight first.

### Whitespace Control
- Whitespace is a control mechanism, not decoration.
- Consistent spacing creates rhythm and predictability.
- Grouping via proximity: Related items closer together than unrelated.

### Alignment Creates Trust
- Left alignment for text blocks (Western languages). Ragged right is natural.
- Center alignment for headings, CTAs. Use sparingly.
- Alignment grids create invisible structure that users subconsciously trust.

### Z-Index Discipline
- Z-index values should follow a scale: 0 (base), 10 (dropdowns), 20 (modals), 30 (tooltips), 40 (notifications).
- Stacking contexts are complex. Use `isolation: isolate` to control them.

---

## Design for Failure

**Slow networks exist. APIs fail. Users make mistakes.**

### Network Resilience
- Offline-first where possible. Service workers cache critical assets.
- Progressive loading: Show skeleton, load content incrementally.
- Retry logic wit