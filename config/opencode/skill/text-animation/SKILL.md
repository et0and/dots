---
name: text-animation
description: Use when implementing CSS text reveal animations, blur-in effects, staggered character animations, or motion design for web content. Covers Tailwind v4 custom animations, @keyframes, and accessible animation patterns.
version: 1.0.0
license: MIT
---

# Text Animation (Blur-In)

**Use this skill for ANY text animation work including reveal effects, blur-to-sharp transitions, staggered character animations, or motion typography.**

## When to Use

Use this skill when:

- Creating text reveal animations on page load
- Implementing staggered character-by-character effects
- Adding blur-to-focus transitions for headings or content
- Building hero section typography animations
- Creating subtle entrance animations for cards/sections
- Ensuring animations are accessible (respect `prefers-reduced-motion`)

## The Technique

This is a **pure CSS** blur-in animation technique that uses Tailwind CSS v4 custom theme properties and `@keyframes`. No JavaScript animation libraries are required.

### Two Animation Variants

| Class | Animation | Use Case |
|-------|-----------|----------|
| `animate-blur-in` | `blurIn` | Whole elements (cards, sections, paragraphs) |
| `animate-blur-in-char` | `blurInChar` | Individual characters in text |

---

## 1. Tailwind v4 Configuration

Add these custom properties to your `@theme` block in your CSS:

```css
@theme {
  --animate-blur-in: blurIn 0.3s ease-in;
  --animate-blur-in-char: blurInChar 0.3s ease-in;
}
```

### Keyframes

Define these in your global CSS:

```css
@keyframes blurIn {
  0% {
    opacity: 0;
    filter: blur(0.2em);
    transform: translateY(var(--offset, 0px));
  }
  to {
    opacity: 1;
    filter: blur(0);
    transform: translateY(0);
  }
}

@keyframes blurInChar {
  0% {
    filter: blur(0.3em);
    opacity: 0;
  }
  to {
    filter: blur(0);
    opacity: 1;
  }
}
```

---

## 2. Element-Level Animation (Sections, Cards, Paragraphs)

Use `animate-blur-in` for animating entire content blocks. Combine with inline `animation-delay` and `animation-fill-mode` for staggered reveals.

```html
<div class="animate-blur-in [animation-delay:1s] [animation-fill-mode:both]">
  <p>This entire block fades in with a blur-to-sharp effect.</p>
</div>
```

**Multiple elements with staggered timing:**

```html
<div class="animate-blur-in [animation-delay:1s] [animation-fill-mode:both]">
  First section
</div>
<div class="animate-blur-in [animation-delay:1.2s] [animation-fill-mode:both]">
  Second section
</div>
<div class="animate-blur-in [animation-delay:1.4s] [animation-fill-mode:both]">
  Third section
</div>
```

---

## 3. Character-Level Animation (Staggered Text Reveal)

Wrap each character in its own `<span>` with `display: inline-block` and incrementing `animation-delay` values.

```html
<h1 class="font-mono text-base font-medium">
  <span class="sr-only">Tim Wilson</span>
  <span aria-hidden="true">
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.2s; animation-fill-mode: both;">T</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.225s; animation-fill-mode: both;">i</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.25s; animation-fill-mode: both;">m</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.275s; animation-fill-mode: both;">&nbsp;</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.3s; animation-fill-mode: both;">W</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.325s; animation-fill-mode: both;">i</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.35s; animation-fill-mode: both;">l</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.375s; animation-fill-mode: both;">s</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.4s; animation-fill-mode: both;">o</span>
    <span class="animate-blur-in-char inline-block"
          style="animation-delay: 0.425s; animation-fill-mode: both;">n</span>
  </span>
</h1>
```

### Accessibility Note

Always include an `.sr-only` (screen reader only) span with the full text so screen readers get the complete string, not individual characters:

```html
<span class="sr-only">Full readable text here</span>
```

The `aria-hidden="true"` on the character wrapper prevents screen readers from announcing each letter individually.

---

## 4. React/JSX Implementation

### Helper Component for Character Splitting

```tsx
function BlurInText({ text, className = '', baseDelay = 0, step = 0.025 }: {
  text: string;
  className?: string;
  baseDelay?: number;
  step?: number;
}) {
  return (
    <span className={className}>
      <span className="sr-only">{text}</span>
      <span aria-hidden="true">
        {text.split('').map((char, i) => (
          <span
            key={i}
            className="animate-blur-in-char inline-block"
            style={{
              animationDelay: `${baseDelay + i * step}s`,
              animationFillMode: 'both',
            }}
          >
            {char === ' ' ? '\u00A0' : char}
          </span>
        ))}
      </span>
    </span>
  );
}

// Usage
<BlurInText text="Tim Wilson" baseDelay={0.2} step={0.025} />
```

### Staggered Section Reveal

```tsx
function BlurInSection({ children, delay = 0, className = '' }: {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}) {
  return (
    <div
      className={`animate-blur-in [animation-fill-mode:both] ${className}`}
      style={{ animationDelay: `${delay}s` }}
    >
      {children}
    </div>
  );
}

// Usage
<BlurInSection delay={1}>
  <h2>Links</h2>
</BlurInSection>
<BlurInSection delay={1.2}>
  <ul>...</ul>
</BlurInSection>
```

