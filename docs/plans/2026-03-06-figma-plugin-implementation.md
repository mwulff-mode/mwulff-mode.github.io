# Figma Design System Generator Plugin — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Figma plugin that generates a complete mobile design system for [APP_NAME] with two visual directions as switchable variable modes.

**Architecture:** TypeScript Figma plugin with a simple HTML UI for direction selection. Data layer defines all tokens (colors, typography, spacing, radius, elevation) for both directions. Generator layer creates Figma variable collections, styles, reference pages, and starter components. All design tokens are wired via Figma's variable binding system.

**Tech Stack:** TypeScript, Figma Plugin API, esbuild (bundler), HTML/CSS (plugin UI)

**Design doc:** `docs/plans/2026-03-06-figma-plugin-design.md`

---

## Task 1: Scaffold Plugin Project

**Files:**
- Create: `figma-plugin/manifest.json`
- Create: `figma-plugin/package.json`
- Create: `figma-plugin/tsconfig.json`
- Create: `figma-plugin/esbuild.config.mjs`
- Create: `figma-plugin/src/code.ts`
- Create: `figma-plugin/src/ui.html`

**Step 1: Create plugin directory**

Run: `mkdir -p figma-plugin/src`

**Step 2: Create manifest.json**

```json
{
  "name": "[APP_NAME] Design System Generator",
  "id": "earnapp-design-system-generator",
  "api": "1.0.0",
  "main": "dist/code.js",
  "ui": "src/ui.html",
  "capabilities": [],
  "enableProposedApi": false,
  "editorType": ["figma"]
}
```

**Step 3: Create package.json**

```json
{
  "name": "earnapp-figma-plugin",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "node esbuild.config.mjs",
    "watch": "node esbuild.config.mjs --watch"
  },
  "devDependencies": {
    "@figma/plugin-typings": "^1.106.0",
    "esbuild": "^0.24.0",
    "typescript": "^5.7.0"
  }
}
```

**Step 4: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2020"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "typeRoots": ["node_modules/@figma"]
  },
  "include": ["src/**/*.ts"]
}
```

**Step 5: Create esbuild.config.mjs**

```javascript
import * as esbuild from 'esbuild';

const watch = process.argv.includes('--watch');

const ctx = await esbuild.context({
  entryPoints: ['src/code.ts'],
  bundle: true,
  outfile: 'dist/code.js',
  target: 'es2020',
  format: 'iife',
  sourcemap: false,
});

if (watch) {
  await ctx.watch();
  console.log('Watching for changes...');
} else {
  await ctx.rebuild();
  await ctx.dispose();
  console.log('Build complete.');
}
```

**Step 6: Create minimal code.ts**

```typescript
figma.showUI(__html__, { width: 320, height: 400 });

figma.ui.onmessage = async (msg: { type: string; direction: string }) => {
  if (msg.type === 'generate') {
    figma.notify(`Generating ${msg.direction} design system...`);
    // TODO: implement generation
    figma.closePlugin();
  }
};
```

**Step 7: Create ui.html**

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Inter, sans-serif; padding: 24px; color: #333; }
    h2 { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
    p.subtitle { font-size: 12px; color: #888; margin-bottom: 20px; }
    .option { display: flex; align-items: flex-start; gap: 10px; padding: 12px; border: 1px solid #e0e0e0; border-radius: 8px; margin-bottom: 8px; cursor: pointer; transition: border-color 0.15s; }
    .option:hover { border-color: #999; }
    .option.selected { border-color: #333; background: #f7f7f7; }
    .option input { margin-top: 3px; }
    .option-text h3 { font-size: 13px; font-weight: 600; }
    .option-text p { font-size: 11px; color: #666; margin-top: 2px; }
    button { width: 100%; padding: 12px; background: #333; color: white; border: none; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; margin-top: 16px; }
    button:hover { background: #555; }
    button:disabled { background: #ccc; cursor: not-allowed; }
  </style>
</head>
<body>
  <h2>[APP_NAME] Design System</h2>
  <p class="subtitle">Generate a complete design system with variables, styles, and components.</p>

  <div class="option" data-value="direction-a" onclick="select(this)">
    <input type="radio" name="direction" value="direction-a">
    <div class="option-text">
      <h3>Soft Piggy Bank</h3>
      <p>Warm, nurturing, pastel. Nunito font. Rounded corners.</p>
    </div>
  </div>

  <div class="option" data-value="direction-b" onclick="select(this)">
    <input type="radio" name="direction" value="direction-b">
    <div class="option-text">
      <h3>Smart & Clean</h3>
      <p>Confident, minimal, premium. DM Sans font. Moderate corners.</p>
    </div>
  </div>

  <div class="option" data-value="both" onclick="select(this)">
    <input type="radio" name="direction" value="both">
    <div class="option-text">
      <h3>Both (switchable modes)</h3>
      <p>Creates both directions as variable modes. Switch instantly in Figma.</p>
    </div>
  </div>

  <button id="generate" disabled onclick="generate()">Generate Design System</button>

  <script>
    let selected = null;
    function select(el) {
      document.querySelectorAll('.option').forEach(o => o.classList.remove('selected'));
      el.classList.add('selected');
      el.querySelector('input').checked = true;
      selected = el.dataset.value;
      document.getElementById('generate').disabled = false;
    }
    function generate() {
      parent.postMessage({ pluginMessage: { type: 'generate', direction: selected } }, '*');
    }
  </script>
</body>
</html>
```

**Step 8: Install dependencies and build**

Run:
```bash
cd figma-plugin && npm install && npm run build
```

Expected: `dist/code.js` created, no errors.

**Step 9: Commit**

```bash
git add figma-plugin/
git commit -m "feat: scaffold Figma design system generator plugin"
```

---

## Task 2: Color Data Layer

**Files:**
- Create: `figma-plugin/src/data/colors.ts`
- Create: `figma-plugin/src/utils/color.ts`

**Step 1: Create color utility**

```typescript
// src/utils/color.ts

/** Convert hex string to Figma RGBA (0-1 range) */
export function hexToFigmaRgb(hex: string): RGB {
  const h = hex.replace('#', '');
  return {
    r: parseInt(h.substring(0, 2), 16) / 255,
    g: parseInt(h.substring(2, 4), 16) / 255,
    b: parseInt(h.substring(4, 6), 16) / 255,
  };
}

/** Convert hex + alpha to Figma RGBA */
export function hexToFigmaRgba(hex: string, alpha: number): RGBA {
  const rgb = hexToFigmaRgb(hex);
  return { ...rgb, a: alpha };
}
```

**Step 2: Create color data**

