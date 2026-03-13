# Presenter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a reference HTML template and CLAUDE.md instructions that enable Claude Code to generate self-contained, interactive HTML presentations from concept documents.

**Architecture:** Single reference template file (`template.html`) demonstrating all components with a fictional "Q3 Product Strategy" concept. CLAUDE.md provides the generation workflow. All CSS/JS inline, D3.js from CDN. Black & white design language, purposeful animations only.

**Tech Stack:** HTML5, CSS (inline), JavaScript (inline), D3.js v7 (CDN)

**Design doc:** `docs/plans/2026-03-05-presenter-design.md`

---

### Task 1: HTML Skeleton + CSS Foundation

**Files:**
- Create: `template.html`

**Step 1: Create the HTML file with base structure and CSS variables**

Create `template.html` with:
- DOCTYPE, html lang="en", meta viewport, meta charset
- `<title>` set to "Q3 Product Strategy -- Presenter"
- D3.js v7 loaded from CDN: `https://d3js.org/d3.v7.min.js`
- `<style>` block containing:
  - CSS custom properties on `:root` for the full color palette:
    - `--ink: #111`, `--ink-light: #666`, `--ink-faint: #999`
    - `--surface: #fff`, `--surface-alt: #f7f7f7`
    - `--border: #e0e0e0`, `--accent: #111`
    - `--content-width: 720px`, `--wide-width: 960px`
    - `--section-gap: 96px`
  - CSS reset: `*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }`
  - `html { scroll-behavior: smooth; font-size: 18px; }`
  - `body` with system font stack, `color: var(--ink)`, `background: var(--surface)`, `line-height: 1.6`
  - `.section` with `padding: var(--section-gap) 24px`, `max-width: var(--content-width)`, `margin: 0 auto`
  - `.section--wide` overriding `max-width: var(--wide-width)`
  - `.section--alt` with `background: var(--surface-alt)` -- this one needs full bleed so it gets `max-width: none` and an inner container
  - Typography: `h1` through `h4` with tight `letter-spacing: -0.02em`, appropriate sizes (h1: 3rem, h2: 2rem, h3: 1.4rem, h4: 1.1rem), `margin-bottom: 0.5em`
  - `p { margin-bottom: 1em; }`, `ul, ol { margin-bottom: 1em; padding-left: 1.5em; }`
  - `prefers-reduced-motion` media query: `* { animation-duration: 0s !important; transition-duration: 0s !important; }`
- Empty `<body>` with a comment `<!-- Components will be added in subsequent tasks -->`

**Step 2: Verify the file is valid**

Run: `open template.html` (macOS) to confirm it opens as a blank white page with no console errors.

**Step 3: Commit**

```bash
git add template.html
git commit -m "feat: add HTML skeleton with CSS design tokens and base styles"
```

---

### Task 2: Hero / Title Block + Narrative Section

**Files:**
- Modify: `template.html`

**Step 1: Add the Hero component**

Inside `<body>`, add a hero section:

```html
<header class="hero">
  <p class="hero__meta">March 2026 &middot; Product Team</p>
  <h1 class="hero__title">Q3 Product Strategy</h1>
  <p class="hero__subtitle">Scaling our core platform while expanding into enterprise segments</p>
</header>
```

Add CSS for `.hero`:
- `text-align: center`, `padding: 120px 24px 80px`
- `.hero__meta`: `font-size: 0.75rem`, `text-transform: uppercase`, `letter-spacing: 0.1em`, `color: var(--ink-faint)`, `margin-bottom: 16px`
- `.hero__title`: `font-size: 3.5rem`, `letter-spacing: -0.03em`, `line-height: 1.1`, `margin-bottom: 16px`
- `.hero__subtitle`: `font-size: 1.25rem`, `color: var(--ink-light)`, `max-width: 600px`, `margin: 0 auto`

**Step 2: Add the Narrative section**

After the hero, add a narrative section demonstrating all text elements:

