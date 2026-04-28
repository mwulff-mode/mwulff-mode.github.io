# v2 Sync Phase 2: Image, SVG, and Icon node types

## Problem

Phase 1 shipped a working v2 sync pipeline for components built from `frame` and `text` widgets. Most of the earnapp design system, however, contains widgets that Phase 1 cannot extract:

- `ListRow`, `VerticalTile`, `CategoryIconSquare`: contain `Icon(IconData)` from Material or Phosphor
- `AppToast`, `SectionHeader`, `StatBubble`: contain icons in their layout
- Various screens: contain `Image.asset(...)` for game thumbnails, brand logos, etc.

Per Phase 1's graceful-degradation rule, ANY of these widgets in a component's tree forces the entire component to fall back to v1 shell shape. The result: roughly 24 of 28 components in earnapp degrade to dashed-outline shells.

Phase 2 lifts the icon and image gates by extending `WidgetNode` with three new types so these components can extract richly while keeping the same architecture (rich-tree apply for components with `variants`, shell apply otherwise).

## Goals

1. **Schema v2 gains `image`, `svg`, `icon` node types** in the `WidgetNode` discriminated union; schema version stays at `2.0.0` (additive change within v2)
2. **Extractor reference doc** describes how to read `Image.asset`, `SvgPicture.asset`, `Icon(IconData)` and emit the new node shapes
3. **Plugin walks the new node types**: image fills, SVG vector imports, icon placeholders
4. **Synthetic test fixture proves the pipeline end-to-end** before any real component is re-extracted
5. **`Icon` widgets stop forcing component degradation**: a component with icons can still extract richly

## Non-Goals

- Real Material/Phosphor IconData glyph rendering. Icon nodes are dashed placeholder frames with a name label. Designers swap them for real icons. (A Phase 2.5 could resolve IconData to actual SVGs from the Material/Phosphor packages, but that requires shipping icon catalogs and is not in this spec.)
- Re-extracting the existing earnapp design system through the LLM workflow. The proof is a synthetic fixture; broader extraction is follow-up work.
- Custom paint, gradient fills with multiple stops, blur effects, blend modes. These remain Phase 3+ or never.

## Architecture

The same five boundaries from Phase 1 apply. Three are touched in Phase 2:

1. **Schema definition** ('extract-design-system/references/schema.v2.json' and 'extract-design-system-figma-plugin/schema.v2.json'): the `WidgetNode` `oneOf` gains three new branches
2. **Extractor reference doc** ('extract-design-system/references/flutter-extraction.md'): a new "v2 Phase 2: Asset and icon extraction" section
3. **Plugin walkTree** ('extract-design-system-figma-plugin/src/main/apply/components-v2.ts'): three new branches in the discriminated `walkTree` switch

TypeScript types in 'src/shared/schema.ts' (both repos) and 'lib/src/schema.ts' (extractor) gain the new union members. Figma mock gains 'figma.createImage' and 'figma.createNodeFromSvg' methods.

## WidgetNode additions

```ts
type WidgetNode =
  | { type: 'frame'; layout; fill?; stroke?; strokeWeight?; children: WidgetNode[] }   // Phase 1
  | { type: 'text'; value; style; color }                                              // Phase 1
  | { type: 'image'; source: string; width: number; height: number; fit?: 'cover' | 'contain' | 'fill' }  // Phase 2
  | { type: 'svg'; source: string; width: number; height: number }                     // Phase 2
  | { type: 'icon'; name: string; size: number };                                      // Phase 2
```

### `image` node

`source`: base64-encoded raw bytes (no `data:` URI prefix). Maximum decoded size soft-capped at 1 MB; oversized images degrade the component.

`width`, `height`: explicit pixel dimensions. The plugin creates a frame at this size and applies the image as a fill.

`fit`: optional, defaults to `'cover'`. Controls Figma's `imageScaleMode` (`COVER` / `FIT` / `STRETCH`).

### `svg` node

`source`: the literal SVG XML, as a single string (no surrounding `<?xml?>` declaration; just `<svg>...</svg>`).