```typescript
// src/data/colors.ts

export interface PrimitiveColor {
  name: string;
  hex: string;
}

export interface PrimitiveGroup {
  groupName: string;
  colors: PrimitiveColor[];
}

export interface SemanticColor {
  name: string;
  /** References a primitive token name */
  refA: string;
  refB: string;
  /** Optional alpha override */
  alphaA?: number;
  alphaB?: number;
}

// --- Direction A: Soft Piggy Bank ---

export const primitivesA: PrimitiveGroup[] = [
  {
    groupName: 'sage',
    colors: [
      { name: 'sage/50', hex: '#F0F5F0' },
      { name: 'sage/100', hex: '#D4E6D5' },
      { name: 'sage/200', hex: '#B5D4B7' },
      { name: 'sage/400', hex: '#8BAB8D' },
      { name: 'sage/600', hex: '#5E8A60' },
      { name: 'sage/800', hex: '#3D6640' },
      { name: 'sage/900', hex: '#2A4A2D' },
    ],
  },
  {
    groupName: 'blush',
    colors: [
      { name: 'blush/50', hex: '#FBF2F1' },
      { name: 'blush/100', hex: '#F2DCD9' },
      { name: 'blush/200', hex: '#E5BCB7' },
      { name: 'blush/400', hex: '#C4918A' },
      { name: 'blush/600', hex: '#A36B63' },
      { name: 'blush/800', hex: '#7D4A43' },
    ],
  },
  {
    groupName: 'lavender',
    colors: [
      { name: 'lavender/50', hex: '#F3F0F8' },
      { name: 'lavender/100', hex: '#E2DCF0' },
      { name: 'lavender/400', hex: '#9B8EC0' },
      { name: 'lavender/600', hex: '#7568A0' },
    ],
  },
  {
    groupName: 'neutral',
    colors: [
      { name: 'neutral/0', hex: '#FFFFFF' },
      { name: 'neutral/50', hex: '#FAF8F5' },
      { name: 'neutral/100', hex: '#F0ECE6' },
      { name: 'neutral/200', hex: '#E0DAD2' },
      { name: 'neutral/300', hex: '#C5BDB3' },
      { name: 'neutral/400', hex: '#9E968B' },
      { name: 'neutral/500', hex: '#7A7268' },
      { name: 'neutral/700', hex: '#4A443C' },
      { name: 'neutral/900', hex: '#2D2A26' },
    ],
  },
  {
    groupName: 'status',
    colors: [
      { name: 'error', hex: '#C75D4A' },
      { name: 'success', hex: '#6B9E6F' },
      { name: 'warning', hex: '#D4A643' },
    ],
  },
];

// --- Direction B: Smart & Clean ---

export const primitivesB: PrimitiveGroup[] = [
  {
    groupName: 'teal',
    colors: [
      { name: 'teal/50', hex: '#EFF8F8' },
      { name: 'teal/100', hex: '#B8E0DF' },
      { name: 'teal/200', hex: '#82C8C7' },
      { name: 'teal/400', hex: '#3D9E9D' },
      { name: 'teal/600', hex: '#1A6B6A' },
      { name: 'teal/800', hex: '#0F4847' },
      { name: 'teal/900', hex: '#083332' },
    ],
  },
  {
    groupName: 'amber',
    colors: [
      { name: 'amber/50', hex: '#FDF8EE' },
      { name: 'amber/100', hex: '#F5E6C8' },
      { name: 'amber/200', hex: '#EBCF96' },
      { name: 'amber/400', hex: '#D4A643' },
      { name: 'amber/600', hex: '#B8860B' },
      { name: 'amber/800', hex: '#8A6408' },
    ],
  },
  {
    groupName: 'slate',
    colors: [
      { name: 'slate/50', hex: '#F2F4F7' },
      { name: 'slate/100', hex: '#D5DCE6' },
      { name: 'slate/400', hex: '#5B6F8A' },
      { name: 'slate/600', hex: '#3E5170' },
    ],
  },
  {
    groupName: 'neutral',
    colors: [
      { name: 'neutral/0', hex: '#FFFFFF' },
      { name: 'neutral/50', hex: '#FAFAF9' },
      { name: 'neutral/100', hex: '#F0F0EE' },
      { name: 'neutral/200', hex: '#DDDDD9' },
      { name: 'neutral/300', hex: '#BDBDB8' },
      { name: 'neutral/400', hex: '#97978F' },
      { name: 'neutral/500', hex: '#717169' },
      { name: 'neutral/700', hex: '#44443E' },
      { name: 'neutral/900', hex: '#1C1C1B' },
    ],
  },
  {
    groupName: 'status',
    colors: [
      { name: 'error', hex: '#C4453A' },
      { name: 'success', hex: '#3D8B7A' },
      { name: 'warning', hex: '#D4A643' },
    ],
  },
];

// --- Semantic Tokens (alias layer) ---
// refA = Direction A primitive name, refB = Direction B primitive name

export const semanticColors: SemanticColor[] = [
  // Primary
  { name: 'color/primary', refA: 'sage/600', refB: 'teal/600' },
  { name: 'color/on-primary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/primary-container', refA: 'sage/100', refB: 'teal/100' },
  { name: 'color/on-primary-container', refA: 'sage/900', refB: 'teal/900' },
  // Secondary
  { name: 'color/secondary', refA: 'blush/600', refB: 'amber/600' },
  { name: 'color/on-secondary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/secondary-container', refA: 'blush/100', refB: 'amber/100' },
  { name: 'color/on-secondary-container', refA: 'blush/800', refB: 'amber/800' },
  // Tertiary
  { name: 'color/tertiary', refA: 'lavender/600', refB: 'slate/600' },
  { name: 'color/on-tertiary', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/tertiary-container', refA: 'lavender/100', refB: 'slate/100' },
  { name: 'color/on-tertiary-container', refA: 'lavender/600', refB: 'slate/600' },
  // Error
  { name: 'color/error', refA: 'error', refB: 'error' },
  { name: 'color/on-error', refA: 'neutral/0', refB: 'neutral/0' },
  // Success / Warning
  { name: 'color/success', refA: 'success', refB: 'success' },
  { name: 'color/warning', refA: 'warning', refB: 'warning' },
  // Surface
  { name: 'color/surface', refA: 'neutral/50', refB: 'neutral/50' },
  { name: 'color/on-surface', refA: 'neutral/900', refB: 'neutral/900' },
  { name: 'color/on-surface-variant', refA: 'neutral/500', refB: 'neutral/500' },
  { name: 'color/surface-container-lowest', refA: 'neutral/0', refB: 'neutral/0' },
  { name: 'color/surface-container-low', refA: 'neutral/50', refB: 'neutral/50' },
  { name: 'color/surface-container', refA: 'neutral/100', refB: 'neutral/100' },
  { name: 'color/surface-container-high', refA: 'neutral/200', refB: 'neutral/200' },
  // Outline
  { name: 'color/outline', refA: 'neutral/300', refB: 'neutral/300' },
  { name: 'color/outline-variant', refA: 'neutral/200', refB: 'neutral/200' },
  // Scrim
  { name: 'color/scrim', refA: 'neutral/900', refB: 'neutral/900', alphaA: 0.5, alphaB: 0.5 },
];
```

**Step 3: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 4: Commit**

```bash
git add figma-plugin/src/data/colors.ts figma-plugin/src/utils/color.ts
git commit -m "feat: add color data layer with both direction palettes"
```

---

## Task 3: Typography, Spacing, Radius, and Elevation Data

**Files:**
- Create: `figma-plugin/src/data/typography.ts`
- Create: `figma-plugin/src/data/spacing.ts`
- Create: `figma-plugin/src/data/radius.ts`
- Create: `figma-plugin/src/data/elevation.ts`

**Step 1: Create typography data**