```html
<section class="section" id="overview">
  <h2>Strategic Overview</h2>
  <p>Our platform has reached a critical inflection point. With <strong>12,000 active teams</strong> and accelerating growth in the mid-market segment, we're positioned to capture the enterprise opportunity without sacrificing our core product simplicity.</p>
  <p>This document outlines our three-pronged approach for Q3: deepening platform capabilities, expanding our go-to-market motion, and investing in the infrastructure that will support our next phase of growth.</p>

  <div class="callout">
    <p><strong>Key Insight:</strong> Enterprise prospects consistently cite our ease of onboarding as the primary differentiator. Any enterprise features must preserve this advantage.</p>
  </div>

  <h3>Guiding Principles</h3>
  <ul>
    <li>Ship incrementally -- no quarter-long feature bets</li>
    <li>Measure adoption within 2 weeks of launch</li>
    <li>Enterprise features must benefit all tiers</li>
    <li>Maintain sub-200ms p95 response times</li>
  </ul>
</section>
```

Add CSS for `.callout`:
- `border-left: 3px solid var(--ink)`, `padding: 16px 24px`, `margin: 24px 0`, `background: var(--surface-alt)`

**Step 3: Verify visually**

Run: `open template.html`
Expected: Clean hero with centered title, narrative section with readable text and a callout box.

**Step 4: Commit**

```bash
git add template.html
git commit -m "feat: add hero title block and narrative section components"
```

---

### Task 3: Metric Cards

**Files:**
- Modify: `template.html`

**Step 1: Add Metric Cards section**

After the narrative section:

```html
<section class="section section--wide" id="metrics">
  <h2>Key Metrics</h2>
  <div class="metrics">
    <div class="metric-card" data-animate>
      <span class="metric-card__trend metric-card__trend--up">&#9650;</span>
      <span class="metric-card__value" data-count="12000">12,000</span>
      <span class="metric-card__label">Active Teams</span>
    </div>
    <div class="metric-card" data-animate>
      <span class="metric-card__trend metric-card__trend--up">&#9650;</span>
      <span class="metric-card__value" data-count="2.4">$2.4M</span>
      <span class="metric-card__label">Monthly Recurring Revenue</span>
    </div>
    <div class="metric-card" data-animate>
      <span class="metric-card__trend metric-card__trend--up">&#9650;</span>
      <span class="metric-card__value" data-count="94">94%</span>
      <span class="metric-card__label">30-Day Retention</span>
    </div>
    <div class="metric-card" data-animate>
      <span class="metric-card__trend metric-card__trend--down">&#9660;</span>
      <span class="metric-card__value" data-count="142">142ms</span>
      <span class="metric-card__label">P95 Response Time</span>
    </div>
  </div>
</section>
```

Add CSS for metrics:
- `.metrics`: `display: grid`, `grid-template-columns: repeat(auto-fit, minmax(180px, 1fr))`, `gap: 24px`, `margin-top: 32px`
- `.metric-card`: `border: 1px solid var(--border)`, `padding: 32px 24px`, `text-align: center`, `transition: transform 0.2s, box-shadow 0.2s`
- `.metric-card:hover`: `transform: scale(1.02)`, `box-shadow: 0 4px 24px rgba(0,0,0,0.08)`
- `.metric-card__value`: `display: block`, `font-size: 2.5rem`, `font-weight: 700`, `letter-spacing: -0.02em`, `line-height: 1.2`
- `.metric-card__label`: `display: block`, `font-size: 0.8rem`, `color: var(--ink-light)`, `margin-top: 8px`, `text-transform: uppercase`, `letter-spacing: 0.05em`
- `.metric-card__trend`: `font-size: 0.75rem`, `display: block`, `margin-bottom: 4px`
- `.metric-card__trend--up`: `color: var(--ink)`
- `.metric-card__trend--down`: `color: var(--ink-faint)`

**Step 2: Verify visually**

Run: `open template.html`
Expected: Four metric cards in a responsive grid with hover lift effect.

**Step 3: Commit**

```bash
git add template.html
git commit -m "feat: add metric cards component with hover interaction"
```

---

### Task 4: D3.js Data Visualizations

**Files:**
- Modify: `template.html`

**Step 1: Add a bar chart section**

After metrics, add a section with a container for D3:

```html
<section class="section section--wide section--alt-wrap" id="growth">
  <div class="section--alt-inner">
    <h2>Revenue Growth by Segment</h2>
    <p>Enterprise segment showing strongest acceleration, validating our expansion thesis.</p>
    <div class="chart-container" id="bar-chart"></div>
  </div>
</section>
```

CSS for chart containers and alt-wrap:
- `.section--alt-wrap`: `background: var(--surface-alt)`, `padding: var(--section-gap) 0`
- `.section--alt-inner`: `max-width: var(--wide-width)`, `margin: 0 auto`, `padding: 0 24px`
- `.chart-container`: `width: 100%`, `margin-top: 32px`, `position: relative`
- `.chart-container svg`: `width: 100%`, `height: auto`

