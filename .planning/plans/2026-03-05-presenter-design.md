# Presenter: Concept-to-HTML Presentation Tool

## Purpose

A template + instructions system for Claude Code that transforms concept documents into self-contained, interactive HTML presentations. Designed for startup teams (GMs, PMs, developers, designers) who need to communicate ideas clearly and professionally.

## Design Principles

1. **Black & white only** -- color used extremely sparingly, only when functionally necessary (e.g., distinguishing data series)
2. **Readability first** -- generous whitespace, readable type sizes, max-width content columns
3. **Purposeful animations** -- every animation must aid comprehension, never decorative
4. **Professional, not flashy** -- high-end editorial feel, like a well-designed strategy memo
5. **Self-contained** -- single HTML file, inline CSS/JS, only external dependency is D3.js from CDN

## Architecture

**Approach:** Single reference template (Approach A)

One complete HTML template file serves as both a working example and a component library. CLAUDE.md provides instructions for Claude to analyze concept docs and generate tailored presentations.

### File Structure

```
Presenter/
  CLAUDE.md              # Instructions for generating presentations
  template.html          # Reference template with all components
  output/                # Generated presentations go here
```

## Visual Design Language

### Color Palette

| Token          | Value   | Usage                              |
|----------------|---------|------------------------------------|
| --ink          | #111    | Primary text, borders, chart fills |
| --ink-light    | #666    | Secondary text, labels             |
| --ink-faint    | #999    | Tertiary text, axis lines          |
| --surface      | #fff    | Background                         |
| --surface-alt  | #f7f7f7 | Alternate section backgrounds      |
| --border       | #e0e0e0 | Subtle dividers                    |
| --accent       | #111    | Bold emphasis (sparingly)          |

### Typography

- System font stack: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- Body: 18px, line-height 1.6
- Headings: tight letter-spacing for elegance
- Monospace for code/data: `'SF Mono', 'Fira Code', monospace`

### Spacing

- 8px grid system
- Section gaps: 80-120px
- Content max-width: ~720px (text), ~960px (charts/diagrams)

## Component Library

### 1. Hero / Title Block
- Large bold title, subtitle, optional date/author metadata
- Centered, generous breathing room

### 2. Narrative Section
- Headings, paragraphs, bullet lists, blockquotes
- Callout boxes (left-bordered with --ink) for key insights
- Bold for emphasis, no color highlighting

### 3. Metric Cards
- Row of 2-4 KPI cards (large number, small label)
- Optional trend indicator (up/down arrow)
- Optional sparkline

### 4. Data Visualizations (D3.js)
- Bar chart (horizontal & vertical)
- Line chart (optional area fill in light gray)
- Pie/donut chart
- Tables with alternating row shading
- All monochrome -- differentiation via pattern, opacity, or grayscale

### 5. Flow & Diagram Sections
- Process flows: horizontal/vertical step sequences (CSS + SVG)
- Timelines: vertical with milestones
- Architecture/relationship diagrams via inline SVG

### 6. Image / Media Blocks
- Full-width or constrained images with captions
- Side-by-side comparison layout
- Embedded content placeholder (iframe-ready)

### 7. Sticky Table of Contents
- Fixed left sidebar (desktop) / collapsible top bar (mobile)
- Auto-generated from section headings
- Highlights current section on scroll

### 8. Custom / Bespoke Visualizations
- Standard components are the floor, not the ceiling
- When a concept is better explained by a custom visualization, animation, or interactive element -- build it
- Examples: animated state machines, interactive sliders, visual metaphors, custom flow animations
- Must follow the same visual language (B&W, system fonts, spacing grid)
- Uses D3.js + vanilla JS + CSS animations

## Animation & Interaction

### Scroll-Triggered Entrance
- IntersectionObserver API (no library needed)
- Elements: `opacity: 0; transform: translateY(20px)` -> transition in
- Staggered timing for groups (100ms apart)
- Charts animate data on first scroll into view

### Hover Interactions
- Chart elements: tooltip with exact value + context
- Diagram nodes: highlight connected paths
- Metric cards: subtle scale (1.02) + shadow lift
- Static reading content: no hover effect

### Rules
- Every animation must answer: "what does this help the reader understand?"
- All animations use transform/opacity only (GPU-accelerated)
- `prefers-reduced-motion` media query disables all animations
- No animation longer than 600ms

## CLAUDE.md Contents

1. Purpose statement and target audience
2. Design principles (B&W, minimal, readability, purposeful animation)
3. Component reference with usage guidance
4. Custom visualization guidance -- when and how to go beyond standard components
5. Generation workflow:
   - Read the concept document
   - Identify sections and content types
   - Map each section to a component (or design a custom one)
   - Generate a single self-contained HTML file in output/
   - Name descriptively (e.g., `output/user-onboarding-redesign.html`)
6. Technical constraints: D3.js from CDN, inline CSS/JS, responsive, accessible

## Layout

- Single scrollable page
- Smooth scroll between sections
- Sticky table of contents for navigation
- Responsive: works on desktop and tablet

## Technical Stack

- HTML5, inline CSS, inline JavaScript
- D3.js (loaded from CDN, ~260KB)
- IntersectionObserver API for scroll animations
- No other external dependencies
