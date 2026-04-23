# Figma Design System Sync Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Figma plugin that consumes `design-system.json` (v1 schema from the `extract-design-system` skill) and applies it to the currently open Figma file, with a diff preview before writing.

**Architecture:** Two-process Figma plugin. Main thread (`code.ts`) owns the Figma document API and runs writers per entity kind. UI thread (React, in iframe) owns the file picker, diff view, and apply orchestration UI. They communicate via typed `postMessage`. Pure diff logic lives in `shared/` and is unit-testable without Figma. Identity is tracked via `pluginData` under the `extract-design-system` namespace.

**Tech Stack:** TypeScript, React, esbuild, vitest, @testing-library/react, jsdom, Ajv, @figma/plugin-typings.

**Repo location:** `/Users/markus/Dev/extract-design-system-figma-plugin/` (sibling to `extract-design-system`). All paths below are relative to this repo unless stated.

**Spec:** See `/Users/markus/Dev/earnapp/docs/superpowers/specs/2026-04-23-figma-design-system-sync-plugin-design.md` for design rationale.

---

## File Structure

```
extract-design-system-figma-plugin/
├── .gitignore
├── README.md
├── manifest.json                 # Figma plugin manifest
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── build.mjs                     # esbuild script
├── schema.v1.json                # copied from extract-design-system/references/
├── src/
│   ├── main/
│   │   ├── code.ts               # entry + message router
│   │   ├── identity.ts           # pluginData get/set
│   │   ├── snapshot.ts           # read current Figma state
│   │   └── apply/
│   │       ├── index.ts          # orchestrator
│   │       ├── variables.ts
│   │       ├── text-styles.ts
│   │       ├── effects.ts
│   │       └── components.ts
│   ├── ui/
│   │   ├── index.tsx
│   │   ├── index.html
│   │   ├── App.tsx               # state machine
│   │   ├── screens/
│   │   │   ├── LoadScreen.tsx
│   │   │   ├── AdoptScreen.tsx
│   │   │   ├── DiffScreen.tsx
│   │   │   └── ApplyScreen.tsx
│   │   ├── components/
│   │   │   ├── DiffRow.tsx
│   │   │   ├── EntityGroup.tsx
│   │   │   └── Button.tsx
│   │   └── styles.css
│   └── shared/
│       ├── schema.ts             # v1 TypeScript types
│       ├── validate.ts           # Ajv validator
│       ├── diff.ts               # pure diff
│       ├── rename.ts             # fuzzy rename detection
│       ├── snapshot.ts           # Snapshot interface (NOT the reader, that's in main/)
│       └── messages.ts           # typed message protocol
└── tests/
    ├── manual-smoke.md           # integration checklist
    ├── fixtures/
    │   ├── flutter-minimal.json
    │   ├── flutter-earnwise.json
    │   └── html-react-earnwise.json
    ├── mocks/
    │   └── figma-mock.ts         # Figma API mock for writer tests
    └── unit/
        ├── validate.test.ts
        ├── diff.test.ts
        ├── rename.test.ts
        ├── messages.test.ts
        ├── apply-variables.test.ts
        ├── apply-text-styles.test.ts
        ├── apply-effects.test.ts
        ├── apply-components.test.ts
        └── ui/
            ├── load-screen.test.tsx
            ├── adopt-screen.test.tsx
            ├── diff-screen.test.tsx
            ├── apply-screen.test.tsx
            └── app.test.tsx
```

---

## Task 1: Repo scaffold and tooling

**Files:**
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/package.json`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/tsconfig.json`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/vitest.config.ts`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/.gitignore`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/build.mjs`

- [ ] **Step 1: Create repo directory and initialize git**

```bash
mkdir -p /Users/markus/Dev/extract-design-system-figma-plugin
cd /Users/markus/Dev/extract-design-system-figma-plugin
git init
git branch -m main
```

- [ ] **Step 2: Write package.json**

```json
{
  "name": "extract-design-system-figma-plugin",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "node build.mjs",
    "dev": "node build.mjs --watch",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "ajv": "^8.17.1",
    "ajv-formats": "^3.0.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@figma/plugin-typings": "^1.108.0",
    "@testing-library/react": "^16.1.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/node": "^22.10.2",
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "esbuild": "^0.24.2",
    "jsdom": "^25.0.1",
    "typescript": "^5.7.2",
    "vitest": "^2.1.8"
  }
}
```

- [ ] **Step 3: Write tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "types": ["@figma/plugin-typings", "node"]
  },
  "include": ["src/**/*", "tests/**/*", "build.mjs"]
}
```

- [ ] **Step 4: Write vitest.config.ts**

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    environmentMatchGlobs: [
      ['tests/unit/ui/**', 'jsdom'],
    ],
  },
});
```

- [ ] **Step 5: Write .gitignore**

```
node_modules/
build/
.DS_Store
*.log
```

- [ ] **Step 6: Write build.mjs stub (just enough for later tasks)**

```js
import { build, context } from 'esbuild';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const outDir = join(root, 'build');
const watch = process.argv.includes('--watch');

async function run() {
  await mkdir(outDir, { recursive: true });

  const mainOpts = {
    entryPoints: [join(root, 'src/main/code.ts')],
    bundle: true,
    outfile: join(outDir, 'code.js'),
    target: 'es2020',
    format: 'iife',
  };

  const uiOpts = {
    entryPoints: [join(root, 'src/ui/index.tsx')],
    bundle: true,
    outfile: join(outDir, 'ui.js'),
    target: 'es2020',
    format: 'iife',
    loader: { '.css': 'text' },
  };

  if (watch) {
    const m = await context(mainOpts);
    const u = await context(uiOpts);
    await Promise.all([m.watch(), u.watch()]);
    console.log('Watching...');
  } else {
    await Promise.all([build(mainOpts), build(uiOpts)]);
  }

  await assembleUiHtml();
}

async function assembleUiHtml() {
  const htmlTemplate = await readFile(join(root, 'src/ui/index.html'), 'utf8');
  const uiJs = await readFile(join(outDir, 'ui.js'), 'utf8');
  const inlined = htmlTemplate.replace('<!--UI_SCRIPT-->', `<script>${uiJs}</script>`);
  await writeFile(join(outDir, 'ui.html'), inlined);
}

run().catch(err => { console.error(err); process.exit(1); });
```

- [ ] **Step 7: Install dependencies**

Run: `npm install`
Expected: exits 0, `node_modules/` created, `package-lock.json` created.

- [ ] **Step 8: Verify typecheck runs (expects no source files yet, so passes trivially)**

Run: `npx tsc --noEmit`
Expected: exits 0 (no errors because no source files exist).

- [ ] **Step 9: Commit**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git add .
git commit -m "chore: scaffold plugin repo with tooling"
```

---

## Task 2: Figma plugin manifest and entry stubs

**Files:**
- Create: `manifest.json`
- Create: `src/main/code.ts`
- Create: `src/ui/index.html`
- Create: `src/ui/index.tsx`

- [ ] **Step 1: Write manifest.json**

```json
{
  "name": "Design System Sync",
  "id": "extract-design-system-sync",
  "api": "1.0.0",
  "main": "build/code.js",
  "ui": "build/ui.html",
  "editorType": ["figma"],
  "capabilities": [],
  "enableProposedApi": false,
  "documentAccess": "dynamic-page",
  "networkAccess": { "allowedDomains": ["none"] }
}
```

- [ ] **Step 2: Write src/main/code.ts stub**

```ts
figma.showUI(__html__, { width: 340, height: 560, themeColors: true });
```

- [ ] **Step 3: Write src/ui/index.html template**

```html
<!DOCTYPE html>
<html>
  <head><meta charset="utf-8"><title>Design System Sync</title></head>
  <body>
    <div id="root"></div>
    <!--UI_SCRIPT-->
  </body>
</html>
```

- [ ] **Step 4: Write src/ui/index.tsx stub**

```tsx
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root')!);
root.render(<div>Design System Sync: ready</div>);
```

- [ ] **Step 5: Run build, verify artifacts appear**

Run: `npm run build`
Expected: exits 0; `build/code.js` and `build/ui.html` exist; `build/ui.html` contains an inlined `<script>...</script>` tag.

Run: `test -f build/code.js && test -f build/ui.html && grep -q '<script>' build/ui.html && echo OK`
Expected: prints `OK`.

- [ ] **Step 6: Commit**

```bash
git add manifest.json src/main/code.ts src/ui/index.html src/ui/index.tsx
git commit -m "feat: add figma plugin manifest and entry stubs"
```

---

## Task 3: Shared schema types

Port the v1 schema TypeScript types from the extract-design-system skill so the plugin and skill stay aligned. v1 duplicates the types; v2 may extract them into a shared npm package.

**Files:**
- Create: `src/shared/schema.ts`

- [ ] **Step 1: Write src/shared/schema.ts**

```ts
export type Stack = 'flutter' | 'html-react' | 'ios' | 'android';

export interface DesignSystem {
  $schema?: string;
  version: '1.0.0';
  source: { stack: Stack; extractedAt: string; commit?: string };
  collections: Collection[];
  variables: Variable[];
  aliases?: Alias[];
  textStyles?: TextStyle[];
  effects?: Effect[];
  components: Component[];
  icons?: Icon[];
}

export interface Collection {
  name: string;
  description?: string;
  modes: string[];
  defaultMode: string;
}

export type VariableType = 'color' | 'number' | 'string' | 'boolean';
export type VariableValue = string | number | boolean;

export interface Variable {
  name: string;
  collection: string;
  type: VariableType;
  scope?: string[];
  valuesByMode: Record<string, VariableValue>;
}

export interface Alias { name: string; resolves: string; }

export type Bound<T> = T | { bind: string };

export interface TextStyle {
  name: string;
  fontFamily: Bound<string>;
  fontWeight: Bound<number>;
  fontSize: Bound<number>;
  lineHeight?: { value: number; unit: 'PIXELS' | 'PERCENT' | 'FLUID' };
  letterSpacing?: Bound<number>;
}

export type EffectType = 'DROP_SHADOW' | 'INNER_SHADOW' | 'LAYER_BLUR' | 'BACKGROUND_BLUR';

export interface Effect {
  name: string;
  type: EffectType;
  radius?: number;
  offset?: { x: number; y: number };
  color?: string;
}

export type Tier = 'atom' | 'molecule' | 'organism' | 'template';
export type AxisSizing = 'FILL' | 'HUG' | 'FIXED';

export interface Layout {
  direction: 'HORIZONTAL' | 'VERTICAL' | 'NONE';
  padding?: { top?: number; right?: number; bottom?: number; left?: number };
  gap?: number;
  alignItems?: 'MIN' | 'CENTER' | 'MAX' | 'BASELINE';
  justify?: 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN';
  sizing: { width: AxisSizing; widthValue?: number; height: AxisSizing; heightValue?: number };
  radius?: Bound<number>;
}

export type ComponentPropertyType = 'VARIANT' | 'TEXT' | 'BOOLEAN' | 'INSTANCE_SWAP';

export interface ComponentProperty {
  name: string;
  type: ComponentPropertyType;
  options?: string[];
  default?: unknown;
  preferredValues?: string[];
}

export interface Component {
  name: string;
  tier: Tier;
  description?: string;
  layout: Layout;
  properties: ComponentProperty[];
  variantMappings?: Record<string, Record<string, Bound<string> | string>>;
  responsive?: {
    constraints?: {
      horizontal?: 'MIN' | 'MAX' | 'STRETCH' | 'CENTER' | 'SCALE';
      vertical?: 'MIN' | 'MAX' | 'STRETCH' | 'CENTER' | 'SCALE';
    };
  };
  slots?: { name: string; kind: 'TEXT' | 'INSTANCE' | 'FRAME'; style?: Bound<string> }[];
}

export interface Icon { name: string; svg: string; size?: number; }
```

- [ ] **Step 2: Verify typecheck**

Run: `npx tsc --noEmit`
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add src/shared/schema.ts
git commit -m "feat: add v1 design system schema types"
```

---

## Task 4: JSON schema validation

Copy the JSON Schema from `extract-design-system/references/schema.v1.json` into this repo, then write a validator function backed by Ajv.

**Files:**
- Create: `schema.v1.json` (copied from `/Users/markus/Dev/extract-design-system/references/schema.v1.json`)
- Create: `src/shared/validate.ts`
- Create: `tests/unit/validate.test.ts`
- Create: `tests/fixtures/flutter-minimal.json` (valid fixture)

- [ ] **Step 1: Copy schema file**

```bash
cp /Users/markus/Dev/extract-design-system/references/schema.v1.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/schema.v1.json
```

- [ ] **Step 2: Write a minimal valid fixture**

Create `tests/fixtures/flutter-minimal.json`:

```json
{
  "version": "1.0.0",
  "source": { "stack": "flutter", "extractedAt": "2026-04-23T00:00:00Z" },
  "collections": [
    { "name": "primitives", "modes": ["default"], "defaultMode": "default" }
  ],
  "variables": [
    {
      "name": "color/brand",
      "collection": "primitives",
      "type": "color",
      "valuesByMode": { "default": "#0D9488" }
    }
  ],
  "components": []
}
```

- [ ] **Step 3: Write the failing test**

Create `tests/unit/validate.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { validate } from '../../src/shared/validate.js';

const fixturePath = (name: string) => join(__dirname, '..', 'fixtures', name);