In the `<script>` block, add a function that renders a horizontal bar chart using D3:
- Data: `[{label: "Startup", value: 680}, {label: "Mid-Market", value: 1120}, {label: "Enterprise", value: 540}, {label: "Self-Serve", value: 60}]`
- SVG dimensions: viewBox-based (responsive), ~500px tall
- Horizontal bars with `fill: var(--ink)` (use `getComputedStyle` to read CSS variable)
- Y-axis: category labels in system font
- X-axis: value labels
- Bars should have opacity variation (0.6 to 1.0) for visual depth
- Hover: bar opacity changes, tooltip appears showing exact value
- Use IntersectionObserver to animate bars growing from 0 width on first view

**Step 2: Add a line chart section**

```html
<section class="section section--wide" id="trajectory">
  <h2>User Growth Trajectory</h2>
  <p>Projecting continued acceleration through Q3 based on current pipeline and conversion improvements.</p>
  <div class="chart-container" id="line-chart"></div>
</section>
```

D3 line chart:
- Data: monthly user counts for 12 months (mix of actual + projected)
- Solid line for actual data, dashed line for projected
- Area fill under actual line with light gray (`rgba(17,17,17,0.05)`)
- X-axis: month labels, Y-axis: user count
- Dots on each data point, tooltip on hover with exact value
- Animate: line draws from left to right on scroll into view using stroke-dasharray technique

**Step 3: Add a donut chart section**

```html
<section class="section section--wide section--alt-wrap" id="allocation">
  <div class="section--alt-inner">
    <h2>Engineering Allocation</h2>
    <p>Proposed engineering investment split for Q3.</p>
    <div class="chart-container" id="donut-chart"></div>
  </div>
</section>
```

D3 donut chart:
- Data: `[{label: "Core Platform", value: 40}, {label: "Enterprise Features", value: 25}, {label: "Infrastructure", value: 20}, {label: "Tech Debt", value: 15}]`
- Grayscale fills: `#111`, `#444`, `#777`, `#aaa`
- Labels outside the donut with leader lines
- Hover: segment scales slightly outward, tooltip with percentage
- Animate: arcs grow from 0 angle on scroll into view

**Step 4: Add a styled table**

Within the allocation section or a new section:

```html
<section class="section" id="timeline-table">
  <h2>Q3 Milestone Timeline</h2>
  <div class="table-wrap">
    <table class="data-table">
      <thead>
        <tr><th>Milestone</th><th>Target</th><th>Owner</th><th>Status</th></tr>
      </thead>
      <tbody>
        <tr><td>SSO Integration</td><td>July 15</td><td>Platform Team</td><td>In Progress</td></tr>
        <tr><td>Audit Logging</td><td>Aug 1</td><td>Security Team</td><td>Planning</td></tr>
        <tr><td>Advanced Analytics</td><td>Aug 15</td><td>Data Team</td><td>Planning</td></tr>
        <tr><td>Custom Roles</td><td>Sep 1</td><td>Platform Team</td><td>Not Started</td></tr>
        <tr><td>Enterprise Onboarding</td><td>Sep 15</td><td>Growth Team</td><td>Not Started</td></tr>
      </tbody>
    </table>
  </div>
</section>
```

CSS for `.data-table`:
- `width: 100%`, `border-collapse: collapse`
- `th`: `text-align: left`, `padding: 12px 16px`, `border-bottom: 2px solid var(--ink)`, `font-size: 0.75rem`, `text-transform: uppercase`, `letter-spacing: 0.05em`
- `td`: `padding: 12px 16px`, `border-bottom: 1px solid var(--border)`
- `tbody tr:nth-child(even)`: `background: var(--surface-alt)`
- `.table-wrap`: `overflow-x: auto` for mobile

**Step 5: Verify all charts render**

Run: `open template.html`
Expected: Bar chart, line chart, donut chart all render in monochrome. Table displays with alternating rows. Hovering shows tooltips.

**Step 6: Commit**

```bash
git add template.html
git commit -m "feat: add D3.js bar, line, donut charts and styled table"
```

---

### Task 5: Flow Diagrams + Timeline

**Files:**
- Modify: `template.html`

**Step 1: Add a process flow**

