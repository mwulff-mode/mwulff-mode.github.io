# v2 Design System Sync: Phase 1: PrimaryButton end-to-end

## Problem

The shipped v1 plugin (`extract-design-system-figma-plugin` v0.1.0) syncs tokens, text styles, and effects from a Flutter codebase into Figma faithfully, but produces only **layout shells** for components: a frame with the outer container's padding/sizing/radius and a name label. Real component visuals (button fills, borders, text content, internal layout decomposition) are missing because the v1 schema captures only the outermost layout primitive of each component, not its widget tree.

The user's stated goal is to rebuild every component (and eventually every screen) in Figma with full visual fidelity, using real assets where the code uses real assets, and exposing component variants (e.g. `BalanceCard` empty / default / cash-out) as Figma ComponentSet variants the designer can switch via the right panel.

This spec describes Phase 1 of that rebuild: a one-component proof targeting `PrimaryButton`. Success in Phase 1 validates the schema, extractor, and plugin architecture before funding the full multi-component rebuild.

## Scope

**In scope:**

- Schema v2 design (additive superset of v1, version-discriminated)
- Extractor reference doc and CLI changes to emit v2 JSON
- Plugin changes to consume v2 JSON
- One concrete component (`PrimaryButton`) with 4 variants extracted and applied end-to-end
- Token bindings: color, text style, radius, on a real component
- Backwards compatibility: existing v1 JSON files continue to work; v2 JSON files with mostly-v1-shaped components also work

**Out of scope:**

- Icons (`IconData`, `Image.asset`, `SvgPicture`): Phase 2
- Cross-component instance references (one component instancing another): Phase 3
- Animations / `CustomPaint`: never; passthrough widgets like `PressScale` are walked through to their static rest-state child
- All other 27 components in the design system: they remain v1 shells in this phase
- Two-way sync (Figma → code)

## Goals

1. **Schema v2 ships** in both `extract-design-system` (CLI + reference doc) and the plugin (`src/shared/schema.ts` + validator)
2. **Extractor emits a valid v2 design-system.json** for the earnapp Flutter source where PrimaryButton has full `variantProperties` + `variants` + rich widget trees, and all other components retain their v1 shape
3. **Plugin applies the v2 JSON** producing a Figma ComponentSet for PrimaryButton with 4 selectable variants, each visually correct (filled / outlined / destructive / destructive-outlined)
4. **Tokens bind round-trip**: changing `color/brand` value in Figma updates all variants that bind to it via `setBoundVariable`
5. **Existing v1 sync flows are not broken**: tokens, text styles, effects, shell components all continue to work as they do today

## Non-Goals

- Pixel-exact visual match: Flutter and Figma rasterize text differently. "Visually equivalent at the rest state" is the bar
- Diff smartness on re-apply: v2 components are removed-and-rebuilt on each apply; idempotency is preserved (same result on re-run) but partial-update is not
- Storage optimization: variants emit full trees with structural redundancy; that's fine for the proof
- Auto-detection of new variant types beyond BOOLEAN; VARIANT/enum-typed properties are supported but no other types are added

## Architecture

### Boundaries

The work crosses 5 well-separated boundaries:

1. **Schema definition**: `references/schema.v2.json` (new) and `lib/src/schema.ts` types in extract-design-system; `src/shared/schema.ts` types in the plugin
2. **Extractor reference doc**: `references/flutter-extraction.md` updated with v2 instructions
3. **Extractor CLI**: `lib/src/validate.ts` dispatches on version
4. **Plugin validate**: `src/shared/validate.ts` dispatches on version
5. **Plugin apply pipeline**: new `src/main/apply/components-v2.ts`; `src/main/apply/index.ts` dispatches on version

Each boundary has one responsibility and a clean interface. The schema files are the contract; everything else consumes it.

### Data flow

```
flutter source code
  ↓ (extract-design-system skill: LLM + CLI)
design-system.json (v2.0.0)
  ↓ (LoadScreen → validate → DiffScreen → ApplyScreen)
Plugin apply
  ↓ (per-component dispatch: rich tree if variants present, else v1 shell)
Figma file (variables + text styles + effects + shell components + PrimaryButton ComponentSet)
```

