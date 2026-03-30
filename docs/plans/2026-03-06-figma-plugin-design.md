# Design: Figma Design System Generator Plugin — [APP_NAME]

> **Date:** 2026-03-06
> **Author:** Markus
> **Status:** Approved — ready for implementation
> **Platform:** Figma Plugin (Professional plan, up to 10 modes per collection)
> **Target:** Flutter mobile app (iOS + Android)

---

## Overview

A Figma plugin that generates a complete mobile design system for [APP_NAME]. The user selects a visual direction (or "Both"), and the plugin creates all variable collections, styles, reference pages, starter components, and screen templates — ready for screen design work.

### UI Flow

```
┌──────────────────────────────┐
│  [APP_NAME] Design System     │
│  Generator                    │
│                               │
│  Select direction:            │
│  ○ Soft Piggy Bank            │
│  ○ Smart & Clean              │
│  ○ Both (creates modes)       │
│                               │
│  [Generate]                   │
└──────────────────────────────┘
```

- **Single direction:** Creates one mode per collection. Clean, simple.
- **Both:** Creates two modes per collection. Switching mode in Figma swaps the entire visual direction instantly.

---

## Architecture

### Variable Collections

| Collection | Variable Type | Modes |
|---|---|---|
| **Colors** | COLOR | Direction A / Direction B (or single) |
| **Typography** | STRING | Direction A / Direction B (or single) |
| **Radius** | FLOAT | Direction A / Direction B (or single) |
| **Spacing** | FLOAT | Single (shared) |
| **Sizing** | FLOAT | Single (shared) |

### Styles

| Style Type | Count | Notes |
|---|---|---|
| Text styles | 15 | M3 type scale, font bound to typography variables |
| Effect styles | 6 | Elevation levels, shadow values differ per direction |
| Grid styles | 1 | 4-column mobile grid |

### Pages

| Page | Contents |
|---|---|
| **Cover** | File title, direction name, date |
| **Colors** | Swatches for all color tokens with names and hex |
| **Typography** | All 15 text styles with sample text |
| **Spacing & Sizing** | Visual spacing scale, icon sizes, touch targets |
| **Elevation** | Cards showing all 6 shadow levels |
| **Components** | Starter components wired to variables |
| **Screen Templates** | Empty mobile frames (393x852) with grid |

---

## Color System

### Primitive Palette — Direction A: "Soft Piggy Bank"

**Primary: Sage Green**

| Token | Hex |
|---|---|
| `sage/50` | #F0F5F0 |
| `sage/100` | #D4E6D5 |
| `sage/200` | #B5D4B7 |
| `sage/400` | #8BAB8D |
| `sage/600` | #5E8A60 |
| `sage/800` | #3D6640 |
| `sage/900` | #2A4A2D |

**Secondary: Warm Blush**

| Token | Hex |
|---|---|
| `blush/50` | #FBF2F1 |
| `blush/100` | #F2DCD9 |
| `blush/200` | #E5BCB7 |
| `blush/400` | #C4918A |
| `blush/600` | #A36B63 |
| `blush/800` | #7D4A43 |

**Tertiary: Lavender**

| Token | Hex |
|---|---|
| `lavender/50` | #F3F0F8 |
| `lavender/100` | #E2DCF0 |
| `lavender/400` | #9B8EC0 |
| `lavender/600` | #7568A0 |

**Neutrals (warm)**

| Token | Hex |
|---|---|
| `neutral/0` | #FFFFFF |
| `neutral/50` | #FAF8F5 |
| `neutral/100` | #F0ECE6 |
| `neutral/200` | #E0DAD2 |
| `neutral/300` | #C5BDB3 |
| `neutral/400` | #9E968B |
| `neutral/500` | #7A7268 |
| `neutral/700` | #4A443C |
| `neutral/900` | #2D2A26 |

**Status**

| Token | Hex |
|---|---|
| `error` | #C75D4A |
| `success` | #6B9E6F |
| `warning` | #D4A643 |

### Primitive Palette — Direction B: "Smart & Clean"

**Primary: Deep Teal**

| Token | Hex |
|---|---|
| `teal/50` | #EFF8F8 |
| `teal/100` | #B8E0DF |
| `teal/200` | #82C8C7 |
| `teal/400` | #3D9E9D |
| `teal/600` | #1A6B6A |
| `teal/800` | #0F4847 |
| `teal/900` | #083332 |

**Secondary: Warm Amber**

