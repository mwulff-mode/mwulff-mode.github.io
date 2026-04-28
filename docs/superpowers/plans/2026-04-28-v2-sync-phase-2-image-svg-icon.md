# v2 Sync Phase 2: Image, SVG, Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three new `WidgetNode` types (`image`, `svg`, `icon`) to the v2 schema, extractor reference doc, and plugin walker so components containing `Image.asset`, `SvgPicture.asset`, or `Icon(IconData)` can extract richly instead of degrading to v1 shells.

**Architecture:** Additive change within v2 (no version bump). The `WidgetNode` `oneOf` gains three branches. Plugin's `walkTree` gains three corresponding cases. Extractor reference doc explains how Claude maps each Flutter widget. Validated end-to-end by a synthetic fixture that exercises all three new types in one variant.

**Tech Stack:** TypeScript, Ajv, vitest, esbuild. Two repos: `/Users/markus/Dev/extract-design-system/` and `/Users/markus/Dev/extract-design-system-figma-plugin/`.

**Spec:** `/Users/markus/Dev/earnapp/docs/superpowers/specs/2026-04-28-v2-sync-phase-2-image-svg-icon.md`

---

## File Structure

### extract-design-system

```
references/
├── schema.v2.json                  (MODIFY: WidgetNode oneOf gets 3 new branches)
└── flutter-extraction.md           (MODIFY: append "v2 Phase 2" section)
lib/src/
└── schema.ts                       (MODIFY: WidgetNode union gains 3 members)
examples/
└── v2-asset-test-card.json         (NEW: synthetic v2 fixture with image, svg, icon)
```

### extract-design-system-figma-plugin

```
schema.v2.json                      (MODIFY: mirror)
src/shared/
└── schema.ts                       (MODIFY: mirror)
src/main/apply/
└── components-v2.ts                (MODIFY: walkTree gains image, svg, icon branches; helper base64ToBytes)
tests/mocks/
└── figma-mock.ts                   (MODIFY: add createImage and createNodeFromSvg)
tests/fixtures/
└── asset-test-card-v2.json         (NEW: copied from extract-design-system examples)
tests/unit/
└── apply-components-v2.test.ts     (MODIFY: add tests for image, svg, icon branches)
```

---

## Task 1: Update schema.v2.json with three new WidgetNode types

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/references/schema.v2.json`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json`

- [ ] **Step 1: Locate the WidgetNode oneOf block in schema.v2.json**

The current file has `"WidgetNode": { "oneOf": [ ...frame branch..., ...text branch... ] }` under `definitions`.

- [ ] **Step 2: Append three branches to the `WidgetNode.oneOf` array**

Insert after the existing frame and text branches (before the closing `]`):

```json
,
{
  "type": "object",
  "required": ["type", "source", "width", "height"],
  "properties": {
    "type": { "const": "image" },
    "source": { "type": "string" },
    "width": { "type": "number" },
    "height": { "type": "number" },
    "fit": { "enum": ["cover", "contain", "fill"] }
  },
  "additionalProperties": false
},
{
  "type": "object",
  "required": ["type", "source", "width", "height"],
  "properties": {
    "type": { "const": "svg" },
    "source": { "type": "string" },
    "width": { "type": "number" },
    "height": { "type": "number" }
  },
  "additionalProperties": false
},
{
  "type": "object",
  "required": ["type", "name", "size"],
  "properties": {
    "type": { "const": "icon" },
    "name": { "type": "string" },
    "size": { "type": "number" }
  },
  "additionalProperties": false
}
```

- [ ] **Step 3: Mirror the change in the plugin's schema.v2.json**

```bash
cp /Users/markus/Dev/extract-design-system/references/schema.v2.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json
diff /Users/markus/Dev/extract-design-system/references/schema.v2.json \
     /Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json
```

Expected: no diff output.

- [ ] **Step 4: Validate the existing PrimaryButton fixture still passes**

```bash
cd /Users/markus/Dev/extract-design-system/lib
cat ../examples/v2-primary-button.json | npx tsx src/cli.ts validate
echo $?
```

Expected: `0`. The old fixture only uses `frame` and `text` nodes, which remain valid.

- [ ] **Step 5: Commit (one commit covers both files; they are intentionally identical)**