`width`, `height`: target dimensions on the Figma canvas. The plugin imports via `figma.createNodeFromSvg(source)` and resizes the result.

### `icon` node

`name`: a stable identifier preserving enough info to identify the icon for designers. Examples:

- Material: `'material:arrow_back'` (codepoint not preserved; designer reads the name)
- Phosphor: `'phosphor:caret-right:bold'`
- Cupertino: `'cupertino:back'`

`size`: target square dimension in pixels (e.g. 16, 24, 48).

The plugin renders a dashed-outline placeholder frame at the requested size with the icon name as a small text label inside (using whatever font is loaded). Designer sees `material:arrow_back` placeholder and knows to swap with a real icon.

## Extractor changes

The reference doc 'flutter-extraction.md' gets a new section after the existing "v2: Widget tree walking" section:

### v2 Phase 2: Asset and icon extraction

`Image.asset` mapping:

```dart
Image.asset('assets/images/logo.png', width: 48, height: 48)
```

becomes:

```json
{ "type": "image", "source": "<base64-bytes>", "width": 48, "height": 48 }
```

The extractor resolves the asset path against `pubspec.yaml`'s `flutter.assets` declarations, reads the file bytes from disk, base64-encodes them. If the resolved file is larger than 1 MB or cannot be read, the component degrades to v1 shell (no `variants` field).

`SvgPicture.asset` mapping:

```dart
SvgPicture.asset('assets/icons/check.svg', width: 16, height: 16)
```

becomes:

```json
{ "type": "svg", "source": "<svg xmlns=\"http://www.w3.org/2000/svg\" ...>...</svg>", "width": 16, "height": 16 }
```

The SVG XML is read verbatim from the file (no transformation). If the file cannot be read, the component degrades.

`Icon(IconData)` mapping:

```dart
Icon(Icons.arrow_back, size: 24, color: t.palette.ink)
Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16)
```

becomes:

```json
{ "type": "icon", "name": "material:arrow_back", "size": 24 }
{ "type": "icon", "name": "phosphor:caret-right:bold", "size": 16 }
```

The icon name format is `<package>:<icon>:<style?>`. For Material icons, prefer the lowercase snake-case name from the IconData usage. For Phosphor, include the style (regular / bold / fill / etc.). For unknown packages, fall back to `unknown:<source-text>`.

`Icon` does not preserve color in the v2 placeholder (the placeholder is dashed gray regardless). When real glyph rendering ships in Phase 2.5, color will be honored.

### Updated category table

The "Leaf (Phase 2+)" row in the existing table is replaced with:

| Leaf (Phase 2) | `Image.asset`, `SvgPicture.asset`, `Icon` | Emit `image`, `svg`, or `icon` node respectively |
| Leaf (out of scope) | `CustomPaint`, `RepaintBoundary` of custom subtree, `BackdropFilter` | Component falls back to v1 shell |

## Plugin changes

### Schema and types

Add the new union members to:
- 'extract-design-system/references/schema.v2.json' (oneOf gets three new branches)
- 'extract-design-system/lib/src/schema.ts' (TS union)
- 'extract-design-system-figma-plugin/schema.v2.json' (mirror)
- 'extract-design-system-figma-plugin/src/shared/schema.ts' (mirror)

### walkTree branches

In 'src/main/apply/components-v2.ts', `walkTree` gains:

```ts
if (node.type === 'image') {
  const f = figma.createFrame();
  f.resize(node.width, node.height);
  const bytes = base64ToBytes(node.source);
  const image = await figma.createImage(bytes);
  const scaleMode = node.fit === 'contain' ? 'FIT' : node.fit === 'fill' ? 'STRETCH' : 'CROP';
  f.fills = [{ type: 'IMAGE', scaleMode, imageHash: image.hash }];
  return f;
}
if (node.type === 'svg') {
  const svgNode = figma.createNodeFromSvg(node.source);
  svgNode.resize(node.width, node.height);
  return svgNode;
}
if (node.type === 'icon') {
  const ph = figma.createFrame();
  ph.resize(node.size, node.size);
  ph.strokes = [{ type: 'SOLID', color: { r: 0.55, g: 0.55, b: 0.55 }, opacity: 0.5 }];
  ph.strokeWeight = 1;
  ph.dashPattern = [4, 4];
  // Inner label with the icon name. Use Inter Regular which is already loaded.
  if (node.size >= 32) {
    const label = figma.createText();
    label.fontSize = Math.max(8, Math.floor(node.size / 4));
    label.characters = node.name;
    ph.appendChild(label);
  }
  return ph;
}
```