describe('validate', () => {
  it('accepts a minimal valid design system', () => {
    const json = JSON.parse(readFileSync(fixturePath('flutter-minimal.json'), 'utf8'));
    const result = validate(json);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
  });

  it('rejects missing required field', () => {
    const bad = { version: '1.0.0' };
    const result = validate(bad);
    expect(result.ok).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('rejects wrong version', () => {
    const bad = {
      version: '2.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
      collections: [], variables: [], components: []
    };
    const result = validate(bad);
    expect(result.ok).toBe(false);
    expect(result.errors.some(e => e.includes('version'))).toBe(true);
  });
});
```

- [ ] **Step 4: Run test to verify it fails**

Run: `npx vitest run tests/unit/validate.test.ts`
Expected: FAIL with "Cannot find module" or similar (validate.ts doesn't exist yet).

- [ ] **Step 5: Write src/shared/validate.ts**

```ts
import Ajv, { type ErrorObject } from 'ajv';
import addFormats from 'ajv-formats';
import schema from '../../schema.v1.json' with { type: 'json' };
import type { DesignSystem } from './schema.js';

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
const validator = ajv.compile(schema);

export interface ValidateResult {
  ok: boolean;
  errors: string[];
  value?: DesignSystem;
}

export function validate(input: unknown): ValidateResult {
  const ok = validator(input);
  if (ok) return { ok: true, errors: [], value: input as DesignSystem };
  return { ok: false, errors: (validator.errors ?? []).map(formatError) };
}

function formatError(e: ErrorObject): string {
  const path = e.instancePath || '(root)';
  return `${path} ${e.message ?? 'invalid'}`;
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `npx vitest run tests/unit/validate.test.ts`
Expected: PASS, 3/3 tests.

- [ ] **Step 7: Commit**

```bash
git add schema.v1.json src/shared/validate.ts tests/unit/validate.test.ts tests/fixtures/flutter-minimal.json
git commit -m "feat: add ajv-based schema validation"
```

---

## Task 5: Typed message protocol

Define the tagged union of messages between UI and main threads. Pure types + a tiny runtime `makeMessage` helper for symmetric construction.

**Files:**
- Create: `src/shared/messages.ts`
- Create: `tests/unit/messages.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/messages.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { makeMessage, isMessage, type Message } from '../../src/shared/messages.js';

describe('messages', () => {
  it('constructs LOAD_JSON message', () => {
    const m = makeMessage.loadJson({ filename: 'ds.json', content: '{}' });
    expect(m.type).toBe('LOAD_JSON');
    expect(m.payload.filename).toBe('ds.json');
  });

  it('isMessage guards known message types', () => {
    const m = makeMessage.applyRequest({ selections: {} });
    expect(isMessage(m)).toBe(true);
    expect(isMessage({ type: 'UNKNOWN' })).toBe(false);
    expect(isMessage('not an object')).toBe(false);
  });

  it('round-trips via JSON', () => {
    const original = makeMessage.applyProgress({ applied: 3, total: 10, currentKind: 'variables' });
    const parsed = JSON.parse(JSON.stringify(original)) as Message;
    expect(parsed.type).toBe('APPLY_PROGRESS');
    if (parsed.type === 'APPLY_PROGRESS') {
      expect(parsed.payload.applied).toBe(3);
      expect(parsed.payload.total).toBe(10);
    }
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/messages.test.ts`
Expected: FAIL ("Cannot find module").

- [ ] **Step 3: Write src/shared/messages.ts**

```ts
import type { DesignSystem } from './schema.js';

export interface Snapshot {
  collections: SnapshotCollection[];
  variables:   SnapshotVariable[];
  textStyles:  SnapshotTextStyle[];
  effects:     SnapshotEffect[];
  components:  SnapshotComponent[];
  duplicates:  { jsonName: string; kind: string; ids: string[] }[];
  adoptionComplete: boolean;
}
export interface SnapshotCollection { figmaId: string; jsonName: string; displayName: string; modes: { modeId: string; name: string }[] }
export interface SnapshotVariable   { figmaId: string; jsonName: string; displayName: string; collectionId: string; resolvedType: 'COLOR' | 'FLOAT' | 'STRING' | 'BOOLEAN' }
export interface SnapshotTextStyle  { figmaId: string; jsonName: string; displayName: string }
export interface SnapshotEffect     { figmaId: string; jsonName: string; displayName: string }
export interface SnapshotComponent  { figmaId: string; jsonName: string; displayName: string }

export interface DiffSelections {
  variables?: Record<string, boolean>;
  textStyles?: Record<string, boolean>;
  effects?: Record<string, boolean>;
  components?: Record<string, boolean>;
  orphans?: Record<string, boolean>;
}

export type Message =
  | { type: 'LOAD_JSON'; payload: { filename: string; content: string } }
  | { type: 'SNAPSHOT_REQUEST'; payload: {} }
  | { type: 'SNAPSHOT_RESULT'; payload: { snapshot: Snapshot } }
  | { type: 'DIFF_REQUEST'; payload: { designSystem: DesignSystem } }
  | { type: 'DIFF_RESULT'; payload: { diffJson: string } }
  | { type: 'ADOPT_APPLY'; payload: { adoptions: Record<string, string[]> } }
  | { type: 'APPLY_REQUEST'; payload: { designSystem?: DesignSystem; selections: DiffSelections } }
  | { type: 'APPLY_PROGRESS'; payload: { applied: number; total: number; currentKind: string } }
  | { type: 'APPLY_DONE'; payload: { appliedCount: number; failed: { jsonName: string; kind: string; reason: string }[] } };

export const makeMessage = {
  loadJson:       (p: { filename: string; content: string }): Message => ({ type: 'LOAD_JSON', payload: p }),
  snapshotRequest:(): Message => ({ type: 'SNAPSHOT_REQUEST', payload: {} }),
  snapshotResult: (p: { snapshot: Snapshot }): Message => ({ type: 'SNAPSHOT_RESULT', payload: p }),
  diffRequest:    (p: { designSystem: DesignSystem }): Message => ({ type: 'DIFF_REQUEST', payload: p }),
  diffResult:     (p: { diffJson: string }): Message => ({ type: 'DIFF_RESULT', payload: p }),
  adoptApply:     (p: { adoptions: Record<string, string[]> }): Message => ({ type: 'ADOPT_APPLY', payload: p }),
  applyRequest:   (p: { designSystem?: DesignSystem; selections: DiffSelections }): Message => ({ type: 'APPLY_REQUEST', payload: p }),
  applyProgress:  (p: { applied: number; total: number; currentKind: string }): Message => ({ type: 'APPLY_PROGRESS', payload: p }),
  applyDone:      (p: { appliedCount: number; failed: { jsonName: string; kind: string; reason: string }[] }): Message => ({ type: 'APPLY_DONE', payload: p }),
};

const KNOWN_TYPES = new Set([
  'LOAD_JSON', 'SNAPSHOT_REQUEST', 'SNAPSHOT_RESULT',
  'DIFF_REQUEST', 'DIFF_RESULT', 'ADOPT_APPLY',
  'APPLY_REQUEST', 'APPLY_PROGRESS', 'APPLY_DONE',
]);

export function isMessage(x: unknown): x is Message {
  return !!x && typeof x === 'object' && 'type' in x && typeof (x as any).type === 'string' && KNOWN_TYPES.has((x as any).type);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/messages.test.ts`
Expected: PASS, 3/3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/shared/messages.ts tests/unit/messages.test.ts
git commit -m "feat: typed message protocol between main and ui"
```

---

## Task 6: Pure diff logic (Snapshot vs DesignSystem)

Compare a Figma snapshot to a target DesignSystem and produce a full diff (added / updated / removed per entity kind). Identity is by `jsonName`, so renames appear as `removed + added` here; rename detection is a separate pass in Task 7.

**Files:**
- Create: `src/shared/diff.ts`
- Create: `tests/unit/diff.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/diff.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { diff } from '../../src/shared/diff.js';
import type { Snapshot } from '../../src/shared/messages.js';
import type { DesignSystem } from '../../src/shared/schema.js';

const emptySnapshot = (): Snapshot => ({
  collections: [], variables: [], textStyles: [], effects: [], components: [], duplicates: [], adoptionComplete: false
});

const ds = (overrides: Partial<DesignSystem> = {}): DesignSystem => ({
  version: '1.0.0',
  source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
  collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
  variables: [],
  components: [],
  ...overrides,
});

describe('diff', () => {
  it('marks all JSON variables as added when snapshot is empty', () => {
    const result = diff(emptySnapshot(), ds({
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }],
    }));
    expect(result.variables.added.length).toBe(1);
    expect(result.variables.added[0].name).toBe('color/brand');
    expect(result.variables.updated).toEqual([]);
    expect(result.variables.removed).toEqual([]);
  });

  it('marks adopted Figma variable as updated when value differs', () => {
    const snap = emptySnapshot();
    snap.variables.push({ figmaId: 'v1', jsonName: 'color/brand', displayName: 'color/brand', collectionId: 'c1', resolvedType: 'COLOR' });
    const result = diff(snap, ds({
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }],
    }));
    expect(result.variables.updated.length).toBe(1);
    expect(result.variables.added).toEqual([]);
  });

  it('marks Figma variable removed from JSON as orphan', () => {
    const snap = emptySnapshot();
    snap.variables.push({ figmaId: 'v1', jsonName: 'color/gone', displayName: 'color/gone', collectionId: 'c1', resolvedType: 'COLOR' });
    const result = diff(snap, ds());
    expect(result.variables.removed.length).toBe(1);
    expect(result.variables.removed[0].jsonName).toBe('color/gone');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/diff.test.ts`
Expected: FAIL ("Cannot find module").

- [ ] **Step 3: Write src/shared/diff.ts**

```ts
import type { DesignSystem, Variable, TextStyle, Effect, Component, Collection } from './schema.js';
import type {
  Snapshot, SnapshotVariable, SnapshotTextStyle, SnapshotEffect, SnapshotComponent, SnapshotCollection
} from './messages.js';

export interface EntityDiff<TNext, TSnap> {
  added:    TNext[];
  updated:  { name: string; before: TSnap; after: TNext }[];
  removed:  TSnap[];
  renamed:  { from: string; to: string; snapshotItem: TSnap; jsonItem: TNext }[];
}

export interface FullDiff {
  collections: EntityDiff<Collection, SnapshotCollection>;
  variables:   EntityDiff<Variable, SnapshotVariable>;
  textStyles:  EntityDiff<TextStyle, SnapshotTextStyle>;
  effects:     EntityDiff<Effect, SnapshotEffect>;
  components:  EntityDiff<Component, SnapshotComponent>;
}

export function diff(snapshot: Snapshot, ds: DesignSystem): FullDiff {
  return {
    collections: diffKind(snapshot.collections, ds.collections, x => x.jsonName, x => x.name, (snap, json) => snap.displayName === json.name && sameModes(snap.modes.map(m => m.name), json.modes)),
    variables:   diffKind(snapshot.variables, ds.variables, x => x.jsonName, x => x.name, () => false),
    textStyles:  diffKind(snapshot.textStyles, ds.textStyles ?? [], x => x.jsonName, x => x.name, () => false),
    effects:     diffKind(snapshot.effects, ds.effects ?? [], x => x.jsonName, x => x.name, () => false),
    components:  diffKind(snapshot.components, ds.components, x => x.jsonName, x => x.name, () => false),
  };
}

function diffKind<TSnap, TNext>(
  snap: TSnap[],
  next: TNext[],
  snapKey: (s: TSnap) => string,
  nextKey: (n: TNext) => string,
  isUnchanged: (s: TSnap, n: TNext) => boolean,
): EntityDiff<TNext, TSnap> {
  const snapMap = new Map(snap.map(s => [snapKey(s), s]));
  const nextMap = new Map(next.map(n => [nextKey(n), n]));
  const added:   TNext[] = [];
  const removed: TSnap[] = [];
  const updated: { name: string; before: TSnap; after: TNext }[] = [];

  for (const [name, n] of nextMap) {
    const s = snapMap.get(name);
    if (!s) added.push(n);
    else if (!isUnchanged(s, n)) updated.push({ name, before: s, after: n });
  }
  for (const [name, s] of snapMap) if (!nextMap.has(name)) removed.push(s);

  return {
    added: sorted(added, nextKey),
    updated: [...updated].sort((a, b) => a.name.localeCompare(b.name)),
    removed: sorted(removed, snapKey),
    renamed: [],
  };
}

function sorted<T>(xs: T[], key: (x: T) => string): T[] {
  return [...xs].sort((a, b) => key(a).localeCompare(key(b)));
}

function sameModes(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  const sa = [...a].sort(), sb = [...b].sort();
  return sa.every((x, i) => x === sb[i]);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/diff.test.ts`
Expected: PASS, 3/3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/shared/diff.ts tests/unit/diff.test.ts
git commit -m "feat: pure diff between figma snapshot and design system"
```

---

## Task 7: Rename detection

Post-process the diff: pair up items in `removed` with items in `added` that look like the same thing under a new name. Score via a name-similarity metric (bigram Jaccard) and accept pairs above a fixed threshold.

**Files:**
- Create: `src/shared/rename.ts`
- Create: `tests/unit/rename.test.ts`
- Modify: `src/shared/diff.ts` (to wire rename detection into `diff()` or expose a separate pass)

- [ ] **Step 1: Write the failing test**

Create `tests/unit/rename.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { detectRenames, nameSimilarity } from '../../src/shared/rename.js';

describe('nameSimilarity', () => {
  it('returns 1.0 for identical names', () => {
    expect(nameSimilarity('PillButton', 'PillButton')).toBe(1);
  });
  it('returns high score for near-identical names', () => {
    expect(nameSimilarity('PillButton', 'PrimaryButton')).toBeGreaterThan(0.4);
  });
  it('returns low score for unrelated names', () => {
    expect(nameSimilarity('color/brand', 'PillButton')).toBeLessThan(0.3);
  });
});

describe('detectRenames', () => {
  it('pairs removed + added with sufficient similarity as rename', () => {
    const removed = [{ jsonName: 'PillButton', displayName: 'PillButton' } as any];
    const added   = [{ name: 'PrimaryButton' } as any];
    const { renames, remainingRemoved, remainingAdded } = detectRenames(removed, added, r => r.jsonName, a => a.name, 0.4);
    expect(renames.length).toBe(1);
    expect(renames[0].from).toBe('PillButton');
    expect(renames[0].to).toBe('PrimaryButton');
    expect(remainingRemoved).toEqual([]);
    expect(remainingAdded).toEqual([]);
  });

  it('leaves unmatched items in their original buckets', () => {
    const removed = [{ jsonName: 'color/gone', displayName: 'color/gone' } as any];
    const added   = [{ name: 'PrimaryButton' } as any];
    const { renames, remainingRemoved, remainingAdded } = detectRenames(removed, added, r => r.jsonName, a => a.name, 0.4);
    expect(renames.length).toBe(0);
    expect(remainingRemoved.length).toBe(1);
    expect(remainingAdded.length).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/rename.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write src/shared/rename.ts**

```ts
export function nameSimilarity(a: string, b: string): number {
  if (a === b) return 1;
  const an = bigrams(a.toLowerCase());
  const bn = bigrams(b.toLowerCase());
  if (an.size === 0 || bn.size === 0) return 0;
  let inter = 0;
  for (const g of an) if (bn.has(g)) inter++;
  return (2 * inter) / (an.size + bn.size);
}

function bigrams(s: string): Set<string> {
  const out = new Set<string>();
  for (let i = 0; i < s.length - 1; i++) out.add(s.slice(i, i + 2));
  return out;
}

export interface RenamePair<TSnap, TNext> {
  from: string;
  to: string;
  snapshotItem: TSnap;
  jsonItem: TNext;
}

export function detectRenames<TSnap, TNext>(
  removed: TSnap[],
  added:   TNext[],
  snapKey: (s: TSnap) => string,
  nextKey: (n: TNext) => string,
  threshold = 0.4,
): { renames: RenamePair<TSnap, TNext>[]; remainingRemoved: TSnap[]; remainingAdded: TNext[] } {
  const renames: RenamePair<TSnap, TNext>[] = [];
  const usedRemoved = new Set<number>();
  const usedAdded   = new Set<number>();

  const candidates: { ri: number; ai: number; score: number }[] = [];
  for (let ri = 0; ri < removed.length; ri++) {
    for (let ai = 0; ai < added.length; ai++) {
      const score = nameSimilarity(snapKey(removed[ri]), nextKey(added[ai]));
      if (score >= threshold) candidates.push({ ri, ai, score });
    }
  }
  candidates.sort((x, y) => y.score - x.score);

  for (const c of candidates) {
    if (usedRemoved.has(c.ri) || usedAdded.has(c.ai)) continue;
    usedRemoved.add(c.ri);
    usedAdded.add(c.ai);
    renames.push({
      from: snapKey(removed[c.ri]),
      to:   nextKey(added[c.ai]),
      snapshotItem: removed[c.ri],
      jsonItem:     added[c.ai],
    });
  }

  return {
    renames,
    remainingRemoved: removed.filter((_, i) => !usedRemoved.has(i)),
    remainingAdded:   added.filter((_, i) => !usedAdded.has(i)),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/rename.test.ts`
Expected: PASS, 5/5 tests.

- [ ] **Step 5: Wire rename detection into diff()**

Modify `src/shared/diff.ts`. Replace the body of `diffKind` to call `detectRenames` after computing added/removed. Import `detectRenames` and `RenamePair`:

```ts
import { detectRenames } from './rename.js';
```

Update `diffKind` so the final return looks like:

```ts
  const { renames, remainingRemoved, remainingAdded } = detectRenames(
    removed, added, snapKey, nextKey, 0.4,
  );

  return {
    added: sorted(remainingAdded, nextKey),
    updated: [...updated].sort((a, b) => a.name.localeCompare(b.name)),
    removed: sorted(remainingRemoved, snapKey),
    renamed: renames.map(r => ({ from: r.from, to: r.to, snapshotItem: r.snapshotItem, jsonItem: r.jsonItem })),
  };
```

- [ ] **Step 6: Add diff test for the rename path**

Append to `tests/unit/diff.test.ts`:

```ts
  it('detects rename when removed and added are similar', () => {
    const snap = emptySnapshot();
    snap.components.push({ figmaId: 'c1', jsonName: 'PillButton', displayName: 'PillButton' });
    const result = diff(snap, ds({
      components: [{
        name: 'PrimaryButton', tier: 'atom',
        layout: { direction: 'HORIZONTAL', sizing: { width: 'FILL', height: 'FIXED', heightValue: 48 } },
        properties: [],
      }],
    }));
    expect(result.components.renamed.length).toBe(1);
    expect(result.components.renamed[0].from).toBe('PillButton');
    expect(result.components.renamed[0].to).toBe('PrimaryButton');
    expect(result.components.added).toEqual([]);
    expect(result.components.removed).toEqual([]);
  });
```

- [ ] **Step 7: Run all diff tests**

Run: `npx vitest run tests/unit/diff.test.ts tests/unit/rename.test.ts`
Expected: PASS, all tests green.

- [ ] **Step 8: Commit**

```bash
git add src/shared/rename.ts src/shared/diff.ts tests/unit/rename.test.ts tests/unit/diff.test.ts
git commit -m "feat: rename detection in diff via bigram similarity"
```

---

## Task 8: Figma API mock

Hand-roll a Figma mock that stands in for the `figma` global in writer tests. It records every call and returns mock nodes with working id/name/pluginData. Only the surface the plugin uses.

**Files:**
- Create: `tests/mocks/figma-mock.ts`

- [ ] **Step 1: Write tests/mocks/figma-mock.ts**

```ts
export interface CallLogEntry { op: string; args: unknown[]; resultId?: string }

export interface MockNode {
  id: string;
  type: string;
  name: string;
  pluginDataByNamespace: Record<string, Record<string, string>>;
  setSharedPluginData: (ns: string, key: string, value: string) => void;
  getSharedPluginData: (ns: string, key: string) => string;
}

export interface MockCollection extends MockNode { modes: { modeId: string; name: string }[]; defaultModeId: string }
export interface MockVariable   extends MockNode { variableCollectionId: string; resolvedType: string; valuesByMode: Record<string, unknown> }
export interface MockTextStyle  extends MockNode { fontName: { family: string; style: string }; fontSize: number }
export interface MockEffectStyle extends MockNode { effects: unknown[] }
export interface MockComponent  extends MockNode {}

export class FigmaMock {
  public calls: CallLogEntry[] = [];
  private idCounter = 0;
  private _collections: MockCollection[] = [];
  private _variables:   MockVariable[] = [];
  private _textStyles:  MockTextStyle[] = [];
  private _effectStyles: MockEffectStyle[] = [];
  private _components:  MockComponent[] = [];
  private _file: Record<string, Record<string, string>> = {};

  readonly variables = {
    createVariableCollection: (name: string) => {
      const coll = this.makeNode('VariableCollection', name) as MockCollection;
      coll.modes = [{ modeId: this.id(), name: 'Mode 1' }];
      coll.defaultModeId = coll.modes[0].modeId;
      this._collections.push(coll);
      this.calls.push({ op: 'createVariableCollection', args: [name], resultId: coll.id });
      return coll;
    },
    createVariable: (name: string, collection: MockCollection, type: string) => {
      const v = this.makeNode('Variable', name) as MockVariable;
      v.variableCollectionId = collection.id;
      v.resolvedType = type;
      v.valuesByMode = {};
      this._variables.push(v);
      this.calls.push({ op: 'createVariable', args: [name, collection.id, type], resultId: v.id });
      return v;
    },
    getLocalVariableCollections: () => [...this._collections],
    getLocalVariables: () => [...this._variables],
  };

  readonly loadFontAsync = async (font: { family: string; style: string }) => {
    this.calls.push({ op: 'loadFontAsync', args: [font] });
  };

  createTextStyle = () => {
    const s = this.makeNode('TextStyle', 'Unnamed') as MockTextStyle;
    s.fontName = { family: 'Inter', style: 'Regular' };
    s.fontSize = 16;
    this._textStyles.push(s);
    this.calls.push({ op: 'createTextStyle', args: [], resultId: s.id });
    return s;
  };

  createEffectStyle = () => {
    const s = this.makeNode('EffectStyle', 'Unnamed') as MockEffectStyle;
    s.effects = [];
    this._effectStyles.push(s);
    this.calls.push({ op: 'createEffectStyle', args: [], resultId: s.id });
    return s;
  };

  createComponent = () => {
    const c = this.makeNode('Component', 'Unnamed') as MockComponent;
    this._components.push(c);
    this.calls.push({ op: 'createComponent', args: [], resultId: c.id });
    return c;
  };

  getLocalTextStyles  = () => [...this._textStyles];
  getLocalEffectStyles = () => [...this._effectStyles];

  readonly root = {
    findAll: (_pred: (n: MockNode) => boolean) => [] as MockNode[],
  };

  setSharedPluginData = (ns: string, key: string, value: string) => {
    this._file[ns] ??= {};
    this._file[ns][key] = value;
    this.calls.push({ op: 'figma.setSharedPluginData', args: [ns, key, value] });
  };
  getSharedPluginData = (ns: string, key: string) => this._file[ns]?.[key] ?? '';

  private id(): string { return `id-${++this.idCounter}`; }

  private makeNode(type: string, name: string): MockNode {
    const self = this;
    const data: Record<string, Record<string, string>> = {};
    const node: MockNode = {
      id: this.id(),
      type,
      name,
      pluginDataByNamespace: data,
      setSharedPluginData(ns, key, value) {
        data[ns] ??= {};
        data[ns][key] = value;
        self.calls.push({ op: 'node.setSharedPluginData', args: [this.id, ns, key, value] });
      },
      getSharedPluginData(ns, key) { return data[ns]?.[key] ?? ''; },
    };
    return node;
  }
}

export function installFigmaMock(): FigmaMock {
  const mock = new FigmaMock();
  (globalThis as any).figma = mock;
  return mock;
}

export function uninstallFigmaMock(): void {
  delete (globalThis as any).figma;
}
```

- [ ] **Step 2: Verify typecheck**

Run: `npx tsc --noEmit`
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add tests/mocks/figma-mock.ts
git commit -m "feat: figma api mock for writer tests"
```

---

## Task 9: Identity helper (pluginData namespaced)

**Files:**
- Create: `src/main/identity.ts`
- Create: `tests/unit/identity.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/identity.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import {
  NAMESPACE, setJsonName, getJsonName,
  setFileFlag, getFileFlag
} from '../../src/main/identity.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

describe('identity', () => {
  it('writes and reads jsonName on a node under our namespace', () => {
    const n = (figma as any).variables.createVariableCollection('primitives');
    setJsonName(n, 'primitives');
    expect(getJsonName(n)).toBe('primitives');
    expect(n.getSharedPluginData(NAMESPACE, 'jsonName')).toBe('primitives');
  });

  it('writes and reads file-level flags', () => {
    setFileFlag('adoptionComplete', 'true');
    expect(getFileFlag('adoptionComplete')).toBe('true');
    expect(getFileFlag('missingKey')).toBe('');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/identity.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write src/main/identity.ts**

```ts
export const NAMESPACE = 'extract-design-system';

type Node = { setSharedPluginData: (ns: string, key: string, value: string) => void; getSharedPluginData: (ns: string, key: string) => string };

export function setJsonName(node: Node, name: string): void {
  node.setSharedPluginData(NAMESPACE, 'jsonName', name);
}
export function getJsonName(node: Node): string {
  return node.getSharedPluginData(NAMESPACE, 'jsonName');
}

export function setJsonKind(node: Node, kind: string): void {
  node.setSharedPluginData(NAMESPACE, 'jsonKind', kind);
}
export function getJsonKind(node: Node): string {
  return node.getSharedPluginData(NAMESPACE, 'jsonKind');
}

export function setLastSyncedAt(node: Node, iso: string): void {
  node.setSharedPluginData(NAMESPACE, 'lastSyncedAt', iso);
}
export function setSchemaVersion(node: Node, version: string): void {
  node.setSharedPluginData(NAMESPACE, 'schemaVersion', version);
}

export function setFileFlag(key: string, value: string): void {
  (figma as any).setSharedPluginData(NAMESPACE, key, value);
}
export function getFileFlag(key: string): string {
  return (figma as any).getSharedPluginData(NAMESPACE, key);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/identity.test.ts`
Expected: PASS, 2/2 tests.

- [ ] **Step 5: Commit**

```bash
git add src/main/identity.ts tests/unit/identity.test.ts
git commit -m "feat: plugin data identity helpers"
```

---

## Task 10: Snapshot reader

Walk the currently open Figma file and produce a `Snapshot`. Only surfaces objects that carry our `jsonName` pluginData, except during Adoption (which uses a separate path that includes non-owned objects).

**Files:**
- Create: `src/main/snapshot.ts`
- Create: `tests/unit/snapshot.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/snapshot.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { readSnapshot, readAdoptionCandidates } from '../../src/main/snapshot.js';
import { setJsonName, setJsonKind, setFileFlag } from '../../src/main/identity.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

describe('readSnapshot', () => {
  it('returns only items tagged with our jsonName', () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    setJsonName(coll, 'primitives'); setJsonKind(coll, 'collection');
    const v1 = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(v1, 'color/brand'); setJsonKind(v1, 'variable');
    const v2 = (figma as any).variables.createVariable('Untagged', coll, 'COLOR');

    const snap = readSnapshot();
    expect(snap.collections.find(c => c.jsonName === 'primitives')).toBeDefined();
    expect(snap.variables.find(v => v.jsonName === 'color/brand')).toBeDefined();
    expect(snap.variables.find(v => v.displayName === 'Untagged')).toBeUndefined();
  });

  it('reports duplicates', () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    setJsonName(coll, 'primitives');
    const a = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(a, 'color/brand'); setJsonKind(a, 'variable');
    const b = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(b, 'color/brand'); setJsonKind(b, 'variable');
    const snap = readSnapshot();
    expect(snap.duplicates.some(d => d.jsonName === 'color/brand')).toBe(true);
  });

  it('reads adoption flag from file pluginData', () => {
    setFileFlag('adoptionComplete', 'true');
    const snap = readSnapshot();
    expect(snap.adoptionComplete).toBe(true);
  });
});

describe('readAdoptionCandidates', () => {
  it('returns all variable collections with displayName, regardless of jsonName', () => {
    (figma as any).variables.createVariableCollection('primitives');
    (figma as any).variables.createVariableCollection('other');
    const cands = readAdoptionCandidates();
    expect(cands.collections.length).toBeGreaterThanOrEqual(2);
    expect(cands.collections.some(c => c.displayName === 'primitives')).toBe(true);
    expect(cands.collections.some(c => c.displayName === 'other')).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/snapshot.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write src/main/snapshot.ts**

```ts
import type { Snapshot, SnapshotVariable, SnapshotCollection, SnapshotTextStyle, SnapshotEffect, SnapshotComponent } from '../shared/messages.js';
import { getFileFlag, getJsonName, getJsonKind } from './identity.js';

export function readSnapshot(): Snapshot {
  const all = readAdoptionCandidates();

  const collections: SnapshotCollection[] = all.collections.filter(c => c.jsonName);
  const variables:   SnapshotVariable[]   = all.variables.filter(v => v.jsonName);
  const textStyles:  SnapshotTextStyle[]  = all.textStyles.filter(s => s.jsonName);
  const effects:     SnapshotEffect[]     = all.effects.filter(s => s.jsonName);
  const components:  SnapshotComponent[]  = all.components.filter(c => c.jsonName);

  const duplicates: { jsonName: string; kind: string; ids: string[] }[] = [];
  const track = (items: { jsonName: string; figmaId: string }[], kind: string) => {
    const byName = new Map<string, string[]>();
    for (const i of items) {
      const arr = byName.get(i.jsonName) ?? [];
      arr.push(i.figmaId);
      byName.set(i.jsonName, arr);
    }
    for (const [jsonName, ids] of byName) if (ids.length > 1) duplicates.push({ jsonName, kind, ids });
  };
  track(variables, 'variable'); track(textStyles, 'textStyle'); track(effects, 'effect'); track(components, 'component');

  return {
    collections, variables, textStyles, effects, components,
    duplicates,
    adoptionComplete: getFileFlag('adoptionComplete') === 'true',
  };
}

export function readAdoptionCandidates(): Snapshot {
  const collRaw = (figma as any).variables.getLocalVariableCollections() as Array<any>;
  const varRaw  = (figma as any).variables.getLocalVariables()          as Array<any>;
  const tsRaw   = typeof (figma as any).getLocalTextStyles === 'function'  ? (figma as any).getLocalTextStyles()   : [];
  const esRaw   = typeof (figma as any).getLocalEffectStyles === 'function' ? (figma as any).getLocalEffectStyles() : [];
  const compRaw: any[] = [];

  const collections = collRaw.map(c => ({
    figmaId: c.id, jsonName: getJsonName(c), displayName: c.name,
    modes: c.modes.map((m: any) => ({ modeId: m.modeId, name: m.name })),
  }));
  const variables = varRaw.map(v => ({
    figmaId: v.id, jsonName: getJsonName(v), displayName: v.name, collectionId: v.variableCollectionId, resolvedType: v.resolvedType,
  }));
  const textStyles = tsRaw.map((s: any) => ({ figmaId: s.id, jsonName: getJsonName(s), displayName: s.name }));
  const effects    = esRaw.map((s: any) => ({ figmaId: s.id, jsonName: getJsonName(s), displayName: s.name }));
  const components = compRaw.map(c => ({ figmaId: c.id, jsonName: getJsonName(c), displayName: c.name }));

  return {
    collections, variables, textStyles, effects, components,
    duplicates: [],
    adoptionComplete: getFileFlag('adoptionComplete') === 'true',
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/snapshot.test.ts`
Expected: PASS, 4/4 tests.

- [ ] **Step 5: Commit**

```bash
git add src/main/snapshot.ts tests/unit/snapshot.test.ts
git commit -m "feat: snapshot reader for figma file state"
```

---

## Task 11: Apply writer — Variables (with collections, values, aliases)

Creates collections, creates/updates variables, sets values per mode, resolves aliases. Writes identity pluginData on every node. Idempotent when re-applied with the same input.

**Files:**
- Create: `src/main/apply/variables.ts`
- Create: `tests/unit/apply-variables.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/apply-variables.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyVariables } from '../../src/main/apply/variables.js';
import type { DesignSystem } from '../../src/shared/schema.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

const ds = (overrides: Partial<DesignSystem> = {}): DesignSystem => ({
  version: '1.0.0',
  source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
  collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
  variables: [],
  components: [],
  ...overrides,
});

describe('applyVariables', () => {
  it('creates a collection and a color variable with correct identity', () => {
    const d = ds({
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#0D9488' } }]
    });
    const report = applyVariables(d, { allowOrphanDelete: {} });
    expect(report.applied).toBe(2); // 1 collection + 1 variable
    expect(report.failed).toEqual([]);
    const ops = mock.calls.map(c => c.op);
    expect(ops).toContain('createVariableCollection');
    expect(ops).toContain('createVariable');
  });

  it('is idempotent on re-run (no new creates when snapshot already covers it)', () => {
    const d = ds({
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#0D9488' } }]
    });
    applyVariables(d, { allowOrphanDelete: {} });
    const callsBefore = mock.calls.length;
    applyVariables(d, { allowOrphanDelete: {} });
    const secondPass = mock.calls.slice(callsBefore).filter(c => c.op === 'createVariable' || c.op === 'createVariableCollection');
    expect(secondPass).toEqual([]);
  });

  it('renames when snapshot has jsonName matching a rename pair', () => {
    const d1 = ds({
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }]
    });
    applyVariables(d1, { allowOrphanDelete: {} });

    const d2 = ds({
      variables: [{ name: 'color/primary', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }]
    });
    const report = applyVariables(d2, { allowOrphanDelete: {} });
    const variables = (figma as any).variables.getLocalVariables();
    const renamed = variables.find((v: any) => v.name === 'color/primary');
    expect(renamed).toBeDefined();
    expect(variables.filter((v: any) => v.name === 'color/brand').length).toBe(0);
    expect(report.failed).toEqual([]);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/apply-variables.test.ts`
Expected: FAIL (`applyVariables` not defined).

- [ ] **Step 3: Write src/main/apply/variables.ts**

```ts
import type { DesignSystem, Variable, Collection } from '../../shared/schema.js';
import { readAdoptionCandidates } from '../snapshot.js';
import { detectRenames } from '../../shared/rename.js';
import { setJsonName, setJsonKind, setLastSyncedAt, setSchemaVersion } from '../identity.js';

export interface ApplyReport {
  applied: number;
  failed: { jsonName: string; kind: string; reason: string }[];
}

export interface ApplyOptions {
  allowOrphanDelete: Record<string, boolean>;
}

export function applyVariables(ds: DesignSystem, opts: ApplyOptions): ApplyReport {
  const report: ApplyReport = { applied: 0, failed: [] };
  const snap = readAdoptionCandidates();
  const now = new Date().toISOString();

  const collByName = new Map<string, any>();
  for (const c of snap.collections.filter(c => c.jsonName)) {
    const figmaColl = findCollectionById(c.figmaId);
    if (figmaColl) collByName.set(c.jsonName, figmaColl);
  }

  for (const coll of ds.collections) {
    let figmaColl = collByName.get(coll.name);
    if (!figmaColl) {
      try {
        figmaColl = (figma as any).variables.createVariableCollection(coll.name);
        setJsonName(figmaColl, coll.name); setJsonKind(figmaColl, 'collection');
        setLastSyncedAt(figmaColl, now); setSchemaVersion(figmaColl, ds.version);
        collByName.set(coll.name, figmaColl);
        report.applied++;
      } catch (e) {
        report.failed.push({ jsonName: coll.name, kind: 'collection', reason: String(e) });
        continue;
      }
    }
  }

  const removedVars: { jsonName: string; figmaId: string }[] = [];
  const addedVars:   Variable[] = [];
  const owned = new Map<string, any>();
  for (const v of snap.variables.filter(x => x.jsonName)) {
    const figmaVar = findVariableById(v.figmaId);
    if (!figmaVar) continue;
    owned.set(v.jsonName, figmaVar);
  }
  const jsonVarNames = new Set(ds.variables.map(v => v.name));
  for (const [jsonName, node] of owned) if (!jsonVarNames.has(jsonName)) removedVars.push({ jsonName, figmaId: node.id });
  for (const v of ds.variables) if (!owned.has(v.name)) addedVars.push(v);

  const { renames, remainingAdded } = detectRenames(removedVars, addedVars, r => r.jsonName, a => a.name, 0.4);
  for (const r of renames) {
    const node = findVariableById(r.snapshotItem.figmaId);
    if (!node) continue;
    node.name = r.to;
    setJsonName(node, r.to); setLastSyncedAt(node, now);
    report.applied++;
  }

  for (const v of remainingAdded) {
    const coll = collByName.get(v.collection);
    if (!coll) { report.failed.push({ jsonName: v.name, kind: 'variable', reason: `collection ${v.collection} not found` }); continue; }
    try {
      const node = (figma as any).variables.createVariable(v.name, coll, toResolvedType(v.type));
      setJsonName(node, v.name); setJsonKind(node, 'variable');
      setLastSyncedAt(node, now); setSchemaVersion(node, ds.version);
      applyVariableValues(node, v, coll);
      owned.set(v.name, node);
      report.applied++;
    } catch (e) {
      report.failed.push({ jsonName: v.name, kind: 'variable', reason: String(e) });
    }
  }

  for (const v of ds.variables) {
    const node = owned.get(v.name);
    if (!node) continue;
    try {
      applyVariableValues(node, v, collByName.get(v.collection));
      setLastSyncedAt(node, now);
    } catch (e) {
      report.failed.push({ jsonName: v.name, kind: 'variable', reason: String(e) });
    }
  }

  for (const r of removedVars.filter(x => !renames.find(ren => ren.snapshotItem.figmaId === x.figmaId))) {
    if (!opts.allowOrphanDelete[`variable:${r.jsonName}`]) continue;
    const node = findVariableById(r.figmaId);
    if (node && typeof node.remove === 'function') {
      node.remove();
      report.applied++;
    }
  }

  return report;
}

function toResolvedType(t: 'color' | 'number' | 'string' | 'boolean'): string {
  return t === 'color' ? 'COLOR' : t === 'number' ? 'FLOAT' : t === 'string' ? 'STRING' : 'BOOLEAN';
}

function applyVariableValues(node: any, v: Variable, coll: any): void {
  if (!coll) return;
  const modeByName = new Map<string, string>(coll.modes.map((m: any) => [m.name, m.modeId]));
  for (const [modeName, value] of Object.entries(v.valuesByMode)) {
    let modeId = modeByName.get(modeName);
    if (!modeId) modeId = coll.defaultModeId;
    const figmaValue = v.type === 'color' ? hexToRgba(String(value)) : value;
    if (typeof node.setValueForMode === 'function') node.setValueForMode(modeId, figmaValue);
    else node.valuesByMode[modeId] = figmaValue;
  }
}

function hexToRgba(hex: string): { r: number; g: number; b: number; a: number } {
  const h = hex.replace('#', '');
  const n = h.length === 3 ? h.split('').map(c => c + c).join('') : h;
  const r = parseInt(n.slice(0, 2), 16) / 255;
  const g = parseInt(n.slice(2, 4), 16) / 255;
  const b = parseInt(n.slice(4, 6), 16) / 255;
  const a = n.length === 8 ? parseInt(n.slice(6, 8), 16) / 255 : 1;
  return { r, g, b, a };
}

function findCollectionById(id: string): any | undefined {
  return (figma as any).variables.getLocalVariableCollections().find((c: any) => c.id === id);
}
function findVariableById(id: string): any | undefined {
  return (figma as any).variables.getLocalVariables().find((v: any) => v.id === id);
}
```

- [ ] **Step 4: Extend the Figma mock to support variable `remove()` and `setValueForMode`**

Edit `tests/mocks/figma-mock.ts` — inside the `createVariable` implementation, add these methods on the returned object before `this._variables.push(v)`:

```ts
(v as any).setValueForMode = (modeId: string, value: unknown) => {
  v.valuesByMode[modeId] = value;
  this.calls.push({ op: 'variable.setValueForMode', args: [v.id, modeId, value] });
};
(v as any).remove = () => {
  this._variables = this._variables.filter(x => x.id !== v.id);
  this.calls.push({ op: 'variable.remove', args: [v.id] });
};
```

Also in `createVariableCollection`, add a second mode entry optional path: leave modes as is (we only need "default" in tests).

- [ ] **Step 5: Run test to verify it passes**

Run: `npx vitest run tests/unit/apply-variables.test.ts`
Expected: PASS, 3/3 tests.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/variables.ts tests/mocks/figma-mock.ts tests/unit/apply-variables.test.ts
git commit -m "feat: apply writer for variables with rename and orphan handling"
```

---

## Task 12: Apply writer — Text Styles

Creates or updates text styles with variable bindings where the JSON supplies `{bind: ...}`. Loads fonts before assignment.

**Files:**
- Create: `src/main/apply/text-styles.ts`
- Create: `tests/unit/apply-text-styles.test.ts`
- Modify: `tests/mocks/figma-mock.ts` (add `setBoundVariable` on text style nodes)

- [ ] **Step 1: Extend Figma mock for text style bindings**

Edit `tests/mocks/figma-mock.ts`, inside `createTextStyle`, add on the returned `s`:

```ts
(s as any).setBoundVariable = (field: string, variable: unknown) => {
  this.calls.push({ op: 'textStyle.setBoundVariable', args: [s.id, field, (variable as any)?.id] });
};
(s as any).remove = () => {
  this._textStyles = this._textStyles.filter(x => x.id !== s.id);
  this.calls.push({ op: 'textStyle.remove', args: [s.id] });
};
```

- [ ] **Step 2: Write the failing test**

Create `tests/unit/apply-text-styles.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyTextStyles } from '../../src/main/apply/text-styles.js';
import type { DesignSystem } from '../../src/shared/schema.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

const ds = (overrides: Partial<DesignSystem> = {}): DesignSystem => ({
  version: '1.0.0',
  source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
  collections: [], variables: [], components: [],
  ...overrides,
});

describe('applyTextStyles', () => {
  it('creates a text style with static values', async () => {
    const d = ds({ textStyles: [{ name: 'text/body', fontFamily: 'Inter', fontWeight: 400, fontSize: 16 }] });
    const report = await applyTextStyles(d);
    expect(report.applied).toBe(1);
    const ops = mock.calls.map(c => c.op);
    expect(ops).toContain('loadFontAsync');
    expect(ops).toContain('createTextStyle');
  });

  it('applies variable bindings when JSON uses bind syntax', async () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('size/body', coll, 'FLOAT');
    const { setJsonName, setJsonKind } = await import('../../src/main/identity.js');
    setJsonName(v, 'size/body'); setJsonKind(v, 'variable');

    const d = ds({ textStyles: [{ name: 'text/body', fontFamily: 'Inter', fontWeight: 400, fontSize: { bind: 'size/body' } as any }] });
    const report = await applyTextStyles(d);
    expect(report.failed).toEqual([]);
    const bind = mock.calls.find(c => c.op === 'textStyle.setBoundVariable');
    expect(bind).toBeDefined();
    expect(bind!.args[1]).toBe('fontSize');
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npx vitest run tests/unit/apply-text-styles.test.ts`
Expected: FAIL.

- [ ] **Step 4: Write src/main/apply/text-styles.ts**

```ts
import type { DesignSystem, TextStyle, Bound } from '../../shared/schema.js';
import { setJsonName, setJsonKind, setLastSyncedAt, setSchemaVersion, getJsonName } from '../identity.js';
import type { ApplyReport } from './variables.js';

export async function applyTextStyles(ds: DesignSystem): Promise<ApplyReport> {
  const report: ApplyReport = { applied: 0, failed: [] };
  const now = new Date().toISOString();

  const existing = typeof (figma as any).getLocalTextStyles === 'function' ? (figma as any).getLocalTextStyles() : [];
  const byJsonName = new Map<string, any>();
  for (const s of existing) { const n = getJsonName(s); if (n) byJsonName.set(n, s); }

  for (const t of ds.textStyles ?? []) {
    try {
      const family = unwrapBound(t.fontFamily, ds) ?? 'Inter';
      const weight = unwrapBound(t.fontWeight, ds) ?? 400;
      const style  = weightToStyle(weight as number);
      await (figma as any).loadFontAsync({ family, style });

      let node = byJsonName.get(t.name);
      if (!node) {
        node = (figma as any).createTextStyle();
        setJsonName(node, t.name); setJsonKind(node, 'textStyle');
        setSchemaVersion(node, ds.version);
      }
      node.name = t.name;
      node.fontName = { family, style };
      node.fontSize = typeof t.fontSize === 'object' ? 16 : t.fontSize;

      if (typeof t.fontSize === 'object' && 'bind' in t.fontSize) {
        const v = findVariableByJsonName(t.fontSize.bind);
        if (v && typeof node.setBoundVariable === 'function') node.setBoundVariable('fontSize', v);
      }

      setLastSyncedAt(node, now);
      report.applied++;
    } catch (e) {
      report.failed.push({ jsonName: t.name, kind: 'textStyle', reason: String(e) });
    }
  }

  return report;
}

function unwrapBound<T>(v: Bound<T> | undefined, _ds: DesignSystem): T | undefined {
  if (v === undefined) return undefined;
  if (typeof v === 'object' && v !== null && 'bind' in (v as any)) return undefined;
  return v as T;
}

function weightToStyle(weight: number): string {
  if (weight <= 350) return 'Light';
  if (weight <= 450) return 'Regular';
  if (weight <= 550) return 'Medium';
  if (weight <= 650) return 'SemiBold';
  if (weight <= 750) return 'Bold';
  return 'Black';
}

function findVariableByJsonName(name: string): any | undefined {
  return (figma as any).variables.getLocalVariables().find((v: any) => getJsonName(v) === name);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npx vitest run tests/unit/apply-text-styles.test.ts`
Expected: PASS, 2/2 tests.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/text-styles.ts tests/mocks/figma-mock.ts tests/unit/apply-text-styles.test.ts
git commit -m "feat: apply writer for text styles with variable bindings"
```

---

## Task 13: Apply writer — Effects

**Files:**
- Create: `src/main/apply/effects.ts`
- Create: `tests/unit/apply-effects.test.ts`

- [ ] **Step 1: Extend Figma mock**

Edit `tests/mocks/figma-mock.ts`, inside `createEffectStyle`, add on returned `s`:

```ts
(s as any).remove = () => {
  this._effectStyles = this._effectStyles.filter(x => x.id !== s.id);
  this.calls.push({ op: 'effectStyle.remove', args: [s.id] });
};
```

- [ ] **Step 2: Write the failing test**

Create `tests/unit/apply-effects.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyEffects } from '../../src/main/apply/effects.js';
import type { DesignSystem } from '../../src/shared/schema.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

describe('applyEffects', () => {
  it('creates a drop shadow effect style', () => {
    const ds: DesignSystem = {
      version: '1.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
      collections: [], variables: [], components: [],
      effects: [{ name: 'shadow/card', type: 'DROP_SHADOW', radius: 12, offset: { x: 0, y: 4 }, color: '#00000020' }],
    };
    const report = applyEffects(ds);
    expect(report.applied).toBe(1);
    expect(mock.calls.some(c => c.op === 'createEffectStyle')).toBe(true);
    const style = (figma as any).getLocalEffectStyles()[0];
    expect(style.effects[0].type).toBe('DROP_SHADOW');
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npx vitest run tests/unit/apply-effects.test.ts`
Expected: FAIL.

- [ ] **Step 4: Write src/main/apply/effects.ts**

```ts
import type { DesignSystem, Effect } from '../../shared/schema.js';
import { setJsonName, setJsonKind, setLastSyncedAt, setSchemaVersion, getJsonName } from '../identity.js';
import type { ApplyReport } from './variables.js';

export function applyEffects(ds: DesignSystem): ApplyReport {
  const report: ApplyReport = { applied: 0, failed: [] };
  const now = new Date().toISOString();
  const existing = typeof (figma as any).getLocalEffectStyles === 'function' ? (figma as any).getLocalEffectStyles() : [];
  const byJsonName = new Map<string, any>();
  for (const s of existing) { const n = getJsonName(s); if (n) byJsonName.set(n, s); }

  for (const e of ds.effects ?? []) {
    try {
      let node = byJsonName.get(e.name);
      if (!node) {
        node = (figma as any).createEffectStyle();
        setJsonName(node, e.name); setJsonKind(node, 'effect');
        setSchemaVersion(node, ds.version);
      }
      node.name = e.name;
      node.effects = [buildEffect(e)];
      setLastSyncedAt(node, now);
      report.applied++;
    } catch (err) {
      report.failed.push({ jsonName: e.name, kind: 'effect', reason: String(err) });
    }
  }
  return report;
}

function buildEffect(e: Effect) {
  return {
    type: e.type,
    radius: e.radius ?? 0,
    offset: e.offset ?? { x: 0, y: 0 },
    color: e.color ? hexToRgba(e.color) : { r: 0, g: 0, b: 0, a: 0.2 },
    visible: true, blendMode: 'NORMAL',
  };
}

function hexToRgba(hex: string): { r: number; g: number; b: number; a: number } {
  const h = hex.replace('#', '');
  const n = h.length === 3 ? h.split('').map(c => c + c).join('') : h;
  const r = parseInt(n.slice(0, 2), 16) / 255;
  const g = parseInt(n.slice(2, 4), 16) / 255;
  const b = parseInt(n.slice(4, 6), 16) / 255;
  const a = n.length === 8 ? parseInt(n.slice(6, 8), 16) / 255 : 1;
  return { r, g, b, a };
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npx vitest run tests/unit/apply-effects.test.ts`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/effects.ts tests/mocks/figma-mock.ts tests/unit/apply-effects.test.ts
git commit -m "feat: apply writer for effect styles"
```

---

## Task 14: Apply writer — Components (shell + slot placeholders)

Creates component sets with one Component per VARIANT combination. Draws the exact frame shell and hydrates slots with placeholders at creation time only (never touched on re-apply, per the placeholder persistence rule).

**Files:**
- Create: `src/main/apply/components.ts`
- Create: `tests/unit/apply-components.test.ts`
- Modify: `tests/mocks/figma-mock.ts` (add `createFrame`, `createText`, `combineAsVariants`, `Component.resize`, property definitions)

- [ ] **Step 1: Extend Figma mock for components and frames**

Edit `tests/mocks/figma-mock.ts`. Add to `FigmaMock` class:

```ts
readonly currentPage = {
  children: [] as any[],
  appendChild: (node: any) => { (this as any).currentPage.children.push(node); this.calls.push({ op: 'page.appendChild', args: [node.id] }); },
};

createFrame = () => {
  const f: any = {
    ...this.makeNode('Frame', 'Frame'),
    layoutMode: 'NONE',
    primaryAxisSizingMode: 'AUTO',
    counterAxisSizingMode: 'AUTO',
    paddingTop: 0, paddingRight: 0, paddingBottom: 0, paddingLeft: 0,
    itemSpacing: 0,
    cornerRadius: 0,
    children: [] as any[],
    fills: [], strokes: [], strokeWeight: 0,
    appendChild: (c: any) => { f.children.push(c); this.calls.push({ op: 'frame.appendChild', args: [f.id, c.id] }); },
    resize: (w: number, h: number) => { f.width = w; f.height = h; this.calls.push({ op: 'frame.resize', args: [f.id, w, h] }); },
    setBoundVariable: (field: string, v: any) => { this.calls.push({ op: 'frame.setBoundVariable', args: [f.id, field, v?.id] }); },
  };
  this.calls.push({ op: 'createFrame', args: [], resultId: f.id });
  return f;
};

createText = () => {
  const t: any = {
    ...this.makeNode('Text', 'Text'),
    characters: '', fontName: { family: 'Inter', style: 'Regular' }, fontSize: 12,
    textStyleId: '',
    setBoundVariable: (field: string, v: any) => { this.calls.push({ op: 'text.setBoundVariable', args: [t.id, field, v?.id] }); },
  };
  this.calls.push({ op: 'createText', args: [], resultId: t.id });
  return t;
};

combineAsVariants = (components: any[], parent: any) => {
  const set: any = {
    ...this.makeNode('ComponentSet', 'ComponentSet'),
    children: [...components],
    componentPropertyDefinitions: {},
    addComponentProperty: (name: string, type: string, defaultValue: unknown, options?: unknown) => {
      set.componentPropertyDefinitions[name] = { type, defaultValue, options };
      this.calls.push({ op: 'set.addComponentProperty', args: [set.id, name, type, defaultValue] });
    },
  };
  this.calls.push({ op: 'combineAsVariants', args: [components.map(c => c.id)], resultId: set.id });
  parent.appendChild(set);
  return set;
};
```

Also extend `createComponent` to add a `resize(w, h)`, `appendChild`, and fill/layoutMode setters:

```ts
createComponent = () => {
  const c: any = {
    ...this.makeNode('Component', 'Unnamed'),
    layoutMode: 'NONE',
    primaryAxisSizingMode: 'AUTO',
    counterAxisSizingMode: 'AUTO',
    paddingTop: 0, paddingRight: 0, paddingBottom: 0, paddingLeft: 0,
    itemSpacing: 0,
    cornerRadius: 0,
    children: [] as any[],
    fills: [], width: 0, height: 0,
    appendChild: (ch: any) => { c.children.push(ch); this.calls.push({ op: 'component.appendChild', args: [c.id, ch.id] }); },
    resize: (w: number, h: number) => { c.width = w; c.height = h; this.calls.push({ op: 'component.resize', args: [c.id, w, h] }); },
    setBoundVariable: (field: string, v: any) => { this.calls.push({ op: 'component.setBoundVariable', args: [c.id, field, v?.id] }); },
  };
  this._components.push(c);
  this.calls.push({ op: 'createComponent', args: [], resultId: c.id });
  return c;
};
```

Also add `findAllPages` or `figma.currentPage` access so the writer can append components. The `currentPage` field above covers this.

Finally expose `_components` via a getter method for tests:

```ts
getLocalComponents = () => [...this._components];
```

- [ ] **Step 2: Write the failing test**

Create `tests/unit/apply-components.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyComponents } from '../../src/main/apply/components.js';
import type { DesignSystem } from '../../src/shared/schema.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

const ds = (overrides: Partial<DesignSystem> = {}): DesignSystem => ({
  version: '1.0.0',
  source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
  collections: [], variables: [], components: [],
  ...overrides,
});

describe('applyComponents', () => {
  it('creates a component with shell properties and text slot placeholder', async () => {
    const d = ds({
      components: [{
        name: 'PillButton',
        tier: 'atom',
        layout: { direction: 'HORIZONTAL', sizing: { width: 'FILL', height: 'FIXED', heightValue: 48 }, padding: { top: 14, right: 16, bottom: 14, left: 16 } },
        properties: [{ name: 'label', type: 'TEXT', default: 'Continue' }],
        slots: [{ name: 'label', kind: 'TEXT' }],
      }],
    });
    const report = await applyComponents(d);
    expect(report.failed).toEqual([]);
    expect(report.applied).toBeGreaterThan(0);
    const ops = mock.calls.map(c => c.op);
    expect(ops).toContain('createComponent');
    expect(ops).toContain('createText');
  });

  it('creates one component per VARIANT combination, wrapped in a set', async () => {
    const d = ds({
      components: [{
        name: 'PillButton',
        tier: 'atom',
        layout: { direction: 'HORIZONTAL', sizing: { width: 'HUG', height: 'HUG' } },
        properties: [{ name: 'variant', type: 'VARIANT', options: ['primary', 'secondary'], default: 'primary' }],
      }],
    });
    const report = await applyComponents(d);
    expect(report.failed).toEqual([]);
    const comps = (figma as any).getLocalComponents();
    expect(comps.length).toBe(2);
    expect(mock.calls.some(c => c.op === 'combineAsVariants')).toBe(true);
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npx vitest run tests/unit/apply-components.test.ts`
Expected: FAIL.

- [ ] **Step 4: Write src/main/apply/components.ts**

```ts
import type { DesignSystem, Component, Layout, ComponentProperty, Bound } from '../../shared/schema.js';
import { setJsonName, setJsonKind, setLastSyncedAt, setSchemaVersion, getJsonName, NAMESPACE } from '../identity.js';
import type { ApplyReport } from './variables.js';

export async function applyComponents(ds: DesignSystem): Promise<ApplyReport> {
  const report: ApplyReport = { applied: 0, failed: [] };
  const now = new Date().toISOString();

  const page = (figma as any).currentPage;
  const existing: any[] = typeof (figma as any).getLocalComponents === 'function' ? (figma as any).getLocalComponents() : [];
  const setsByJsonName = new Map<string, any>();
  for (const c of existing) { const n = getJsonName(c); if (n) setsByJsonName.set(n, c); }

  for (const comp of ds.components) {
    try {
      if (setsByJsonName.has(comp.name)) {
        updateComponentShell(setsByJsonName.get(comp.name), comp, ds);
        setLastSyncedAt(setsByJsonName.get(comp.name), now);
        report.applied++;
        continue;
      }

      const variantCombos = enumerateVariants(comp.properties);
      const createdVariants: any[] = [];
      for (const combo of variantCombos) {
        const variantComp = (figma as any).createComponent();
        variantComp.name = variantNameFrom(comp.name, combo);
        applyShell(variantComp, comp.layout, comp.variantMappings?.[combo.key] ?? {});
        hydrateSlots(variantComp, comp, ds);
        setJsonName(variantComp, comp.name); setJsonKind(variantComp, 'component');
        setSchemaVersion(variantComp, ds.version); setLastSyncedAt(variantComp, now);
        createdVariants.push(variantComp);
      }

      if (createdVariants.length === 0) {
        const onlyComp = (figma as any).createComponent();
        onlyComp.name = comp.name;
        applyShell(onlyComp, comp.layout, {});
        hydrateSlots(onlyComp, comp, ds);
        setJsonName(onlyComp, comp.name); setJsonKind(onlyComp, 'component');
        setSchemaVersion(onlyComp, ds.version); setLastSyncedAt(onlyComp, now);
        createdVariants.push(onlyComp);
      }

      const set = (figma as any).combineAsVariants(createdVariants, page);
      set.name = comp.name;
      setJsonName(set, comp.name); setJsonKind(set, 'component');
      setSchemaVersion(set, ds.version); setLastSyncedAt(set, now);

      for (const p of comp.properties) {
        if (p.type === 'VARIANT') continue;
        const figType = p.type === 'TEXT' ? 'TEXT' : p.type === 'BOOLEAN' ? 'BOOLEAN' : 'INSTANCE_SWAP';
        set.addComponentProperty(p.name, figType, p.default ?? defaultForType(p.type));
      }

      report.applied++;
    } catch (e) {
      report.failed.push({ jsonName: comp.name, kind: 'component', reason: String(e) });
    }
  }

  return report;
}

function enumerateVariants(props: ComponentProperty[]): { key: string; values: Record<string, string> }[] {
  const variantProps = props.filter(p => p.type === 'VARIANT' && p.options && p.options.length > 0);
  if (variantProps.length === 0) return [];
  const combos: Record<string, string>[] = [{}];
  for (const vp of variantProps) {
    const next: Record<string, string>[] = [];
    for (const c of combos) for (const opt of vp.options!) next.push({ ...c, [vp.name]: opt });
    combos.length = 0; combos.push(...next);
  }
  return combos.map(v => ({ key: Object.entries(v).map(([k, val]) => `${k}=${val}`).join(','), values: v }));
}

function variantNameFrom(base: string, combo: { key: string }): string {
  return combo.key.length ? combo.key : base;
}

function applyShell(node: any, layout: Layout, mapping: Record<string, any>): void {
  node.layoutMode = layout.direction === 'NONE' ? 'NONE' : layout.direction;
  node.primaryAxisSizingMode   = sizingToMode(layout.sizing.width, layout.direction === 'HORIZONTAL');
  node.counterAxisSizingMode   = sizingToMode(layout.sizing.height, layout.direction !== 'HORIZONTAL');
  if (layout.sizing.width === 'FIXED' && typeof layout.sizing.widthValue === 'number' && typeof node.resize === 'function') {
    const h = layout.sizing.heightValue ?? node.height ?? 0;
    node.resize(layout.sizing.widthValue, h);
  }
  if (layout.sizing.height === 'FIXED' && typeof layout.sizing.heightValue === 'number' && typeof node.resize === 'function') {
    const w = layout.sizing.widthValue ?? node.width ?? 0;
    node.resize(w, layout.sizing.heightValue);
  }
  if (layout.padding) {
    node.paddingTop    = layout.padding.top    ?? 0;
    node.paddingRight  = layout.padding.right  ?? 0;
    node.paddingBottom = layout.padding.bottom ?? 0;
    node.paddingLeft   = layout.padding.left   ?? 0;
  }
  if (typeof layout.gap === 'number') node.itemSpacing = layout.gap;
  if (layout.alignItems) node.counterAxisAlignItems = alignmentToFigma(layout.alignItems);
  if (layout.justify)    node.primaryAxisAlignItems = justifyToFigma(layout.justify);
  applyRadius(node, layout.radius);
  applyFill(node, mapping.fill);
}

function sizingToMode(a: 'FILL' | 'HUG' | 'FIXED', _isPrimary: boolean): 'FIXED' | 'AUTO' {
  return a === 'FIXED' ? 'FIXED' : 'AUTO';
}
function alignmentToFigma(a: 'MIN' | 'CENTER' | 'MAX' | 'BASELINE'): string { return a === 'BASELINE' ? 'MIN' : a; }
function justifyToFigma(j: 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN'): string { return j; }

function applyRadius(node: any, radius: Bound<number> | undefined): void {
  if (radius === undefined) return;
  if (typeof radius === 'number') { node.cornerRadius = radius; return; }
  if ('bind' in radius) {
    const v = findVariableByJsonName(radius.bind);
    if (v && typeof node.setBoundVariable === 'function') node.setBoundVariable('topLeftRadius', v);
  }
}

function applyFill(node: any, fill: any): void {
  if (!fill) return;
  if (typeof fill === 'object' && 'bind' in fill) {
    const v = findVariableByJsonName(fill.bind);
    if (v && typeof node.setBoundVariable === 'function') node.setBoundVariable('fills', v);
    return;
  }
  if (typeof fill === 'string') {
    node.fills = [{ type: 'SOLID', color: hexToRgb(fill), opacity: 1 }];
  }
}

function hydrateSlots(node: any, comp: Component, ds: DesignSystem): void {
  for (const slot of comp.slots ?? []) {
    if (slot.kind === 'TEXT') {
      const t = (figma as any).createText();
      t.name = slot.name;
      t.characters = capitalize(slot.name);
      t.setSharedPluginData(NAMESPACE, 'isPlaceholder', 'true');
      if (slot.style && typeof slot.style === 'object' && 'bind' in (slot.style as any)) {
        const v = findVariableByJsonName((slot.style as any).bind);
        if (v && typeof t.setBoundVariable === 'function') t.setBoundVariable('fontSize', v);
      }
      node.appendChild(t);
    } else if (slot.kind === 'INSTANCE') {
      const ph = (figma as any).createFrame();
      ph.name = slot.name;
      ph.resize(24, 24);
      ph.strokes = [{ type: 'SOLID', color: { r: 0.7, g: 0.7, b: 0.7 } }];
      ph.strokeWeight = 1;
      ph.setSharedPluginData(NAMESPACE, 'isPlaceholder', 'true');
      node.appendChild(ph);
    } else {
      const ph = (figma as any).createFrame();
      ph.name = slot.name;
      ph.resize(48, 48);
      ph.setSharedPluginData(NAMESPACE, 'isPlaceholder', 'true');
      node.appendChild(ph);
    }
  }
}

function updateComponentShell(set: any, comp: Component, _ds: DesignSystem): void {
  for (const variant of (set.children ?? [])) applyShell(variant, comp.layout, {});
}

function capitalize(s: string): string { return s.charAt(0).toUpperCase() + s.slice(1); }

function findVariableByJsonName(name: string): any | undefined {
  const vars = (figma as any).variables?.getLocalVariables?.() ?? [];
  return vars.find((v: any) => getJsonName(v) === name);
}

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const h = hex.replace('#', '');
  const n = h.length === 3 ? h.split('').map(c => c + c).join('') : h;
  return { r: parseInt(n.slice(0, 2), 16) / 255, g: parseInt(n.slice(2, 4), 16) / 255, b: parseInt(n.slice(4, 6), 16) / 255 };
}

function defaultForType(t: string): unknown { return t === 'BOOLEAN' ? false : t === 'TEXT' ? '' : ''; }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npx vitest run tests/unit/apply-components.test.ts`
Expected: PASS, 2/2 tests.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/components.ts tests/mocks/figma-mock.ts tests/unit/apply-components.test.ts
git commit -m "feat: apply writer for components with shell and slot placeholders"
```

---

## Task 15: Apply orchestrator

Sequences the writers in order (variables → text-styles → effects → components), emits progress events via a callback, collects a unified `ApplyReport`, and writes the `lastJsonHash` on success.

**Files:**
- Create: `src/main/apply/index.ts`
- Create: `tests/unit/apply-orchestrator.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/apply-orchestrator.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyAll } from '../../src/main/apply/index.js';
import type { DesignSystem } from '../../src/shared/schema.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

describe('applyAll', () => {
  it('runs all writers in order and emits progress per kind', async () => {
    const progress: { currentKind: string; applied: number; total: number }[] = [];
    const ds: DesignSystem = {
      version: '1.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
      collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }],
      textStyles: [{ name: 'text/body', fontFamily: 'Inter', fontWeight: 400, fontSize: 16 }],
      effects: [{ name: 'shadow/card', type: 'DROP_SHADOW', radius: 10 }],
      components: [],
    };
    const report = await applyAll(ds, { allowOrphanDelete: {} }, p => progress.push(p));
    expect(report.failed).toEqual([]);
    const kinds = progress.map(p => p.currentKind);
    expect(kinds).toEqual(['variables', 'textStyles', 'effects', 'components']);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/apply-orchestrator.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write src/main/apply/index.ts**

```ts
import type { DesignSystem } from '../../shared/schema.js';
import { applyVariables, type ApplyReport, type ApplyOptions } from './variables.js';
import { applyTextStyles } from './text-styles.js';
import { applyEffects } from './effects.js';
import { applyComponents } from './components.js';
import { setFileFlag } from '../identity.js';

export type ProgressCb = (p: { currentKind: string; applied: number; total: number }) => void;

export async function applyAll(ds: DesignSystem, opts: ApplyOptions, onProgress: ProgressCb): Promise<ApplyReport> {
  const total = (ds.collections.length + ds.variables.length + (ds.textStyles?.length ?? 0) + (ds.effects?.length ?? 0) + ds.components.length) || 1;
  const combined: ApplyReport = { applied: 0, failed: [] };

  const r1 = applyVariables(ds, opts);
  combined.applied += r1.applied; combined.failed.push(...r1.failed);
  onProgress({ currentKind: 'variables', applied: combined.applied, total });

  const r2 = await applyTextStyles(ds);
  combined.applied += r2.applied; combined.failed.push(...r2.failed);
  onProgress({ currentKind: 'textStyles', applied: combined.applied, total });

  const r3 = applyEffects(ds);
  combined.applied += r3.applied; combined.failed.push(...r3.failed);
  onProgress({ currentKind: 'effects', applied: combined.applied, total });

  const r4 = await applyComponents(ds);
  combined.applied += r4.applied; combined.failed.push(...r4.failed);
  onProgress({ currentKind: 'components', applied: combined.applied, total });

  if (combined.failed.length === 0) setFileFlag('lastJsonHash', hashString(JSON.stringify(ds)));
  return combined;
}

function hashString(s: string): string {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0;
  return String(h);
}
```

Note: `hashString` is a placeholder for SHA-256. In-plugin SHA-256 requires Web Crypto (`crypto.subtle.digest`). We use a lightweight non-cryptographic hash in v1 because the only use is cache short-circuiting; collisions would degrade to "show diff anyway", not lose data. This is a conscious trade-off to avoid a browser-crypto detour.

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/apply-orchestrator.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/index.ts tests/unit/apply-orchestrator.test.ts
git commit -m "feat: apply orchestrator sequencing writers with progress"
```

---

## Task 16: Main thread entry and message router

Wire up the `code.ts` entry so it responds to UI messages by dispatching to the read/apply modules.

**Files:**
- Modify: `src/main/code.ts`

- [ ] **Step 1: Replace src/main/code.ts**

```ts
import { readSnapshot, readAdoptionCandidates } from './snapshot.js';
import { applyAll } from './apply/index.js';
import type { Message } from '../shared/messages.js';
import { makeMessage, isMessage } from '../shared/messages.js';
import { diff } from '../shared/diff.js';
import { setJsonName, setJsonKind } from './identity.js';

figma.showUI(__html__, { width: 340, height: 560, themeColors: true });

figma.ui.onmessage = async (raw: unknown) => {
  if (!isMessage(raw)) return;
  const msg = raw as Message;

  try {
    switch (msg.type) {
      case 'SNAPSHOT_REQUEST': {
        const snapshot = readSnapshot();
        post(makeMessage.snapshotResult({ snapshot }));
        break;
      }
      case 'DIFF_REQUEST': {
        const snapshot = readSnapshot();
        const d = diff(snapshot, msg.payload.designSystem);
        post(makeMessage.diffResult({ diffJson: JSON.stringify(d) }));
        break;
      }
      case 'ADOPT_APPLY': {
        const candidates = readAdoptionCandidates();
        for (const [kind, names] of Object.entries(msg.payload.adoptions)) {
          for (const jsonName of names) adoptByName(candidates, kind, jsonName);
        }
        (figma as any).setSharedPluginData('extract-design-system', 'adoptionComplete', 'true');
        post(makeMessage.applyDone({ appliedCount: 0, failed: [] }));
        break;
      }
      case 'APPLY_REQUEST': {
        if (!msg.payload.designSystem) { post(makeMessage.applyDone({ appliedCount: 0, failed: [{ jsonName: '(root)', kind: 'designSystem', reason: 'missing designSystem' }] })); break; }
        const report = await applyAll(msg.payload.designSystem, { allowOrphanDelete: msg.payload.selections.orphans ?? {} }, p => post(makeMessage.applyProgress(p)));
        post(makeMessage.applyDone({ appliedCount: report.applied, failed: report.failed }));
        break;
      }
    }
  } catch (e) {
    post(makeMessage.applyDone({ appliedCount: 0, failed: [{ jsonName: '(router)', kind: 'router', reason: String(e) }] }));
  }
};

function post(msg: Message): void { figma.ui.postMessage(msg); }

function adoptByName(candidates: any, kind: string, jsonName: string): void {
  const buckets: Record<string, any[]> = {
    collection: candidates.collections,
    variable:   candidates.variables,
    textStyle:  candidates.textStyles,
    effect:     candidates.effects,
    component:  candidates.components,
  };
  const bucket = buckets[kind];
  if (!bucket) return;
  for (const item of bucket) {
    if (item.displayName === jsonName && !item.jsonName) {
      const node = lookupNode(kind, item.figmaId);
      if (!node) continue;
      setJsonName(node, jsonName);
      setJsonKind(node, kind);
    }
  }
}

function lookupNode(kind: string, id: string): any | undefined {
  if (kind === 'collection') return (figma as any).variables.getLocalVariableCollections().find((x: any) => x.id === id);
  if (kind === 'variable')   return (figma as any).variables.getLocalVariables().find((x: any) => x.id === id);
  if (kind === 'textStyle')  return ((figma as any).getLocalTextStyles?.() ?? []).find((x: any) => x.id === id);
  if (kind === 'effect')     return ((figma as any).getLocalEffectStyles?.() ?? []).find((x: any) => x.id === id);
  return undefined;
}
```

- [ ] **Step 2: Run build to confirm everything compiles**

Run: `npm run build`
Expected: exits 0; `build/code.js` exists.

- [ ] **Step 3: Typecheck**

Run: `npx tsc --noEmit`
Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add src/main/code.ts
git commit -m "feat: wire main thread message router"
```

---

## Task 17: UI scaffold and messaging bridge

Set up the React app shell with a state machine stub and a small `postToMain` helper.

**Files:**
- Create: `src/ui/messaging.ts`
- Create: `src/ui/App.tsx`
- Modify: `src/ui/index.tsx`
- Create: `src/ui/styles.css`

- [ ] **Step 1: Write src/ui/messaging.ts**

```ts
import type { Message } from '../shared/messages.js';

type Listener = (m: Message) => void;
const listeners = new Set<Listener>();

window.addEventListener('message', (e: MessageEvent) => {
  const raw = (e.data as any)?.pluginMessage ?? e.data;
  if (raw && typeof raw === 'object' && 'type' in raw) {
    for (const l of listeners) l(raw as Message);
  }
});

export function postToMain(msg: Message): void {
  (window as any).parent?.postMessage({ pluginMessage: msg }, '*');
}

export function onMessage(l: Listener): () => void {
  listeners.add(l);
  return () => listeners.delete(l);
}
```

- [ ] **Step 2: Write src/ui/styles.css**

```css
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-size: 12px; }
.app { display: flex; flex-direction: column; height: 100vh; }
.header { padding: 10px 12px; border-bottom: 1px solid var(--figma-color-border, #e5e5e5); }
.body { flex: 1; overflow-y: auto; }
.footer { padding: 10px 12px; border-top: 1px solid var(--figma-color-border, #e5e5e5); display: flex; gap: 8px; }
button { cursor: pointer; padding: 6px 10px; border-radius: 4px; border: 1px solid var(--figma-color-border, #ccc); background: var(--figma-color-bg, #fff); }
button.primary { background: #18a0fb; color: white; border-color: #18a0fb; }
button:disabled { opacity: 0.5; cursor: not-allowed; }
```

- [ ] **Step 3: Write src/ui/App.tsx (skeleton state machine)**

```tsx
import { useState } from 'react';

type Screen = 'load' | 'adopt' | 'diff' | 'apply';

export function App(): JSX.Element {
  const [screen] = useState<Screen>('load');
  return (
    <div className="app">
      <div className="header">Design System Sync</div>
      <div className="body">
        {screen === 'load' && <div>Load screen (placeholder)</div>}
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Replace src/ui/index.tsx**

```tsx
import { createRoot } from 'react-dom/client';
import { App } from './App.js';
import './styles.css';

const root = createRoot(document.getElementById('root')!);
root.render(<App />);
```

- [ ] **Step 5: Run build**

Run: `npm run build`
Expected: exits 0.

- [ ] **Step 6: Commit**

```bash
git add src/ui/messaging.ts src/ui/App.tsx src/ui/index.tsx src/ui/styles.css
git commit -m "feat: ui scaffold with state machine skeleton and messaging bridge"
```

---

## Task 18: LoadScreen — file picker, parse, validate

**Files:**
- Create: `src/ui/screens/LoadScreen.tsx`
- Create: `tests/unit/ui/load-screen.test.tsx`
- Modify: `src/ui/App.tsx`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/ui/load-screen.test.tsx`:

```tsx
import { describe, it, expect, vi } from 'vitest';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { LoadScreen } from '../../../src/ui/screens/LoadScreen.js';

describe('LoadScreen', () => {
  it('shows file picker UI on first render', () => {
    const { getByText } = render(<LoadScreen onLoaded={() => {}} />);
    expect(getByText(/load your design-system\.json/i)).toBeTruthy();
  });

  it('calls onLoaded with parsed design system when valid JSON is selected', async () => {
    const onLoaded = vi.fn();
    const { getByTestId } = render(<LoadScreen onLoaded={onLoaded} />);
    const file = new File([JSON.stringify({
      version: '1.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
      collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
      variables: [],
      components: []
    })], 'ds.json', { type: 'application/json' });
    const input = getByTestId('file-input') as HTMLInputElement;
    fireEvent.change(input, { target: { files: [file] } });
    await waitFor(() => expect(onLoaded).toHaveBeenCalled());
    const ds = onLoaded.mock.calls[0][0];
    expect(ds.version).toBe('1.0.0');
  });

  it('shows error message when JSON is invalid', async () => {
    const onLoaded = vi.fn();
    const { getByTestId, findByText } = render(<LoadScreen onLoaded={onLoaded} />);
    const file = new File(['not json'], 'bad.json', { type: 'application/json' });
    fireEvent.change(getByTestId('file-input') as HTMLInputElement, { target: { files: [file] } });
    expect(await findByText(/invalid json/i)).toBeTruthy();
    expect(onLoaded).not.toHaveBeenCalled();
  });

  it('shows validation errors when schema fails', async () => {
    const onLoaded = vi.fn();
    const { getByTestId, findByText } = render(<LoadScreen onLoaded={onLoaded} />);
    const file = new File([JSON.stringify({ version: '1.0.0' })], 'bad.json', { type: 'application/json' });
    fireEvent.change(getByTestId('file-input') as HTMLInputElement, { target: { files: [file] } });
    expect(await findByText(/schema error/i)).toBeTruthy();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/ui/load-screen.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Write src/ui/screens/LoadScreen.tsx**

```tsx
import { useState } from 'react';
import type { DesignSystem } from '../../shared/schema.js';
import { validate } from '../../shared/validate.js';

interface Props { onLoaded: (ds: DesignSystem) => void }

export function LoadScreen({ onLoaded }: Props): JSX.Element {
  const [error, setError] = useState<string | null>(null);
  const [errors, setErrors] = useState<string[]>([]);

  const handleFile = async (file: File) => {
    setError(null); setErrors([]);
    const text = await file.text();
    let parsed: unknown;
    try { parsed = JSON.parse(text); } catch (e) { setError('Invalid JSON: ' + (e as Error).message); return; }
    const res = validate(parsed);
    if (!res.ok) { setError('Schema error'); setErrors(res.errors); return; }
    if (res.value!.version !== '1.0.0') { setError(`Schema version mismatch: ${res.value!.version} (expected 1.0.0)`); return; }
    onLoaded(res.value!);
  };

  const onChange: React.ChangeEventHandler<HTMLInputElement> = e => {
    const f = e.target.files?.[0]; if (f) handleFile(f);
  };

  return (
    <div style={{ padding: 12 }}>
      <p>Load your design-system.json to sync its tokens, styles, and components to this file.</p>
      <input data-testid="file-input" type="file" accept="application/json,.json" onChange={onChange} />
      {error && <div style={{ color: 'red', marginTop: 8 }}>{error}</div>}
      {errors.length > 0 && (
        <ul style={{ marginTop: 4 }}>
          {errors.slice(0, 10).map((e, i) => <li key={i}>{e}</li>)}
        </ul>
      )}
    </div>
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/ui/load-screen.test.tsx`
Expected: PASS, 4/4 tests.

- [ ] **Step 5: Wire LoadScreen into App**

Replace `src/ui/App.tsx`:

```tsx
import { useState } from 'react';
import type { DesignSystem } from '../shared/schema.js';
import { LoadScreen } from './screens/LoadScreen.js';

type Screen = 'load' | 'adopt' | 'diff' | 'apply';

export function App(): JSX.Element {
  const [screen, setScreen] = useState<Screen>('load');
  const [ds, setDs] = useState<DesignSystem | null>(null);

  return (
    <div className="app">
      <div className="header">Design System Sync</div>
      <div className="body">
        {screen === 'load' && <LoadScreen onLoaded={d => { setDs(d); setScreen('diff'); }} />}
        {screen !== 'load' && ds && <div>TODO next screen: {screen}</div>}
      </div>
    </div>
  );
}
```

- [ ] **Step 6: Run build and all UI tests**

Run: `npm run build && npx vitest run tests/unit/ui`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add src/ui/screens/LoadScreen.tsx src/ui/App.tsx tests/unit/ui/load-screen.test.tsx
git commit -m "feat: load screen with parse and validation"
```

---

## Task 19: AdoptScreen — first-run by-name match list

**Files:**
- Create: `src/ui/screens/AdoptScreen.tsx`
- Create: `tests/unit/ui/adopt-screen.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/ui/adopt-screen.test.tsx`:

```tsx
import { describe, it, expect, vi } from 'vitest';
import { render, fireEvent } from '@testing-library/react';
import { AdoptScreen } from '../../../src/ui/screens/AdoptScreen.js';
import type { DesignSystem } from '../../../src/shared/schema.js';

const ds: DesignSystem = {
  version: '1.0.0',
  source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
  collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
  variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }],
  components: [],
};

describe('AdoptScreen', () => {
  it('lists proposed matches with default-checked boxes', () => {
    const candidates = {
      collections: [{ figmaId: 'c1', jsonName: '', displayName: 'primitives', modes: [] }],
      variables:   [{ figmaId: 'v1', jsonName: '', displayName: 'color/brand', collectionId: 'c1', resolvedType: 'COLOR' }],
      textStyles: [], effects: [], components: [], duplicates: [], adoptionComplete: false,
    };
    const { getByLabelText } = render(<AdoptScreen ds={ds} candidates={candidates} onContinue={() => {}} />);
    const box = getByLabelText(/color\/brand/i) as HTMLInputElement;
    expect(box.checked).toBe(true);
  });

  it('calls onContinue with selected adoptions', () => {
    const onContinue = vi.fn();
    const candidates = {
      collections: [{ figmaId: 'c1', jsonName: '', displayName: 'primitives', modes: [] }],
      variables:   [{ figmaId: 'v1', jsonName: '', displayName: 'color/brand', collectionId: 'c1', resolvedType: 'COLOR' }],
      textStyles: [], effects: [], components: [], duplicates: [], adoptionComplete: false,
    };
    const { getByText } = render(<AdoptScreen ds={ds} candidates={candidates} onContinue={onContinue} />);
    fireEvent.click(getByText(/continue/i));
    expect(onContinue).toHaveBeenCalled();
    const adoptions = onContinue.mock.calls[0][0];
    expect(adoptions.variable).toContain('color/brand');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/ui/adopt-screen.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Write src/ui/screens/AdoptScreen.tsx**

```tsx
import { useMemo, useState } from 'react';
import type { DesignSystem } from '../../shared/schema.js';
import type { Snapshot } from '../../shared/messages.js';

interface Props {
  ds: DesignSystem;
  candidates: Snapshot;
  onContinue: (adoptions: Record<string, string[]>) => void;
}

export function AdoptScreen({ ds, candidates, onContinue }: Props): JSX.Element {
  const proposed = useMemo(() => computeProposedMatches(ds, candidates), [ds, candidates]);
  const [selected, setSelected] = useState<Record<string, Record<string, boolean>>>(() => {
    const init: Record<string, Record<string, boolean>> = {};
    for (const [kind, names] of Object.entries(proposed)) {
      init[kind] = {};
      for (const n of names) init[kind][n] = true;
    }
    return init;
  });

  const toggle = (kind: string, name: string) => {
    setSelected(s => ({ ...s, [kind]: { ...s[kind], [name]: !s[kind][name] } }));
  };

  const continueAdopt = () => {
    const out: Record<string, string[]> = {};
    for (const [kind, rec] of Object.entries(selected)) {
      out[kind] = Object.entries(rec).filter(([, v]) => v).map(([n]) => n);
    }
    onContinue(out);
  };

  return (
    <div style={{ padding: 12 }}>
      <h3 style={{ margin: '0 0 8px 0' }}>Match existing Figma objects?</h3>
      {Object.entries(proposed).map(([kind, names]) => (
        <div key={kind} style={{ marginBottom: 10 }}>
          <div style={{ fontWeight: 600, marginBottom: 4 }}>{kind}</div>
          {names.map(name => (
            <label key={name} style={{ display: 'block', padding: '3px 0' }}>
              <input type="checkbox"
                     checked={selected[kind]?.[name] ?? false}
                     onChange={() => toggle(kind, name)} />
              {' '}{name}
            </label>
          ))}
        </div>
      ))}
      <button className="primary" onClick={continueAdopt}>Continue</button>
    </div>
  );
}

function computeProposedMatches(ds: DesignSystem, snap: Snapshot): Record<string, string[]> {
  const collFigma = new Set(snap.collections.filter(x => !x.jsonName).map(x => x.displayName));
  const varFigma  = new Set(snap.variables.filter(x => !x.jsonName).map(x => x.displayName));
  const tsFigma   = new Set(snap.textStyles.filter(x => !x.jsonName).map(x => x.displayName));
  const esFigma   = new Set(snap.effects.filter(x => !x.jsonName).map(x => x.displayName));
  const compFigma = new Set(snap.components.filter(x => !x.jsonName).map(x => x.displayName));
  return {
    collection: ds.collections.map(c => c.name).filter(n => collFigma.has(n)),
    variable:   ds.variables.map(v => v.name).filter(n => varFigma.has(n)),
    textStyle:  (ds.textStyles ?? []).map(t => t.name).filter(n => tsFigma.has(n)),
    effect:     (ds.effects ?? []).map(e => e.name).filter(n => esFigma.has(n)),
    component:  ds.components.map(c => c.name).filter(n => compFigma.has(n)),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/ui/adopt-screen.test.tsx`
Expected: PASS, 2/2 tests.

- [ ] **Step 5: Commit**

```bash
git add src/ui/screens/AdoptScreen.tsx tests/unit/ui/adopt-screen.test.tsx
git commit -m "feat: adopt screen for first-run by-name matches"
```

---

## Task 20: DiffScreen — grouped list with selection and apply footer

**Files:**
- Create: `src/ui/screens/DiffScreen.tsx`
- Create: `src/ui/components/DiffRow.tsx`
- Create: `src/ui/components/EntityGroup.tsx`
- Create: `tests/unit/ui/diff-screen.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/ui/diff-screen.test.tsx`:

```tsx
import { describe, it, expect, vi } from 'vitest';
import { render, fireEvent } from '@testing-library/react';
import { DiffScreen } from '../../../src/ui/screens/DiffScreen.js';
import type { FullDiff } from '../../../src/shared/diff.js';

const emptyGroup = () => ({ added: [], updated: [], removed: [], renamed: [] });

const fullDiff: FullDiff = {
  collections: emptyGroup(),
  variables: {
    added: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#000' } }],
    updated: [], removed: [], renamed: [],
  },
  textStyles: emptyGroup(),
  effects: emptyGroup(),
  components: emptyGroup(),
};

describe('DiffScreen', () => {
  it('renders rows grouped by kind with a count in footer', () => {
    const { getByText } = render(<DiffScreen diff={fullDiff} onApply={() => {}} onBack={() => {}} />);
    expect(getByText(/Variables/i)).toBeTruthy();
    expect(getByText(/Apply 1 changes/i)).toBeTruthy();
  });

  it('shows empty state for zero-change diff', () => {
    const empty: FullDiff = {
      collections: emptyGroup(), variables: emptyGroup(), textStyles: emptyGroup(),
      effects: emptyGroup(), components: emptyGroup(),
    };
    const { getByText } = render(<DiffScreen diff={empty} onApply={() => {}} onBack={() => {}} />);
    expect(getByText(/No changes to apply/i)).toBeTruthy();
  });

  it('calls onApply with selection when Apply clicked', () => {
    const onApply = vi.fn();
    const { getByText } = render(<DiffScreen diff={fullDiff} onApply={onApply} onBack={() => {}} />);
    fireEvent.click(getByText(/Apply 1/i));
    expect(onApply).toHaveBeenCalled();
    const selections = onApply.mock.calls[0][0];
    expect(selections.variables?.['color/brand']).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/ui/diff-screen.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Write src/ui/components/DiffRow.tsx**

```tsx
interface Props {
  icon: '+' | '~' | '→' | '−';
  label: string;
  detail?: string;
  checked: boolean;
  onToggle: () => void;
}

export function DiffRow({ icon, label, detail, checked, onToggle }: Props): JSX.Element {
  return (
    <label style={{ display: 'flex', gap: 8, padding: '3px 0', alignItems: 'center' }}>
      <input type="checkbox" checked={checked} onChange={onToggle} />
      <span style={{ width: 10, textAlign: 'center', color: iconColor(icon) }}>{icon}</span>
      <span style={{ flex: 1 }}>{label}</span>
      {detail && <span style={{ color: '#888', fontSize: 10 }}>{detail}</span>}
    </label>
  );
}

function iconColor(i: string): string {
  if (i === '+') return '#22a06b';
  if (i === '~') return '#e69b17';
  if (i === '→') return '#6b7bff';
  return '#b8860b';
}
```

- [ ] **Step 4: Write src/ui/components/EntityGroup.tsx**

```tsx
import { useState } from 'react';

interface Props { title: string; count: number; children: React.ReactNode; defaultOpen?: boolean; accent?: boolean }

export function EntityGroup({ title, count, children, defaultOpen = true, accent = false }: Props): JSX.Element {
  const [open, setOpen] = useState(defaultOpen);
  if (count === 0) return <></>;
  return (
    <div style={{ padding: '10px 12px', borderBottom: '1px solid #f2f2f2', background: accent ? '#fffaf0' : undefined }}>
      <button onClick={() => setOpen(o => !o)} style={{ all: 'unset', cursor: 'pointer', fontWeight: 600, width: '100%', display: 'block', marginBottom: 4 }}>
        {open ? '▾' : '▸'} {title} <span style={{ color: '#888', fontWeight: 400 }}>({count})</span>
      </button>
      {open && <div style={{ paddingLeft: 12 }}>{children}</div>}
    </div>
  );
}
```

- [ ] **Step 5: Write src/ui/screens/DiffScreen.tsx**

```tsx
import { useMemo, useState } from 'react';
import type { FullDiff, EntityDiff } from '../../shared/diff.js';
import type { DiffSelections } from '../../shared/messages.js';
import { DiffRow } from '../components/DiffRow.js';
import { EntityGroup } from '../components/EntityGroup.js';

interface Props {
  diff: FullDiff;
  onApply: (selections: DiffSelections) => void;
  onBack: () => void;
}

export function DiffScreen({ diff, onApply, onBack }: Props): JSX.Element {
  const total = totalChanges(diff);
  const [selections, setSelections] = useState<DiffSelections>(() => defaultSelections(diff));

  const selectedCount = countSelected(selections);

  if (total === 0) {
    return (
      <div style={{ padding: 20, textAlign: 'center' }}>
        <p>No changes to apply.</p>
        <button onClick={onBack}>Done</button>
      </div>
    );
  }

  return (
    <div className="app">
      <div className="body">
        <RenderGroup title="Variables"   kind="variables"  group={diff.variables}  selections={selections} onChange={setSelections} labelOf={v => v.name} />
        <RenderGroup title="Text Styles" kind="textStyles" group={diff.textStyles} selections={selections} onChange={setSelections} labelOf={v => v.name} />
        <RenderGroup title="Effects"     kind="effects"    group={diff.effects}    selections={selections} onChange={setSelections} labelOf={v => v.name} />
        <RenderGroup title="Components"  kind="components" group={diff.components} selections={selections} onChange={setSelections} labelOf={v => v.name} />
        <OrphanGroup diff={diff} selections={selections} onChange={setSelections} />
      </div>
      <div className="footer">
        <button onClick={onBack}>Back</button>
        <button className="primary" disabled={selectedCount === 0} onClick={() => onApply(selections)}>Apply {selectedCount} changes</button>
      </div>
    </div>
  );
}

function RenderGroup<TNext, TSnap>(props: {
  title: string;
  kind: keyof DiffSelections;
  group: EntityDiff<TNext, TSnap>;
  selections: DiffSelections;
  onChange: (s: DiffSelections) => void;
  labelOf: (x: TNext) => string;
}): JSX.Element {
  const { title, kind, group, selections, onChange, labelOf } = props;
  const count = group.added.length + group.updated.length + group.renamed.length + group.removed.length;
  const set = (name: string, v: boolean) => onChange({ ...selections, [kind]: { ...(selections[kind] ?? {}), [name]: v } });
  return (
    <EntityGroup title={title} count={count}>
      {group.added.map(x => <DiffRow key={'a'+labelOf(x)} icon="+" label={labelOf(x)} checked={!!selections[kind]?.[labelOf(x)]} onToggle={() => set(labelOf(x), !selections[kind]?.[labelOf(x)])} />)}
      {group.updated.map(u => <DiffRow key={'u'+u.name} icon="~" label={u.name} checked={!!selections[kind]?.[u.name]} onToggle={() => set(u.name, !selections[kind]?.[u.name])} />)}
      {group.renamed.map(r => <DiffRow key={'r'+r.from} icon="→" label={`${r.from} → ${r.to}`} checked={!!selections[kind]?.[r.to]} onToggle={() => set(r.to, !selections[kind]?.[r.to])} />)}
    </EntityGroup>
  );
}

function OrphanGroup({ diff, selections, onChange }: { diff: FullDiff; selections: DiffSelections; onChange: (s: DiffSelections) => void }): JSX.Element {
  const orphans: { kind: string; name: string }[] = [];
  for (const v of diff.variables.removed)  orphans.push({ kind: 'variable',  name: v.jsonName });
  for (const v of diff.textStyles.removed) orphans.push({ kind: 'textStyle', name: v.jsonName });
  for (const v of diff.effects.removed)    orphans.push({ kind: 'effect',    name: v.jsonName });
  for (const v of diff.components.removed) orphans.push({ kind: 'component', name: v.jsonName });
  const set = (key: string, v: boolean) => onChange({ ...selections, orphans: { ...(selections.orphans ?? {}), [key]: v } });
  return (
    <EntityGroup title="Orphans" count={orphans.length} accent defaultOpen={false}>
      {orphans.map(o => {
        const key = `${o.kind}:${o.name}`;
        return <DiffRow key={key} icon="−" label={`${o.name}`} detail={`delete ${o.kind}?`} checked={!!selections.orphans?.[key]} onToggle={() => set(key, !selections.orphans?.[key])} />;
      })}
    </EntityGroup>
  );
}

function defaultSelections(diff: FullDiff): DiffSelections {
  const out: DiffSelections = { variables: {}, textStyles: {}, effects: {}, components: {}, orphans: {} };
  for (const v of diff.variables.added)    out.variables![v.name] = true;
  for (const u of diff.variables.updated)  out.variables![u.name] = true;
  for (const r of diff.variables.renamed)  out.variables![r.to]   = true;
  for (const v of diff.textStyles.added)   out.textStyles![v.name] = true;
  for (const u of diff.textStyles.updated) out.textStyles![u.name] = true;
  for (const r of diff.textStyles.renamed) out.textStyles![r.to]   = true;
  for (const v of diff.effects.added)      out.effects![v.name] = true;
  for (const u of diff.effects.updated)    out.effects![u.name] = true;
  for (const r of diff.effects.renamed)    out.effects![r.to]   = true;
  for (const v of diff.components.added)   out.components![v.name] = true;
  for (const u of diff.components.updated) out.components![u.name] = true;
  for (const r of diff.components.renamed) out.components![r.to]   = true;
  return out;
}

function countSelected(sel: DiffSelections): number {
  let n = 0;
  for (const kind of ['variables', 'textStyles', 'effects', 'components', 'orphans'] as const) {
    const rec = sel[kind] ?? {};
    for (const v of Object.values(rec)) if (v) n++;
  }
  return n;
}

function totalChanges(d: FullDiff): number {
  const each = (g: EntityDiff<any, any>) => g.added.length + g.updated.length + g.renamed.length + g.removed.length;
  return each(d.variables) + each(d.textStyles) + each(d.effects) + each(d.components);
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `npx vitest run tests/unit/ui/diff-screen.test.tsx`
Expected: PASS, 3/3 tests.

- [ ] **Step 7: Commit**

```bash
git add src/ui/screens/DiffScreen.tsx src/ui/components/DiffRow.tsx src/ui/components/EntityGroup.tsx tests/unit/ui/diff-screen.test.tsx
git commit -m "feat: diff screen with grouped list and selection"
```

---

## Task 21: ApplyScreen — progress, done, retry failed

**Files:**
- Create: `src/ui/screens/ApplyScreen.tsx`
- Create: `tests/unit/ui/apply-screen.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/ui/apply-screen.test.tsx`:

```tsx
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { ApplyScreen } from '../../../src/ui/screens/ApplyScreen.js';

describe('ApplyScreen', () => {
  it('shows progress while applying', () => {
    const { getByText } = render(<ApplyScreen state={{ kind: 'running', applied: 3, total: 10, currentKind: 'variables' }} onRetry={() => {}} onDone={() => {}} />);
    expect(getByText(/Applying/i)).toBeTruthy();
    expect(getByText(/3/)).toBeTruthy();
  });

  it('shows success summary when done with no failures', () => {
    const { getByText } = render(<ApplyScreen state={{ kind: 'done', appliedCount: 7, failed: [] }} onRetry={() => {}} onDone={() => {}} />);
    expect(getByText(/7 changes applied/i)).toBeTruthy();
  });

  it('shows failed rows with retry button', () => {
    const { getByText } = render(<ApplyScreen state={{ kind: 'done', appliedCount: 3, failed: [{ jsonName: 'text/body', kind: 'textStyle', reason: 'missing font' }] }} onRetry={() => {}} onDone={() => {}} />);
    expect(getByText(/text\/body/)).toBeTruthy();
    expect(getByText(/Retry failed/i)).toBeTruthy();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/ui/apply-screen.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Write src/ui/screens/ApplyScreen.tsx**

```tsx
export type ApplyState =
  | { kind: 'running'; applied: number; total: number; currentKind: string }
  | { kind: 'done'; appliedCount: number; failed: { jsonName: string; kind: string; reason: string }[] };

interface Props { state: ApplyState; onRetry: () => void; onDone: () => void }

export function ApplyScreen({ state, onRetry, onDone }: Props): JSX.Element {
  if (state.kind === 'running') {
    return (
      <div style={{ padding: 20 }}>
        <p>Applying {state.applied} of {state.total}…</p>
        <div style={{ background: '#eee', height: 4, borderRadius: 2 }}>
          <div style={{ background: '#18a0fb', height: 4, width: `${(state.applied / Math.max(state.total, 1)) * 100}%`, borderRadius: 2 }} />
        </div>
        <p style={{ color: '#888', fontSize: 10 }}>Kind: {state.currentKind}</p>
      </div>
    );
  }
  return (
    <div style={{ padding: 20 }}>
      <p>{state.appliedCount} changes applied.</p>
      {state.failed.length > 0 && (
        <>
          <h4 style={{ margin: '12px 0 6px 0' }}>Failed</h4>
          <ul>{state.failed.map(f => <li key={`${f.kind}:${f.jsonName}`}>{f.jsonName}: {f.reason}</li>)}</ul>
          <button onClick={onRetry}>Retry failed</button>{' '}
        </>
      )}
      <button className="primary" onClick={onDone}>Done</button>
    </div>
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/ui/apply-screen.test.tsx`
Expected: PASS, 3/3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/ui/screens/ApplyScreen.tsx tests/unit/ui/apply-screen.test.tsx
git commit -m "feat: apply screen with progress and retry"
```

---

## Task 22: App state machine — wire all screens together

**Files:**
- Modify: `src/ui/App.tsx`
- Create: `tests/unit/ui/app.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/ui/app.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { App } from '../../../src/ui/App.js';
import { makeMessage } from '../../../src/shared/messages.js';
import type { FullDiff } from '../../../src/shared/diff.js';

const postMessage = vi.fn();
beforeEach(() => {
  postMessage.mockReset();
  (window as any).parent = { postMessage };
});

function dispatchFromMain(msg: unknown) {
  window.dispatchEvent(new MessageEvent('message', { data: { pluginMessage: msg } }));
}

describe('App', () => {
  it('transitions from load to adopt when adoption not complete', async () => {
    const { getByTestId, findByText } = render(<App />);
    const file = new File([JSON.stringify({
      version: '1.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-23T00:00:00Z' },
      collections: [], variables: [], components: []
    })], 'ds.json', { type: 'application/json' });
    fireEvent.change(getByTestId('file-input'), { target: { files: [file] } });

    await waitFor(() => expect(postMessage).toHaveBeenCalled());
    const snap = { collections: [], variables: [], textStyles: [], effects: [], components: [], duplicates: [], adoptionComplete: false };
    dispatchFromMain(makeMessage.snapshotResult({ snapshot: snap }));

    expect(await findByText(/Match existing Figma objects/i)).toBeTruthy();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/ui/app.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Replace src/ui/App.tsx with full state machine**

```tsx
import { useEffect, useMemo, useState } from 'react';
import type { DesignSystem } from '../shared/schema.js';
import type { DiffSelections, Snapshot } from '../shared/messages.js';
import type { FullDiff } from '../shared/diff.js';
import { makeMessage } from '../shared/messages.js';
import { postToMain, onMessage } from './messaging.js';
import { LoadScreen } from './screens/LoadScreen.js';
import { AdoptScreen } from './screens/AdoptScreen.js';
import { DiffScreen } from './screens/DiffScreen.js';
import { ApplyScreen, type ApplyState } from './screens/ApplyScreen.js';

type Screen =
  | { kind: 'load' }
  | { kind: 'snapshot-wait'; ds: DesignSystem }
  | { kind: 'adopt'; ds: DesignSystem; candidates: Snapshot }
  | { kind: 'diff-wait'; ds: DesignSystem }
  | { kind: 'diff'; ds: DesignSystem; diff: FullDiff }
  | { kind: 'apply'; ds: DesignSystem; state: ApplyState };

export function App(): JSX.Element {
  const [screen, setScreen] = useState<Screen>({ kind: 'load' });

  useEffect(() => {
    const off = onMessage(msg => {
      if (msg.type === 'SNAPSHOT_RESULT') {
        if (screen.kind === 'snapshot-wait') {
          const snap = msg.payload.snapshot;
          if (snap.adoptionComplete) {
            postToMain(makeMessage.diffRequest({ designSystem: screen.ds }));
            setScreen({ kind: 'diff-wait', ds: screen.ds });
          } else {
            setScreen({ kind: 'adopt', ds: screen.ds, candidates: snap });
          }
        }
      } else if (msg.type === 'DIFF_RESULT') {
        if (screen.kind === 'diff-wait') {
          const d = JSON.parse(msg.payload.diffJson) as FullDiff;
          setScreen({ kind: 'diff', ds: screen.ds, diff: d });
        }
      } else if (msg.type === 'APPLY_PROGRESS') {
        if (screen.kind === 'apply' && screen.state.kind === 'running') {
          setScreen({ kind: 'apply', ds: screen.ds, state: { ...screen.state, applied: msg.payload.applied, currentKind: msg.payload.currentKind } });
        }
      } else if (msg.type === 'APPLY_DONE') {
        if (screen.kind === 'apply') {
          setScreen({ kind: 'apply', ds: screen.ds, state: { kind: 'done', appliedCount: msg.payload.appliedCount, failed: msg.payload.failed } });
        }
      }
    });
    return () => off();
  }, [screen]);

  return (
    <div className="app">
      <div className="header">Design System Sync</div>
      <div className="body">
        {screen.kind === 'load' && <LoadScreen onLoaded={ds => { postToMain(makeMessage.snapshotRequest()); setScreen({ kind: 'snapshot-wait', ds }); }} />}
        {screen.kind === 'adopt' && <AdoptScreen ds={screen.ds} candidates={screen.candidates} onContinue={adoptions => {
          postToMain(makeMessage.adoptApply({ adoptions }));
          postToMain(makeMessage.diffRequest({ designSystem: screen.ds }));
          setScreen({ kind: 'diff-wait', ds: screen.ds });
        }} />}
        {screen.kind === 'diff' && <DiffScreen diff={screen.diff} onApply={(selections: DiffSelections) => {
          postToMain(makeMessage.applyRequest({ designSystem: screen.ds, selections }));
          setScreen({ kind: 'apply', ds: screen.ds, state: { kind: 'running', applied: 0, total: 100, currentKind: '' } });
        }} onBack={() => setScreen({ kind: 'load' })} />}
        {screen.kind === 'apply' && <ApplyScreen state={screen.state} onRetry={() => {
          postToMain(makeMessage.applyRequest({ designSystem: screen.ds, selections: {} }));
          setScreen({ kind: 'apply', ds: screen.ds, state: { kind: 'running', applied: 0, total: 100, currentKind: '' } });
        }} onDone={() => setScreen({ kind: 'load' })} />}
        {(screen.kind === 'snapshot-wait' || screen.kind === 'diff-wait') && <div style={{ padding: 20 }}>Working…</div>}
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/ui/app.test.tsx`
Expected: PASS.

- [ ] **Step 5: Run full test suite**

Run: `npx vitest run`
Expected: ALL tests pass.

- [ ] **Step 6: Run build**

Run: `npm run build`
Expected: exits 0.

- [ ] **Step 7: Commit**

```bash
git add src/ui/App.tsx tests/unit/ui/app.test.tsx
git commit -m "feat: wire app state machine across all screens"
```

---

## Task 23: Fixture files for manual smoke + README

**Files:**
- Create: `tests/fixtures/flutter-earnwise.json` (copied from extract-design-system fixture)
- Create: `tests/fixtures/html-react-earnwise.json` (copied from extract-design-system fixture)
- Create: `tests/manual-smoke.md`
- Create: `README.md`

- [ ] **Step 1: Copy fixtures from extract-design-system (if present there)**

The extract skill's test fixtures live at `/Users/markus/Dev/extract-design-system/lib/tests/fixtures/`. If a generated JSON is available there, copy it; otherwise, construct from `examples/flutter-example.json`.

```bash
cp /Users/markus/Dev/extract-design-system/examples/flutter-example.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/tests/fixtures/flutter-earnwise.json
cp /Users/markus/Dev/extract-design-system/examples/html-react-example.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/tests/fixtures/html-react-earnwise.json
```

- [ ] **Step 2: Write tests/manual-smoke.md**

```markdown
# Manual Smoke Test Checklist

Run before publishing a release. Requires Figma desktop.

## Setup

1. `npm run build`
2. In Figma desktop, Plugins → Development → Import plugin from manifest. Pick `manifest.json` in this repo.
3. Create a new, empty Figma file for testing.

## Tests

### 1. Full sync, fresh file
- Open the plugin, pick `tests/fixtures/flutter-earnwise.json`
- Adoption screen should show "Will be created" items only (no matches in a blank file)
- Click Continue
- Diff screen should show all items as Added
- Click Apply; wait for "N changes applied"
- Inspect the file: variables exist in a `primitives` collection, a `Design System` page contains all components

### 2. Idempotency
- Re-run the plugin with the same JSON
- Diff screen should show "No changes to apply"

### 3. Rename
- Edit the JSON locally: rename `PillButton` to `PrimaryButton`
- Re-run the plugin
- Diff screen should show a "→ PillButton → PrimaryButton" row under Components
- Apply; verify the component is renamed in place

### 4. Orphan flagged, then deleted
- Edit the JSON: remove `color/gold`
- Re-run; diff shows "Orphans (1)" section (cream background)
- Tick the delete box, Apply
- Verify `color/gold` is gone; verify other variables still work

### 5. Adoption on a seeded file
- Open a different Figma file and manually create a variable named `color/brand` in a `primitives` collection
- Run the plugin with the same `flutter-earnwise.json`
- Adoption screen should list `color/brand` as a proposed match, default-checked
- Click Continue, inspect the variable: its `pluginData["extract-design-system"].jsonName` should equal `color/brand`
```

- [ ] **Step 3: Write README.md**

```markdown
# Design System Sync: Figma Plugin

A Figma plugin that syncs a design system from code into Figma. Consumes `design-system.json` produced by the `extract-design-system` skill and applies tokens, text styles, effects, and component shells to the currently open Figma file, with a diff preview before anything is written.

## How it works

1. Engineer generates or updates `design-system.json` in their repo via the `extract-design-system` skill.
2. Designer opens a Figma file and runs this plugin.
3. Plugin: file picker → (first run) adopt matching existing objects → show diff → apply on approval.

See `docs/superpowers/specs/2026-04-23-figma-design-system-sync-plugin-design.md` in the earnapp repo for the full spec, and `docs/superpowers/plans/2026-04-23-figma-design-system-sync-plugin.md` for the implementation plan.

## Development

```bash
npm install
npm run build         # one-off build
npm run dev           # watch mode
npm test              # unit tests
```

Install the plugin locally: Figma desktop → Plugins → Development → Import plugin from manifest → pick `manifest.json`.

Run `tests/manual-smoke.md` before publishing.

## Relationship to extract-design-system

This plugin consumes the output of the companion skill at `~/Dev/extract-design-system/`. They share the v1 schema (`schema.v1.json`), and this plugin reuses fixtures from the skill's tests. v1 duplicates the pure diff logic; v2 may extract a shared npm package.
```

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/flutter-earnwise.json tests/fixtures/html-react-earnwise.json tests/manual-smoke.md README.md
git commit -m "docs: fixtures, manual smoke checklist, and README"
```

---

## Task 24: Final verification

- [ ] **Step 1: Run full test suite**

Run: `npx vitest run`
Expected: all tests pass.

- [ ] **Step 2: Typecheck**

Run: `npx tsc --noEmit`
Expected: exits 0.

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: `build/code.js` and `build/ui.html` exist; both non-empty.

Verify:

```bash
test -s build/code.js && test -s build/ui.html && echo OK
```

Expected: prints `OK`.

- [ ] **Step 4: Tag v0.1.0**

```bash
git tag v0.1.0
```

- [ ] **Step 5: Final commit (only if any uncommitted changes)**

```bash
git status
# if clean, skip; if dirty, investigate and commit
```

---

## Notes for the implementer

- **SHA-256 for `lastJsonHash`**: Task 15 uses a lightweight non-cryptographic hash. If collisions become a real concern during manual smoke testing, swap to `crypto.subtle.digest('SHA-256', ...)` in `hashString`. Low priority for v1.
- **Figma mock completeness**: the mock covers only the API surface the plugin actually uses. If a writer test fails with "function is not a function", extend the mock to match the real API per `@figma/plugin-typings` — don't work around it with defensive checks in production code.
- **Font loading**: Task 12 resolves font weight to a Figma style name via simple thresholds. In real Figma there are subtle family-specific style names ("Inter Medium" vs "Inter Medium Italic"). The manual smoke test will surface any misses.
- **Variant enumeration**: Task 14 generates one Component per VARIANT option combination. For a component with 3 VARIANT properties of 3/2/2 options, that's 12 components. Acceptable at human scales; watch performance if a design system has high-cardinality variants.
- **Placeholder persistence rule**: enforced implicitly in Task 14 — `updateComponentShell` only touches layout fields, never children. Do not add logic that replaces slot content on update; that breaks the spec's contract with designers.