---

## 5. Accessibility: Respect `prefers-reduced-motion`

Always wrap animations in a `prefers-reduced-motion` media query or utility:

```css
@media (prefers-reduced-motion: reduce) {
  .animate-blur-in,
  .animate-blur-in-char {
    animation: none;
    opacity: 1;
    filter: none;
    transform: none;
  }
}
```

With Tailwind v4, you can use `motion-safe:` prefix:

```html
<div class="motion-safe:animate-blur-in [animation-delay:1s] [animation-fill-mode:both]">
  Content
</div>
```

---

## Key Technical Details

### `animation-fill-mode: both`

**Critical**: This ensures the element stays in the `0%` state before the animation starts (hidden/blurred) and the `100%` state after it ends (visible/sharp). Without this, elements may flash visible before animating.

### `filter: blur()` vs `filter: blur(0)`

`filter: blur()` (without a value) is equivalent to `blur(0px)` and is the standard way to remove a blur. This is what the animation transitions to.

### `display: inline-block` on characters

CSS `filter` and `transform` do not apply to plain `display: inline` elements. Each character span **must** be `inline-block` (or `block`) for the blur to work.

### `--offset` custom property on `blurIn`

The `blurIn` keyframe uses `translateY(var(--offset, 0px))`. You can customize this per element:

```html
<div class="animate-blur-in [animation-delay:1s] [animation-fill-mode:both]"
     style="--offset: 10px;">
  This slides up 10px while blurring in
</div>
```

---

## Common Mistakes

### Wrong: Forgetting `inline-block`

```html
<!-- ❌ filter won't apply -->
<span class="animate-blur-in-char">T</span>
```

```html
<!-- ✅ works correctly -->
<span class="animate-blur-in-char inline-block">T</span>
```

### Wrong: Missing `animation-fill-mode`

```html
<!-- ❌ element visible before animation starts -->
<span class="animate-blur-in-char inline-block"
      style="animation-delay: 0.2s;">T</span>
```

```html
<!-- ✅ stays hidden until animation begins -->
<span class="animate-blur-in-char inline-block"
      style="animation-delay: 0.2s; animation-fill-mode: both;">T</span>
```

### Wrong: No accessibility fallback

```html
<!-- ❌ screen readers announce "T... i... m..." -->
<span>
  <span class="animate-blur-in-char inline-block">T</span>
  <span class="animate-blur-in-char inline-block">i</span>
  <span class="animate-blur-in-char inline-block">m</span>
</span>
```

```html
<!-- ✅ screen readers get "Tim", visual users get animation -->
<span>
  <span class="sr-only">Tim</span>
  <span aria-hidden="true">
    <span class="animate-blur-in-char inline-block">T</span>
    <span class="animate-blur-in-char inline-block">i</span>
    <span class="animate-blur-in-char inline-block">m</span>
  </span>
</span>
```

### Wrong: Forgetting reduced motion support

```css
/* ❌ no respect for user preferences */
.animate-blur-in {
  animation: blurIn 0.3s ease-in;
}
```

```css
/* ✅ disables animation for users who prefer reduced motion */
@media (prefers-reduced-motion: reduce) {
  .animate-blur-in,
  .animate-blur-in-char {
    animation: none;
    opacity: 1;
    filter: none;
    transform: none;
  }
}
```

---

## Decision Tree

```
User asks about text animation
  |
  |-- Staggered character reveal?
  |   |-- Use `animate-blur-in-char` with inline-block spans
  |   |-- Add `sr-only` fallback for screen readers
  |   \-- Increment `animation-delay` by ~0.025s per character
  |
  |-- Section/element entrance?
  |   |-- Use `animate-blur-in` on the container
  |   |-- Set `animation-delay` per element for stagger
  |   \-- Add `animation-fill-mode: both`
  |
  |-- Typography motion design?
  |   |-- Combine `filter: blur()` with `opacity` and `transform`
  |   |-- Keep durations short (0.3s) for snappy feel
  |   \-- Use `ease-in` or `cubic-bezier` for organic motion
  |
  |-- Accessibility concern?
  |   |-- Add `prefers-reduced-motion` media query
  |   |-- Provide `sr-only` text for split characters
  |   \-- Use `aria-hidden` on decorative animation spans
  |
  \-- Performance concern?
      |-- Prefer CSS animations over JS libraries
      |-- Use `will-change: filter, opacity, transform` sparingly
      \-- Animate `transform` and `opacity` for GPU compositing
```

---

## Example Invocations

**User:** "How do I make text blur in on page load?"
→ Use `animate-blur-in` with `animation-fill-mode: both`

**User:** "I want a typewriter effect with blur"
→ Use `animate-blur-in-char` on individual spans with staggered `animation-delay`

**User:** "Should I use Framer Motion for this?"
→ For simple blur-in reveals, prefer CSS. Use Framer Motion only for complex choreography or scroll-triggered animations.

**User:** "How do I make it accessible?"
→ Add `sr-only` text, `aria-hidden` on animation spans, and `prefers-reduced-motion` support.

**User:** "Can I combine this with scroll-triggered animations?"
→ Yes, but use `animation-play-state: paused` initially and toggle to `running` via Intersection Observer or a library like Framer Motion.