```bash
cd /Users/markus/Dev/extract-design-system
git add references/schema.v2.json
git commit -m "feat(schema): WidgetNode oneOf gains image, svg, icon branches"
```

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git add schema.v2.json
git commit -m "feat(schema): mirror image, svg, icon branches"
```

---

## Task 2: Add new TS types to extractor and plugin schema files

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/lib/src/schema.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/shared/schema.ts`

- [ ] **Step 1: Locate the WidgetNode union in extract-design-system/lib/src/schema.ts**

It currently reads:

```ts
export type WidgetNode =
  | {
      type: 'frame';
      layout: Layout;
      fill?: ColorBinding;
      stroke?: ColorBinding;
      strokeWeight?: number;
      children: WidgetNode[];
    }
  | {
      type: 'text';
      value: string;
      style: TextStyleBinding;
      color: ColorBinding;
    };
```

- [ ] **Step 2: Replace with the expanded union**

```ts
export type WidgetNode =
  | {
      type: 'frame';
      layout: Layout;
      fill?: ColorBinding;
      stroke?: ColorBinding;
      strokeWeight?: number;
      children: WidgetNode[];
    }
  | {
      type: 'text';
      value: string;
      style: TextStyleBinding;
      color: ColorBinding;
    }
  | {
      type: 'image';
      source: string;
      width: number;
      height: number;
      fit?: 'cover' | 'contain' | 'fill';
    }
  | {
      type: 'svg';
      source: string;
      width: number;
      height: number;
    }
  | {
      type: 'icon';
      name: string;
      size: number;
    };
```

- [ ] **Step 3: Mirror the change in `extract-design-system-figma-plugin/src/shared/schema.ts`**

Find the same `WidgetNode` union and replace with the identical text.

- [ ] **Step 4: Typecheck both repos**

```bash
cd /Users/markus/Dev/extract-design-system/lib
npx tsc --noEmit
```

Expected: clean.

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx tsc --noEmit
```

Expected: clean. (The existing `walkTree` discriminator in components-v2.ts has a fallback `throw new Error` for unknown types, so adding new union members does not break the type.)

- [ ] **Step 5: Run all tests in both repos to confirm no regression**

```bash
cd /Users/markus/Dev/extract-design-system/lib && npx vitest run
cd /Users/markus/Dev/extract-design-system-figma-plugin && npx vitest run
```

Expected: 41/41 in extract-design-system, 68/68 in plugin.

- [ ] **Step 6: Commit (one per repo)**

```bash
cd /Users/markus/Dev/extract-design-system
git add lib/src/schema.ts
git commit -m "feat(types): add image, svg, icon to WidgetNode union"
```

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git add src/shared/schema.ts
git commit -m "feat(types): mirror image, svg, icon WidgetNode additions"
```

---

## Task 3: Extend the Figma mock with createImage and createNodeFromSvg

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/mocks/figma-mock.ts`

- [ ] **Step 1: Read the current mock**

```bash
cat /Users/markus/Dev/extract-design-system-figma-plugin/tests/mocks/figma-mock.ts | head -40
```

Note where existing top-level Figma factory functions (`createFrame`, `createText`, etc.) live in the `FigmaMock` class.

- [ ] **Step 2: Add createImage and createNodeFromSvg to FigmaMock**

Append the following methods inside the `FigmaMock` class, near the other factory methods:

```ts
createImage = async (bytes: Uint8Array) => {
  const hash = `image-${++this.idCounter}`;
  this.calls.push({ op: 'figma.createImage', args: [bytes.length], resultId: hash });
  return { hash };
};

createNodeFromSvg = (svg: string) => {
  const node: any = {
    ...this.makeNode('Frame', 'SvgImport'),
    width: 0, height: 0,
    children: [] as any[],
    fills: [],
    strokes: [],
    strokeWeight: 0,
    appendChild: (c: any) => { node.children.push(c); this.calls.push({ op: 'frame.appendChild', args: [node.id, c.id] }); },
    resize: (w: number, h: number) => { node.width = w; node.height = h; this.calls.push({ op: 'svg.resize', args: [node.id, w, h] }); },
  };
  (node as any)._svg = svg;
  this.calls.push({ op: 'figma.createNodeFromSvg', args: [svg.length], resultId: node.id });
  return node;
};
```

`makeNode` and the `idCounter` are existing private members in the FigmaMock class. The pattern matches `createFrame` already in the file.

- [ ] **Step 3: Typecheck and run tests**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx tsc --noEmit
npx vitest run
```