```html
<section class="section section--wide" id="process">
  <h2>Go-to-Market Process</h2>
  <p>Our refined enterprise sales motion, from first touch to expansion.</p>
  <div class="flow">
    <div class="flow__step" data-animate>
      <div class="flow__icon">1</div>
      <div class="flow__content">
        <strong>Inbound Lead</strong>
        <span>Website, referral, or content</span>
      </div>
    </div>
    <div class="flow__arrow">&rarr;</div>
    <div class="flow__step" data-animate>
      <div class="flow__icon">2</div>
      <div class="flow__content">
        <strong>Product Trial</strong>
        <span>14-day guided experience</span>
      </div>
    </div>
    <div class="flow__arrow">&rarr;</div>
    <div class="flow__step" data-animate>
      <div class="flow__icon">3</div>
      <div class="flow__content">
        <strong>Sales Engagement</strong>
        <span>Demo + technical review</span>
      </div>
    </div>
    <div class="flow__arrow">&rarr;</div>
    <div class="flow__step" data-animate>
      <div class="flow__icon">4</div>
      <div class="flow__content">
        <strong>Contract</strong>
        <span>Annual commitment</span>
      </div>
    </div>
    <div class="flow__arrow">&rarr;</div>
    <div class="flow__step" data-animate>
      <div class="flow__icon">5</div>
      <div class="flow__content">
        <strong>Expansion</strong>
        <span>Upsell + referrals</span>
      </div>
    </div>
  </div>
</section>
```

CSS for `.flow`:
- `display: flex`, `align-items: center`, `gap: 8px`, `margin-top: 32px`, `flex-wrap: wrap`, `justify-content: center`
- `.flow__step`: `border: 1px solid var(--border)`, `padding: 24px 20px`, `text-align: center`, `flex: 0 1 160px`
- `.flow__icon`: `width: 32px`, `height: 32px`, `border-radius: 50%`, `background: var(--ink)`, `color: var(--surface)`, `display: inline-flex`, `align-items: center`, `justify-content: center`, `font-size: 0.8rem`, `font-weight: 700`, `margin: 0 auto 12px`
- `.flow__content strong`: `display: block`, `margin-bottom: 4px`
- `.flow__content span`: `font-size: 0.8rem`, `color: var(--ink-light)`
- `.flow__arrow`: `color: var(--ink-faint)`, `font-size: 1.5rem`
- On mobile (`max-width: 640px`): flow goes vertical, arrows rotate to `↓`

**Step 2: Add a vertical timeline**

```html
<section class="section" id="roadmap">
  <h2>Q3 Roadmap</h2>
  <div class="timeline">
    <div class="timeline__item" data-animate>
      <div class="timeline__date">July</div>
      <div class="timeline__content">
        <strong>Foundation Phase</strong>
        <p>SSO integration, audit logging infrastructure, enterprise trial flow.</p>
      </div>
    </div>
    <div class="timeline__item" data-animate>
      <div class="timeline__date">August</div>
      <div class="timeline__content">
        <strong>Build Phase</strong>
        <p>Advanced analytics dashboard, custom roles and permissions, API rate limiting.</p>
      </div>
    </div>
    <div class="timeline__item" data-animate>
      <div class="timeline__date">September</div>
      <div class="timeline__content">
        <strong>Launch Phase</strong>
        <p>Enterprise onboarding experience, dedicated support tier, case study publication.</p>
      </div>
    </div>
  </div>
</section>
```

CSS for `.timeline`:
- `position: relative`, `margin-top: 32px`, `padding-left: 40px`
- `::before` pseudo-element: vertical line `left: 8px`, `width: 2px`, `background: var(--border)`, full height
- `.timeline__item`: `position: relative`, `margin-bottom: 48px`
- `.timeline__item::before`: circle dot at `left: -40px`, `width: 16px`, `height: 16px`, `border-radius: 50%`, `border: 2px solid var(--ink)`, `background: var(--surface)`
- `.timeline__date`: `font-size: 0.75rem`, `text-transform: uppercase`, `letter-spacing: 0.1em`, `color: var(--ink-faint)`, `margin-bottom: 4px`
- `.timeline__content strong`: `display: block`, `margin-bottom: 4px`
- `.timeline__content p`: `color: var(--ink-light)`, `font-size: 0.95rem`

**Step 3: Verify visually**

Run: `open template.html`
Expected: Horizontal process flow with numbered steps and arrows. Vertical timeline with dots and connecting line.

**Step 4: Commit**

```bash
git add template.html
git commit -m "feat: add process flow and vertical timeline components"
```

