# v2 Sync Phase 1: PrimaryButton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove the v2 design-system schema + extractor + plugin pipeline by extracting and rebuilding `PrimaryButton` from the earnapp Flutter codebase as a 4-variant Figma ComponentSet with full token bindings.

**Architecture:** v2 is a strict additive superset of v1. Extractor (LLM-driven skill + TS CLI) emits `version: "2.0.0"` JSON where some components have a `variants` array containing rich `WidgetNode` trees; components without `variants` keep their v1 shape. Plugin dispatches per `version`, then per-component on `variants` presence: rich-tree apply for v2 components with variants, existing shell apply for everything else. v1 JSON files keep working unchanged.

**Tech Stack:** TypeScript, Ajv (JSON Schema validation), vitest, esbuild. Two repos: `/Users/markus/Dev/extract-design-system/` (CLI + reference docs) and `/Users/markus/Dev/extract-design-system-figma-plugin/` (Figma plugin).

**Spec:** `/Users/markus/Dev/earnapp/docs/superpowers/specs/2026-04-28-v2-sync-phase-1-primary-button-design.md`

---

## File Structure

### extract-design-system repo (`/Users/markus/Dev/extract-design-system/`)

```
references/
├── schema.v1.json                 (existing, unchanged)
├── schema.v2.json                 (NEW: v2 JSON Schema)
└── flutter-extraction.md          (MODIFIED: add v2 sections)
lib/src/
├── schema.ts                      (MODIFIED: add v2 TS types)
└── validate.ts                    (MODIFIED: dispatch on version)
lib/tests/
└── validate.test.ts               (MODIFIED: add v2 tests)
examples/
└── v2-primary-button.json         (NEW: fixture)
lib/scripts/
└── smoke.sh                       (MODIFIED: add v2 validation)
```

### extract-design-system-figma-plugin repo (`/Users/markus/Dev/extract-design-system-figma-plugin/`)

```
schema.v2.json                     (NEW: copied from extract-design-system)
src/shared/
├── schema.ts                      (MODIFIED: add v2 types + discriminated union)
└── validate.ts                    (MODIFIED: dispatch on version)
src/main/apply/
├── index.ts                       (MODIFIED: dispatch on version + per-component on variants)
├── components.ts                  (REFACTORED: extract applyComponentShell function)
├── components-v2.ts               (NEW: v2 rich-tree apply)
└── layout.ts                      (NEW: shared layout helpers)
tests/unit/
├── apply-components-v2.test.ts    (NEW)
├── apply-orchestrator.test.ts     (MODIFIED: add v2 dispatch test)
└── validate.test.ts               (MODIFIED: add v2 tests)
tests/fixtures/
└── primary-button-v2.json         (NEW: PrimaryButton v2 fixture)
```

Each file has one responsibility:
- `schema.v2.json`: formal JSON Schema for validation. Single source of truth for v2 shape, copied verbatim into both repos.
- `schema.ts`: TypeScript types mirroring the JSON Schema, with discriminated unions.
- `validate.ts`: dispatches on `version` field, runs Ajv, returns `ValidateResult`.
- `apply/layout.ts`: layout-application helpers shared by v1 shell and v2 walker.
- `apply/components-v2.ts`: rich-tree walker, `applyComponentV2`, color/text-style bindings.
- `apply/components.ts`: existing v1 shell logic, refactored to expose a per-component function.
- `apply/index.ts`: orchestrator + version dispatcher.

---

## Task 1: Define schema.v2.json in extract-design-system

**Files:**
- Create: `/Users/markus/Dev/extract-design-system/references/schema.v2.json`

This is the formal JSON Schema for v2. It extends v1 by adding optional `variantProperties` and `variants` fields on the `Component` type, and defines `WidgetNode`, `ColorBinding`, `TextStyleBinding`.

- [ ] **Step 1: Read existing schema.v1.json**

```bash
cat /Users/markus/Dev/extract-design-system/references/schema.v1.json | head -50
```

This gives the structure to mirror.