Expected: typecheck clean, 68/68 tests pass.

- [ ] **Step 4: Commit**

```bash
git add tests/mocks/figma-mock.ts
git commit -m "test(mock): add createImage and createNodeFromSvg"
```

---

## Task 4: Implement walkTree branch for image (TDD)

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`

- [ ] **Step 1: Append failing test**

Add to the end of `tests/unit/apply-components-v2.test.ts`:

```ts
describe('walkTree (image)', () => {
  it('creates a frame at requested size with image fill', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    // 1x1 transparent PNG: minimal valid base64
    const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=';
    const node = await walkTree({
      type: 'image',
      source: tinyPng,
      width: 48,
      height: 48,
    });
    expect(node).toBeDefined();
    expect(node.fills?.[0]?.type).toBe('IMAGE');
    expect(node.fills?.[0]?.imageHash).toMatch(/^image-/);
    expect(mock.calls.some(c => c.op === 'figma.createImage')).toBe(true);
    expect(mock.calls.some(c => c.op === 'frame.resize' && c.args[1] === 48 && c.args[2] === 48)).toBe(true);
  });

  it('honors fit mode when provided', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=';
    const node = await walkTree({
      type: 'image',
      source: tinyPng,
      width: 48,
      height: 48,
      fit: 'contain',
    });
    expect(node.fills?.[0]?.scaleMode).toBe('FIT');
  });
});
```

- [ ] **Step 2: Run test to verify red**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 2 new tests fail with "unknown WidgetNode type: image".

- [ ] **Step 3: Add base64ToBytes helper and image branch**

In `src/main/apply/components-v2.ts`, add at the top (alongside the existing imports and helpers):

```ts
function base64ToBytes(b64: string): Uint8Array {
  // Figma plugin runtime supports atob; in jsdom test env it does too.
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
```

Then add the image branch inside `walkTree`. Place it BEFORE the existing `throw` at the end of the function:

```ts
if (node.type === 'image') {
  const f = (figma as any).createFrame();
  f.resize(node.width, node.height);
  const bytes = base64ToBytes(node.source);
  const image = await (figma as any).createImage(bytes);
  const scaleMode = node.fit === 'contain' ? 'FIT' : node.fit === 'fill' ? 'STRETCH' : 'CROP';
  f.fills = [{ type: 'IMAGE', scaleMode, imageHash: image.hash }];
  return f;
}
```

The test expects `scaleMode === 'FIT'` for `fit: 'contain'`. Default is `'CROP'` (Figma's name for cover behavior).

- [ ] **Step 4: Run test to verify green**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 11/11 tests pass (9 existing + 2 new).

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): walkTree handles image nodes via createImage"
```

---

## Task 5: Implement walkTree branch for svg (TDD)

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`

- [ ] **Step 1: Append failing test**

```ts
describe('walkTree (svg)', () => {
  it('imports SVG via createNodeFromSvg and resizes', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const svgXml = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16" fill="black"/></svg>';
    const node = await walkTree({
      type: 'svg',
      source: svgXml,
      width: 16,
      height: 16,
    });
    expect(node).toBeDefined();
    expect(mock.calls.some(c => c.op === 'figma.createNodeFromSvg')).toBe(true);
    expect(mock.calls.some(c => c.op === 'svg.resize' && c.args[1] === 16 && c.args[2] === 16)).toBe(true);
    expect((node as any)._svg).toBe(svgXml);
  });
});
```

- [ ] **Step 2: Run to verify red**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: new test fails.

- [ ] **Step 3: Add svg branch**

In `walkTree`, add before the `throw`:

```ts
if (node.type === 'svg') {
  const svgNode = (figma as any).createNodeFromSvg(node.source);
  svgNode.resize(node.width, node.height);
  return svgNode;
}
```

- [ ] **Step 4: Run to verify green**

Expected: 12/12 pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): walkTree handles svg nodes via createNodeFromSvg"
```

---

