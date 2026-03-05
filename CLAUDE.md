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