- [ ] **Step 2: Write schema.v2.json**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "DesignSystem v2",
  "type": "object",
  "required": ["version", "source", "collections", "variables", "components"],
  "properties": {
    "$schema": { "type": "string" },
    "version": { "const": "2.0.0" },
    "source": {
      "type": "object",
      "required": ["stack", "extractedAt"],
      "properties": {
        "stack": { "enum": ["flutter", "html-react", "ios", "android"] },
        "extractedAt": { "type": "string", "format": "date-time" },
        "commit": { "type": "string" }
      }
    },
    "collections": { "type": "array", "items": { "$ref": "#/definitions/Collection" } },
    "variables": { "type": "array", "items": { "$ref": "#/definitions/Variable" } },
    "aliases": { "type": "array", "items": { "$ref": "#/definitions/Alias" } },
    "textStyles": { "type": "array", "items": { "$ref": "#/definitions/TextStyle" } },
    "effects": { "type": "array", "items": { "$ref": "#/definitions/Effect" } },
    "components": { "type": "array", "items": { "$ref": "#/definitions/ComponentV2" } },
    "icons": { "type": "array", "items": { "$ref": "#/definitions/Icon" } }
  },
  "definitions": {
    "Collection": {
      "type": "object",
      "required": ["name", "modes", "defaultMode"],
      "properties": {
        "name": { "type": "string" },
        "description": { "type": "string" },
        "modes": { "type": "array", "items": { "type": "string" }, "minItems": 1 },
        "defaultMode": { "type": "string" }
      }
    },
    "Variable": {
      "type": "object",
      "required": ["name", "collection", "type", "valuesByMode"],
      "properties": {
        "name": { "type": "string" },
        "collection": { "type": "string" },
        "type": { "enum": ["color", "number", "string", "boolean"] },
        "scope": { "type": "array", "items": { "type": "string" } },
        "valuesByMode": { "type": "object", "additionalProperties": true }
      }
    },
    "Alias": {
      "type": "object",
      "required": ["name", "resolves"],
      "properties": {
        "name": { "type": "string" },
        "resolves": { "type": "string" }
      }
    },
    "Bound": {
      "oneOf": [
        { "type": ["string", "number", "boolean"] },
        { "type": "object", "required": ["bind"], "properties": { "bind": { "type": "string" } } }
      ]
    },
    "TextStyle": {
      "type": "object",
      "required": ["name", "fontFamily", "fontWeight", "fontSize"],
      "properties": {
        "name": { "type": "string" },
        "fontFamily": { "$ref": "#/definitions/Bound" },
        "fontWeight": { "$ref": "#/definitions/Bound" },
        "fontSize": { "$ref": "#/definitions/Bound" },
        "lineHeight": {
          "type": "object",
          "required": ["value", "unit"],
          "properties": {
            "value": { "type": "number" },
            "unit": { "enum": ["PIXELS", "PERCENT", "FLUID"] }
          }
        },
        "letterSpacing": { "$ref": "#/definitions/Bound" }
      }
    },
    "Effect": {
      "type": "object",
      "required": ["name", "type"],
      "properties": {
        "name": { "type": "string" },
        "type": { "enum": ["DROP_SHADOW", "INNER_SHADOW", "LAYER_BLUR", "BACKGROUND_BLUR"] },
        "radius": { "type": "number" },
        "offset": {
          "type": "object",
          "properties": { "x": { "type": "number" }, "y": { "type": "number" } }
        },
        "color": { "type": "string" }
      }
    },
    "Layout": {
      "type": "object",
      "required": ["direction", "sizing"],
      "properties": {
        "direction": { "enum": ["HORIZONTAL", "VERTICAL", "NONE"] },
        "padding": {
          "type": "object",
          "properties": {
            "top": { "type": "number" }, "right": { "type": "number" },
            "bottom": { "type": "number" }, "left": { "type": "number" }
          }
        },
        "gap": { "type": "number" },
        "alignItems": { "enum": ["MIN", "CENTER", "MAX", "BASELINE"] },
        "justify": { "enum": ["MIN", "CENTER", "MAX", "SPACE_BETWEEN"] },
        "sizing": {
          "type": "object",
          "required": ["width", "height"],
          "properties": {
            "width": { "enum": ["FILL", "HUG", "FIXED"] },
            "widthValue": { "type": "number" },
            "height": { "enum": ["FILL", "HUG", "FIXED"] },
            "heightValue": { "type": "number" }
          }
        },
        "radius": { "$ref": "#/definitions/Bound" }
      }
    },
    "ColorBinding": {
      "oneOf": [
        { "type": "object", "required": ["bind"], "properties": { "bind": { "type": "string" } }, "additionalProperties": false },
        { "type": "object", "required": ["hex"], "properties": { "hex": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$" } }, "additionalProperties": false }
      ]
    },
    "TextStyleBinding": {
      "type": "object",
      "required": ["bind"],
      "properties": { "bind": { "type": "string" } },
      "additionalProperties": false
    },
    "WidgetNode": {
      "oneOf": [
        {
          "type": "object",
          "required": ["type", "layout", "children"],
          "properties": {
            "type": { "const": "frame" },
            "layout": { "$ref": "#/definitions/Layout" },
            "fill": { "$ref": "#/definitions/ColorBinding" },
            "stroke": { "$ref": "#/definitions/ColorBinding" },
            "strokeWeight": { "type": "number" },
            "children": { "type": "array", "items": { "$ref": "#/definitions/WidgetNode" } }
          }
        },
        {
          "type": "object",
          "required": ["type", "value", "style", "color"],
          "properties": {
            "type": { "const": "text" },
            "value": { "type": "string" },
            "style": { "$ref": "#/definitions/TextStyleBinding" },
            "color": { "$ref": "#/definitions/ColorBinding" }
          }
        }
      ]
    },
    "ComponentProperty": {
      "type": "object",
      "required": ["name", "type"],
      "properties": {
        "name": { "type": "string" },
        "type": { "enum": ["VARIANT", "TEXT", "BOOLEAN", "INSTANCE_SWAP"] },
        "options": { "type": "array", "items": { "type": "string" } },
        "default": {},
        "preferredValues": { "type": "array", "items": { "type": "string" } }
      }
    },
    "ComponentV2": {
      "type": "object",
      "required": ["name", "tier", "layout"],
      "properties": {
        "name": { "type": "string" },
        "tier": { "enum": ["atom", "molecule", "organism", "template"] },
        "description": { "type": "string" },
        "layout": { "$ref": "#/definitions/Layout" },
        "properties": { "type": "array", "items": { "$ref": "#/definitions/ComponentProperty" } },
        "variantMappings": { "type": "object" },
        "responsive": { "type": "object" },
        "slots": { "type": "array" },
        "variantProperties": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "type"],
            "properties": {
              "name": { "type": "string" },
              "type": { "enum": ["BOOLEAN", "VARIANT"] },
              "options": { "type": "array", "items": { "type": "string" } }
            }
          }
        },
        "variants": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["key", "properties", "tree"],
            "properties": {
              "key": { "type": "string" },
              "properties": { "type": "object", "additionalProperties": { "type": "string" } },
              "tree": { "$ref": "#/definitions/WidgetNode" }
            }
          }
        }
      }
    },
    "Icon": {
      "type": "object",
      "required": ["name", "svg"],
      "properties": {
        "name": { "type": "string" },
        "svg": { "type": "string" },
        "size": { "type": "number" }
      }
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add references/schema.v2.json
git commit -m "feat(schema): add v2 JSON Schema with WidgetNode, variants"
```

---

## Task 2: Add v2 TypeScript types in extract-design-system CLI

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/lib/src/schema.ts`

- [ ] **Step 1: Read existing schema.ts**

```bash
cat /Users/markus/Dev/extract-design-system/lib/src/schema.ts
```

Note the existing exports (Collection, Variable, etc.). Append (do not replace) the new types at the end.

- [ ] **Step 2: Append v2 types to schema.ts**

Add at the end of the file:

```ts
// ============================================================================
// v2 schema additions
// ============================================================================

export type ColorBinding = { bind: string } | { hex: string };
export type TextStyleBinding = { bind: string };

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

export interface VariantProperty {
  name: string;
  type: 'BOOLEAN' | 'VARIANT';
  options?: string[];
}

export interface VariantEntry {
  key: string;
  properties: Record<string, string>;
  tree: WidgetNode;
}

export interface ComponentV2 extends Component {
  variantProperties?: VariantProperty[];
  variants?: VariantEntry[];
}

export interface DesignSystemV2 extends Omit<DesignSystem, 'version' | 'components'> {
  version: '2.0.0';
  components: ComponentV2[];
}

export type AnyDesignSystem = DesignSystem | DesignSystemV2;
```

The `Component` and `DesignSystem` and `Layout` types already exist in schema.ts (Layout was added in v1). `ComponentV2` extends `Component` so all v1 fields remain valid.

- [ ] **Step 3: Run typecheck**

```bash
cd /Users/markus/Dev/extract-design-system/lib
npx tsc --noEmit
```

Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add lib/src/schema.ts
git commit -m "feat(schema): add v2 TS types (WidgetNode, ColorBinding, ComponentV2)"
```

---

## Task 3: Update extract-design-system validate.ts to dispatch on version

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/lib/src/validate.ts`

- [ ] **Step 1: Read existing validate.ts**

```bash
cat /Users/markus/Dev/extract-design-system/lib/src/validate.ts
```

Note how it currently loads `schema.v1.json` and compiles it once.

- [ ] **Step 2: Replace validate.ts**

```ts
import Ajv, { type ErrorObject } from 'ajv';
import addFormats from 'ajv-formats';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const refsDir = join(__dirname, '..', '..', 'references');

const schemaV1 = JSON.parse(readFileSync(join(refsDir, 'schema.v1.json'), 'utf8'));
const schemaV2 = JSON.parse(readFileSync(join(refsDir, 'schema.v2.json'), 'utf8'));

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
const validateV1 = ajv.compile(schemaV1);
const validateV2 = ajv.compile(schemaV2);

export interface ValidateResult {
  ok: boolean;
  errors: string[];
  version?: '1.0.0' | '2.0.0';
}

export function validate(input: unknown): ValidateResult {
  if (!input || typeof input !== 'object') {
    return { ok: false, errors: ['(root) must be an object'] };
  }
  const version = (input as any).version;
  if (version === '2.0.0') {
    const ok = validateV2(input);
    if (ok) return { ok: true, errors: [], version: '2.0.0' };
    return { ok: false, errors: (validateV2.errors ?? []).map(formatError), version: '2.0.0' };
  }
  if (version === '1.0.0') {
    const ok = validateV1(input);
    if (ok) return { ok: true, errors: [], version: '1.0.0' };
    return { ok: false, errors: (validateV1.errors ?? []).map(formatError), version: '1.0.0' };
  }
  return { ok: false, errors: [`(root) unknown version "${version}", expected "1.0.0" or "2.0.0"`] };
}

function formatError(e: ErrorObject): string {
  const path = e.instancePath || '(root)';
  return `${path} ${e.message ?? 'invalid'}`;
}
```

- [ ] **Step 3: Run typecheck**

```bash
cd /Users/markus/Dev/extract-design-system/lib
npx tsc --noEmit
```

Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add lib/src/validate.ts
git commit -m "feat(validate): dispatch on version field, support v1 and v2"
```

---

## Task 4: Add v2 fixture and validate test

**Files:**
- Create: `/Users/markus/Dev/extract-design-system/examples/v2-primary-button.json`
- Modify: `/Users/markus/Dev/extract-design-system/lib/tests/validate.test.ts`

- [ ] **Step 1: Write v2 PrimaryButton fixture**

Create `/Users/markus/Dev/extract-design-system/examples/v2-primary-button.json`:

```json
{
  "version": "2.0.0",
  "source": { "stack": "flutter", "extractedAt": "2026-04-28T00:00:00Z" },
  "collections": [
    { "name": "primitives", "modes": ["default"], "defaultMode": "default" }
  ],
  "variables": [
    { "name": "color/brand", "collection": "primitives", "type": "color", "valuesByMode": { "default": "#0D9488" } },
    { "name": "color/ink-inverse", "collection": "primitives", "type": "color", "valuesByMode": { "default": "#FAF8F5" } },
    { "name": "radius/pill", "collection": "primitives", "type": "number", "valuesByMode": { "default": 9999 } }
  ],
  "textStyles": [
    { "name": "text/cta-label", "fontFamily": "Outfit", "fontWeight": 600, "fontSize": 20 }
  ],
  "components": [
    {
      "name": "PrimaryButton",
      "tier": "atom",
      "layout": {
        "direction": "HORIZONTAL",
        "alignItems": "CENTER",
        "justify": "CENTER",
        "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
        "radius": { "bind": "radius/pill" }
      },
      "properties": [
        { "name": "destructive", "type": "BOOLEAN", "default": false },
        { "name": "outlined", "type": "BOOLEAN", "default": false }
      ],
      "variantProperties": [
        { "name": "destructive", "type": "BOOLEAN" },
        { "name": "outlined", "type": "BOOLEAN" }
      ],
      "variants": [
        {
          "key": "destructive=false,outlined=false",
          "properties": { "destructive": "false", "outlined": "false" },
          "tree": {
            "type": "frame",
            "layout": {
              "direction": "HORIZONTAL", "alignItems": "CENTER", "justify": "CENTER",
              "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
              "radius": { "bind": "radius/pill" }
            },
            "fill": { "bind": "color/brand" },
            "children": [
              { "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "bind": "color/ink-inverse" } }
            ]
          }
        },
        {
          "key": "destructive=false,outlined=true",
          "properties": { "destructive": "false", "outlined": "true" },
          "tree": {
            "type": "frame",
            "layout": {
              "direction": "HORIZONTAL", "alignItems": "CENTER", "justify": "CENTER",
              "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
              "radius": { "bind": "radius/pill" }
            },
            "stroke": { "bind": "color/brand" },
            "strokeWeight": 1.5,
            "children": [
              { "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "bind": "color/brand" } }
            ]
          }
        },
        {
          "key": "destructive=true,outlined=false",
          "properties": { "destructive": "true", "outlined": "false" },
          "tree": {
            "type": "frame",
            "layout": {
              "direction": "HORIZONTAL", "alignItems": "CENTER", "justify": "CENTER",
              "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
              "radius": { "bind": "radius/pill" }
            },
            "fill": { "hex": "#DC2626" },
            "children": [
              { "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "bind": "color/ink-inverse" } }
            ]
          }
        },
        {
          "key": "destructive=true,outlined=true",
          "properties": { "destructive": "true", "outlined": "true" },
          "tree": {
            "type": "frame",
            "layout": {
              "direction": "HORIZONTAL", "alignItems": "CENTER", "justify": "CENTER",
              "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
              "radius": { "bind": "radius/pill" }
            },
            "stroke": { "hex": "#DC2626" },
            "strokeWeight": 1.5,
            "children": [
              { "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "hex": "#DC2626" } }
            ]
          }
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Read existing validate.test.ts**

```bash
cat /Users/markus/Dev/extract-design-system/lib/tests/validate.test.ts
```

If the file does not exist, create it. Append v2 tests.

- [ ] **Step 3: Add v2 tests**

Append (or create) `/Users/markus/Dev/extract-design-system/lib/tests/validate.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { validate } from '../src/validate.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const examples = join(__dirname, '..', '..', 'examples');

describe('validate v2', () => {
  it('accepts a valid v2 PrimaryButton fixture', () => {
    const json = JSON.parse(readFileSync(join(examples, 'v2-primary-button.json'), 'utf8'));
    const result = validate(json);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.version).toBe('2.0.0');
  });

  it('rejects a v2 component variant with missing tree', () => {
    const json = JSON.parse(readFileSync(join(examples, 'v2-primary-button.json'), 'utf8'));
    delete json.components[0].variants[0].tree;
    const result = validate(json);
    expect(result.ok).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('rejects a v2 widget node with unknown type', () => {
    const json = JSON.parse(readFileSync(join(examples, 'v2-primary-button.json'), 'utf8'));
    json.components[0].variants[0].tree.type = 'image';
    const result = validate(json);
    expect(result.ok).toBe(false);
  });

  it('rejects unknown version', () => {
    const result = validate({ version: '3.0.0' });
    expect(result.ok).toBe(false);
    expect(result.errors[0]).toMatch(/unknown version/);
  });
});
```

- [ ] **Step 4: Run tests**

```bash
cd /Users/markus/Dev/extract-design-system/lib
npx vitest run tests/validate.test.ts
```

Expected: 4 v2 tests pass (plus any pre-existing v1 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add examples/v2-primary-button.json lib/tests/validate.test.ts
git commit -m "test(validate): v2 fixture and validation tests"
```

---

## Task 5: Update extract-design-system smoke script for v2

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/lib/scripts/smoke.sh`

- [ ] **Step 1: Read existing smoke.sh**

```bash
cat /Users/markus/Dev/extract-design-system/lib/scripts/smoke.sh
```

- [ ] **Step 2: Append v2 validation step**

At the end of the script (before any `echo "All checks passed"` line), add:

```bash

echo "== v2 validation =="
cat ../examples/v2-primary-button.json | npx tsx src/cli.ts validate
```

If the script structure is different, add a comparable line that pipes the v2 fixture into `cli validate` and checks exit code 0.

- [ ] **Step 3: Run smoke**

```bash
cd /Users/markus/Dev/extract-design-system/lib
bash scripts/smoke.sh
```

Expected: exits 0; v2 fixture validates without error.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add lib/scripts/smoke.sh
git commit -m "test(smoke): include v2 fixture validation"
```

---

## Task 6: Copy schema.v2.json into the plugin repo

**Files:**
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json`

- [ ] **Step 1: Copy the file**

```bash
cp /Users/markus/Dev/extract-design-system/references/schema.v2.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json
```

- [ ] **Step 2: Verify identical**

```bash
diff /Users/markus/Dev/extract-design-system/references/schema.v2.json \
     /Users/markus/Dev/extract-design-system-figma-plugin/schema.v2.json
```

Expected: no output (files are identical).

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git add schema.v2.json
git commit -m "feat(schema): copy v2 JSON Schema from extract-design-system"
```

---

## Task 7: Add v2 TypeScript types to plugin schema.ts

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/shared/schema.ts`

- [ ] **Step 1: Read existing plugin schema.ts**

```bash
cat /Users/markus/Dev/extract-design-system-figma-plugin/src/shared/schema.ts
```

- [ ] **Step 2: Append v2 types**

Append at the end (do not replace existing types):

```ts
// ============================================================================
// v2 schema additions
// ============================================================================

export type ColorBinding = { bind: string } | { hex: string };
export type TextStyleBinding = { bind: string };

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

export interface VariantProperty {
  name: string;
  type: 'BOOLEAN' | 'VARIANT';
  options?: string[];
}

export interface VariantEntry {
  key: string;
  properties: Record<string, string>;
  tree: WidgetNode;
}

export interface ComponentV2 extends Component {
  variantProperties?: VariantProperty[];
  variants?: VariantEntry[];
}

export interface DesignSystemV2 extends Omit<DesignSystem, 'version' | 'components'> {
  version: '2.0.0';
  components: ComponentV2[];
}

export type AnyDesignSystem = DesignSystem | DesignSystemV2;
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx tsc --noEmit
```

Expected: exits 0.

- [ ] **Step 4: Commit**

```bash
git add src/shared/schema.ts
git commit -m "feat(schema): add v2 TS types in plugin"
```

---

## Task 8: Update plugin validate.ts to dispatch on version

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/shared/validate.ts`

- [ ] **Step 1: Read existing validate.ts**

```bash
cat /Users/markus/Dev/extract-design-system-figma-plugin/src/shared/validate.ts
```

- [ ] **Step 2: Replace with version-aware validate**

```ts
import Ajv, { type ErrorObject } from 'ajv';
import addFormats from 'ajv-formats';
import schemaV1 from '../../schema.v1.json';
import schemaV2 from '../../schema.v2.json';
import type { DesignSystem, DesignSystemV2 } from './schema.js';

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
const validateV1 = ajv.compile(schemaV1);
const validateV2 = ajv.compile(schemaV2);

export interface ValidateResult {
  ok: boolean;
  errors: string[];
  value?: DesignSystem | DesignSystemV2;
  version?: '1.0.0' | '2.0.0';
}

export function validate(input: unknown): ValidateResult {
  if (!input || typeof input !== 'object') {
    return { ok: false, errors: ['(root) must be an object'] };
  }
  const version = (input as any).version;
  if (version === '2.0.0') {
    const ok = validateV2(input);
    if (ok) return { ok: true, errors: [], value: input as unknown as DesignSystemV2, version: '2.0.0' };
    return { ok: false, errors: (validateV2.errors ?? []).map(formatError), version: '2.0.0' };
  }
  if (version === '1.0.0') {
    const ok = validateV1(input);
    if (ok) return { ok: true, errors: [], value: input as unknown as DesignSystem, version: '1.0.0' };
    return { ok: false, errors: (validateV1.errors ?? []).map(formatError), version: '1.0.0' };
  }
  return { ok: false, errors: [`(root) unknown version "${version}", expected "1.0.0" or "2.0.0"`] };
}

function formatError(e: ErrorObject): string {
  const path = e.instancePath || '(root)';
  return `${path} ${e.message ?? 'invalid'}`;
}
```

- [ ] **Step 3: Add v2 fixture to plugin tests/fixtures**

```bash
cp /Users/markus/Dev/extract-design-system/examples/v2-primary-button.json \
   /Users/markus/Dev/extract-design-system-figma-plugin/tests/fixtures/primary-button-v2.json
```

- [ ] **Step 4: Append v2 tests to validate.test.ts**

Append to `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/validate.test.ts`:

```ts
describe('validate v2', () => {
  it('accepts a valid v2 PrimaryButton fixture', () => {
    const json = JSON.parse(readFileSync(fixturePath('primary-button-v2.json'), 'utf8'));
    const result = validate(json);
    expect(result.ok).toBe(true);
    expect(result.errors).toEqual([]);
    expect(result.version).toBe('2.0.0');
  });

  it('rejects a v2 component variant with missing tree', () => {
    const json = JSON.parse(readFileSync(fixturePath('primary-button-v2.json'), 'utf8'));
    delete json.components[0].variants[0].tree;
    const result = validate(json);
    expect(result.ok).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('rejects unknown version', () => {
    const result = validate({ version: '3.0.0' });
    expect(result.ok).toBe(false);
    expect(result.errors[0]).toMatch(/unknown version/);
  });
});
```

- [ ] **Step 5: Run tests**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run tests/unit/validate.test.ts
```

Expected: all tests pass (existing v1 tests + new v2 tests).

- [ ] **Step 6: Typecheck**

```bash
npx tsc --noEmit
```

Expected: exits 0.

- [ ] **Step 7: Commit**

```bash
git add src/shared/validate.ts tests/unit/validate.test.ts tests/fixtures/primary-button-v2.json
git commit -m "feat(validate): dispatch on version, accept v2 design systems"
```

---

## Task 9: Extract shared layout helpers from components.ts

**Files:**
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/layout.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components.ts`

The current `components.ts` contains `applyShell`, `applyRadius`, `applyFill`, `sizingToMode`, `alignmentToFigma`, `justifyToFigma`, `findVariableByJsonName`, `hexToRgb`. v2's walker needs these too. Extract them into a shared module.

- [ ] **Step 1: Read components.ts**

```bash
cat /Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components.ts
```

- [ ] **Step 2: Create layout.ts with the shared helpers**

```ts
// src/main/apply/layout.ts
import type { Layout, Bound } from '../../shared/schema.js';
import { getJsonName } from '../identity.js';

export function applyLayout(node: any, layout: Layout): void {
  const isAutoLayout = layout.direction !== 'NONE';
  node.layoutMode = isAutoLayout ? layout.direction : 'NONE';
  if (isAutoLayout) {
    node.primaryAxisSizingMode = sizingToMode(
      layout.direction === 'HORIZONTAL' ? layout.sizing.width : layout.sizing.height
    );
    node.counterAxisSizingMode = sizingToMode(
      layout.direction === 'HORIZONTAL' ? layout.sizing.height : layout.sizing.width
    );
    if (typeof layout.gap === 'number') node.itemSpacing = layout.gap;
    if (layout.alignItems) node.counterAxisAlignItems = alignmentToFigma(layout.alignItems);
    if (layout.justify) node.primaryAxisAlignItems = justifyToFigma(layout.justify);
  }
  if (layout.sizing.width === 'FIXED' && typeof layout.sizing.widthValue === 'number' && typeof node.resize === 'function') {
    const h = layout.sizing.heightValue ?? node.height ?? 0;
    node.resize(layout.sizing.widthValue, h);
  }
  if (layout.sizing.height === 'FIXED' && typeof layout.sizing.heightValue === 'number' && typeof node.resize === 'function') {
    const w = layout.sizing.widthValue ?? node.width ?? 0;
    node.resize(w, layout.sizing.heightValue);
  }
  if (layout.padding) {
    node.paddingTop = layout.padding.top ?? 0;
    node.paddingRight = layout.padding.right ?? 0;
    node.paddingBottom = layout.padding.bottom ?? 0;
    node.paddingLeft = layout.padding.left ?? 0;
  }
  applyRadius(node, layout.radius);
}

export function sizingToMode(a: 'FILL' | 'HUG' | 'FIXED'): 'FIXED' | 'AUTO' {
  return a === 'FIXED' ? 'FIXED' : 'AUTO';
}

export function alignmentToFigma(a: 'MIN' | 'CENTER' | 'MAX' | 'BASELINE'): string {
  return a === 'BASELINE' ? 'MIN' : a;
}

export function justifyToFigma(j: 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN'): string {
  return j;
}

export function applyRadius(node: any, radius: Bound<number> | undefined): void {
  if (radius === undefined) return;
  if (typeof radius === 'number') {
    node.cornerRadius = radius;
    return;
  }
  if ('bind' in radius) {
    const v = findVariableByJsonName(radius.bind);
    if (v && typeof node.setBoundVariable === 'function') node.setBoundVariable('topLeftRadius', v);
  }
}

export function findVariableByJsonName(name: string): any | undefined {
  const vars = (figma as any).variables?.getLocalVariables?.() ?? [];
  return vars.find((v: any) => getJsonName(v) === name);
}

export function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const h = hex.replace('#', '');
  const n = h.length === 3 ? h.split('').map(c => c + c).join('') : h;
  return {
    r: parseInt(n.slice(0, 2), 16) / 255,
    g: parseInt(n.slice(2, 4), 16) / 255,
    b: parseInt(n.slice(4, 6), 16) / 255,
  };
}
```

- [ ] **Step 3: Update components.ts to import from layout.ts**

In `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components.ts`:

1. Replace the existing implementations of `applyShell` (rename to use `applyLayout` from new module), `applyRadius`, `applyFill`, `sizingToMode`, `alignmentToFigma`, `justifyToFigma`, `findVariableByJsonName`, `hexToRgb` with imports from `./layout.js`.

2. The existing `applyShell` function combines `applyLayout` + `applyFill`. Keep `applyShell` as a local thin wrapper:

```ts
import { applyLayout, findVariableByJsonName, hexToRgb } from './layout.js';

// ... existing imports unchanged ...

function applyShell(node: any, layout: Layout, mapping: Record<string, any>): void {
  applyLayout(node, layout);
  applyFill(node, mapping.fill);
  if (!mapping.fill) {
    node.strokes = [{ type: 'SOLID', color: { r: 0.55, g: 0.55, b: 0.55 }, opacity: 0.5 }];
    node.strokeWeight = 1;
    if (Array.isArray(node.dashPattern) || node.dashPattern === undefined) node.dashPattern = [4, 4];
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
```

Remove the now-duplicated definitions of the helpers from `components.ts`.

- [ ] **Step 4: Run tests**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run
```

Expected: all existing tests pass (the refactor changes implementation location but not behavior).

- [ ] **Step 5: Typecheck and build**

```bash
npx tsc --noEmit
npm run build
```

Expected: both succeed.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/layout.ts src/main/apply/components.ts
git commit -m "refactor(apply): extract shared layout helpers into layout.ts"
```

---

## Task 10: Extract per-component shell function from components.ts

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components.ts`

The existing `applyComponents(ds, opts)` loops over `ds.components`. Extract the per-component logic into `applyComponentShell(comp, ds, opts, ctx)` so the v2 dispatcher can call it for v2 components without `variants`.

- [ ] **Step 1: Read components.ts to find the per-component loop**

```bash
grep -n "for (const comp of ds.components)" /Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components.ts
```

- [ ] **Step 2: Create the per-component function**

In `components.ts`, extract the body of the for-loop into:

```ts
export interface ShellApplyContext {
  page: any;
  setsByJsonName: Map<string, any>;
  placedIndex: { value: number };
  now: string;
}

export async function applyComponentShell(
  comp: Component,
  ds: DesignSystem,
  opts: ApplyOptions,
  ctx: ShellApplyContext,
  report: ApplyReport,
): Promise<void> {
  if (opts.selections?.components && opts.selections.components[comp.name] !== true) return;
  try {
    if (ctx.setsByJsonName.has(comp.name)) {
      updateComponentShell(ctx.setsByJsonName.get(comp.name), comp, ds);
      setLastSyncedAt(ctx.setsByJsonName.get(comp.name), ctx.now);
      report.applied++;
      return;
    }

    const variantCombos = enumerateVariants(comp.properties ?? []);
    const createdVariants: any[] = [];
    for (const combo of variantCombos) {
      const variantComp = (figma as any).createComponent();
      variantComp.name = variantNameFrom(comp.name, combo);
      applyShell(variantComp, comp.layout, comp.variantMappings?.[combo.key] ?? {});
      hydrateSlots(variantComp, comp, ds);
      ensureVisibleMasterSize(variantComp, comp);
      setJsonName(variantComp, comp.name); setJsonKind(variantComp, 'component');
      setSchemaVersion(variantComp, ds.version); setLastSyncedAt(variantComp, ctx.now);
      createdVariants.push(variantComp);
    }

    if (createdVariants.length === 0) {
      const onlyComp = (figma as any).createComponent();
      onlyComp.name = comp.name;
      applyShell(onlyComp, comp.layout, {});
      hydrateSlots(onlyComp, comp, ds);
      ensureVisibleMasterSize(onlyComp, comp);
      setJsonName(onlyComp, comp.name); setJsonKind(onlyComp, 'component');
      setSchemaVersion(onlyComp, ds.version); setLastSyncedAt(onlyComp, ctx.now);
      createdVariants.push(onlyComp);
    }

    const set = (figma as any).combineAsVariants(createdVariants, ctx.page);
    set.name = comp.name;
    setJsonName(set, comp.name); setJsonKind(set, 'component');
    setSchemaVersion(set, ds.version); setLastSyncedAt(set, ctx.now);

    const GRID_COLS = 4, GRID_CELL_W = 360, GRID_CELL_H = 280, GRID_GAP = 32;
    set.x = (ctx.placedIndex.value % GRID_COLS) * (GRID_CELL_W + GRID_GAP);
    set.y = Math.floor(ctx.placedIndex.value / GRID_COLS) * (GRID_CELL_H + GRID_GAP);
    ctx.placedIndex.value++;

    for (const p of comp.properties ?? []) {
      if (p.type === 'VARIANT') continue;
      if (p.type === 'INSTANCE_SWAP') continue;
      const figType = p.type === 'TEXT' ? 'TEXT' : 'BOOLEAN';
      set.addComponentProperty(p.name, figType, coerceDefault(p, figType));
    }

    report.applied++;
  } catch (e) {
    report.failed.push({ jsonName: comp.name, kind: 'component', reason: String(e) });
  }
}
```

- [ ] **Step 3: Refactor `applyComponents` to use the per-component function**

Replace the body of `applyComponents` to construct the context once and call `applyComponentShell` per component:

```ts
export async function applyComponents(ds: DesignSystem, opts: ApplyOptions = { allowOrphanDelete: {} }): Promise<ApplyReport> {
  const report: ApplyReport = { applied: 0, failed: [] };
  const now = new Date().toISOString();

  try { await (figma as any).loadFontAsync({ family: 'Inter', style: 'Regular' }); } catch { /* font load failures surface per slot */ }

  const page = (figma as any).currentPage;
  const existing: any[] = typeof (figma as any).getLocalComponents === 'function' ? (figma as any).getLocalComponents() : [];
  const setsByJsonName = new Map<string, any>();
  for (const c of existing) { const n = getJsonName(c); if (n) setsByJsonName.set(n, c); }

  const ctx: ShellApplyContext = { page, setsByJsonName, placedIndex: { value: 0 }, now };

  for (const comp of ds.components) {
    await applyComponentShell(comp, ds, opts, ctx, report);
  }
  return report;
}
```

- [ ] **Step 4: Run all tests**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run
```

Expected: all 50+ existing tests pass. Behavior is unchanged; only structure was refactored.

- [ ] **Step 5: Typecheck**

```bash
npx tsc --noEmit
```

Expected: exits 0.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/components.ts
git commit -m "refactor(apply): extract applyComponentShell per-component function"
```

---

## Task 11: Create components-v2.ts skeleton with applyColorBinding

**Files:**
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`
- Create: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/apply-components-v2.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { installFigmaMock, uninstallFigmaMock, type FigmaMock } from '../mocks/figma-mock.js';
import { applyColorBinding } from '../../src/main/apply/components-v2.js';
import { setJsonName, setJsonKind } from '../../src/main/identity.js';

let mock: FigmaMock;
beforeEach(() => { mock = installFigmaMock(); });
afterEach(() => { uninstallFigmaMock(); });

describe('applyColorBinding', () => {
  it('hex binding sets a SOLID fill', () => {
    const node: any = { fills: [], setBoundVariable: () => {} };
    applyColorBinding(node, 'fills', { hex: '#0D9488' });
    expect(node.fills.length).toBe(1);
    expect(node.fills[0].type).toBe('SOLID');
    expect(node.fills[0].color.r).toBeCloseTo(0x0D / 255, 3);
    expect(node.fills[0].color.g).toBeCloseTo(0x94 / 255, 3);
    expect(node.fills[0].color.b).toBeCloseTo(0x88 / 255, 3);
  });

  it('bind binding calls setBoundVariable when variable exists', () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(v, 'color/brand'); setJsonKind(v, 'variable');

    let calledField = '';
    let calledVar: any = null;
    const node: any = { fills: [], setBoundVariable: (field: string, variable: any) => { calledField = field; calledVar = variable; } };
    applyColorBinding(node, 'fills', { bind: 'color/brand' });
    expect(calledField).toBe('fills');
    expect(calledVar?.id).toBe(v.id);
  });

  it('bind binding falls back to placeholder fill when variable missing', () => {
    const node: any = { fills: [], setBoundVariable: () => {} };
    applyColorBinding(node, 'fills', { bind: 'color/missing' });
    expect(node.fills.length).toBe(1);
    expect(node.fills[0].opacity).toBeCloseTo(0.3, 2);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: FAIL with "Cannot find module" or similar.

- [ ] **Step 3: Create components-v2.ts skeleton**

Create `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`:

```ts
import type { ColorBinding, TextStyleBinding, WidgetNode, ComponentV2, DesignSystemV2 } from '../../shared/schema.js';
import { findVariableByJsonName, hexToRgb, applyLayout } from './layout.js';
import { getJsonName, setJsonName, setJsonKind, setSchemaVersion, setLastSyncedAt } from '../identity.js';
import type { ApplyReport, ApplyOptions } from './variables.js';

export function applyColorBinding(node: any, field: 'fills' | 'strokes', binding: ColorBinding): void {
  if ('bind' in binding) {
    const v = findVariableByJsonName(binding.bind);
    if (v && typeof node.setBoundVariable === 'function') {
      node.setBoundVariable(field, v);
      return;
    }
    node[field] = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 }, opacity: 0.3 }];
    return;
  }
  node[field] = [{ type: 'SOLID', color: hexToRgb(binding.hex), opacity: 1 }];
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 3/3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): applyColorBinding for bind and hex paths"
```

---

## Task 12: Implement applyTextStyleBinding

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`

- [ ] **Step 1: Append failing test**

Append to `tests/unit/apply-components-v2.test.ts`:

```ts
describe('applyTextStyleBinding', () => {
  it('finds local text style by jsonName and sets textStyleId', async () => {
    const ts = (figma as any).createTextStyle();
    setJsonName(ts, 'text/cta-label'); setJsonKind(ts, 'textStyle');

    const text: any = { textStyleId: '' };
    const { applyTextStyleBinding } = await import('../../src/main/apply/components-v2.js');
    applyTextStyleBinding(text, 'text/cta-label');
    expect(text.textStyleId).toBe(ts.id);
  });

  it('does nothing when text style not found', async () => {
    const text: any = { textStyleId: 'untouched' };
    const { applyTextStyleBinding } = await import('../../src/main/apply/components-v2.js');
    applyTextStyleBinding(text, 'text/missing');
    expect(text.textStyleId).toBe('untouched');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 2 new tests fail with "applyTextStyleBinding is not a function".

- [ ] **Step 3: Add applyTextStyleBinding to components-v2.ts**

Append to `src/main/apply/components-v2.ts`:

```ts
export function applyTextStyleBinding(text: any, jsonName: string): void {
  const styles: any[] = typeof (figma as any).getLocalTextStyles === 'function'
    ? (figma as any).getLocalTextStyles()
    : [];
  const ts = styles.find(s => getJsonName(s) === jsonName);
  if (ts) text.textStyleId = ts.id;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 5/5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): applyTextStyleBinding by jsonName lookup"
```

---

## Task 13: Implement walkTree for frame nodes

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`

- [ ] **Step 1: Append failing test**

Append:

```ts
describe('walkTree (frame)', () => {
  it('creates a frame with hex fill', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const node = await walkTree({
      type: 'frame',
      layout: { direction: 'NONE', sizing: { width: 'FIXED', widthValue: 100, height: 'FIXED', heightValue: 50 } },
      fill: { hex: '#0D9488' },
      children: [],
    });
    expect(node).toBeDefined();
    expect(mock.calls.some(c => c.op === 'createFrame')).toBe(true);
    expect(node.fills?.[0]?.type).toBe('SOLID');
  });

  it('creates a frame with bound stroke', async () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(v, 'color/brand'); setJsonKind(v, 'variable');

    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const node = await walkTree({
      type: 'frame',
      layout: { direction: 'NONE', sizing: { width: 'FIXED', widthValue: 100, height: 'FIXED', heightValue: 50 } },
      stroke: { bind: 'color/brand' },
      strokeWeight: 1.5,
      children: [],
    });
    expect(node.strokeWeight).toBe(1.5);
    expect(mock.calls.some(c => c.op === 'frame.setBoundVariable' && c.args[1] === 'strokes')).toBe(true);
  });

  it('recursively appends frame children', async () => {
    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const parent = await walkTree({
      type: 'frame',
      layout: { direction: 'VERTICAL', sizing: { width: 'HUG', height: 'HUG' } },
      children: [
        { type: 'frame', layout: { direction: 'NONE', sizing: { width: 'FIXED', widthValue: 10, height: 'FIXED', heightValue: 10 } }, children: [] },
      ],
    });
    expect(parent.children?.length).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 3 new tests fail (`walkTree is not a function`).

- [ ] **Step 3: Add walkTree (frame branch) to components-v2.ts**

Append:

```ts
export async function walkTree(node: WidgetNode): Promise<any> {
  if (node.type === 'frame') {
    const f = (figma as any).createFrame();
    applyLayout(f, node.layout);
    if (node.fill) applyColorBinding(f, 'fills', node.fill);
    if (node.stroke) {
      applyColorBinding(f, 'strokes', node.stroke);
      f.strokeWeight = node.strokeWeight ?? 1;
    }
    for (const child of node.children) {
      const c = await walkTree(child);
      f.appendChild(c);
    }
    return f;
  }
  // text branch added in next task
  throw new Error(`unknown WidgetNode type: ${(node as any).type}`);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 8/8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): walkTree handles frame nodes with fill, stroke, children"
```

---

## Task 14: Implement walkTree for text nodes

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`

- [ ] **Step 1: Append failing test**

Append:

```ts
describe('walkTree (text)', () => {
  it('creates a text node with characters and bound text style + color', async () => {
    const ts = (figma as any).createTextStyle();
    setJsonName(ts, 'text/cta-label'); setJsonKind(ts, 'textStyle');

    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/ink-inverse', coll, 'COLOR');
    setJsonName(v, 'color/ink-inverse'); setJsonKind(v, 'variable');

    const { walkTree } = await import('../../src/main/apply/components-v2.js');
    const text = await walkTree({
      type: 'text',
      value: 'Continue',
      style: { bind: 'text/cta-label' },
      color: { bind: 'color/ink-inverse' },
    });
    expect(text.characters).toBe('Continue');
    expect(text.textStyleId).toBe(ts.id);
    expect(mock.calls.some(c => c.op === 'loadFontAsync')).toBe(true);
    const fontIdx = mock.calls.findIndex(c => c.op === 'loadFontAsync');
    const textIdx = mock.calls.findIndex(c => c.op === 'createText');
    expect(textIdx).toBeGreaterThan(fontIdx);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: new test fails with `unknown WidgetNode type: text`.

- [ ] **Step 3: Add the text branch to walkTree**

Modify `walkTree` in `components-v2.ts` to handle `text`:

```ts
export async function walkTree(node: WidgetNode): Promise<any> {
  if (node.type === 'frame') {
    // ... existing frame branch ...
  }
  if (node.type === 'text') {
    await (figma as any).loadFontAsync({ family: 'Inter', style: 'Regular' });
    const t = (figma as any).createText();
    t.characters = node.value;
    if (node.style && 'bind' in node.style) applyTextStyleBinding(t, node.style.bind);
    applyColorBinding(t, 'fills', node.color);
    return t;
  }
  throw new Error(`unknown WidgetNode type: ${(node as any).type}`);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 9/9 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): walkTree handles text nodes with style and color binding"
```

---

## Task 15: Implement applyComponentV2 orchestrator

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/components-v2.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-components-v2.test.ts`

- [ ] **Step 1: Append failing test for variant set creation**

Append to `tests/unit/apply-components-v2.test.ts`:

```ts
describe('applyComponentV2', () => {
  it('creates a ComponentSet with one master per variant', async () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(v, 'color/brand'); setJsonKind(v, 'variable');
    const ts = (figma as any).createTextStyle();
    setJsonName(ts, 'text/cta-label'); setJsonKind(ts, 'textStyle');

    const { applyComponentV2 } = await import('../../src/main/apply/components-v2.js');

    const comp: any = {
      name: 'PrimaryButton',
      tier: 'atom',
      layout: { direction: 'HORIZONTAL', alignItems: 'CENTER', justify: 'CENTER',
                sizing: { width: 'FIXED', widthValue: 280, height: 'FIXED', heightValue: 60 } },
      properties: [],
      variantProperties: [{ name: 'destructive', type: 'BOOLEAN' }],
      variants: [
        {
          key: 'destructive=false',
          properties: { destructive: 'false' },
          tree: {
            type: 'frame',
            layout: { direction: 'HORIZONTAL', alignItems: 'CENTER', justify: 'CENTER',
                      sizing: { width: 'FIXED', widthValue: 280, height: 'FIXED', heightValue: 60 } },
            fill: { bind: 'color/brand' },
            children: [{ type: 'text', value: 'Continue', style: { bind: 'text/cta-label' }, color: { hex: '#FFFFFF' } }],
          },
        },
        {
          key: 'destructive=true',
          properties: { destructive: 'true' },
          tree: {
            type: 'frame',
            layout: { direction: 'HORIZONTAL', alignItems: 'CENTER', justify: 'CENTER',
                      sizing: { width: 'FIXED', widthValue: 280, height: 'FIXED', heightValue: 60 } },
            fill: { hex: '#DC2626' },
            children: [{ type: 'text', value: 'Continue', style: { bind: 'text/cta-label' }, color: { hex: '#FFFFFF' } }],
          },
        },
      ],
    };

    const ds: any = { version: '2.0.0', source: { stack: 'flutter', extractedAt: '2026-04-28T00:00:00Z' },
                      collections: [], variables: [], components: [comp] };
    const report = { applied: 0, failed: [] };
    const ctx = { page: (figma as any).currentPage, setsByJsonName: new Map(), placedIndex: { value: 0 }, now: '2026-04-28T00:00:00Z' };

    await applyComponentV2(comp, ds, { allowOrphanDelete: {} }, ctx, report);
    expect(report.failed).toEqual([]);
    expect(report.applied).toBe(1);
    const components = (figma as any).getLocalComponents();
    expect(components.length).toBe(2);
    expect(components[0].name).toBe('destructive=false');
    expect(components[1].name).toBe('destructive=true');
    expect(mock.calls.some(c => c.op === 'combineAsVariants')).toBe(true);
  });

  it('places the master ComponentSet at a grid position', async () => {
    const coll = (figma as any).variables.createVariableCollection('primitives');
    const v = (figma as any).variables.createVariable('color/brand', coll, 'COLOR');
    setJsonName(v, 'color/brand'); setJsonKind(v, 'variable');
    const ts = (figma as any).createTextStyle();
    setJsonName(ts, 'text/cta-label'); setJsonKind(ts, 'textStyle');

    const { applyComponentV2 } = await import('../../src/main/apply/components-v2.js');

    const baseTree = {
      type: 'frame' as const,
      layout: { direction: 'NONE' as const, sizing: { width: 'FIXED' as const, widthValue: 100, height: 'FIXED' as const, heightValue: 100 } },
      fill: { hex: '#000000' },
      children: [],
    };

    const ctx = { page: (figma as any).currentPage, setsByJsonName: new Map(), placedIndex: { value: 0 }, now: '2026-04-28T00:00:00Z' };
    const ds: any = { version: '2.0.0', source: { stack: 'flutter', extractedAt: '' }, collections: [], variables: [], components: [] };

    const compA: any = { name: 'A', tier: 'atom', layout: baseTree.layout, properties: [],
                         variants: [{ key: 'k=v', properties: { k: 'v' }, tree: baseTree }] };
    const compB: any = { ...compA, name: 'B' };
    const reportA = { applied: 0, failed: [] };
    const reportB = { applied: 0, failed: [] };
    await applyComponentV2(compA, ds, { allowOrphanDelete: {} }, ctx, reportA);
    await applyComponentV2(compB, ds, { allowOrphanDelete: {} }, ctx, reportB);

    const sets = (figma as any).currentPage.children;
    expect(sets.length).toBe(2);
    expect(sets[0].x).toBe(0);
    expect(sets[1].x).toBe(360 + 32);
    expect(sets[1].y).toBe(0);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: new tests fail (`applyComponentV2 is not a function`).

- [ ] **Step 3: Implement applyComponentV2**

Append to `src/main/apply/components-v2.ts`:

```ts
export interface V2ApplyContext {
  page: any;
  setsByJsonName: Map<string, any>;
  placedIndex: { value: number };
  now: string;
}

export async function applyComponentV2(
  comp: ComponentV2,
  ds: DesignSystemV2,
  opts: ApplyOptions,
  ctx: V2ApplyContext,
  report: ApplyReport,
): Promise<void> {
  if (opts.selections?.components && opts.selections.components[comp.name] !== true) return;
  if (!comp.variants || comp.variants.length === 0) {
    report.failed.push({ jsonName: comp.name, kind: 'component', reason: 'applyComponentV2 called on component without variants' });
    return;
  }
  try {
    const masters: any[] = [];
    for (const variant of comp.variants) {
      const m = (figma as any).createComponent();
      m.name = variant.key;
      const built = await walkTree(variant.tree);
      // Move children of built into m, copy layout. Simpler: append built as a child.
      m.appendChild(built);
      setJsonName(m, comp.name); setJsonKind(m, 'component');
      setSchemaVersion(m, ds.version); setLastSyncedAt(m, ctx.now);
      masters.push(m);
    }
    const set = (figma as any).combineAsVariants(masters, ctx.page);
    set.name = comp.name;
    setJsonName(set, comp.name); setJsonKind(set, 'component');
    setSchemaVersion(set, ds.version); setLastSyncedAt(set, ctx.now);

    const GRID_COLS = 4, GRID_CELL_W = 360, GRID_CELL_H = 280, GRID_GAP = 32;
    set.x = (ctx.placedIndex.value % GRID_COLS) * (GRID_CELL_W + GRID_GAP);
    set.y = Math.floor(ctx.placedIndex.value / GRID_COLS) * (GRID_CELL_H + GRID_GAP);
    ctx.placedIndex.value++;

    report.applied++;
  } catch (e) {
    report.failed.push({ jsonName: comp.name, kind: 'component', reason: String(e) });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npx vitest run tests/unit/apply-components-v2.test.ts
```

Expected: 11/11 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/main/apply/components-v2.ts tests/unit/apply-components-v2.test.ts
git commit -m "feat(apply-v2): applyComponentV2 builds ComponentSet with one master per variant"
```

---

## Task 16: Wire v2 dispatch into apply/index.ts

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/index.ts`
- Modify: `/Users/markus/Dev/extract-design-system-figma-plugin/tests/unit/apply-orchestrator.test.ts`

- [ ] **Step 1: Append failing dispatcher test**

Append to `tests/unit/apply-orchestrator.test.ts`:

```ts
describe('applyAll v2 dispatch', () => {
  it('routes v2 components with variants through applyComponentV2', async () => {
    const ts = (figma as any).createTextStyle();
    const { setJsonName: sN, setJsonKind: sK } = await import('../../src/main/identity.js');
    sN(ts, 'text/cta-label'); sK(ts, 'textStyle');

    const ds: any = {
      version: '2.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-28T00:00:00Z' },
      collections: [{ name: 'primitives', modes: ['default'], defaultMode: 'default' }],
      variables: [{ name: 'color/brand', collection: 'primitives', type: 'color', valuesByMode: { default: '#0D9488' } }],
      textStyles: [{ name: 'text/cta-label', fontFamily: 'Outfit', fontWeight: 600, fontSize: 20 }],
      components: [{
        name: 'PrimaryButton',
        tier: 'atom',
        layout: { direction: 'HORIZONTAL', sizing: { width: 'FIXED', widthValue: 280, height: 'FIXED', heightValue: 60 } },
        properties: [],
        variantProperties: [{ name: 'destructive', type: 'BOOLEAN' }],
        variants: [
          {
            key: 'destructive=false',
            properties: { destructive: 'false' },
            tree: {
              type: 'frame',
              layout: { direction: 'HORIZONTAL', alignItems: 'CENTER', justify: 'CENTER',
                        sizing: { width: 'FIXED', widthValue: 280, height: 'FIXED', heightValue: 60 } },
              fill: { bind: 'color/brand' },
              children: [{ type: 'text', value: 'Continue', style: { bind: 'text/cta-label' }, color: { hex: '#FFFFFF' } }],
            },
          },
        ],
      }],
    };

    await applyAll(ds, { allowOrphanDelete: {} }, () => {});
    const components = (figma as any).getLocalComponents();
    expect(components.length).toBe(1);
    expect(components[0].name).toBe('destructive=false');
  });

  it('routes v2 components without variants through shell path', async () => {
    const ds: any = {
      version: '2.0.0',
      source: { stack: 'flutter', extractedAt: '2026-04-28T00:00:00Z' },
      collections: [],
      variables: [],
      components: [{
        name: 'BasicShell',
        tier: 'atom',
        layout: { direction: 'NONE', sizing: { width: 'HUG', height: 'HUG' } },
        properties: [],
      }],
    };
    const report = await applyAll(ds, { allowOrphanDelete: {} }, () => {});
    expect(report.failed).toEqual([]);
    // shell components produce a name label inside; v2 components with variants do not.
    const labels = mock.calls.filter(c => c.op === 'createText');
    expect(labels.length).toBeGreaterThanOrEqual(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run tests/unit/apply-orchestrator.test.ts
```

Expected: new tests fail because the dispatcher does not yet route v2 components through the v2 pipeline.

- [ ] **Step 3: Update apply/index.ts to dispatch on version**

Read existing `src/main/apply/index.ts`:

```bash
cat /Users/markus/Dev/extract-design-system-figma-plugin/src/main/apply/index.ts
```

Replace with:

```ts
import type { DesignSystem } from '../../shared/schema.js';
import type { DesignSystemV2, ComponentV2 } from '../../shared/schema.js';
import { applyVariables, type ApplyReport, type ApplyOptions } from './variables.js';
import { applyTextStyles } from './text-styles.js';
import { applyEffects } from './effects.js';
import { applyComponents, applyComponentShell, type ShellApplyContext } from './components.js';
import { applyComponentV2, type V2ApplyContext } from './components-v2.js';
import { setFileFlag, getJsonName } from '../identity.js';

export type ProgressCb = (p: { currentKind: string; applied: number; total: number }) => void;

export async function applyAll(
  ds: DesignSystem | DesignSystemV2,
  opts: ApplyOptions,
  onProgress: ProgressCb,
): Promise<ApplyReport> {
  const total = (
    ds.collections.length + ds.variables.length +
    (ds.textStyles?.length ?? 0) + (ds.effects?.length ?? 0) +
    ds.components.length
  ) || 1;
  const combined: ApplyReport = { applied: 0, failed: [] };
  const now = new Date().toISOString();

  const r1 = applyVariables(ds as any, opts);
  combined.applied += r1.applied; combined.failed.push(...r1.failed);
  onProgress({ currentKind: 'variables', applied: combined.applied, total });

  const r2 = await applyTextStyles(ds as any, opts);
  combined.applied += r2.applied; combined.failed.push(...r2.failed);
  onProgress({ currentKind: 'textStyles', applied: combined.applied, total });

  const r3 = applyEffects(ds as any, opts);
  combined.applied += r3.applied; combined.failed.push(...r3.failed);
  onProgress({ currentKind: 'effects', applied: combined.applied, total });

  if (ds.version === '2.0.0') {
    try { await (figma as any).loadFontAsync({ family: 'Inter', style: 'Regular' }); } catch { /* surface per slot */ }

    const page = (figma as any).currentPage;
    const existing: any[] = typeof (figma as any).getLocalComponents === 'function' ? (figma as any).getLocalComponents() : [];
    const setsByJsonName = new Map<string, any>();
    for (const c of existing) { const n = getJsonName(c); if (n) setsByJsonName.set(n, c); }
    const placedIndex = { value: 0 };

    const shellCtx: ShellApplyContext = { page, setsByJsonName, placedIndex, now };
    const v2Ctx: V2ApplyContext = { page, setsByJsonName, placedIndex, now };

    for (const comp of ds.components as ComponentV2[]) {
      if (comp.variants && comp.variants.length > 0) {
        await applyComponentV2(comp, ds as DesignSystemV2, opts, v2Ctx, combined);
      } else {
        await applyComponentShell(comp, ds as any, opts, shellCtx, combined);
      }
    }
  } else {
    const r4 = await applyComponents(ds as any, opts);
    combined.applied += r4.applied; combined.failed.push(...r4.failed);
  }
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

- [ ] **Step 4: Run all tests**

```bash
npx vitest run
```

Expected: all existing tests pass + new dispatcher tests pass.

- [ ] **Step 5: Typecheck and build**

```bash
npx tsc --noEmit
npm run build
```

Expected: both succeed.

- [ ] **Step 6: Commit**

```bash
git add src/main/apply/index.ts tests/unit/apply-orchestrator.test.ts
git commit -m "feat(apply): dispatch v2 components through applyComponentV2"
```

---

## Task 17: Update flutter-extraction.md with theme accessor map

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/references/flutter-extraction.md`

- [ ] **Step 1: Read existing flutter-extraction.md**

```bash
cat /Users/markus/Dev/extract-design-system/references/flutter-extraction.md
```

- [ ] **Step 2: Append v2 section on theme resolution**

Append at the end of the file:

```markdown

## v2: Theme accessor resolution

Before extracting any component widget tree, build a **theme accessor map** by reading every file under `lib/theme/` (or the paths listed in `sources.tokens`). The map associates each unique accessor chain (e.g. `t.cta.background`, `AppText.bodyStrong`, `AppRadius.pill`, `AppSpacing.cardPad`) with the corresponding variable jsonName from the v2 design system, or with a literal `{ hex: "..." }` if the chain terminates in a hardcoded `Color(0xFF...)`.

Example map for an earnapp-style codebase:

```
t.cta.background      → color/brand           (via EarnWiseTheme.cta.background = palette.brand)
t.cta.foreground      → color/ink-inverse     (via EarnWiseTheme.cta.foreground = palette.inkInverse)
t.radii.button        → radius/pill           (via EarnWiseTheme.radii.button = AppRadius.pill)
t.palette.ink         → color/ink
t.palette.inkInverse  → color/ink-inverse
t.palette.brand       → color/brand
AppText.ctaLabel      → text/cta-label
AppText.bodyStrong    → text/body-strong
AppSpacing.cardPad    → space/card-pad
kDestructiveRed       → { hex: "#DC2626" }
```

When extracting a component:

- Each theme accessor encountered in the widget tree is resolved through this map and emitted as `{ "bind": "<jsonName>" }`
- A hardcoded `Color(0xFFRRGGBB)` is emitted as `{ "hex": "#RRGGBB" }` (alpha ignored unless not 0xFF)
- If a theme accessor cannot be resolved (chain ambiguous, accessor not present in map), the component falls back to v1 shell extraction (no `variants` field; emit only the v1-shaped fields)
```

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/extract-design-system
git add references/flutter-extraction.md
git commit -m "docs(extract): v2 theme accessor map section"
```

---

## Task 18: Update flutter-extraction.md with variant enumeration rules

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/references/flutter-extraction.md`

- [ ] **Step 1: Append section**

Append:

```markdown

## v2: Variant enumeration

For each top-level Widget class, identify variant-driving properties from the constructor:

- `bool` parameters where the value affects branches in `build()`
- `String` or `enum` parameters with a small fixed set of values used in switches/conditions
- Skip `Widget`, `IconData`, `VoidCallback`, and other Widget-typed parameters: those are per-instance overrides, not variants

Cap the cartesian product at **8 variants**. Beyond 8, the component falls back to v1 shell extraction (or requires explicit annotation, which is not in scope for Phase 1).

For each combination of variant-driving property values:

1. Mentally evaluate `build()` with those values fixed
2. Walk the resulting widget tree (see next section)
3. Emit a `variant` entry with:
   - `key`: comma-separated `name=value` pairs (e.g. `"destructive=true,outlined=false"`)
   - `properties`: the same values as a `Record<string, string>`
   - `tree`: the WidgetNode produced by walking

Also emit `variantProperties` at the component level: one entry per variant-driving property, with `type: "BOOLEAN"` or `type: "VARIANT"` and (for VARIANT) the list of options.

Example for `PrimaryButton`:

```
constructor: PrimaryButton({ String label, VoidCallback? onTap, bool destructive=false, IconData? leadingIcon, IconData? trailingIcon, bool outlined=false, HapticIntensity haptic=confirm })
```

Variant-driving: `destructive: bool`, `outlined: bool`. Skip: `label` (TEXT property), `onTap` (callback), `leadingIcon`/`trailingIcon` (Widget-typed), `haptic` (enum but does not affect visual rest state).

Result: 4 variants (`destructive=false,outlined=false`, etc.), each with its own widget tree.
```

- [ ] **Step 2: Commit**

```bash
git add references/flutter-extraction.md
git commit -m "docs(extract): v2 variant enumeration rules"
```

---

## Task 19: Update flutter-extraction.md with widget tree walking rules

**Files:**
- Modify: `/Users/markus/Dev/extract-design-system/references/flutter-extraction.md`

- [ ] **Step 1: Append section**

Append:

```markdown

## v2: Widget tree walking

When evaluating `build()` for a specific variant, walk the resulting widget tree and emit `WidgetNode` entries. Each Flutter widget falls into one of four categories:

| Category | Examples | Action |
|---|---|---|
| **Passthrough** | `PressScale`, `Opacity`, `IgnorePointer`, `AnimatedOpacity`, `AnimatedContainer`, `GestureDetector`, `MouseRegion`, `FocusableActionDetector`, `Tooltip`, `Builder`, `LayoutBuilder` | Walk to the single child; emit nothing for the wrapper itself |
| **Structural** | `Container` (with `BoxDecoration`), `Padding`, `Row`, `Column`, `SizedBox` (used as gap or spacer is collapsed into parent gap; standalone fixed-size SizedBox emits a frame), `Stack`, `Expanded`, `Flexible` | Emit `frame` node with corresponding `Layout` |
| **Leaf (Phase 1)** | `Text` | Emit `text` node |
| **Leaf (Phase 2+)** | `Icon`, `Image.asset`, `SvgPicture`, `CustomPaint`, `RepaintBoundary` of a custom subtree | Component falls back to v1 shell extraction in Phase 1 |

If any descendant of a component's `build()` is a Phase 2 leaf, the **entire component degrades** to v1 shell extraction (omit the `variants` field; emit only v1-shaped fields).

### Building the WidgetNode

For a structural widget producing a `frame`:

- `direction`: `HORIZONTAL` for `Row`, `VERTICAL` for `Column`, `NONE` for `Container` / `Padding` / `SizedBox` / `Stack`
- `padding`: from `Container.padding` or `Padding.padding`. `EdgeInsets.symmetric(horizontal: H, vertical: V)` produces `{ top: V, right: H, bottom: V, left: H }`
- `gap`: from `mainAxisAlignment` + `SizedBox` siblings, or `Wrap.spacing`. `Row` with explicit `SizedBox(width: N)` between children: collapse the `SizedBox` and set `gap: N` on the parent
- `alignItems`: from `crossAxisAlignment` (`start` → `MIN`, `center` → `CENTER`, `end` → `MAX`, `stretch` → `MAX`, `baseline` → `BASELINE`)
- `justify`: from `mainAxisAlignment` (`start` → `MIN`, `center` → `CENTER`, `end` → `MAX`, `spaceBetween` → `SPACE_BETWEEN`)
- `sizing.width`: `FIXED` if `width: N` is set explicitly, `FILL` if `Expanded`/`Flexible(fit: tight)` wraps, otherwise `HUG`
- `sizing.height`: same rule with `height`
- `radius`: from `BorderRadius.circular(N)` or `BorderRadius.all(Radius.circular(N))`. If the radius is a theme accessor (`t.radii.button`), emit as `{ "bind": "<jsonName>" }`
- `fill`: from `BoxDecoration.color` (or `Container.color` directly). Resolve via the theme accessor map. Hardcoded `Color(0xFF...)` becomes `{ "hex": "..." }`
- `stroke`: from `BoxDecoration.border`. `Border.all(color: X, width: W)` produces `stroke: <X resolved>` and `strokeWeight: W`

For a `Text` leaf:

- `value`: the literal first positional argument if it is a string literal; otherwise the parameter name (e.g. `label` → emit the parameter's default if known, else the parameter name in quotes as a placeholder)
- `style`: `{ "bind": "<jsonName>" }`. The text style accessor (e.g. `AppText.ctaLabel`) is resolved via the theme accessor map
- `color`: from `style.copyWith(color: X)`. Resolve via the theme accessor map; hardcoded color becomes `{ "hex": "..." }`. If the parameter cannot be resolved, the component degrades

If walking encounters a Phase 2 leaf or fails to resolve any binding, the component degrades to v1 shell.
```

- [ ] **Step 2: Commit**

```bash
git add references/flutter-extraction.md
git commit -m "docs(extract): v2 widget tree walking rules and category table"
```

---

## Task 20: Run extractor on earnapp Flutter source to produce v2 design-system.json

**Files:**
- Modify: `/Users/markus/Dev/earnapp_handover/design-system.json` (or wherever the extractor's `config.output.path` points)

This task uses the extract-design-system skill itself: the user (or the implementer) invokes `/extract-design-system` and the skill produces v2 JSON for the earnapp Flutter codebase.

- [ ] **Step 1: Run the extractor**

The extractor is a skill, not a CLI command from this plan. Run it via Claude Code:

```
/extract-design-system
```

When the skill prompts, confirm the working directory is `/Users/markus/Dev/earnapp/flutter_app/` (or whichever path the user's `.design-system.config.yaml` specifies).

The skill should:
- Build the theme accessor map from `lib/theme/`
- For each component, attempt v2 extraction (variants + widget trees)
- For PrimaryButton specifically, produce 4 variants with full token bindings
- For the other 27 components, fall back to v1 shape (no `variants` field)
- Emit `design-system.json` with `version: "2.0.0"`

- [ ] **Step 2: Verify the output**

```bash
cat /Users/markus/Dev/earnapp_handover/design-system.json | jq '.version'
```

Expected: `"2.0.0"`.

```bash
cat /Users/markus/Dev/earnapp_handover/design-system.json | jq '.components[] | select(.name == "PrimaryButton") | .variants | length'
```

Expected: `4`.

```bash
cat /Users/markus/Dev/earnapp_handover/design-system.json | jq '.components | map(select(.variants)) | length'
```

Expected: `1` (only PrimaryButton has variants in Phase 1).

- [ ] **Step 3: Validate**

```bash
cd /Users/markus/Dev/extract-design-system/lib
cat /Users/markus/Dev/earnapp_handover/design-system.json | npx tsx src/cli.ts validate
```

Expected: `{ "ok": true, "errors": [], "version": "2.0.0" }`.

If validation fails, fix the extractor output (the skill iterates, refining until validate passes). Do not commit a partial file.

---

## Task 21: Manual smoke test in Figma

**Files:**
- (none modified)

- [ ] **Step 1: Build the plugin**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npm run build
```

Expected: exits 0; `build/code.js` and `build/ui.html` updated.

- [ ] **Step 2: Reload the plugin in Figma desktop**

In Figma: **Plugins → Development → Manage plugins in development → Reload `Design System Sync`**.

- [ ] **Step 3: Run the plugin against a fresh Figma file**

Open a brand new empty Figma file (so no v1 components are around). Run **Plugins → Development → Design System Sync**. When the LoadScreen appears, pick `/Users/markus/Dev/earnapp_handover/design-system.json`.

Walk through:
- LoadScreen accepts the v2 JSON without error
- Adoption screen appears (file is fresh: no proposed matches; click Continue)
- Diff screen shows all entities as Added (60+ variables, 15 text styles, 3 effects, 28 components)
- Click **Apply N changes**

- [ ] **Step 4: Verify results**

After Apply completes (no Failed rows except known v1-shell components):
- Open Figma's Variables panel: 60+ variables present, named as expected
- Open Local Styles panel: 15 text styles + 3 effect styles
- On the canvas, find the PrimaryButton ComponentSet
- Click into the set: 4 component variants exist, named `destructive=false,outlined=false`, `destructive=false,outlined=true`, `destructive=true,outlined=false`, `destructive=true,outlined=true`
- Right panel shows two BOOLEAN variant properties: Destructive, Outlined
- Drag a PrimaryButton instance onto the canvas. Switch the Destructive toggle: fill changes from teal (`color/brand`) to red (`#DC2626`). Switch Outlined: fill becomes transparent, stroke appears in matching color
- In the Variables panel, change `color/brand` value (e.g. to `#FF00FF`). The `destructive=false,outlined=false` and `destructive=false,outlined=true` variants update live; the destructive variants stay red (intended: literal hex)

- [ ] **Step 5: Re-run idempotency**

Re-run the plugin against the same JSON. Diff screen should show "No changes to apply" (or near-zero diff). Apply. The PrimaryButton ComponentSet is preserved at its position; variants are rebuilt but visually identical.

- [ ] **Step 6: Verify v1 fallback for other components**

The other 27 components should appear as before: v1 dashed-shell rectangles with name labels. They are not regressed by the v2 path.

If all checks pass, Phase 1 is a success. Document any deviations as v0.2.0 candidates.

---

## Task 22: Final verification

- [ ] **Step 1: Run full plugin test suite**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npx vitest run
```

Expected: all tests pass (existing 50+ plus new v2 tests; total ~60).

- [ ] **Step 2: Run extract-design-system CLI tests**

```bash
cd /Users/markus/Dev/extract-design-system/lib
npx vitest run
```

Expected: all tests pass.

- [ ] **Step 3: Typecheck both repos**

```bash
cd /Users/markus/Dev/extract-design-system/lib && npx tsc --noEmit
cd /Users/markus/Dev/extract-design-system-figma-plugin && npx tsc --noEmit
```

Expected: both exit 0.

- [ ] **Step 4: Build the plugin**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
npm run build
```

Expected: exits 0; both artifacts non-empty.

- [ ] **Step 5: Tag**

```bash
cd /Users/markus/Dev/extract-design-system-figma-plugin
git tag v0.2.0-phase1
```

```bash
cd /Users/markus/Dev/extract-design-system
git tag v0.2.0-phase1
```

---

## Notes for the implementer

- **Schema files are duplicated across repos.** `schema.v2.json` lives in both `extract-design-system/references/` and the plugin root. This duplication is deliberate (the plugin needs the schema bundled at build time without depending on the skill's directory). Keep them in sync; if you update one, copy to the other in the same commit.

- **The shell pipeline is preserved.** v2 components without `variants` go through `applyComponentShell`. Existing v1 sync flows for tokens, text styles, effects, and components are untouched. If a regression appears in any of those, the dispatcher in `apply/index.ts` is the most likely culprit.

- **`combineAsVariants` requires variant masters with parsed names.** The variant `key` (e.g. `"destructive=false,outlined=false"`) is the master's `name`. Figma parses this on `combineAsVariants` to build the variant property panel. Do not change the format.

- **`applyColorBinding` falls back to a placeholder gray fill** when a `bind` reference cannot be resolved. This is intentional: the variable is supposed to exist (variables are written before components) but if it does not, the master is still visible and the failure is debuggable.

- **`walkTree` is async** because text nodes require `loadFontAsync`. Frame children must be awaited in order. Do not parallelize via `Promise.all` without verifying Figma's plugin API is safe for concurrent node creation.

- **Theme accessor map is the trickiest part of the extractor.** If a component degrades to v1 shell because a theme accessor cannot be resolved, that is a soft failure (component still extracts as a shell). The skill should log which accessors fail so the user can extend the map manually if needed.

- **Phase 2 (icons) and Phase 3 (instance refs) reuse this scaffolding.** The `WidgetNode` discriminated union has reserved tokens for `image`, `svg`, and `instance`; adding them in subsequent phases is purely additive to the schema and the walker.