## Schema v2

### Design

v2 is a strict additive superset of v1's component shape: existing fields (`name`, `tier`, `description`, `layout`, `properties`, `variantMappings`, `slots`, `responsive`) remain valid. v2 adds two optional fields on `Component`:

```ts
interface ComponentV2 extends Component {
  variantProperties?: { name: string; type: 'BOOLEAN' | 'VARIANT'; options?: string[] }[];
  variants?: { key: string; properties: Record<string, string>; tree: WidgetNode }[];
}
```

A component with `variants` is rendered via the rich-tree path. A component without `variants` falls back to the v1 shell path.

The top-level `DesignSystem` object becomes a discriminated union by `version`:

```ts
interface DesignSystemV1 { version: '1.0.0'; ... }
interface DesignSystemV2 { version: '2.0.0'; components: ComponentV2[]; ... }
type DesignSystem = DesignSystemV1 | DesignSystemV2;
```

### WidgetNode

Phase 1 supports two node types; the union is open so Phase 2/3 add `image`, `svg`, `instance` without schema break:

```ts
type WidgetNode =
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

type ColorBinding = { bind: string } | { hex: string };
type TextStyleBinding = { bind: string };
```

`ColorBinding` distinguishes variable-bound colors (`{ bind: "color/brand" }`) from intentional literals (`{ hex: "#DC2626" }`). `TextStyleBinding` always binds: text styles are a complete unit; we do not emit inline literal text styles in v2.

### PrimaryButton example

The full v2 entry for PrimaryButton (showing the filled variant in detail; the other three variants follow the same skeleton with different fill / stroke / text color):

```json
{
  "name": "PrimaryButton",
  "tier": "atom",
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
          "direction": "HORIZONTAL",
          "alignItems": "CENTER",
          "justify": "CENTER",
          "sizing": { "width": "FILL", "height": "FIXED", "heightValue": 60 },
          "radius": { "bind": "radius/pill" }
        },
        "fill": { "bind": "color/brand" },
        "children": [
          {
            "type": "text",
            "value": "Continue",
            "style": { "bind": "text/cta-label" },
            "color": { "bind": "color/ink-inverse" }
          }
        ]
      }
    },
    {
      "key": "destructive=false,outlined=true",
      "properties": { "destructive": "false", "outlined": "true" },
      "tree": { "type": "frame", "layout": {...}, "stroke": { "bind": "color/brand" }, "strokeWeight": 1.5, "children": [{ "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "bind": "color/brand" } }] }
    },
    {
      "key": "destructive=true,outlined=false",
      "properties": { "destructive": "true", "outlined": "false" },
      "tree": { "type": "frame", "layout": {...}, "fill": { "hex": "#DC2626" }, "children": [{ "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "bind": "color/ink-inverse" } }] }
    },
    {
      "key": "destructive=true,outlined=true",
      "properties": { "destructive": "true", "outlined": "true" },
      "tree": { "type": "frame", "layout": {...}, "stroke": { "hex": "#DC2626" }, "strokeWeight": 1.5, "children": [{ "type": "text", "value": "Continue", "style": { "bind": "text/cta-label" }, "color": { "hex": "#DC2626" } }] }
    }
  ]
}
```

**Notes:**

- `kDestructiveRed` (`Color(0xFFDC2626)`) is intentionally a literal in the source ("destructive UI does not change color across themes"). The schema preserves this as `{ hex: "#DC2626" }`: no fake binding is invented.
- `radius/pill` is used because `t.radii.button` resolves through `EarnWiseTheme.radii.button = AppRadius.pill` per the theme accessors; the extractor verifies this during theme map construction.
- The `children` array is non-empty for frame nodes that wrap content. A leaf frame with just a fill + no children is still valid (degenerate but not malformed).

## Extractor

### Reference doc additions

`~/Dev/extract-design-system/references/flutter-extraction.md` gains three new sections.

