# Brand Direction Presentation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate a single-file HTML presentation from the "From Alignment to Direction" brand brief — 8 sections, ~5 minute read, visual-forward.

**Architecture:** Single `output/from-alignment-to-direction.html` file following template.html patterns. All CSS/JS inline. Images base64-encoded. No D3 charts needed — this presentation uses metric cards, tables, callouts, figures, and custom color swatch/typography specimen components.

**Tech Stack:** HTML, CSS (custom properties from template.html), vanilla JS (IntersectionObserver, TOC, theme toggle). No D3 needed.

**Spec:** `docs/superpowers/specs/2026-03-12-brand-direction-presentation-design.md`

**Critical design note:** The presentation itself uses the Presenter system's editorial B&W design language (template.html). The brand's sage/blush/lavender palette and Outfit typeface appear ONLY as rendered specimens within Section 5 — they are content being shown, not the presentation's own styling.

---

## Chunk 1: Complete Presentation

This is a single-file deliverable — one task that builds the full presentation.

### Task 1: Build the presentation HTML

**Files:**
- Create: `output/from-alignment-to-direction.html`
- Reference: `template.html` (CSS variables, component patterns, JS patterns)
- Assets: `assets/earnwise_v01/*.png` (base64-encode inline)

- [ ] **Step 1: Create the HTML file with full CSS foundation**

Copy the CSS foundation from template.html:
- All `:root` custom properties (light mode)
- `@media (prefers-color-scheme: dark)` block
- `html.dark` block
- `html.light` block
- Base reset (`*, *::before, *::after`)
- Body styles (background gradients, texture)
- Typography (h1-h4, p, ul/ol, strong)
- `.theme-toggle`, `.toc`, `.toc__*` styles
- `.hero`, `.hero__*` styles
- `.section`, `.section--panel`, `.section--wide`, `.section__*` styles
- `.callout` styles
- `.metric-card`, `.metrics` styles
- `.comparison`, `.comparison__*` styles
- `.figure`, `.figure__*`, `.caption` styles
- `[data-animate]` styles
- `.tooltip` styles
- All responsive breakpoints (`@media max-width: 1120px/900px/720px`)
- `@media (prefers-reduced-motion: reduce)` block

Add new component styles for this presentation:
- `.alignment-cards` — 4-column grid of compact cards (Section 2)
- `.swatch-row` — horizontal layout for color swatches (Section 5)
- `.swatch` — individual color circle + label
- `.type-specimen` — typography showcase block (Section 5)
- `.voice-table` — styled comparison table for voice examples (Section 6)
- `.feedback-grid` — the 5-dimension scale layout (Section 8)
- `.screen-grid` — responsive grid for onboarding screenshots (Section 7)
- `.data-table` — from template, for the values→visual bridge table (Section 4)

Title: `From Alignment to Direction`

- [ ] **Step 2: Add the HTML body — navigation and hero (Sections 1-2)**

**TOC + Theme toggle:**
```html
<button class="toc__toggle" id="toc-toggle" aria-label="Toggle table of contents">Menu</button>
<button class="theme-toggle" id="theme-toggle" aria-label="Toggle theme">Theme</button>
<nav class="toc" id="toc">
  <div class="toc__brand">
    <div class="toc__kicker">Brand Direction</div>
    <div class="toc__title">From Alignment to Direction</div>
    <p class="toc__subtitle">~5 min read</p>
  </div>
  <ul class="toc__list"></ul>
</nav>
<div class="toc-backdrop" id="toc-backdrop"></div>
```

**Section 1 — Hero:**
- `hero__meta`: "March 2026 · Design Team"
- `hero__title`: "From Alignment to Direction"
- `hero__subtitle`: "We aligned on who we're building for and what we stand for. This is what those decisions look like."
- `hero__aside`: Brief reading guide — "~5 min read. Feedback requested at the end. Think compass, not GPS."

**Section 2 — What We Aligned On:**
- `section` with eyebrow "Recap"
- `h2`: "What We Aligned On"
- Four `.alignment-cards` in a grid:
  - Card 1: "Who" → "Smart Earners, 40–65. Designed for her, welcoming to all."
  - Card 2: "What we stand for" → "Simplicity · Reliability · Valuable"
  - Card 3: "What we're not" → "Confusing · Spammy · Cold"
  - Card 4: "How we communicate" → "Encouraging · Real dollars · Soft & rounded"

- [ ] **Step 3: Add Sections 3-4 (Who She Is + Values to Visual)**