| Token | Hex |
|---|---|
| `amber/50` | #FDF8EE |
| `amber/100` | #F5E6C8 |
| `amber/200` | #EBCF96 |
| `amber/400` | #D4A643 |
| `amber/600` | #B8860B |
| `amber/800` | #8A6408 |

**Tertiary: Slate Blue**

| Token | Hex |
|---|---|
| `slate/50` | #F2F4F7 |
| `slate/100` | #D5DCE6 |
| `slate/400` | #5B6F8A |
| `slate/600` | #3E5170 |

**Neutrals (cool)**

| Token | Hex |
|---|---|
| `neutral/0` | #FFFFFF |
| `neutral/50` | #FAFAF9 |
| `neutral/100` | #F0F0EE |
| `neutral/200` | #DDDDD9 |
| `neutral/300` | #BDBDB8 |
| `neutral/400` | #97978F |
| `neutral/500` | #717169 |
| `neutral/700` | #44443E |
| `neutral/900` | #1C1C1B |

**Status**

| Token | Hex |
|---|---|
| `error` | #C4453A |
| `success` | #3D8B7A |
| `warning` | #D4A643 |

### Semantic Tokens (alias layer — used in actual design)

| Semantic Token | Direction A → | Direction B → |
|---|---|---|
| `color/primary` | sage/600 | teal/600 |
| `color/on-primary` | neutral/0 | neutral/0 |
| `color/primary-container` | sage/100 | teal/100 |
| `color/on-primary-container` | sage/900 | teal/900 |
| `color/secondary` | blush/600 | amber/600 |
| `color/on-secondary` | neutral/0 | neutral/0 |
| `color/secondary-container` | blush/100 | amber/100 |
| `color/on-secondary-container` | blush/800 | amber/800 |
| `color/tertiary` | lavender/600 | slate/600 |
| `color/on-tertiary` | neutral/0 | neutral/0 |
| `color/tertiary-container` | lavender/100 | slate/100 |
| `color/on-tertiary-container` | lavender/600 | slate/600 |
| `color/error` | error | error |
| `color/on-error` | neutral/0 | neutral/0 |
| `color/success` | success | success |
| `color/warning` | warning | warning |
| `color/surface` | neutral/50 | neutral/50 |
| `color/on-surface` | neutral/900 | neutral/900 |
| `color/on-surface-variant` | neutral/500 | neutral/500 |
| `color/surface-container-lowest` | neutral/0 | neutral/0 |
| `color/surface-container-low` | neutral/50 | neutral/50 |
| `color/surface-container` | neutral/100 | neutral/100 |
| `color/surface-container-high` | neutral/200 | neutral/200 |
| `color/outline` | neutral/300 | neutral/300 |
| `color/outline-variant` | neutral/200 | neutral/200 |
| `color/scrim` | neutral/900 @ 50% | neutral/900 @ 50% |

---

## Typography

### Scale (shared — M3 standard)

| Token | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|
| `display/large` | 57 | Regular (400) | 64 | -0.25 |
| `display/medium` | 45 | Regular | 52 | 0 |
| `display/small` | 36 | Regular | 44 | 0 |
| `headline/large` | 32 | Regular | 40 | 0 |
| `headline/medium` | 28 | Regular | 36 | 0 |
| `headline/small` | 24 | Regular | 32 | 0 |
| `title/large` | 22 | Regular | 28 | 0 |
| `title/medium` | 16 | Medium (500) | 24 | 0.15 |
| `title/small` | 14 | Medium | 20 | 0.1 |
| `body/large` | 16 | Regular | 24 | 0.5 |
| `body/medium` | 14 | Regular | 20 | 0.25 |
| `body/small` | 12 | Regular | 16 | 0.4 |
| `label/large` | 14 | Medium | 20 | 0.1 |
| `label/medium` | 12 | Medium | 16 | 0.5 |
| `label/small` | 11 | Medium | 16 | 0.5 |

### Font Family (per mode)

| Mode | Font | Weights to load |
|---|---|---|
| Direction A: Soft Piggy Bank | **Nunito** | Regular, Medium, SemiBold, Bold |
| Direction B: Smart & Clean | **DM Sans** | Regular, Medium, SemiBold, Bold |

---

## Spacing (shared — single mode)

| Token | Value (px) |
|---|---|
| `space/0` | 0 |
| `space/1` | 2 |
| `space/2` | 4 |
| `space/3` | 8 |
| `space/4` | 12 |
| `space/5` | 16 |
| `space/6` | 20 |
| `space/7` | 24 |
| `space/8` | 32 |
| `space/9` | 40 |
| `space/10` | 48 |
| `space/11` | 64 |
| `space/12` | 80 |