```typescript
// src/data/typography.ts

export interface TypeToken {
  name: string;
  size: number;
  weight: 'Regular' | 'Medium' | 'SemiBold' | 'Bold';
  lineHeight: number;
  letterSpacing: number;
}

export const fontFamilies = {
  directionA: 'Nunito',
  directionB: 'DM Sans',
};

export const fontWeightsToLoad = ['Regular', 'Medium', 'SemiBold', 'Bold'] as const;

export const typeScale: TypeToken[] = [
  { name: 'display/large', size: 57, weight: 'Regular', lineHeight: 64, letterSpacing: -0.25 },
  { name: 'display/medium', size: 45, weight: 'Regular', lineHeight: 52, letterSpacing: 0 },
  { name: 'display/small', size: 36, weight: 'Regular', lineHeight: 44, letterSpacing: 0 },
  { name: 'headline/large', size: 32, weight: 'Regular', lineHeight: 40, letterSpacing: 0 },
  { name: 'headline/medium', size: 28, weight: 'Regular', lineHeight: 36, letterSpacing: 0 },
  { name: 'headline/small', size: 24, weight: 'Regular', lineHeight: 32, letterSpacing: 0 },
  { name: 'title/large', size: 22, weight: 'Regular', lineHeight: 28, letterSpacing: 0 },
  { name: 'title/medium', size: 16, weight: 'Medium', lineHeight: 24, letterSpacing: 0.15 },
  { name: 'title/small', size: 14, weight: 'Medium', lineHeight: 20, letterSpacing: 0.1 },
  { name: 'body/large', size: 16, weight: 'Regular', lineHeight: 24, letterSpacing: 0.5 },
  { name: 'body/medium', size: 14, weight: 'Regular', lineHeight: 20, letterSpacing: 0.25 },
  { name: 'body/small', size: 12, weight: 'Regular', lineHeight: 16, letterSpacing: 0.4 },
  { name: 'label/large', size: 14, weight: 'Medium', lineHeight: 20, letterSpacing: 0.1 },
  { name: 'label/medium', size: 12, weight: 'Medium', lineHeight: 16, letterSpacing: 0.5 },
  { name: 'label/small', size: 11, weight: 'Medium', lineHeight: 16, letterSpacing: 0.5 },
];
```

**Step 2: Create spacing data**

```typescript
// src/data/spacing.ts

export interface SpacingToken {
  name: string;
  value: number;
}

export const spacingScale: SpacingToken[] = [
  { name: 'space/0', value: 0 },
  { name: 'space/1', value: 2 },
  { name: 'space/2', value: 4 },
  { name: 'space/3', value: 8 },
  { name: 'space/4', value: 12 },
  { name: 'space/5', value: 16 },
  { name: 'space/6', value: 20 },
  { name: 'space/7', value: 24 },
  { name: 'space/8', value: 32 },
  { name: 'space/9', value: 40 },
  { name: 'space/10', value: 48 },
  { name: 'space/11', value: 64 },
  { name: 'space/12', value: 80 },
];

export interface SizingToken {
  name: string;
  value: number;
}

export const sizingScale: SizingToken[] = [
  { name: 'icon/sm', value: 20 },
  { name: 'icon/md', value: 24 },
  { name: 'icon/lg', value: 40 },
  { name: 'icon/xl', value: 48 },
  { name: 'touch-target', value: 48 },
];
```

**Step 3: Create radius data**

```typescript
// src/data/radius.ts

export interface RadiusToken {
  name: string;
  valueA: number;
  valueB: number;
}

export const radiusScale: RadiusToken[] = [
  { name: 'radius/none', valueA: 0, valueB: 0 },
  { name: 'radius/xs', valueA: 8, valueB: 4 },
  { name: 'radius/sm', valueA: 12, valueB: 8 },
  { name: 'radius/md', valueA: 16, valueB: 12 },
  { name: 'radius/lg', valueA: 24, valueB: 16 },
  { name: 'radius/xl', valueA: 32, valueB: 24 },
  { name: 'radius/full', valueA: 9999, valueB: 9999 },
];
```

**Step 4: Create elevation data**

```typescript
// src/data/elevation.ts

export interface ElevationToken {
  name: string;
  a: { y: number; blur: number; opacity: number } | null;
  b: { y: number; blur: number; opacity: number } | null;
}

export const elevationScale: ElevationToken[] = [
  { name: 'elevation/0', a: null, b: null },
  { name: 'elevation/1', a: { y: 1, blur: 6, opacity: 0.08 }, b: { y: 1, blur: 3, opacity: 0.12 } },
  { name: 'elevation/2', a: { y: 2, blur: 12, opacity: 0.08 }, b: { y: 2, blur: 6, opacity: 0.10 } },
  { name: 'elevation/3', a: { y: 4, blur: 20, opacity: 0.10 }, b: { y: 4, blur: 10, opacity: 0.12 } },
  { name: 'elevation/4', a: { y: 6, blur: 28, opacity: 0.10 }, b: { y: 6, blur: 14, opacity: 0.12 } },
  { name: 'elevation/5', a: { y: 10, blur: 40, opacity: 0.12 }, b: { y: 10, blur: 24, opacity: 0.14 } },
];
```

**Step 5: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 6: Commit**

```bash
git add figma-plugin/src/data/
git commit -m "feat: add typography, spacing, radius, and elevation data"
```

---

## Task 4: Variable Collection Generator

**Files:**
- Create: `figma-plugin/src/generators/variables.ts`

This is the core generator. It creates all Figma variable collections, variables, and sets values per mode.

**Step 1: Create the variables generator**