#### Section: Theme resolution

Before walking any component's widget tree, build an in-memory **theme accessor map** by reading `lib/theme/`. The map associates each theme accessor chain with a variable jsonName (or a literal hex string when the chain terminates in a hardcoded color).

For earnapp:

```
t.cta.background      → color/brand          (via EarnWiseTheme.cta.background = palette.brand)
t.cta.foreground      → color/ink-inverse    (via EarnWiseTheme.cta.foreground = palette.inkInverse)
t.radii.button        → radius/pill          (via EarnWiseTheme.radii.button = AppRadius.pill)
t.palette.ink         → color/ink
t.palette.inkInverse  → color/ink-inverse
t.palette.brand       → color/brand
AppText.ctaLabel      → text/cta-label       (text style)
AppText.bodyStrong    → text/body-strong
AppSpacing.cardPad    → space/card-pad       (number variable, used in padding)
```

When extracting a component:
- Each theme accessor encountered is resolved through this map and emitted as `{ bind: "<jsonName>" }`
- A hardcoded `Color(0xFFAARRGGBB)` literal is emitted as `{ hex: "#RRGGBB" }` (alpha ignored unless not 0xFF; Phase 1 assumes opaque)
- If a theme accessor cannot be resolved (chain ambiguous, accessor not found in map), the component falls back to v1 shell extraction (no `variants` field, just the existing layout/properties/slots)

#### Section: Variant enumeration

For each component:
1. Identify **variant-driving properties** in the constructor:
   - `bool` parameters where the value affects branches in `build()`
   - `String` or `enum` parameters with a small set of values used in `build()` switches/conditions
2. Skip non-variant parameters:
   - `Widget`, `IconData`, `VoidCallback`: these are per-instance overrides, not variants
3. Cap the cartesian product at **8 variants**. Beyond 8, fall back to v1 shell extraction or require an explicit annotation
4. For each combination of variant-driving property values, evaluate `build()` mentally with those values fixed, walk the resulting widget tree, and emit a `variant` entry with that tree

For `PrimaryButton`: variant-driving properties are `destructive: bool` and `outlined: bool`. 4 combinations. Each combination's `build()` produces a different combination of fill/stroke/text-color but the same skeletal structure.

#### Section: Widget tree walking

Three categories define the walk:

| Category | Examples | Action |
|---|---|---|
| **Passthrough** | `PressScale`, `Opacity`, `IgnorePointer`, `AnimatedOpacity`, `AnimatedContainer`, `GestureDetector`, `MouseRegion`, `FocusableActionDetector`, `Tooltip`, `Builder`, `LayoutBuilder` | Walk to single child; emit nothing for the wrapper itself |
| **Structural** | `Container` (with `BoxDecoration`), `Padding`, `Row`, `Column`, `SizedBox`, `Stack`, `Expanded`, `Flexible` | Emit `frame` node with corresponding `Layout` |
| **Leaf** | `Text` | Emit `text` node |
| **Phase 2 leaf** | `Icon`, `Image.asset`, `SvgPicture`, `CustomPaint` | Component falls back to v1 shell extraction |

If any descendant of a component's `build()` is a Phase 2 leaf, the entire component degrades gracefully. PrimaryButton has no Phase 2 leaves when `leadingIcon` and `trailingIcon` are both null: and we extract only that case (per the variant enumeration: no icon properties drive a variant; the icon-present cases would be additional variants that we explicitly skip in Phase 1).

#### `build()` mental evaluation rules

When the extractor evaluates `build()` for a specific variant combination:
- `if (condition) A else B` resolves by evaluating `condition` against the fixed property values
- Ternary expressions resolve the same way
- `?? defaultValue` resolves to either the parameter's default (when null) or the parameter's value
- Spread operators (`...[A, B]`) are inlined into the parent's children list
- `if (someProp != null) ... ,` with the property absent: skip the children
- `Widget` parameters and `IconData` parameters are treated as non-extractable in Phase 1; if encountered during walk for a variant, that variant degrades