## Task 6: Implement walkTree branch for icon (TDD)

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`

- [ ] **Step 1: Append failing tests**

```ts
describe('walkTree (icon)', () => {
  it('emits a dashed placeholder frame at requested size', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const node = await walkTree({
      type: 'icon',
      name: 'material:arrow_back',
      size: 24,
    });
    expect(node.strokes?.[0]?.type).toBe('SOLID');
    expect(node.strokeWeight).toBe(1);
    expect(node.dashPattern).toEqual([4, 4]);
    expect(mock.calls.some(c => c.op === 'frame.resize' && c.args[1] === 24 && c.args[2] === 24)).toBe(true);
  });

  it('includes a name label inside when size is at least 32', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    await walkTree({
      type: 'icon',
      name: 'phosphor:caret-right:bold',
      size: 48,
    });
    const textOp = mock.calls.find(c => c.op === 'createText');
    expect(textOp).toBeDefined();
  });

  it('omits the label for small icons', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const callsBefore = mock.calls.length;
    await walkTree({
      type: 'icon',
      name: 'material:close',
      size: 16,
    });
    const newCalls = mock.calls.slice(callsBefore);
    expect(newCalls.some(c => c.op === 'createText')).toBe(false);
  });
});
```

- [ ] **Step 2: Run to verify red**

Expected: 3 new tests fail.

- [ ] **Step 3: Add icon branch**

In `walkTree`, before the `throw`:

```ts
if (node.type === 'icon') {
  const ph = (figma as any).createFrame();
  ph.resize(node.size, node.size);
  ph.strokes = [{ type: 'SOLID', color: { r: 0.55, g: 0.55, b: 0.55 }, opacity: 0.5 }];
  ph.strokeWeight = 1;
  ph.dashPattern = [4, 4];
  if (node.size >= 32) {
    await (figma as any).loadFontAsync({ family: 'Inter', style: 'Regular' });
    const label = (figma as any).createText();
    label.fontSize = Math.max(8, Math.floor(node.size / 4));
    label.characters = node.name;
    ph.appendChild(label);
  }
  return ph;
}
```

- [ ] **Step 4: Run to verify green**

Expected: 15/15 pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): walkTree handles icon nodes as dashed placeholders"
```

---

## Task 7: Synthetic v2 fixture exercising all three new node types