```typescript
// src/generators/variables.ts

import { hexToFigmaRgb, hexToFigmaRgba } from '../utils/color';
import { primitivesA, primitivesB, semanticColors, type PrimitiveGroup } from '../data/colors';
import { spacingScale, sizingScale } from '../data/spacing';
import { radiusScale } from '../data/radius';
import { fontFamilies } from '../data/typography';

export type Direction = 'direction-a' | 'direction-b' | 'both';

interface ModeConfig {
  modeAId: string;
  modeBId: string | null;
  isBoth: boolean;
}

/** Flatten a PrimitiveGroup[] into a name→hex map */
function flattenPrimitives(groups: PrimitiveGroup[]): Map<string, string> {
  const map = new Map<string, string>();
  for (const group of groups) {
    for (const c of group.colors) {
      map.set(c.name, c.hex);
    }
  }
  return map;
}

/** Create a variable collection with appropriate modes */
function createCollection(name: string, direction: Direction): { collection: VariableCollection; config: ModeConfig } {
  const collection = figma.variables.createVariableCollection(name);

  if (direction === 'both') {
    // Rename default mode to Direction A
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Soft Piggy Bank');
    const modeBId = collection.addMode('Smart & Clean');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId, isBoth: true },
    };
  } else if (direction === 'direction-a') {
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Soft Piggy Bank');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId: null, isBoth: false },
    };
  } else {
    const defaultModeId = collection.modes[0].modeId;
    collection.renameMode(defaultModeId, 'Smart & Clean');
    return {
      collection,
      config: { modeAId: defaultModeId, modeBId: null, isBoth: false },
    };
  }
}

/** Create all color variables (primitives + semantics) */
export function createColorVariables(direction: Direction): {
  collection: VariableCollection;
  /** Map of semantic token name → Variable for binding later */
  semanticVarMap: Map<string, Variable>;
} {
  const { collection, config } = createCollection('Colors', direction);
  const semanticVarMap = new Map<string, Variable>();

  // Build primitive lookup maps
  const mapA = flattenPrimitives(primitivesA);
  const mapB = flattenPrimitives(primitivesB);

  // Create primitive variables
  const primitiveVarMap = new Map<string, Variable>();

  // Get union of all primitive names
  const allPrimitiveNames = new Set([...mapA.keys(), ...mapB.keys()]);

  for (const name of allPrimitiveNames) {
    const variable = figma.variables.createVariable(name, collection, 'COLOR');
    variable.scopes = ['ALL_FILLS', 'STROKE_COLOR', 'EFFECT_COLOR'];
    primitiveVarMap.set(name, variable);

    if (config.isBoth) {
      const hexA = mapA.get(name);
      const hexB = mapB.get(name);
      if (hexA) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hexA));
      if (hexB && config.modeBId) variable.setValueForMode(config.modeBId, hexToFigmaRgb(hexB));
    } else if (direction === 'direction-a') {
      const hex = mapA.get(name);
      if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hex));
    } else {
      const hex = mapB.get(name);
      if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgb(hex));
    }
  }

  // Create semantic variables as aliases
  for (const token of semanticColors) {
    const variable = figma.variables.createVariable(token.name, collection, 'COLOR');
    variable.scopes = ['ALL_FILLS', 'STROKE_COLOR', 'EFFECT_COLOR'];
    semanticVarMap.set(token.name, variable);

    if (token.alphaA !== undefined || token.alphaB !== undefined) {
      // For scrim/alpha tokens, use direct color values (no aliasing)
      if (config.isBoth) {
        const hexA = mapA.get(token.refA);
        const hexB = mapB.get(token.refB);
        if (hexA) variable.setValueForMode(config.modeAId, hexToFigmaRgba(hexA, token.alphaA ?? 1));
        if (hexB && config.modeBId) variable.setValueForMode(config.modeBId, hexToFigmaRgba(hexB, token.alphaB ?? 1));
      } else {
        const ref = direction === 'direction-a' ? token.refA : token.refB;
        const alpha = direction === 'direction-a' ? (token.alphaA ?? 1) : (token.alphaB ?? 1);
        const hex = (direction === 'direction-a' ? mapA : mapB).get(ref);
        if (hex) variable.setValueForMode(config.modeAId, hexToFigmaRgba(hex, alpha));
      }
    } else {
      // Alias to primitive variable
      if (config.isBoth) {
        const varA = primitiveVarMap.get(token.refA);
        const varB = primitiveVarMap.get(token.refB);
        if (varA) variable.setValueForMode(config.modeAId, figma.variables.createVariableAlias(varA));
        if (varB && config.modeBId) variable.setValueForMode(config.modeBId, figma.variables.createVariableAlias(varB));
      } else {
        const ref = direction === 'direction-a' ? token.refA : token.refB;
        const primitiveVar = primitiveVarMap.get(ref);
        if (primitiveVar) variable.setValueForMode(config.modeAId, figma.variables.createVariableAlias(primitiveVar));
      }
    }
  }

  return { collection, semanticVarMap };
}

/** Create spacing + sizing variables (shared, single mode) */
export function createSpacingVariables(): { collection: VariableCollection; varMap: Map<string, Variable> } {
  const collection = figma.variables.createVariableCollection('Spacing');
  const modeId = collection.modes[0].modeId;
  collection.renameMode(modeId, 'Default');
  const varMap = new Map<string, Variable>();

  for (const token of spacingScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['GAP', 'WIDTH_HEIGHT'];
    variable.setValueForMode(modeId, token.value);
    varMap.set(token.name, variable);
  }

  for (const token of sizingScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['WIDTH_HEIGHT'];
    variable.setValueForMode(modeId, token.value);
    varMap.set(token.name, variable);
  }

  return { collection, varMap };
}

/** Create radius variables (per direction) */
export function createRadiusVariables(direction: Direction): { collection: VariableCollection; varMap: Map<string, Variable> } {
  const { collection, config } = createCollection('Radius', direction);
  const varMap = new Map<string, Variable>();

  for (const token of radiusScale) {
    const variable = figma.variables.createVariable(token.name, collection, 'FLOAT');
    variable.scopes = ['CORNER_RADIUS'];
    varMap.set(token.name, variable);

    if (config.isBoth) {
      variable.setValueForMode(config.modeAId, token.valueA);
      if (config.modeBId) variable.setValueForMode(config.modeBId, token.valueB);
    } else if (direction === 'direction-a') {
      variable.setValueForMode(config.modeAId, token.valueA);
    } else {
      variable.setValueForMode(config.modeAId, token.valueB);
    }
  }

  return { collection, varMap };
}

/** Create typography string variables (font family per direction) */
export function createTypographyVariables(direction: Direction): { collection: VariableCollection } {
  const { collection, config } = createCollection('Typography', direction);

  const fontVar = figma.variables.createVariable('font/family', collection, 'STRING');
  fontVar.scopes = ['FONT_FAMILY'];

  if (config.isBoth) {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionA);
    if (config.modeBId) fontVar.setValueForMode(config.modeBId, fontFamilies.directionB);
  } else if (direction === 'direction-a') {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionA);
  } else {
    fontVar.setValueForMode(config.modeAId, fontFamilies.directionB);
  }

  return { collection };
}
```

**Step 2: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 3: Commit**

```bash
git add figma-plugin/src/generators/variables.ts
git commit -m "feat: add variable collection generator (colors, spacing, radius, typography)"
```

---

## Task 5: Text Styles and Effect Styles Generator

**Files:**
- Create: `figma-plugin/src/generators/styles.ts`

**Step 1: Create the styles generator**

```typescript
// src/generators/styles.ts

import { typeScale, fontFamilies, fontWeightsToLoad } from '../data/typography';
import { elevationScale } from '../data/elevation';
import type { Direction } from './variables';

/** Load all required fonts for both directions */
export async function loadFonts(direction: Direction): Promise<void> {
  const families: string[] = [];

  if (direction === 'direction-a' || direction === 'both') {
    families.push(fontFamilies.directionA);
  }
  if (direction === 'direction-b' || direction === 'both') {
    families.push(fontFamilies.directionB);
  }

  for (const family of families) {
    for (const weight of fontWeightsToLoad) {
      await figma.loadFontAsync({ family, style: weight });
    }
  }

  // Also load Inter for the UI/reference pages
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
}

/** Create all 15 M3 text styles */
export function createTextStyles(direction: Direction): void {
  const family = direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;

  for (const token of typeScale) {
    const style = figma.createTextStyle();
    style.name = token.name;
    style.fontName = { family, style: token.weight };
    style.fontSize = token.size;
    style.lineHeight = { value: token.lineHeight, unit: 'PIXELS' };
    style.letterSpacing = { value: token.letterSpacing, unit: 'PIXELS' };
  }
}

/** Create effect styles for all elevation levels */
export function createEffectStyles(direction: Direction): void {
  for (const token of elevationScale) {
    const style = figma.createEffectStyle();
    style.name = token.name;

    const shadow = direction === 'direction-b' ? token.b : token.a;

    if (shadow === null) {
      style.effects = [];
    } else {
      style.effects = [
        {
          type: 'DROP_SHADOW',
          color: { r: 0, g: 0, b: 0, a: shadow.opacity },
          offset: { x: 0, y: shadow.y },
          radius: shadow.blur,
          spread: 0,
          visible: true,
          blendMode: 'NORMAL',
        },
      ];
    }
  }
}

/** Create mobile grid style */
export function createGridStyle(): void {
  const style = figma.createGridStyle();
  style.name = 'mobile/4-column';
  style.layoutGrids = [
    {
      pattern: 'COLUMNS',
      alignment: 'STRETCH',
      count: 4,
      gutterSize: 16,
      offset: 16,
      visible: true,
      color: { r: 1, g: 0, b: 0, a: 0.1 },
    },
  ];
}
```