### CLI changes

The extractor CLI (`~/Dev/extract-design-system/lib/`) gets:

1. **New schema file** `~/Dev/extract-design-system/references/schema.v2.json`: formal JSON Schema definition for v2. Imports v1's component shape and adds `variantProperties` + `variants` as optional fields. Defines `WidgetNode`, `ColorBinding`, `TextStyleBinding`.
2. **`lib/src/schema.ts`**: TS types `WidgetNode`, `ColorBinding`, `TextStyleBinding`, `ComponentV2`, `DesignSystemV2`. Existing types kept.
3. **`lib/src/validate.ts`**: reads `version` from input, picks the matching JSON schema (v1 or v2), runs Ajv, returns errors. Existing v1 tests keep passing.
4. **`lib/scripts/smoke.sh`**: extends to validate a v2 fixture (one PrimaryButton component, all 4 variants).

The diff/serialize/fuzzy-match utilities are unchanged. They operate on the entity-name level and don't introspect `variants`.

## Plugin

### Schema and validate

`src/shared/schema.ts` mirrors the extractor types: `DesignSystemV1`, `DesignSystemV2`, the union, `WidgetNode`, `ColorBinding`, `TextStyleBinding`, `ComponentV2`. Existing v1 types stay.

`src/shared/validate.ts` dispatches on `version` field, runs the matching Ajv schema (`schema.v1.json` from the v1 plugin, `schema.v2.json` newly added). Returns the same `ValidateResult` shape so callers don't change.

### Apply pipeline

`src/main/apply/index.ts` is the dispatcher. Behavior:

```ts
if (ds.version === '2.0.0') {
  // ... existing variables/textStyles/effects pipeline (unchanged) ...
  // Then per-component dispatch:
  for (const comp of ds.components) {
    if (comp.variants && comp.variants.length > 0) {
      await applyComponentV2(comp, ds, opts, onProgress);
    } else {
      await applyComponentShell(comp, ds, opts, onProgress);  // refactored from existing logic
    }
  }
} else {
  // existing v1 pipeline (unchanged)
  await applyComponents(ds, opts, onProgress);
}
```

The variables/textStyles/effects writers are invoked the same way for both versions because their shape is unchanged in v2.

The v1 component shell logic in `src/main/apply/components.ts` is refactored to expose a per-component function `applyComponentShell(comp, ds, opts)` that the v2 dispatcher can call for v2 components without `variants`. The existing `applyComponents(ds, opts)` is preserved as the v1 entry point and wraps the per-component function in a loop.

### `src/main/apply/components-v2.ts`

New file containing:

- `applyComponentV2(comp: ComponentV2, ds, opts, onProgress)`: the orchestrator for one v2 component
- `walkTree(node: WidgetNode, parent: any): Promise<SceneNode>`: recursive walker
- `applyColorBinding(node, field: 'fills' | 'strokes', binding: ColorBinding)`: variable bind or hex literal
- `applyTextStyleBinding(text, jsonName: string)`: find local TextStyle by `jsonName` pluginData, set `textStyleId`
- Layout helpers shared with v1's `applyShell` (refactor common code into a shared module if it grows)

`applyComponentV2` flow:

1. Look up existing ComponentSet by `jsonName` pluginData
2. If exists: detach and remove all child variants (clean slate); the ComponentSet itself is preserved with its position
3. If missing: create a new ComponentSet; assign grid position via the existing 4-column layout code
4. For each entry in `comp.variants`:
   - `figma.createComponent()`: produces a master Component
   - Set `name = variant.key` (Figma parses the `key=value,key=value` format into the variant property panel)
   - `walkTree(variant.tree, masterComponent)` builds the widget hierarchy
   - Identity pluginData on the master: `jsonName` = comp.name, `jsonKind` = 'component', `schemaVersion` = '2.0.0', `lastSyncedAt` = now
5. `figma.combineAsVariants(masters, page)` collapses into a ComponentSet
6. Identity pluginData on the set: same as master, marking it as the canonical owner
7. Position the set using the existing 4-column grid placement helper