---

## Border Radius (per mode)

| Token | Direction A | Direction B |
|---|---|---|
| `radius/none` | 0 | 0 |
| `radius/xs` | 8 | 4 |
| `radius/sm` | 12 | 8 |
| `radius/md` | 16 | 12 |
| `radius/lg` | 24 | 16 |
| `radius/xl` | 32 | 24 |
| `radius/full` | 9999 | 9999 |

---

## Elevation / Effect Styles (per mode)

| Token | Direction A (soft, diffuse) | Direction B (precise, tight) |
|---|---|---|
| `elevation/0` | none | none |
| `elevation/1` | y:1 blur:6 color:neutral/900 @ 8% | y:1 blur:3 color:neutral/900 @ 12% |
| `elevation/2` | y:2 blur:12 color:neutral/900 @ 8% | y:2 blur:6 color:neutral/900 @ 10% |
| `elevation/3` | y:4 blur:20 color:neutral/900 @ 10% | y:4 blur:10 color:neutral/900 @ 12% |
| `elevation/4` | y:6 blur:28 color:neutral/900 @ 10% | y:6 blur:14 color:neutral/900 @ 12% |
| `elevation/5` | y:10 blur:40 color:neutral/900 @ 12% | y:10 blur:24 color:neutral/900 @ 14% |

---

## Sizing (shared — single mode)

| Token | Value (px) | Notes |
|---|---|---|
| `icon/sm` | 20 | Dense contexts |
| `icon/md` | 24 | Standard |
| `icon/lg` | 40 | Feature icons |
| `icon/xl` | 48 | Hero / empty state |
| `touch-target` | 48 | Minimum interactive area |

---

## Grid Style

| Property | Value |
|---|---|
| Columns | 4 |
| Margins | 16px |
| Gutters | 16px |
| Frame width | 393 (iPhone 15/16) |
| Frame height | 852 (iPhone 15/16) |

---

## Starter Components

All components use auto-layout and bind fills, corner radius, spacing, and typography to variables. Switching mode swaps the entire look.

### Button

| Variant | Fill | Text | Border | Radius |
|---|---|---|---|---|
| Primary / Default | color/primary | color/on-primary | none | radius/sm |
| Primary / Pressed | color/primary @ 90% | color/on-primary | none | radius/sm |
| Primary / Disabled | color/on-surface @ 12% | color/on-surface @ 38% | none | radius/sm |
| Secondary / Default | color/secondary-container | color/on-secondary-container | none | radius/sm |
| Secondary / Pressed | color/secondary-container @ 90% | color/on-secondary-container | none | radius/sm |
| Secondary / Disabled | color/on-surface @ 12% | color/on-surface @ 38% | none | radius/sm |
| Text / Default | transparent | color/primary | none | radius/sm |
| Text / Pressed | color/primary @ 8% | color/primary | none | radius/sm |
| Text / Disabled | transparent | color/on-surface @ 38% | none | radius/sm |

**Size:** height 48 (touch target), horizontal padding space/5 (16), text style label/large.

### Card

| Variant | Fill | Border | Shadow | Radius |
|---|---|---|---|---|
| Elevated | color/surface | none | elevation/1 | radius/md |
| Outlined | color/surface | color/outline-variant 1px | none | radius/md |
| Filled | color/surface-container | none | none | radius/md |

**Padding:** space/5 (16) all sides.

### Input Field

| Variant | Fill | Border | Radius |
|---|---|---|---|
| Default | transparent | color/outline 1px bottom | radius/xs (top only) |
| Focused | transparent | color/primary 2px bottom | radius/xs (top only) |
| Error | transparent | color/error 2px bottom | radius/xs (top only) |
| Disabled | color/on-surface @ 4% | color/on-surface @ 12% 1px bottom | radius/xs (top only) |

**Size:** height 56, padding space/5 (16) horizontal, text style body/large, label text style body/small.

### Bottom Navigation Bar

- Height: 80
- Fill: color/surface
- Shadow: elevation/2
- Icons: icon/md (24)
- Labels: label/small
- Active: color/primary
- Inactive: color/on-surface-variant
- Active indicator: color/primary-container, radius/full

### Top App Bar (Small)

- Height: 64
- Fill: color/surface
- Title: title/large, color/on-surface
- Padding: space/5 (16) horizontal