**Step 2: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 3: Commit**

```bash
git add figma-plugin/src/generators/styles.ts
git commit -m "feat: add text styles, effect styles, and grid style generators"
```

---

## Task 6: Reference Pages Generator

**Files:**
- Create: `figma-plugin/src/generators/pages.ts`

This creates all reference pages with visual documentation of the design system.

**Step 1: Create the pages generator**

```typescript
// src/generators/pages.ts

import { primitivesA, primitivesB, semanticColors, type PrimitiveGroup } from '../data/colors';
import { typeScale, fontFamilies } from '../data/typography';
import { spacingScale, sizingScale } from '../data/spacing';
import { radiusScale } from '../data/radius';
import { elevationScale } from '../data/elevation';
import { hexToFigmaRgb } from '../utils/color';
import type { Direction } from './variables';

const PAGE_PADDING = 80;
const SECTION_GAP = 60;

function getDirectionLabel(direction: Direction): string {
  if (direction === 'direction-a') return 'Soft Piggy Bank';
  if (direction === 'direction-b') return 'Smart & Clean';
  return 'Both Directions';
}

function createSectionTitle(text: string, parent: FrameNode | PageNode): TextNode {
  const node = figma.createText();
  node.fontName = { family: 'Inter', style: 'Bold' };
  node.fontSize = 24;
  node.characters = text;
  node.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
  parent.appendChild(node);
  return node;
}

function createLabel(text: string, parent: FrameNode): TextNode {
  const node = figma.createText();
  node.fontName = { family: 'Inter', style: 'Regular' };
  node.fontSize = 11;
  node.characters = text;
  node.fills = [{ type: 'SOLID', color: { r: 0.4, g: 0.4, b: 0.4 } }];
  parent.appendChild(node);
  return node;
}

function createAutoLayoutFrame(name: string, direction: 'VERTICAL' | 'HORIZONTAL', gap: number): FrameNode {
  const frame = figma.createFrame();
  frame.name = name;
  frame.layoutMode = direction;
  frame.itemSpacing = gap;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [];
  return frame;
}

/** Create a color swatch (80x80 square with label) */
function createColorSwatch(name: string, hex: string, parent: FrameNode): void {
  const wrapper = createAutoLayoutFrame(name, 'VERTICAL', 4);

  const swatch = figma.createRectangle();
  swatch.name = name;
  swatch.resize(80, 80);
  swatch.cornerRadius = 8;
  swatch.fills = [{ type: 'SOLID', color: hexToFigmaRgb(hex) }];
  swatch.strokes = [{ type: 'SOLID', color: { r: 0.9, g: 0.9, b: 0.9 } }];
  swatch.strokeWeight = 1;
  wrapper.appendChild(swatch);

  const nameLabel = figma.createText();
  nameLabel.fontName = { family: 'Inter', style: 'Medium' };
  nameLabel.fontSize = 10;
  nameLabel.characters = name;
  nameLabel.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
  wrapper.appendChild(nameLabel);

  const hexLabel = figma.createText();
  hexLabel.fontName = { family: 'Inter', style: 'Regular' };
  hexLabel.fontSize = 10;
  hexLabel.characters = hex;
  hexLabel.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
  wrapper.appendChild(hexLabel);

  parent.appendChild(wrapper);
}

// --- Page: Cover ---

export function createCoverPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '📋 Cover';

  const frame = figma.createFrame();
  frame.name = 'Cover';
  frame.resize(1920, 1080);
  frame.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.97, b: 0.95 } }];
  frame.layoutMode = 'VERTICAL';
  frame.primaryAxisAlignItems = 'CENTER';
  frame.counterAxisAlignItems = 'CENTER';
  frame.itemSpacing = 16;
  page.appendChild(frame);

  const title = figma.createText();
  title.fontName = { family: 'Inter', style: 'Bold' };
  title.fontSize = 48;
  title.characters = '[APP_NAME] Design System';
  title.fills = [{ type: 'SOLID', color: { r: 0.15, g: 0.15, b: 0.15 } }];
  frame.appendChild(title);

  const subtitle = figma.createText();
  subtitle.fontName = { family: 'Inter', style: 'Regular' };
  subtitle.fontSize = 20;
  subtitle.characters = `Direction: ${getDirectionLabel(direction)}`;
  subtitle.fills = [{ type: 'SOLID', color: { r: 0.4, g: 0.4, b: 0.4 } }];
  frame.appendChild(subtitle);

  const date = figma.createText();
  date.fontName = { family: 'Inter', style: 'Regular' };
  date.fontSize = 14;
  date.characters = `Generated: ${new Date().toISOString().split('T')[0]}`;
  date.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
  frame.appendChild(date);
}

// --- Page: Colors ---

function createColorGroupRow(group: PrimitiveGroup, parent: FrameNode): void {
  const groupTitle = figma.createText();
  groupTitle.fontName = { family: 'Inter', style: 'Semi Bold' };
  groupTitle.fontSize = 14;
  groupTitle.characters = group.groupName.toUpperCase();
  groupTitle.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  parent.appendChild(groupTitle);

  const row = createAutoLayoutFrame(group.groupName, 'HORIZONTAL', 12);
  for (const color of group.colors) {
    createColorSwatch(color.name, color.hex, row);
  }
  parent.appendChild(row);
}

export function createColorsPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🎨 Colors';

  const container = createAutoLayoutFrame('Colors', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  // Primitives
  if (direction === 'direction-a' || direction === 'both') {
    createSectionTitle('Primitives — Soft Piggy Bank', container);
    for (const group of primitivesA) {
      createColorGroupRow(group, container);
    }
  }

  if (direction === 'direction-b' || direction === 'both') {
    createSectionTitle('Primitives — Smart & Clean', container);
    for (const group of primitivesB) {
      createColorGroupRow(group, container);
    }
  }

  // Semantic tokens
  createSectionTitle('Semantic Tokens', container);
  const semanticNote = figma.createText();
  semanticNote.fontName = { family: 'Inter', style: 'Regular' };
  semanticNote.fontSize = 12;
  semanticNote.characters = 'These tokens reference primitives and switch automatically when you change the variable mode.';
  semanticNote.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
  container.appendChild(semanticNote);

  const semanticRow = createAutoLayoutFrame('semantic-tokens', 'HORIZONTAL', 12);
  semanticRow.layoutWrap = 'WRAP';
  semanticRow.counterAxisSpacing = 12;
  semanticRow.resize(1200, 100);
  semanticRow.primaryAxisSizingMode = 'FIXED';
  semanticRow.counterAxisSizingMode = 'AUTO';

  // Show resolved colors for direction A (or single direction)
  const resolveMap = direction === 'direction-b'
    ? new Map(primitivesB.flatMap(g => g.colors.map(c => [c.name, c.hex])))
    : new Map(primitivesA.flatMap(g => g.colors.map(c => [c.name, c.hex])));

  for (const token of semanticColors) {
    const ref = direction === 'direction-b' ? token.refB : token.refA;
    const hex = resolveMap.get(ref) ?? '#CCCCCC';
    createColorSwatch(token.name, hex, semanticRow);
  }
  container.appendChild(semanticRow);
}

// --- Page: Typography ---

export function createTypographyPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🔤 Typography';

  const container = createAutoLayoutFrame('Typography', 'VERTICAL', 32);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  const family = direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;
  createSectionTitle(`Type Scale — ${family}`, container);

  for (const token of typeScale) {
    const row = createAutoLayoutFrame(token.name, 'VERTICAL', 4);

    // Meta label
    const meta = figma.createText();
    meta.fontName = { family: 'Inter', style: 'Medium' };
    meta.fontSize = 11;
    meta.characters = `${token.name}  |  ${token.size}/${token.lineHeight}  |  ${token.weight}  |  ls: ${token.letterSpacing}`;
    meta.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    row.appendChild(meta);

    // Sample text
    const sample = figma.createText();
    sample.fontName = { family, style: token.weight };
    sample.fontSize = token.size;
    sample.lineHeight = { value: token.lineHeight, unit: 'PIXELS' };
    sample.letterSpacing = { value: token.letterSpacing, unit: 'PIXELS' };
    sample.characters = 'The quick brown fox jumps over the lazy dog';
    sample.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
    row.appendChild(sample);

    container.appendChild(row);
  }
}

// --- Page: Spacing & Sizing ---

export function createSpacingPage(): void {
  const page = figma.createPage();
  page.name = '📏 Spacing & Sizing';

  const container = createAutoLayoutFrame('Spacing', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  // Spacing scale
  createSectionTitle('Spacing Scale (8px grid)', container);

  for (const token of spacingScale) {
    if (token.value === 0) continue;

    const row = createAutoLayoutFrame(token.name, 'HORIZONTAL', 12);
    row.counterAxisAlignItems = 'CENTER';

    const label = figma.createText();
    label.fontName = { family: 'Inter', style: 'Medium' };
    label.fontSize = 12;
    label.characters = `${token.name}  (${token.value}px)`;
    label.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
    label.resize(160, label.height);
    row.appendChild(label);

    const bar = figma.createRectangle();
    bar.name = `${token.value}px`;
    bar.resize(token.value, 24);
    bar.cornerRadius = 4;
    bar.fills = [{ type: 'SOLID', color: { r: 0.35, g: 0.55, b: 0.95 } }];
    row.appendChild(bar);

    container.appendChild(row);
  }

  // Icon sizes
  createSectionTitle('Icon Sizes', container);
  const iconRow = createAutoLayoutFrame('icons', 'HORIZONTAL', 24);
  iconRow.counterAxisAlignItems = 'MAX';

  for (const token of sizingScale) {
    const wrapper = createAutoLayoutFrame(token.name, 'VERTICAL', 4);
    wrapper.counterAxisAlignItems = 'CENTER';

    const rect = figma.createRectangle();
    rect.name = token.name;
    rect.resize(token.value, token.value);
    rect.cornerRadius = 4;
    rect.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
    wrapper.appendChild(rect);

    createLabel(`${token.name} (${token.value})`, wrapper);
    iconRow.appendChild(wrapper);
  }
  container.appendChild(iconRow);
}

// --- Page: Elevation ---

export function createElevationPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🔲 Elevation';

  const container = createAutoLayoutFrame('Elevation', 'VERTICAL', SECTION_GAP);
  container.paddingTop = PAGE_PADDING;
  container.paddingLeft = PAGE_PADDING;
  container.paddingRight = PAGE_PADDING;
  container.paddingBottom = PAGE_PADDING;
  page.appendChild(container);

  createSectionTitle('Elevation Levels', container);

  const row = createAutoLayoutFrame('levels', 'HORIZONTAL', 32);

  for (const token of elevationScale) {
    const shadow = direction === 'direction-b' ? token.b : token.a;
    const card = figma.createFrame();
    card.name = token.name;
    card.resize(160, 160);
    card.cornerRadius = 12;
    card.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    card.layoutMode = 'VERTICAL';
    card.primaryAxisAlignItems = 'CENTER';
    card.counterAxisAlignItems = 'CENTER';
    card.itemSpacing = 8;

    if (shadow) {
      card.effects = [
        {
          type: 'DROP_SHADOW',
          color: { r: 0, g: 0, b: 0, a: shadow.opacity },
          offset: { x: 0, y: shadow.y },
          radius: shadow.blur,
          spread: 0,
          visible: true,
          blendMode: 'NORMAL',
        },
      ];
    }

    const nameText = figma.createText();
    nameText.fontName = { family: 'Inter', style: 'Semi Bold' };
    nameText.fontSize = 14;
    nameText.characters = token.name;
    nameText.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
    card.appendChild(nameText);

    if (shadow) {
      const detailText = figma.createText();
      detailText.fontName = { family: 'Inter', style: 'Regular' };
      detailText.fontSize = 10;
      detailText.characters = `y:${shadow.y} blur:${shadow.blur}\nopacity:${(shadow.opacity * 100).toFixed(0)}%`;
      detailText.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
      card.appendChild(detailText);
    }

    row.appendChild(card);
  }

  container.appendChild(row);
}

// --- Page: Screen Templates ---

export function createScreenTemplatesPage(): void {
  const page = figma.createPage();
  page.name = '📱 Screen Templates';

  const screenNames = ['Home', 'Task Detail', 'Earnings'];
  let xOffset = 0;

  for (const name of screenNames) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.resize(393, 852);
    frame.x = xOffset;
    frame.y = 0;
    frame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];

    // Apply grid
    frame.layoutGrids = [
      {
        pattern: 'COLUMNS',
        alignment: 'STRETCH',
        count: 4,
        gutterSize: 16,
        offset: 16,
        visible: true,
        color: { r: 1, g: 0, b: 0, a: 0.05 },
      },
    ];

    page.appendChild(frame);
    xOffset += 393 + 40;
  }
}
```