`walkTree` per node type:

```ts
async function walkTree(node: WidgetNode, parent: any): Promise<any> {
  if (node.type === 'frame') {
    const f = (figma as any).createFrame();
    applyLayout(f, node.layout);
    if (node.fill) applyColorBinding(f, 'fills', node.fill);
    if (node.stroke) {
      applyColorBinding(f, 'strokes', node.stroke);
      f.strokeWeight = node.strokeWeight ?? 1;
    }
    for (const child of node.children) {
      const c = await walkTree(child, f);
      f.appendChild(c);
    }
    return f;
  }
  if (node.type === 'text') {
    await (figma as any).loadFontAsync({ family: 'Inter', style: 'Regular' });
    const t = (figma as any).createText();
    t.characters = node.value;
    if (node.style.bind) applyTextStyleBinding(t, node.style.bind);
    applyColorBinding(t, 'fills', node.color);
    return t;
  }
  throw new Error(`unknown WidgetNode type: ${(node as any).type}`);
}
```

`applyColorBinding`:

```ts
function applyColorBinding(node: any, field: 'fills' | 'strokes', binding: ColorBinding): void {
  if ('bind' in binding) {
    const v = findVariableByJsonName(binding.bind);
    if (v && typeof node.setBoundVariable === 'function') {
      node.setBoundVariable(field, v);
      return;
    }
    // Variable not found: fall back to a placeholder fill so node remains visible
    node[field] = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 }, opacity: 0.3 }];
    return;
  }
  node[field] = [{ type: 'SOLID', color: hexToRgb(binding.hex), opacity: 1 }];
}
```

`applyTextStyleBinding`:

```ts
function applyTextStyleBinding(text: any, jsonName: string): void {
  const existing = ((figma as any).getLocalTextStyles?.() ?? []) as any[];
  const ts = existing.find(s => getJsonName(s) === jsonName);
  if (ts) text.textStyleId = ts.id;
}
```

`applyLayout` is the same logic from v1's `applyShell` (auto-layout direction, padding, gap, alignment, sizing, corner radius binding). For Phase 1 we factor it out of `components.ts` into a shared utility callable by both pipelines.

## Identity and re-apply

The existing identity convention (`pluginData.jsonName` under `extract_design_system` namespace) is unchanged. Re-apply behavior for v2 components:

- ComponentSet looked up by `jsonName`
- If found: child variants are deleted and rebuilt from the v2 trees. Set's `id`, position, and any external references to it are preserved
- Internal placeholder pluginData (`isPlaceholder = 'true'`) is preserved on synthetic frames the plugin writes; designer-edited frames are protected: except that a delete-and-rebuild deletes everything, so for Phase 1 there is no protection. This is documented as a known v2-of-v1 simplification; partial-update is a v0.2.0 concern.

## Backwards compatibility