**Files:**
- Create: `/Users/markus/Dev/extract-design-system/examples/v2-asset-test-card.json`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/fixtures/asset-test-card-v2.json`

- [ ] **Step 1: Write the fixture**

`/Users/markus/Dev/extract-design-system/examples/v2-asset-test-card.json`:

```json
{
  "version": "2.0.0",
  "source": { "stack": "flutter", "extractedAt": "2026-04-28T00:00:00Z" },
  "collections": [{ "name": "primitives", "modes": ["default"], "defaultMode": "default" }],
  "variables": [
    { "name": "color/surface", "collection": "primitives", "type": "color", "valuesByMode": { "default": "#FFFFFF" } }
  ],
  "textStyles": [
    { "name": "text/body", "fontFamily": "Inter", "fontWeight": 400, "fontSize": 14 }
  ],
  "components": [
    {
      "name": "AssetTestCard",
      "tier": "molecule",
      "layout": {
        "direction": "VERTICAL",
        "padding": { "top": 12, "right": 12, "bottom": 12, "left": 12 },
        "gap": 8,
        "sizing": { "width": "FIXED", "widthValue": 200, "height": "FIXED", "heightValue": 240 },
        "radius": 12
      },
      "properties": [{ "name": "expanded", "type": "BOOLEAN", "default": false }],
      "variantProperties": [{ "name": "expanded", "type": "BOOLEAN" }],
      "variants": [
        {
          "key": "expanded=false",
          "properties": { "expanded": "false" },
          "tree": {
            "type": "frame",
            "layout": {
              "direction": "VERTICAL",
              "padding": { "top": 12, "right": 12, "bottom": 12, "left": 12 },
              "gap": 8,
              "sizing": { "width": "FIXED", "widthValue": 200, "height": "FIXED", "heightValue": 240 },
              "radius": 12
            },
            "fill": { "bind": "color/surface" },
            "children": [
              { "type": "image", "source": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=", "width": 176, "height": 100, "fit": "cover" },
              { "type": "svg", "source": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\"><circle cx=\"12\" cy=\"12\" r=\"10\" fill=\"black\"/></svg>", "width": 24, "height": 24 },
              { "type": "icon", "name": "material:bookmark", "size": 24 },
              { "type": "text", "value": "Asset test card", "style": { "bind": "text/body" }, "color": { "hex": "#000000" } }
            ]
          }
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Validate via CLI**

```bash
cd /Users/markus/Dev/extract-design-system/lib
cat ../examples/v2-asset-test-card.json | npx tsx src/cli.ts validate
echo "exit=$?"
```

Expected: `exit=0`.

- [ ] **Step 3: Copy to plugin tests/fixtures**

```bash
cp /Users/markus/Dev/extract-design-system/examples/v2-asset-test-card.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/tests/fixtures/asset-test-card-v2.json
```

- [ ] **Step 4: Add an end-to-end fixture test**

Append to `tests/unit/apply-components-v2.test.ts`:

```ts
describe('applyComponentV2 with image, svg, icon nodes (asset-test-card fixture)', () => {
  it('applies the synthetic fixture and produces the expected Figma operations', async () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/surface', coll, 'COLOR');
    setJsonName(v, 'color/surface'); setJsonKind(v, 'variable');
    const ts = (figma as any).createTextStyle();
    setJsonName(ts, 'text/body'); setJsonKind(ts, 'textStyle');

    const { applyComponentV2 } = await import('../../src/main/apply/components-v2.js');
    const json = JSON.parse(readFileSync(fixturePath('asset-test-card-v2.json'), 'utf8'));
    const comp = json.components[0];
    const ds = json;
    const ctx = { page: (figma as any).currentPage, setsByJsonName: new Map(), placedIndex: { value: 0 }, now: '2026-04-28T00:00:00Z' };
    const report: any = { applied: 0, failed: [] };

    await applyComponentV2(comp, ds, { allowOrphanDelete: {} }, ctx, report);
    expect(report.failed).toEqual([]);
    expect(report.applied).toBe(1);
    expect(mock.calls.some(c => c.op === 'figma.createImage')).toBe(true);
    expect(mock.calls.some(c => c.op === 'figma.createNodeFromSvg')).toBe(true);
    expect(mock.calls.some(c => c.op === 'createText')).toBe(true);
    expect(mock.calls.some(c => c.op === 'combineAsVariants')).toBe(true);
  });
});
```

This test requires `readFileSync` and `fixturePath` to be in scope. Look at the existing test file's imports and helpers; if they are not already imported, add at the top:

```ts
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixturePath = (name: string) => join(__dirname, '..', 'fixtures', name);
```

If a similar helper already exists in the file, reuse it.

- [ ] **Step 5: Run full plugin test suite**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run
npx tsc --noEmit
npm run build
```

Expected:
- 16 tests pass total in `apply-components-v2.test.ts` (15 from earlier tasks + 1 fixture test)
- 70+ overall (counting grew across batches)
- typecheck and build clean

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git add tests/fixtures/asset-test-card-v2.json tests/unit/apply-components-v2.test.ts
git commit -m "test(v2): synthetic asset-test-card fixture and end-to-end test"
```

```bash
cd /Users/markus/Dev/extract-design-system
git add examples/v2-asset-test-card.json
git commit -m "docs(examples): add v2 asset test card fixture (image, svg, icon)"
```

---

## Task 8: Update extractor reference doc with Phase 2 section

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/references/flutter-extraction.md`

- [ ] **Step 1: Append the new section**

Append at the end of the file:

```markdown

## v2 Phase 2: Asset and icon extraction

The widget tree walker now handles three more leaf widgets that previously forced full component degradation. These produce new `WidgetNode` types: `image`, `svg`, `icon`.

### `Image.asset` -> `image` node

```dart
Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.cover)
```

becomes:

```json
{ "type": "image", "source": "<base64-bytes>", "width": 48, "height": 48, "fit": "cover" }
```

Resolve the asset path against `pubspec.yaml`'s `flutter.assets` declarations. Read the file bytes from disk and base64-encode them. Map `BoxFit.cover` -> `"cover"`, `BoxFit.contain` -> `"contain"`, `BoxFit.fill` -> `"fill"`. Other BoxFit values default to `"cover"`.

If the resolved file is larger than 1 MB or cannot be read, the entire component degrades to v1 shell extraction.

### `SvgPicture.asset` -> `svg` node

```dart
SvgPicture.asset('assets/icons/check.svg', width: 16, height: 16)
```

becomes:

```json
{ "type": "svg", "source": "<svg xmlns=\"...\">...</svg>", "width": 16, "height": 16 }
```

Read the SVG XML verbatim (no transformation). If the file cannot be read, the component degrades.

### `Icon(IconData)` -> `icon` node

```dart
Icon(Icons.arrow_back, size: 24, color: t.palette.ink)
Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16)
```

becomes:

```json
{ "type": "icon", "name": "material:arrow_back", "size": 24 }
{ "type": "icon", "name": "phosphor:caret-right:bold", "size": 16 }
```

Icon name format: `<package>:<icon>:<style?>`. For Material, use the lowercase snake-case identifier from the source (`Icons.arrow_back` -> `arrow_back`). For Phosphor, include the style suffix (`PhosphorIcons.caretRight(PhosphorIconsStyle.bold)` -> `caret-right:bold`). Unknown packages: `unknown:<source-text>`.

Color is intentionally not preserved in the v2 placeholder. Designers see a dashed gray placeholder with the icon name; they swap it for a real icon glyph in Figma. Real glyph rendering is a Phase 2.5 enhancement that is not in scope.

### Updated category table

Replace the prior "Leaf (Phase 2+)" row with:

| Leaf (Phase 2) | `Image.asset`, `SvgPicture.asset`, `Icon` | Emit `image`, `svg`, or `icon` node |
| Leaf (out of scope) | `CustomPaint`, `RepaintBoundary` of custom subtree, `BackdropFilter`, gradient fills with multiple stops | Component falls back to v1 shell |
```

- [ ] **Step 2: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add references/flutter-extraction.md
git commit -m "docs(extract): v2 Phase 2 section for image, svg, icon extraction"
```

---

## Task 9: Final verification

- [ ] **Step 1: Run full test suites in both repos**

```bash
cd /Users/markus/Dev/extract-design-system/lib && npx vitest run
cd /Users/markus/Dev/extract-design-system-figma-plugin && npx vitest run
```

Expected: 41 in extractor (no new tests there in this phase), 70+ in plugin.

- [ ] **Step 2: Typecheck both repos**

```bash
cd /Users/markus/Dev/extract-design-system/lib && npx tsc --noEmit
cd /Users/markus/Dev/extract-design-system-figma-plugin && npx tsc --noEmit
```

Expected: clean.

- [ ] **Step 3: Build the plugin**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npm run build
test -s build/code.js && test -s build/ui.html && echo OK
```

Expected: `OK`.

- [ ] **Step 4: Validate the existing earnapp design-system.json still passes**

The earnapp file from Phase 1 contains only `frame` and `text` nodes, so it should remain valid.

```bash
cd /Users/markus/Dev/extract-design-system/lib
cat /Users/markus/Dev/earnapp_handover/design-system.json | npx tsx src/cli.ts validate
echo "exit=$?"
```

Expected: `exit=0`.

- [ ] **Step 5: Tag both repos**

```bash
cd /Users/markus/Dev/extract-design-system && git tag v0.2.0-phase2
cd /Users/markus/Dev/extract-design-system-figma-plugin && git tag v0.2.0-phase2
```

---

## Notes for the implementer

- **Schema files are duplicated across repos.** The schema.v2.json and TS WidgetNode union must stay in sync. Each task that touches one repo's copy should immediately mirror to the other. The diff command is the canonical check.
- **`base64ToBytes` runs in the Figma plugin runtime.** That runtime supports `atob` (which converts base64 to a binary string). For each character, take its `charCodeAt(0)` (which is 0..255) into a `Uint8Array`. The plugin's `figma.createImage` expects `Uint8Array`.
- **`createNodeFromSvg` on real Figma returns a `FrameNode`.** Once returned, set `name`, `resize(w, h)`, identity pluginData, etc. The mock mimics this enough for unit tests.
- **The icon placeholder uses Inter Regular for its label.** That font is loaded earlier in `applyComponentV2` (or in `walkTree`'s text branch). For an icon-only tree where no text node is otherwise emitted, the label code path is the first place that needs the font; load it on demand.
- **All new tests use the existing FigmaMock pattern.** The mock's `calls` array is the assertion surface. Tests verify call ordering and arguments rather than asserting on actual node geometry.