**Step 2: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 3: Commit**

```bash
git add figma-plugin/src/generators/pages.ts
git commit -m "feat: add reference page generators (cover, colors, typography, spacing, elevation, screens)"
```

---

## Task 7: Starter Components Generator

**Files:**
- Create: `figma-plugin/src/generators/components.ts`

**Step 1: Create the components generator**

```typescript
// src/generators/components.ts

import { hexToFigmaRgb } from '../utils/color';
import { fontFamilies } from '../data/typography';
import type { Direction } from './variables';

function getFont(direction: Direction): string {
  return direction === 'direction-b' ? fontFamilies.directionB : fontFamilies.directionA;
}

function createButtonComponent(
  name: string,
  fillColor: RGB,
  textColor: RGB,
  radius: number,
  font: string,
  hasBorder: boolean = false,
  borderColor?: RGB,
): ComponentNode {
  const component = figma.createComponent();
  component.name = name;
  component.resize(200, 48);
  component.layoutMode = 'HORIZONTAL';
  component.primaryAxisAlignItems = 'CENTER';
  component.counterAxisAlignItems = 'CENTER';
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.cornerRadius = radius;
  component.fills = [{ type: 'SOLID', color: fillColor }];

  if (hasBorder && borderColor) {
    component.strokes = [{ type: 'SOLID', color: borderColor }];
    component.strokeWeight = 1;
  }

  const label = figma.createText();
  label.fontName = { family: font, style: 'Medium' };
  label.fontSize = 14;
  label.lineHeight = { value: 20, unit: 'PIXELS' };
  label.characters = 'Button Label';
  label.fills = [{ type: 'SOLID', color: textColor }];
  component.appendChild(label);

  return component;
}

function createCardComponent(
  name: string,
  fillColor: RGB,
  radius: number,
  hasBorder: boolean = false,
  borderColor?: RGB,
  shadowY?: number,
  shadowBlur?: number,
  shadowOpacity?: number,
): ComponentNode {
  const component = figma.createComponent();
  component.name = name;
  component.resize(343, 120);
  component.layoutMode = 'VERTICAL';
  component.paddingTop = 16;
  component.paddingBottom = 16;
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.itemSpacing = 8;
  component.cornerRadius = radius;
  component.fills = [{ type: 'SOLID', color: fillColor }];

  if (hasBorder && borderColor) {
    component.strokes = [{ type: 'SOLID', color: borderColor }];
    component.strokeWeight = 1;
  }

  if (shadowY !== undefined && shadowBlur !== undefined && shadowOpacity !== undefined) {
    component.effects = [
      {
        type: 'DROP_SHADOW',
        color: { r: 0, g: 0, b: 0, a: shadowOpacity },
        offset: { x: 0, y: shadowY },
        radius: shadowBlur,
        spread: 0,
        visible: true,
        blendMode: 'NORMAL',
      },
    ];
  }

  return component;
}

export function createComponentsPage(direction: Direction): void {
  const page = figma.createPage();
  page.name = '🧩 Components';

  const font = getFont(direction);
  const isA = direction !== 'direction-b';

  // Resolve key colors from the direction
  const primaryFill = isA ? hexToFigmaRgb('#5E8A60') : hexToFigmaRgb('#1A6B6A');
  const onPrimary: RGB = { r: 1, g: 1, b: 1 };
  const secondaryContainer = isA ? hexToFigmaRgb('#F2DCD9') : hexToFigmaRgb('#F5E6C8');
  const onSecondaryContainer = isA ? hexToFigmaRgb('#7D4A43') : hexToFigmaRgb('#8A6408');
  const surface: RGB = { r: 1, g: 1, b: 1 };
  const surfaceContainer = isA ? hexToFigmaRgb('#F0ECE6') : hexToFigmaRgb('#F0F0EE');
  const onSurface = isA ? hexToFigmaRgb('#2D2A26') : hexToFigmaRgb('#1C1C1B');
  const outline = isA ? hexToFigmaRgb('#C5BDB3') : hexToFigmaRgb('#BDBDB8');
  const outlineVariant = isA ? hexToFigmaRgb('#E0DAD2') : hexToFigmaRgb('#DDDDD9');

  const radiusSm = isA ? 12 : 8;
  const radiusMd = isA ? 16 : 12;
  const radiusFull = 9999;

  const shadowConfig = isA
    ? { y: 1, blur: 6, opacity: 0.08 }
    : { y: 1, blur: 3, opacity: 0.12 };

  const container = figma.createFrame();
  container.name = 'Components';
  container.layoutMode = 'VERTICAL';
  container.primaryAxisSizingMode = 'AUTO';
  container.counterAxisSizingMode = 'AUTO';
  container.itemSpacing = 60;
  container.paddingTop = 80;
  container.paddingLeft = 80;
  container.paddingRight = 80;
  container.paddingBottom = 80;
  container.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.97 } }];
  page.appendChild(container);

  // --- Buttons section ---
  const btnSection = figma.createFrame();
  btnSection.name = 'Buttons';
  btnSection.layoutMode = 'VERTICAL';
  btnSection.primaryAxisSizingMode = 'AUTO';
  btnSection.counterAxisSizingMode = 'AUTO';
  btnSection.itemSpacing = 16;
  btnSection.fills = [];
  container.appendChild(btnSection);

  const btnTitle = figma.createText();
  btnTitle.fontName = { family: 'Inter', style: 'Bold' };
  btnTitle.fontSize = 20;
  btnTitle.characters = 'Buttons';
  btnTitle.fills = [{ type: 'SOLID', color: onSurface }];
  btnSection.appendChild(btnTitle);

  const btnRow = figma.createFrame();
  btnRow.name = 'button-variants';
  btnRow.layoutMode = 'HORIZONTAL';
  btnRow.primaryAxisSizingMode = 'AUTO';
  btnRow.counterAxisSizingMode = 'AUTO';
  btnRow.itemSpacing = 16;
  btnRow.fills = [];
  btnSection.appendChild(btnRow);

  const primaryBtn = createButtonComponent('Type=Primary', primaryFill, onPrimary, radiusSm, font);
  btnRow.appendChild(primaryBtn);

  const secondaryBtn = createButtonComponent('Type=Secondary', secondaryContainer, onSecondaryContainer, radiusSm, font);
  btnRow.appendChild(secondaryBtn);

  const textBtn = createButtonComponent('Type=Text', { r: 0, g: 0, b: 0 }, primaryFill, radiusSm, font);
  textBtn.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0 }];
  btnRow.appendChild(textBtn);

  // Combine as variants
  figma.combineAsVariants([primaryBtn, secondaryBtn, textBtn], btnRow);

  // --- Cards section ---
  const cardSection = figma.createFrame();
  cardSection.name = 'Cards';
  cardSection.layoutMode = 'VERTICAL';
  cardSection.primaryAxisSizingMode = 'AUTO';
  cardSection.counterAxisSizingMode = 'AUTO';
  cardSection.itemSpacing = 16;
  cardSection.fills = [];
  container.appendChild(cardSection);

  const cardTitle = figma.createText();
  cardTitle.fontName = { family: 'Inter', style: 'Bold' };
  cardTitle.fontSize = 20;
  cardTitle.characters = 'Cards';
  cardTitle.fills = [{ type: 'SOLID', color: onSurface }];
  cardSection.appendChild(cardTitle);

  const cardRow = figma.createFrame();
  cardRow.name = 'card-variants';
  cardRow.layoutMode = 'HORIZONTAL';
  cardRow.primaryAxisSizingMode = 'AUTO';
  cardRow.counterAxisSizingMode = 'AUTO';
  cardRow.itemSpacing = 16;
  cardRow.fills = [];
  cardSection.appendChild(cardRow);

  const elevatedCard = createCardComponent('Type=Elevated', surface, radiusMd, false, undefined, shadowConfig.y, shadowConfig.blur, shadowConfig.opacity);
  cardRow.appendChild(elevatedCard);

  const outlinedCard = createCardComponent('Type=Outlined', surface, radiusMd, true, outlineVariant);
  cardRow.appendChild(outlinedCard);

  const filledCard = createCardComponent('Type=Filled', surfaceContainer, radiusMd);
  cardRow.appendChild(filledCard);

  figma.combineAsVariants([elevatedCard, outlinedCard, filledCard], cardRow);

  // --- Chips section ---
  const chipSection = figma.createFrame();
  chipSection.name = 'Chips';
  chipSection.layoutMode = 'VERTICAL';
  chipSection.primaryAxisSizingMode = 'AUTO';
  chipSection.counterAxisSizingMode = 'AUTO';
  chipSection.itemSpacing = 16;
  chipSection.fills = [];
  container.appendChild(chipSection);

  const chipTitle = figma.createText();
  chipTitle.fontName = { family: 'Inter', style: 'Bold' };
  chipTitle.fontSize = 20;
  chipTitle.characters = 'Chips';
  chipTitle.fills = [{ type: 'SOLID', color: onSurface }];
  chipSection.appendChild(chipTitle);

  const chipRow = figma.createFrame();
  chipRow.name = 'chip-variants';
  chipRow.layoutMode = 'HORIZONTAL';
  chipRow.primaryAxisSizingMode = 'AUTO';
  chipRow.counterAxisSizingMode = 'AUTO';
  chipRow.itemSpacing = 12;
  chipRow.fills = [];
  chipSection.appendChild(chipRow);

  // Assist chip
  const assistChip = figma.createComponent();
  assistChip.name = 'Type=Assist';
  assistChip.resize(100, 32);
  assistChip.layoutMode = 'HORIZONTAL';
  assistChip.primaryAxisAlignItems = 'CENTER';
  assistChip.counterAxisAlignItems = 'CENTER';
  assistChip.paddingLeft = 16;
  assistChip.paddingRight = 16;
  assistChip.cornerRadius = radiusFull;
  assistChip.fills = [{ type: 'SOLID', color: surface, opacity: 0 }];
  assistChip.strokes = [{ type: 'SOLID', color: outline }];
  assistChip.strokeWeight = 1;
  const assistLabel = figma.createText();
  assistLabel.fontName = { family: font, style: 'Medium' };
  assistLabel.fontSize = 14;
  assistLabel.characters = 'Assist';
  assistLabel.fills = [{ type: 'SOLID', color: onSurface }];
  assistChip.appendChild(assistLabel);
  chipRow.appendChild(assistChip);

  // Filter selected chip
  const filterChip = figma.createComponent();
  filterChip.name = 'Type=Filter, Selected=true';
  filterChip.resize(100, 32);
  filterChip.layoutMode = 'HORIZONTAL';
  filterChip.primaryAxisAlignItems = 'CENTER';
  filterChip.counterAxisAlignItems = 'CENTER';
  filterChip.paddingLeft = 16;
  filterChip.paddingRight = 16;
  filterChip.cornerRadius = radiusFull;
  filterChip.fills = [{ type: 'SOLID', color: secondaryContainer }];
  const filterLabel = figma.createText();
  filterLabel.fontName = { family: font, style: 'Medium' };
  filterLabel.fontSize = 14;
  filterLabel.characters = 'Filter';
  filterLabel.fills = [{ type: 'SOLID', color: onSecondaryContainer }];
  filterChip.appendChild(filterLabel);
  chipRow.appendChild(filterChip);

  figma.combineAsVariants([assistChip, filterChip], chipRow);
}
```

