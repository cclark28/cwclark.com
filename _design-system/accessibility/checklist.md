# Accessibility Checklist — cwclark.com

Target: WCAG 2.1 AA minimum on all pages.

## Semantic HTML
- [ ] Single `<h1>` per page
- [ ] Correct heading hierarchy (no skipping levels)
- [ ] Landmark roles: `<header>`, `<nav>`, `<main>`, `<footer>`
- [ ] Lists use `<ul>`/`<ol>` not divs
- [ ] Buttons use `<button>`, links use `<a href>`

## Keyboard Navigation
- [ ] All interactive elements reachable via Tab
- [ ] Focus order matches visual/logical order
- [ ] Visible focus indicator on all elements (never `outline: none` without a replacement)
- [ ] Modals/overlays trap focus and restore on close
- [ ] Skip-to-main-content link at top of page

## Color & Contrast
- [ ] Body text on white: ≥ 4.5:1 (#000 on #FFF = 21:1 ✓)
- [ ] Muted text (#9BA3AF on #FFF): check — may need darkening for body use
- [ ] Interactive elements: focus state visible at ≥ 3:1 against adjacent colors
- [ ] No information conveyed by color alone

## Images & Icons
- [ ] All `<img>` have descriptive `alt` text (empty alt `""` for decorative)
- [ ] All icon-only buttons have `aria-label`
- [ ] SVG icons: `aria-hidden="true"` when paired with visible text

## Forms (Contact)
- [ ] All inputs have visible `<label>` (not placeholder-only)
- [ ] Error messages are descriptive and linked via `aria-describedby`
- [ ] Success state announced to screen readers (`role="status"` or `aria-live`)
- [ ] Required fields marked with `aria-required="true"` and visually
- [ ] Email obfuscated — never plain text in source

## Motion & Animation
- [ ] Respect `prefers-reduced-motion` for all transitions
- [ ] No auto-playing video with audio
- [ ] No content that flashes > 3 times/second
