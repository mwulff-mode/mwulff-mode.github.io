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
6. **Editorial art direction** -- prefer serif display type with a restrained sans body, warm paper surfaces, fine dividers, and strong visual rhythm
7. **Restraint over dashboard chrome** -- avoid colorful accents, generic app cards, and default SaaS-looking layouts unless the content truly needs them

## How to Generate a Presentation

1. Read the concept document the user provides
2. Challenge the brief before coding. If the input is broad, ask a small number of high-value questions that force scope, audience, decision, and desired length into focus.
3. Slim the story down to the essential sections. Prefer fewer, stronger sections over covering every detail from the source material.
4. Identify sections and their content types:
   - Narrative/text -> headings, paragraphs, callouts
   - Key numbers -> metric cards
   - Trends/comparisons -> D3.js charts (bar, line, donut)
   - Processes/sequences -> flow diagrams, timelines
   - Structures -> SVG architecture diagrams
   - Before/after or A/B -> comparison layouts
   - Images -> figure blocks with captions
5. Decide if any section needs a **custom visualization** -- something beyond
   standard components that would explain the concept better (interactive sliders,
   animated state machines, visual metaphors, etc.)
6. Use imagery, charts, and interactive objects when they improve comprehension, but never as decoration. Every visual should make the message faster to understand.
7. Choose an art direction before coding: define the reading mood, the typography hierarchy,
   and where asymmetry or full-bleed moments should appear
8. Generate a single HTML file in `docs/` named descriptively
9. Reference `template.html` for all component patterns, CSS variables, and JS patterns

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
| Act Divider | Separating major sections (acts/chapters) in long presentations |
| Alignment Cards | Displaying key decisions/principles in a 4-column grid |
| Intro Cards | Side-by-side comparison of two directions/options |
| Screen Grid | Displaying 5 app screenshots in a row |
| Illustration Row | 3-column grid for illustrations with captions |
| Swatch Row | Displaying color palettes with hex values |
| Type Specimen | Showcasing typography hierarchy and brand typeface |
| Voice Bubbles | Showing conversational tone/voice examples |
| Feedback Grid | Interactive bipolar rating scales (5 dots per dimension) |
| Direction Slider | Range input for preference between two options |
| Prototype Link | Styled CTA linking to Figma, FigJam, or prototype |
| Feedback Float | Floating panel that accumulates feedback + copy to clipboard |

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

## Design Taste Requirements

- Start from the premise that this is closer to an editorial document than an app UI
- Use grayscale or warm-neutral palettes first; only introduce color when it adds real explanatory value
- Prefer composition over ornament: asymmetry, pacing, whitespace, framing, and typography should do most of the work
- Charts should feel premium and monochrome: differentiate with weight, dash, texture, or opacity before using color
- Avoid "template energy": default card grids, loud gradients, pill overload, or decorative motion without narrative purpose
- Default to brevity. A good presentation informs quickly; it should not read like a book.
- If a source document is bloated, summarize, consolidate, or cut until only the highest-signal material remains.
- Prefer visuals over paragraphs when the visual makes the point faster. If it does not, leave it out.

## Feedback & Interactivity

When a presentation needs stakeholder feedback:

1. Use **Feedback Grid** for structured dimensional ratings (e.g., warmth, trust, energy)
2. Use **Feedback Words** (textarea) for open-ended comments
3. Use **Direction Slider** when comparing two options
4. Use **Feedback Float** -- a floating panel that appears on first interaction,
   accumulates all feedback in real time, and has a single "Copy to Slack" button
5. Never use multiple copy buttons -- one floating panel handles everything
6. All external links must use `target="_blank"` to preserve feedback state

The floating panel pattern replaces per-section copy buttons. It appears bottom-right,
is collapsible, and builds a formatted text summary for clipboard.

## Multi-Act Presentations

For presentations comparing multiple directions or covering distinct phases:

1. Use **Act Dividers** to separate major sections with a label + title + subtitle
2. Use **TOC Grouping** -- act dividers automatically create group headers in the TOC
3. Keep shared context (recap, audience, bridge) before the first act divider
4. Each direction gets parallel structure: design direction, screenshots, feedback
5. End with a comparison section and unified vote/feedback

## Technical Constraints

- Single `.html` file, everything inline except D3.js
- D3.js v7 from CDN: `https://d3js.org/d3.v7.min.js`
- Google Fonts via `@import` when brand typefaces are needed
- Use CSS custom properties from template.html (--ink, --surface, etc.)
- Responsive: works on desktop and tablet (min-width ~768px)
- Accessibility: `prefers-reduced-motion` disables all animations
- All animations use transform/opacity only (GPU-accelerated)
- No animation longer than 600ms
- Scroll-based TOC tracking (scroll listener, not IntersectionObserver)
- Sticky TOC auto-generated from h2 elements, with act-based grouping
- Base64-encode images inline for self-contained files

## Output

Save generated files to: `docs/<descriptive-name>.html`

Examples:
- `docs/q3-product-strategy.html`
- `docs/user-onboarding-redesign.html`
- `docs/infrastructure-migration-plan.html`