### Chip

| Variant | Fill | Border | Text |
|---|---|---|---|
| Assist | transparent | color/outline 1px | color/on-surface |
| Filter / Selected | color/secondary-container | none | color/on-secondary-container |
| Filter / Unselected | transparent | color/outline 1px | color/on-surface-variant |

**Size:** height 32, padding space/5 (16) horizontal, radius/full, text style label/large.

### Badge

| Variant | Size | Fill | Text |
|---|---|---|---|
| Dot | 6x6 | color/error | none |
| Number | min 16x16 | color/error | color/on-error, label/small |

### Snackbar

- Fill: color/on-surface (inverse)
- Text: color/surface (inverse), body/medium
- Action: color/primary, label/large
- Radius: radius/xs
- Padding: space/5 (16)

---

## Reference Pages

### Cover Page
- Frame: 1920 x 1080
- App name, direction name, date, version
- Color coded to primary color of selected direction

### Colors Page
- Primitive swatches: rows of color chips per hue (sage/teal, blush/amber, lavender/slate, neutrals)
- Semantic tokens: labeled cards showing token name → resolved color
- Each swatch: 80x80, radius/sm, with token name and hex below

### Typography Page
- All 15 text styles rendered with: "The quick brown fox jumps over the lazy dog"
- Each row shows: token name, size, weight, line height, letter spacing
- Grouped by category (Display, Headline, Title, Body, Label)

### Spacing & Sizing Page
- Horizontal bars showing each spacing value with pixel labels
- Icon size reference: squares at 20, 24, 40, 48
- Touch target overlay: 48x48 dotted outline around a 24px icon

### Elevation Page
- 6 cards (one per level) on a neutral background
- Each card labeled with elevation level and shadow values

### Components Page
- All starter components laid out with variant labels
- Organized by component type in auto-layout sections

### Screen Templates Page
- 3 mobile frames (393 x 852) with grid applied
- Named: "Home", "Task Detail", "Earnings"
- Empty except for grid — ready for design work

---

## Plugin Technical Details

### Stack
- TypeScript
- Figma Plugin API
- UI: HTML/CSS in plugin iframe (simple selection UI)
- Build: esbuild or webpack for single-file bundle

### File Structure
```
figma-plugin/
├── manifest.json
├── package.json
├── tsconfig.json
├── src/
│   ├── code.ts              # Main plugin logic
│   ├── ui.html              # Plugin UI
│   ├── data/
│   │   ├── colors.ts        # Color palettes for both directions
│   │   ├── typography.ts    # Type scale definitions
│   │   ├── spacing.ts       # Spacing + sizing tokens
│   │   ├── radius.ts        # Border radius per direction
│   │   ├── elevation.ts     # Shadow definitions per direction
│   │   └── components.ts    # Component definitions
│   ├── generators/
│   │   ├── variables.ts     # Creates variable collections + modes
│   │   ├── styles.ts        # Creates text, effect, grid styles
│   │   ├── pages.ts         # Creates reference pages with frames
│   │   └── components.ts    # Creates starter components
│   └── utils/
│       ├── color.ts         # Hex → Figma RGBA conversion
│       └── figma.ts         # Helper wrappers for Figma API
└── dist/
    └── code.js              # Bundled output
```

### Key Implementation Notes

1. **Font loading:** Must `await figma.loadFontAsync()` for all Nunito and DM Sans weight variants before creating text nodes or text styles.

2. **Variable aliasing:** Semantic tokens should use `figma.variables.createVariableAlias()` to reference primitive variables, not duplicate color values.

3. **Variable scopes:** Set appropriate scopes so colors only appear in fill pickers, spacing only in gap/padding pickers, etc.

4. **Code syntax:** Set `variable.codeSyntax` for WEB, ANDROID, and iOS platforms to enable developer handoff.

5. **Naming convention:** Use `/` delimiter for folder structure in variable and style names (e.g., `color/primary`, `display/large`).

6. **Mode creation:** New collections start with one default mode. Rename it, then call `collection.addMode()` for the second direction.

7. **Component wiring:** All component fills, strokes, corner radii, and spacing should use `setBoundVariable()` to bind to the design tokens.

---

## What This Enables

After running the plugin, the designer can:
- Switch between Direction A and Direction B by changing the variable mode on any frame
- Start designing screens immediately with all tokens, styles, and components ready
- Export variables for Flutter development via Figma's built-in dev mode
- Add new directions later by adding modes to existing collections