- v1 JSON files (`version: '1.0.0'`) take the existing path entirely. No v1 code is modified except the dispatcher in `apply/index.ts`.
- v2 JSON files where most components lack `variants` (Phase 1's reality) work: each such component goes through `applyComponentShell`, producing the same dashed-shell visual we have today.
- v2 JSON file containing one component with `variants` (PrimaryButton) and all others without: PrimaryButton is the only ComponentSet that gets the rich-tree treatment. Designers see it side-by-side with 27 v1 shells, exactly the validation surface we want.
- The existing test suite (50+ tests) is unaffected: no v1 production code path changes. New v2 tests are additive.

## Testing

### Extractor tests

- **CLI validate** snapshot test: a fixture v2 PrimaryButton JSON validates. An invalid v2 JSON (e.g., missing `tree.children` on a frame, unknown WidgetNode `type`) fails validation with a readable error.
- **Reference doc** is documentation; no automated tests, but the extractor smoke script runs validation on the example fixture.

### Plugin tests

- **Unit: `walkTree`** against a v2 fixture. Asserts the FigmaMock receives the right calls in the right order:
  - `createFrame` for the outer frame
  - `setBoundVariable` for the fill (binding `color/brand` to the frame's `fills` field)
  - `loadFontAsync` before `createText`
  - `createText` for the label
  - `setBoundVariable` for the text color
  - The text's `textStyleId` is set
- **Unit: `applyColorBinding`**:
  - `{ bind: "color/brand" }` calls `setBoundVariable(field, variable)` when variable exists
  - `{ bind: "color/missing" }` falls back to placeholder gray fill
  - `{ hex: "#DC2626" }` sets fills directly with parsed RGB
- **Unit: `applyComponentV2`** end-to-end against a fixture:
  - 4 variants → 4 `createComponent` calls → 1 `combineAsVariants` call
  - Each master's `name` matches its variant `key`
  - Identity pluginData written on the set and each variant
- **Unit: dispatcher** in `apply/index.ts`:
  - v1 JSON → calls existing `applyComponents`
  - v2 JSON with PrimaryButton (variants) and 27 others (no variants) → calls `applyComponentV2` once and `applyComponentShell` 27 times
- **Manual smoke test**: load a v2 design-system.json in Figma desktop, verify:
  - PrimaryButton appears as a ComponentSet with 4 variants
  - Right panel shows two BOOLEAN variant properties (`destructive`, `outlined`)
  - Switching variants shows the correct fill/stroke/text color combinations
  - Changing `color/brand` value in Figma's Variables panel updates filled and outlined-non-destructive variants live (token round-trip)
  - Re-running the plugin with the same JSON: ComponentSet preserved, variants rebuilt, no duplication, no error

## Error handling

- **Unknown WidgetNode type** at apply time → throws; caught by the per-component try/catch in the dispatcher; failure surfaced via existing `ApplyReport.failed` channel
- **Variable jsonName not found** during binding → fallback to placeholder gray fill; logged as a warning in `failed` (kind = `'binding'`)
- **TextStyle jsonName not found** → text node created without `textStyleId`; logged as a warning
- **Schema validation failure** at LoadScreen → existing error UI shows the validation messages (no change)
- **Theme accessor unresolvable** at extraction time → component degrades to v1 shell; the extractor logs which accessor was unresolvable

## Success criteria

Phase 1 is a success when ALL of these hold:

1. The extractor produces a v2 design-system.json from `/Users/markus/Dev/earnapp/flutter_app/` containing PrimaryButton with 4 variants, full token bindings, and all other 27 components in their existing v1 shape.
2. The plugin loads, diffs, and applies the v2 JSON without errors.
3. Figma shows a PrimaryButton ComponentSet with 4 variants. Each variant's master is visually correct: filled / outlined / destructive / destructive-outlined.
4. Designer can switch variants via Figma's right-panel variant property controls.
5. Modifying `color/brand` in Figma's Variables panel updates the filled and outlined (non-destructive) variants live.
6. Re-running the plugin against the same JSON preserves the ComponentSet's position and id; only the inner variants are rebuilt.
7. All existing 50+ unit tests continue to pass; new v2 unit tests pass; the manual smoke checklist passes.
8. v1 JSON files continue to apply correctly through the existing pipeline.

## Estimate

Roughly 1 week of focused work:

- Schema design (JSON schema + TS types) and CLI updates: 1 day
- Reference doc additions and theme map for earnapp: 1.5 days
- Plugin schema/validate/dispatcher: 1 day
- `applyComponentV2` and `walkTree`: 1.5 days
- Tests (extractor + plugin) and manual smoke: 1 day

## Open questions (deliberately closed for this phase)

- **Diff smartness**: deferred. v2 components rebuild on re-apply.
- **Image / SVG / Instance node types**: deferred to Phase 2/3 but reserved in the discriminator.
- **Variant explosion (>8 properties)**: deferred. Extractor falls back to v1 shell.
- **Theme accessor resolution failure feedback**: extractor logs but does not block; component degrades to v1 shell.
- **Backwards round-trip migration (v1 file → v2)**: deferred. v1 files keep working but are not auto-upgraded.