---

### Task 6: Image/Media Blocks + Comparison Layout

**Files:**
- Modify: `template.html`

**Step 1: Add image and comparison components**

```html
<section class="section section--wide" id="comparison">
  <h2>Current vs. Proposed Architecture</h2>
  <div class="comparison">
    <div class="comparison__panel">
      <h4>Current</h4>
      <div class="comparison__placeholder">
        <svg viewBox="0 0 400 250" xmlns="http://www.w3.org/2000/svg">
          <!-- Simple architecture diagram: monolith -->
          <rect x="100" y="20" width="200" height="210" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="200" y="70" text-anchor="middle" font-size="14" fill="#111" font-weight="bold">Monolith</text>
          <line x1="120" y1="90" x2="280" y2="90" stroke="#e0e0e0"/>
          <text x="200" y="115" text-anchor="middle" font-size="12" fill="#666">API + Auth + Data</text>
          <text x="200" y="140" text-anchor="middle" font-size="12" fill="#666">Processing</text>
          <text x="200" y="165" text-anchor="middle" font-size="12" fill="#666">Storage</text>
          <text x="200" y="205" text-anchor="middle" font-size="11" fill="#999">Single deployment</text>
        </svg>
      </div>
    </div>
    <div class="comparison__panel">
      <h4>Proposed</h4>
      <div class="comparison__placeholder">
        <svg viewBox="0 0 400 250" xmlns="http://www.w3.org/2000/svg">
          <!-- Simple architecture diagram: services -->
          <rect x="20" y="20" width="110" height="70" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="75" y="60" text-anchor="middle" font-size="12" fill="#111">API Gateway</text>
          <rect x="150" y="20" width="110" height="70" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="205" y="60" text-anchor="middle" font-size="12" fill="#111">Auth Service</text>
          <rect x="280" y="20" width="110" height="70" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="335" y="60" text-anchor="middle" font-size="12" fill="#111">Analytics</text>
          <rect x="85" y="130" width="110" height="70" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="140" y="170" text-anchor="middle" font-size="12" fill="#111">Core Platform</text>
          <rect x="215" y="130" width="110" height="70" rx="4" fill="none" stroke="#111" stroke-width="2"/>
          <text x="270" y="170" text-anchor="middle" font-size="12" fill="#111">Data Store</text>
          <!-- Connection lines -->
          <line x1="75" y1="90" x2="140" y2="130" stroke="#999" stroke-width="1"/>
          <line x1="205" y1="90" x2="140" y2="130" stroke="#999" stroke-width="1"/>
          <line x1="335" y1="90" x2="270" y2="130" stroke="#999" stroke-width="1"/>
          <line x1="195" y1="165" x2="215" y2="165" stroke="#999" stroke-width="1"/>
          <text x="200" y="230" text-anchor="middle" font-size="11" fill="#999">Independent services</text>
        </svg>
      </div>
    </div>
  </div>
  <p class="caption">Side-by-side comparison of current monolithic architecture versus proposed service-oriented approach.</p>
</section>
```

CSS:
- `.comparison`: `display: grid`, `grid-template-columns: 1fr 1fr`, `gap: 32px`, `margin-top: 32px`
- `.comparison__panel`: `border: 1px solid var(--border)`, `padding: 24px`
- `.comparison__panel h4`: `margin-bottom: 16px`, `text-align: center`
- `.comparison__placeholder svg`: `width: 100%`, `height: auto`
- `.caption`: `font-size: 0.8rem`, `color: var(--ink-faint)`, `text-align: center`, `margin-top: 16px`, `font-style: italic`
- On mobile (`max-width: 640px`): `grid-template-columns: 1fr`

**Step 2: Add a full-width image placeholder**

```html
<section class="section" id="mockup">
  <h2>Proposed Dashboard Redesign</h2>
  <figure class="figure">
    <div class="figure__placeholder" style="aspect-ratio: 16/9; background: var(--surface-alt); border: 1px solid var(--border); display: flex; align-items: center; justify-content: center;">
      <span style="color: var(--ink-faint); font-size: 0.9rem;">Image: dashboard-mockup.png</span>
    </div>
    <figcaption class="caption">Early wireframe of the enterprise analytics dashboard showing team-level insights.</figcaption>
  </figure>
</section>
```

CSS for `.figure`:
- `margin-top: 32px`
- `figcaption` inherits `.caption` styles