**Step 2: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: No errors.

**Step 3: Commit**

```bash
git add figma-plugin/src/generators/components.ts
git commit -m "feat: add starter component generators (buttons, cards, chips)"
```

---

## Task 8: Wire Up Main Plugin Logic

**Files:**
- Modify: `figma-plugin/src/code.ts`

**Step 1: Rewrite code.ts to orchestrate all generators**

```typescript
// src/code.ts

import { createColorVariables, createSpacingVariables, createRadiusVariables, createTypographyVariables, type Direction } from './generators/variables';
import { loadFonts, createTextStyles, createEffectStyles, createGridStyle } from './generators/styles';
import { createCoverPage, createColorsPage, createTypographyPage, createSpacingPage, createElevationPage, createScreenTemplatesPage } from './generators/pages';
import { createComponentsPage } from './generators/components';

figma.showUI(__html__, { width: 320, height: 400 });

figma.ui.onmessage = async (msg: { type: string; direction: string }) => {
  if (msg.type !== 'generate') return;

  const direction = msg.direction as Direction;

  try {
    figma.notify('Loading fonts...', { timeout: 2000 });
    await loadFonts(direction);

    figma.notify('Creating variables...', { timeout: 2000 });
    createColorVariables(direction);
    createSpacingVariables();
    createRadiusVariables(direction);
    createTypographyVariables(direction);

    figma.notify('Creating styles...', { timeout: 2000 });
    createTextStyles(direction);
    createEffectStyles(direction);
    createGridStyle();

    figma.notify('Creating reference pages...', { timeout: 2000 });
    createCoverPage(direction);
    createColorsPage(direction);
    createTypographyPage(direction);
    createSpacingPage();
    createElevationPage(direction);
    createComponentsPage(direction);
    createScreenTemplatesPage();

    // Remove the default empty page if it exists and is empty
    const defaultPage = figma.root.children[0];
    if (defaultPage && defaultPage.children.length === 0 && defaultPage.name === 'Page 1') {
      defaultPage.remove();
    }

    // Navigate to cover page
    const coverPage = figma.root.children.find(p => p.name === '📋 Cover');
    if (coverPage) {
      figma.currentPage = coverPage;
    }

    figma.notify('✓ Design system generated!', { timeout: 3000 });
  } catch (error) {
    figma.notify(`Error: ${error}`, { error: true, timeout: 5000 });
  }

  figma.closePlugin();
};
```