**Section 3 — Who She Is:**
- `section` with eyebrow "Audience"
- `h2`: "Who She Is"
- Two metric cards: "65%" (finances as top stressor) and "37%" (can't cover $400 emergency)
- Summary paragraph: "She's not desperate — she's cautious. She wants small, reliable ways to stretch the household budget. $50 a month — a tank of gas, a week of groceries."
- Callout: The "Being Seen" Insight — "This audience feels invisible in much of their daily life. Undervalued at work. Overlooked by products built for younger demographics. Our opportunity: make her feel recognized, valued, and smart for what she does. That's why she stays — and why she tells a friend."
- Short trust line: "She deletes anything scammy within 30 seconds. Trust isn't a feature — it's the baseline."

**Section 4 — From Values to Visual:**
- `section` with eyebrow "The Bridge"
- `h2`: "From Values to Visual"
- Lede: "Our alignment decisions already answered most of the design questions. We just had to follow them."
- `data-table` with two columns: "Because we said…" and "The direction…"
- 7 rows mapping alignment decisions to design direction (from spec)

- [ ] **Step 4: Add Section 5 (The Design Direction — palette, type, illustration)**

**Section 5 — The Design Direction:**
- `section section--wide` with eyebrow "Direction"
- `h2`: "The Design Direction"

**Palette subsection:**
- `h3`: "The Palette"
- Brief intro: "Colors needed to say 'safe and real' — not 'startup' and not 'coupon app.'"
- `.swatch-row` with color circles:
  - Sage green (#7C9A82) — "Trust, calm, growth"
  - Blush (#E8B4B8) — "Warmth and softness"
  - Lavender (#B8A9C9) — "Personality without tipping into gendered"
  - Warm cream (#F5F0E8) — "Paper, not screen"
- Caption: "Nothing shouts. Nothing competes for attention. The only thing that pops is the dollar amount."

**Typography subsection:**
- `h3`: "The Typography"
- Load Outfit from Google Fonts CDN (inline `@import` in style block)
- `.type-specimen` block showing:
  - "Your Grocery Fund" at headline size in Outfit
  - "$47.20" at large display size in Outfit (the largest element)
  - "earned this month" at body size in Outfit
- Caption: "Outfit — rounded enough to feel friendly, structured enough to make dollar amounts feel real. The type does the work so the design doesn't have to be loud."

**Illustration subsection:**
- `h3`: "The Illustration Style"
- Brief intro about continuous-line style
- Three illustration images in a row (from assets, base64-encoded):
  - `wallet.png` with caption "Calm — task moments"
  - `surveys.png` with caption "Calm — everyday actions"
  - `jar.png` with caption "Dynamic — reward moments"
- Caption: "Continuous-line illustrations in deep sage with watercolor washes. No faces — hands and silhouettes only. Two energy levels: calm for tasks, dynamic for rewards."

- [ ] **Step 5: Add Sections 6-7 (Voice + See It Together)**

**Section 6 — The Voice:**
- `section` with eyebrow "Tone"
- `h2`: "How We Talk"
- Lede: "State what happened, state the value, move on. No hype. No fake urgency."
- `.voice-table` — styled comparison table with columns: Moment, Our voice, Not our voice
  - 4 rows: First earning, Balance, Cashout, Re-engagement
  - "Our voice" column styled normally
  - "Not our voice" column styled with reduced opacity / strikethrough feel
- Callout with earnings rule: "Never let her do the math. Anchor to real expenses. Lead with cumulative totals. Frame time as context, not labor."

**Section 7 — See It Together:**
- `section section--wide` with eyebrow "In Context"
- `h2`: "See It Together"
- Lede: "Don't analyze individual screens — just notice how it feels."
- `.screen-grid` — 5 onboarding screenshots in a responsive grid (base64-encoded from assets):
  - `01_Start.png`
  - `02_Info.png`
  - `03_Questionnaire.png`
  - `04_First Task.png`
  - `05_Home.png`
- Each in a figure with rounded corners and subtle shadow
- Below: styled link to prototype — `<a href="../assets/earnwise_v01/onboarding.html">Open clickable prototype →</a>`

- [ ] **Step 6: Add Section 8 (Feedback + Next Steps)**

**Section 8 — Your Feedback + Next Steps:**
- `section` with eyebrow "Feedback"
- `h2`: "Your Feedback"
- Lede: "We're not looking for detailed notes. We want to know: does this direction feel right?"
- `.feedback-grid` — 5 rows, each with:
  - Dimension label (Warmth, Professionalism, Playfulness, Trust, Energy)
  - Left anchor text ("Too cozy / soft", etc.)
  - Visual scale (5 empty circles in a row, center one slightly emphasized)
  - Right anchor text ("Too cold / clinical", etc.)
- Open question callout: "If you had to describe how this app feels in 3 words, what would they be?"

**Next Steps subsection:**
- `h3`: "What's Next"
- Two items:
  - "Direction refinement based on your feedback from this session"
  - "Name & tagline brainstorm — a separate session, informed by this feedback"

- [ ] **Step 7: Add JavaScript**

Copy JS patterns from template.html:
- `reduceMotionEnabled()`, `motionDuration()`, `token()` utility functions
- IntersectionObserver for `[data-animate]` elements
- TOC auto-generation from h2 elements + scroll tracking + active state
- TOC mobile toggle (open/close with backdrop)
- Theme toggle (dark/light with localStorage persistence)

No D3 charts or simulator JS needed.

- [ ] **Step 8: Base64-encode all images**

Run a script to read each PNG from `assets/earnwise_v01/` and replace the `src` attributes with `data:image/png;base64,...` encoded strings. Files to encode:
- `assets/earnwise_v01/wallet.png`
- `assets/earnwise_v01/jar.png`
- `assets/earnwise_v01/surveys.png`
- `assets/earnwise_v01/01_Start.png`
- `assets/earnwise_v01/02_Info.png`
- `assets/earnwise_v01/03_Questionnaire.png`
- `assets/earnwise_v01/04_First Task.png`
- `assets/earnwise_v01/05_Home.png`

- [ ] **Step 9: Visual review and polish**

Open the file in a browser and verify:
- All 8 sections render correctly
- TOC generates and tracks scroll position
- Theme toggle works
- Scroll animations fire
- Images display correctly
- Responsive layout works at tablet width
- Color swatches render the brand palette accurately
- Typography specimen shows Outfit correctly
- Feedback grid is readable and clear

- [ ] **Step 10: Commit**

```bash
git add output/from-alignment-to-direction.html
git commit -m "feat: add brand direction presentation"
```