`base64ToBytes` is a small helper using `atob` plus a `Uint8Array` (the Figma plugin runtime supports both). For images smaller than the size threshold the conversion is fast.

### Mock changes

'tests/mocks/figma-mock.ts' adds:

```ts
createImage = async (bytes: Uint8Array) => {
  const hash = `image-${++this.idCounter}`;
  this.calls.push({ op: 'figma.createImage', args: [bytes.length], resultId: hash });
  return { hash };
};

createNodeFromSvg = (svg: string) => {
  const node = this.createFrame();
  node.name = 'SvgImport';
  (node as any)._svg = svg;
  this.calls.push({ op: 'figma.createNodeFromSvg', args: [svg.length], resultId: node.id });
  return node;
};
```

## Tests

Add to 'tests/unit/apply-components-v2.test.ts':

- `walkTree (image)`: emits frame at correct size with IMAGE fill; `figma.createImage` was called with byte length matching the decoded base64
- `walkTree (svg)`: emits SVG-imported node at correct size; `figma.createNodeFromSvg` was called with the literal SVG string
- `walkTree (icon)`: emits dashed frame at correct size; for size ≥ 32, includes an inner text label with the icon name
- `walkTree (image) errors gracefully when source is not valid base64`: throws or returns a placeholder; component report records the error

Add a synthetic fixture 'tests/fixtures/asset-test-card-v2.json' that exercises all three new node types in one component with one variant. Plugin test asserts the resulting Figma tree contains a frame, an image fill, an SVG import, and a dashed icon placeholder.

## Backwards compatibility

- v1 JSON: unchanged path
- v2 JSON without new node types: unchanged path; existing PrimaryButton tests still pass
- v2 JSON with `image`, `svg`, or `icon` nodes: handled by the new `walkTree` branches
- A v2 JSON file containing both old (`frame`/`text`) and new (`image`/`svg`/`icon`) node types: both paths run

## Error handling

- Invalid base64 in `image.source`: `walkTree` catches the `atob` failure, returns a placeholder gray frame, and the component's `applyComponentV2` try/catch records the error
- Malformed SVG: `figma.createNodeFromSvg` throws; same try/catch records the error
- Unknown icon name format: extractor falls back to `unknown:<source-text>`; plugin draws the dashed placeholder regardless

## Success criteria

1. Schema v2 in both repos has the three new node types in the `oneOf`
2. CLI validate accepts a v2 fixture containing `image`, `svg`, `icon` nodes
3. Plugin's `walkTree` produces correct Figma operations for each new type
4. Synthetic test fixture extracts and applies cleanly end-to-end (unit-level, no Figma desktop required)
5. All existing 109 tests continue to pass (41 extract-design-system + 68 plugin)
6. Extractor reference doc has the new section so a future LLM extraction run handles assets
7. `Icon` no longer triggers full component degradation: a synthetic component with an icon child can route through the v2 rich-tree path

## Estimate

Roughly 4-5 days of focused work:

- Schema + TS types in both repos: 0.5 day
- Extractor reference doc: 0.5 day
- Plugin walkTree (image, svg, icon): 1 day
- Mock additions + unit tests: 1 day
- Synthetic fixture + end-to-end test + manual verification: 1 day

## Open questions (deliberately closed)

- Real IconData glyph rendering: Phase 2.5
- Material icon catalog as embedded SVGs: Phase 2.5
- Image fit modes beyond cover/fit/fill: future
- Image vs SVG decision when both formats exist for an asset: prefer SVG (vector); image is the fallback