**Step 3: Verify visually**

Run: `open template.html`
Expected: Side-by-side SVG architecture diagrams and an image placeholder with caption.

**Step 4: Commit**

```bash
git add template.html
git commit -m "feat: add comparison layout, SVG diagrams, and image placeholder"
```

---

### Task 7: Sticky Table of Contents

**Files:**
- Modify: `template.html`

**Step 1: Add TOC HTML structure**

Add before the hero (first child of body):

```html
<nav class="toc" id="toc">
  <button class="toc__toggle" aria-label="Toggle table of contents">&#9776;</button>
  <ul class="toc__list">
    <!-- JS will populate this from h2 elements -->
  </ul>
</nav>
```

Also add a wrapping `<main class="content">` around all sections (hero through last section) so we can offset for the TOC.

**Step 2: Add TOC CSS**

```css
.toc {
  position: fixed;
  top: 0;
  left: 0;
  width: 220px;
  height: 100vh;
  padding: 32px 16px;
  border-right: 1px solid var(--border);
  background: var(--surface);
  overflow-y: auto;
  z-index: 100;
  transition: transform 0.3s;
}
.toc__toggle {
  display: none;
  background: none;
  border: 1px solid var(--border);
  padding: 8px 12px;
  cursor: pointer;
  font-size: 1.2rem;
  position: fixed;
  top: 16px;
  left: 16px;
  z-index: 101;
  background: var(--surface);
}
.toc__list {
  list-style: none;
  padding: 0;
  margin-top: 16px;
}
.toc__list li {
  margin-bottom: 8px;
}
.toc__list a {
  color: var(--ink-light);
  text-decoration: none;
  font-size: 0.8rem;
  display: block;
  padding: 4px 8px;
  border-left: 2px solid transparent;
  transition: color 0.2s, border-color 0.2s;
}
.toc__list a:hover {
  color: var(--ink);
}
.toc__list a.active {
  color: var(--ink);
  border-left-color: var(--ink);
  font-weight: 600;
}
.content {
  margin-left: 220px;
}

/* Mobile: collapsible TOC */
@media (max-width: 768px) {
  .toc {
    transform: translateX(-100%);
    width: 260px;
  }
  .toc.open {
    transform: translateX(0);
  }
  .toc__toggle {
    display: block;
  }
  .content {
    margin-left: 0;
  }
}
```

**Step 3: Add TOC JavaScript**

In the `<script>` block, add:
- Auto-populate TOC from all `h2` elements (get their `id` and `textContent`)
- IntersectionObserver watching all sections -- when a section enters the viewport, mark its TOC link as `.active`
- Toggle button click handler for mobile (toggles `.open` on `.toc`)
- Click any TOC link on mobile closes the menu

**Step 4: Verify**

Run: `open template.html`
Expected: Fixed left sidebar with section links. Current section highlighted as you scroll. On narrow window, sidebar collapses and hamburger button appears.

**Step 5: Commit**

```bash
git add template.html
git commit -m "feat: add sticky table of contents with scroll tracking"
```

---

### Task 8: Scroll Animations + Tooltip System

**Files:**
- Modify: `template.html`

**Step 1: Add scroll animation CSS**

```css
[data-animate] {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.5s ease, transform 0.5s ease;
}
[data-animate].visible {
  opacity: 1;
  transform: translateY(0);
}
```

**Step 2: Add `data-animate` attributes**

Add `data-animate` to all major content blocks that should animate in:
- Each `.metric-card` (already has it)
- Each `.flow__step` (already has it)
- Each `.timeline__item` (already has it)
- `.chart-container` elements
- `.callout` elements
- `.comparison` element
- `.figure` element

**Step 3: Add scroll animation JavaScript**

IntersectionObserver with `threshold: 0.1`:
- When element enters viewport, add `.visible` class
- For groups (metric cards, flow steps), stagger with `transitionDelay` (index * 100ms)
- `once: true` -- only animate on first appearance (unobserve after)

**Step 4: Add tooltip system**

CSS for tooltips (used by D3 charts):
```css
.tooltip {
  position: fixed;
  background: var(--ink);
  color: var(--surface);
  padding: 8px 12px;
  font-size: 0.75rem;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.15s;
  z-index: 200;
  max-width: 200px;
  line-height: 1.4;
}
.tooltip.visible {
  opacity: 1;
}
```

Add a single `<div class="tooltip" id="tooltip"></div>` to the body.