**Step 2: Build and verify**

Run: `cd figma-plugin && npm run build`
Expected: `dist/code.js` created, no errors.

**Step 3: Commit**

```bash
git add figma-plugin/src/code.ts
git commit -m "feat: wire up main plugin logic to orchestrate all generators"
```

---

## Task 9: Final Build, Test, and Polish

**Step 1: Full clean build**

Run:
```bash
cd figma-plugin && rm -rf dist && npm run build
```

Expected: `dist/code.js` created with no warnings or errors.

**Step 2: Verify file structure**

Run: `find figma-plugin -type f | sort`

Expected:
```
figma-plugin/dist/code.js
figma-plugin/esbuild.config.mjs
figma-plugin/manifest.json
figma-plugin/package.json
figma-plugin/src/code.ts
figma-plugin/src/data/colors.ts
figma-plugin/src/data/elevation.ts
figma-plugin/src/data/radius.ts
figma-plugin/src/data/spacing.ts
figma-plugin/src/data/typography.ts
figma-plugin/src/generators/components.ts
figma-plugin/src/generators/pages.ts
figma-plugin/src/generators/styles.ts
figma-plugin/src/generators/variables.ts
figma-plugin/src/ui.html
figma-plugin/src/utils/color.ts
figma-plugin/tsconfig.json
```

**Step 3: Add .gitignore**

Create `figma-plugin/.gitignore`:
```
node_modules/
dist/
```

**Step 4: Commit**

```bash
git add figma-plugin/
git commit -m "feat: complete Figma design system generator plugin"
```

---

## How to Use the Plugin

1. Open Figma Desktop
2. Go to **Plugins → Development → Import plugin from manifest...**
3. Select `figma-plugin/manifest.json`
4. Create a new Figma file
5. Run the plugin from **Plugins → Development → [APP_NAME] Design System Generator**
6. Select a direction and click **Generate**
7. The plugin creates all variable collections, styles, reference pages, components, and screen templates

To switch between directions (if "Both" was selected): select any frame → in the right panel under "Layer" → change the variable mode from "Soft Piggy Bank" to "Smart & Clean".

---

## Task Summary

| Task | Description | Dependencies |
|------|-------------|-------------|
| 1 | Scaffold plugin project | None |
| 2 | Color data layer | Task 1 |
| 3 | Typography, spacing, radius, elevation data | Task 1 |
| 4 | Variable collection generator | Tasks 2, 3 |
| 5 | Text styles and effect styles generator | Task 3 |
| 6 | Reference pages generator | Tasks 2, 3 |
| 7 | Starter components generator | Tasks 2, 3 |
| 8 | Wire up main plugin logic | Tasks 4, 5, 6, 7 |
| 9 | Final build, test, and polish | Task 8 |