JS: helper functions `showTooltip(event, html)` and `hideTooltip()` that position and show/hide the tooltip div based on mouse coordinates. Used by D3 chart hover handlers.

**Step 5: Verify**

Run: `open template.html`
Expected: Elements fade/slide in as you scroll. Chart hover shows tooltips. Metric cards stagger in.

**Step 6: Commit**

```bash
git add template.html
git commit -m "feat: add scroll-triggered animations and tooltip system"
```

---

### Task 9: Custom Bespoke Visualization Example

**Files:**
- Modify: `template.html`

**Step 1: Add a custom interactive visualization**

Add a section demonstrating a bespoke visualization -- an interactive "impact simulator" that shows how changing a variable affects outcomes. This demonstrates the "floor not ceiling" principle.

```html
<section class="section section--wide" id="impact">
  <h2>Growth Lever Impact</h2>
  <p>Adjust the levers below to see projected impact on ARR by end of Q3.</p>
  <div class="simulator" id="simulator">
    <div class="simulator__controls">
      <div class="simulator__lever">
        <label>Conversion Rate Improvement</label>
        <input type="range" min="0" max="50" value="15" id="lever-conversion">
        <span class="simulator__lever-value" id="lever-conversion-val">+15%</span>
      </div>
      <div class="simulator__lever">
        <label>Expansion Revenue</label>
        <input type="range" min="0" max="100" value="30" id="lever-expansion">
        <span class="simulator__lever-value" id="lever-expansion-val">+30%</span>
      </div>
      <div class="simulator__lever">
        <label>Churn Reduction</label>
        <input type="range" min="0" max="50" value="10" id="lever-churn">
        <span class="simulator__lever-value" id="lever-churn-val">-10%</span>
      </div>
    </div>
    <div class="simulator__output">
      <div class="simulator__result">
        <span class="simulator__result-label">Projected Q3 ARR</span>
        <span class="simulator__result-value" id="simulator-arr">$32.4M</span>
      </div>
      <div class="chart-container" id="simulator-chart"></div>
    </div>
  </div>
</section>
```

CSS:
- `.simulator`: `display: grid`, `grid-template-columns: 1fr 1fr`, `gap: 48px`, `margin-top: 32px`, `align-items: start`
- `.simulator__lever`: `margin-bottom: 24px`
- `.simulator__lever label`: `display: block`, `font-size: 0.85rem`, `margin-bottom: 8px`, `font-weight: 600`
- `input[type="range"]`: styled minimally -- `width: 100%`, `accent-color: var(--ink)` (or custom styling with `-webkit-` prefixes for a clean B&W slider)
- `.simulator__lever-value`: `font-size: 0.85rem`, `color: var(--ink-light)`, `margin-left: 8px`
- `.simulator__result`: `text-align: center`, `margin-bottom: 32px`
- `.simulator__result-value`: `font-size: 3rem`, `font-weight: 700`, `letter-spacing: -0.02em`
- On mobile: `grid-template-columns: 1fr`

JS:
- D3 renders a small grouped bar chart in `#simulator-chart` showing current ARR vs projected ARR across months
- Sliders update the projection in real-time (recalculate and re-render the chart with smooth transitions)
- Base ARR: $28.8M (2.4M * 12), apply conversion/expansion/churn adjustments
- Chart bars transition smoothly with D3 `.transition().duration(300)`

**Step 2: Verify interactivity**

Run: `open template.html`
Expected: Three sliders that dynamically update the projected ARR number and bar chart. Smooth transitions on adjustment.

**Step 3: Commit**

```bash
git add template.html
git commit -m "feat: add interactive growth lever simulator as custom viz example"
```

---

### Task 10: CLAUDE.md Instructions

**Files:**
- Create: `CLAUDE.md`

**Step 1: Write the CLAUDE.md**

Create `CLAUDE.md` with the following content:

```markdown
# Presenter

Generate self-contained HTML presentations from concept documents.

## What This Is

A system for turning concept docs, strategy memos, and plans into interactive,
single-file HTML presentations. The output is professional, minimal, and readable --
designed for startup teams (GMs, PMs, developers, designers).

## Design Principles

1. **Black & white only** -- use color extremely sparingly, only when functionally
   necessary (e.g., distinguishing 3+ data series in a chart)
2. **Readability first** -- generous whitespace, large type, max-width content columns
3. **Purposeful animations** -- every animation must aid comprehension. Ask: "what does
   this help the reader understand?" If the answer is "nothing" -- skip it
4. **Professional, not flashy** -- high-end editorial feel, like a strategy memo
5. **Self-contained** -- single HTML file, inline CSS/JS, D3.js from CDN only

## How to Generate a Presentation

1. Read the concept document the user provides
2. Identify sections and their content types:
   - Narrative/text -> headings, paragraphs, callouts
   - Key numbers -> metric cards
   - Trends/comparisons -> D3.js charts (bar, line, donut)
   - Processes/sequences -> flow diagrams, timelines
   - Structures -> SVG architecture diagrams
   - Before/after or A/B -> comparison layouts
   - Images -> figure blocks with captions
3. Decide if any section needs a **custom visualization** -- something beyond
   standard components that would explain the concept better (interactive sliders,
   animated state machines, visual metaphors, etc.)
4. Generate a single HTML file in `output/` named descriptively
5. Reference `template.html` for all component patterns, CSS variables, and JS patterns

## Component Reference

See `template.html` for live examples of every component:

| Component | Use When |
|-----------|----------|
| Hero / Title | Every presentation starts with one |
| Narrative | Explaining context, strategy, rationale |
| Callout | Highlighting a key insight or decision |
| Metric Cards | Showing 2-4 KPIs or key numbers |
| Bar Chart | Comparing categories |
| Line Chart | Showing trends over time |
| Donut Chart | Showing proportional breakdown |
| Data Table | Structured data with multiple columns |
| Process Flow | Sequential steps in a process |
| Timeline | Chronological milestones |
| Comparison | Side-by-side (before/after, option A/B) |
| SVG Diagram | Architecture, relationships, structures |
| Image/Figure | Screenshots, mockups, photos |
| Custom Viz | When standard components don't capture the idea |

## Custom Visualizations

Standard components are the **floor, not the ceiling**. When a concept is better
explained by something custom -- build it. Examples:

- Interactive sliders that show impact of variables
- Animated state machines showing system behavior
- Network graphs showing relationships
- Funnel visualizations
- Heat maps or matrix views

Custom visualizations must still follow the design language: B&W palette, system fonts,
same spacing grid, purposeful animation.

## Technical Constraints

- Single `.html` file, everything inline except D3.js
- D3.js v7 from CDN: `https://d3js.org/d3.v7.min.js`
- Use CSS custom properties from template.html (--ink, --surface, etc.)
- Responsive: works on desktop and tablet (min-width ~768px)
- Accessibility: `prefers-reduced-motion` disables all animations
- All animations use transform/opacity only (GPU-accelerated)
- No animation longer than 600ms
- IntersectionObserver for scroll-triggered effects
- Sticky TOC auto-generated from h2 elements

## Output

Save generated files to: `output/<descriptive-name>.html`

Examples:
- `output/q3-product-strategy.html`
- `output/user-onboarding-redesign.html`
- `output/infrastructure-migration-plan.html`
```

**Step 2: Verify CLAUDE.md is readable and complete**

Read through the file. Ensure it references `template.html`, covers all components, and provides clear generation instructions.

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with presentation generation instructions"
```

---

### Task 11: Create output directory + final cleanup

**Files:**
- Create: `output/.gitkeep`
- Modify: `template.html` (final review)

**Step 1: Create output directory**

```bash
mkdir -p output
touch output/.gitkeep
```

**Step 2: Final review of template.html**

Open `template.html` and verify:
- All components render correctly
- Scroll animations work
- TOC highlights current section
- Charts are interactive (hover tooltips)
- Simulator sliders update in real-time
- Mobile responsive (resize browser window)
- No console errors

Run: `open template.html`

**Step 3: Commit**

```bash
git add output/.gitkeep
git commit -m "feat: add output directory for generated presentations"
```

---

## Summary

| Task | Component | Estimated Complexity |
|------|-----------|---------------------|
| 1 | HTML skeleton + CSS foundation | Low |
| 2 | Hero + Narrative | Low |
| 3 | Metric Cards | Low |
| 4 | D3.js charts (bar, line, donut) + table | High |
| 5 | Process flow + Timeline | Medium |
| 6 | Comparison layout + Image blocks | Medium |
| 7 | Sticky TOC | Medium |
| 8 | Scroll animations + Tooltips | Medium |
| 9 | Custom viz (growth simulator) | High |
| 10 | CLAUDE.md instructions | Low |
| 11 | Output directory + final review | Low |
