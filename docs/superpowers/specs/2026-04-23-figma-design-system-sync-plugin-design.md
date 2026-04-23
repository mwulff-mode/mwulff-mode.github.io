# Figma Design System Sync Plugin: Design

**Date:** 2026-04-23
**Status:** Design approved, ready for implementation plan
**Related:** `~/Dev/extract-design-system/` (the extraction skill that produces this plugin's input)

## Problem

The `extract-design-system` skill produces a `design-system.json` file describing a codebase's tokens, styles, and components. This JSON is the shared contract between engineering and design: engineers change code, the skill regenerates the JSON, the design file should follow.

Today there is no automated path from that JSON into Figma. Designers rebuild tokens and components by hand, drift accumulates, and the JSON is useful to engineers but invisible to the design team.

This plugin closes that loop: a Figma plugin that consumes `design-system.json` and applies it to the currently open Figma file: creating, updating, renaming, and flagging stale Figma objects in one guided pass, with a diff preview before anything is written.

## Goals

1. **One-way sync, code → Figma, gated by preview.** Apply the JSON to the file, but never silently. Every run ends with a diff the designer approves or cancels.
2. **Stable identity across renames.** A code-side rename should rename the Figma object, not delete-and-recreate it, so designer references (components bound to colors, styles bound to variables) survive.
3. **Render components as far as the JSON allows, honestly.** Draw the exact shell (size, padding, radius, fill per variant) and fill slot contents with obvious placeholders. Do not invent internal composition we do not have.
4. **Safe by default.** No destructive action without designer confirmation. Orphaned objects are flagged, never auto-deleted.
5. **Zero setup friction.** Designer loads a JSON file from disk and gets value on the first run.

## Non-Goals (v1)

- Two-way sync (Figma → code)
- Continuous / live sync (every run is manual)
- Library publishing automation (designer still publishes their library manually after sync)
- Pixel-exact rendering of internal component composition (icons inside cards, chevrons, nested widgets: these remain placeholders)
- Rendering images / illustrations / the `icons[]` SVG array from the JSON
- Multi-file sync orchestration or merge of competing JSONs
- Figma REST API path (plugin API only; the file must be open in Figma)

## Contract

**Input**

- A `design-system.json` file conforming to schema v1.0.0 (defined in `~/Dev/extract-design-system/references/schema.v1.json`)
- Loaded via file picker in the plugin UI (drag-and-drop also accepted)

**Target**

- Whichever Figma file is currently open when the plugin runs. The plugin does not bind to a specific file; identity is tracked via `pluginData` on objects inside the file.

**Output**

The plugin creates or updates in the open file:

- `VariableCollection`s and `Variable`s (matching JSON `collections[]` and `variables[]`)
- `TextStyle`s (matching `textStyles[]`)
- `EffectStyle`s (matching `effects[]`, v1 assumes one effect per style)
- `ComponentSet`s with variants, slots, and property definitions (matching `components[]`)
- Variable aliases (matching `aliases[]`)

All created components live on a page named `Design System` (created if absent), organized by tier (Atoms row, Molecules row, Organisms row), variants laid out horizontally per component.

**Sync model**

- One-way: code → Figma. The JSON is source of truth; the plugin never writes back to the JSON.
- Gated: every run shows a diff screen listing Added / Updated / Removed / Renamed per entity kind. Designer approves, cancels, or toggles individual rows. Nothing applies until the designer clicks Apply.
- Stable identity via `pluginData`: once an object is adopted or created, its `jsonName` is recorded on the Figma node. Renames on either side are matched by this key, not by current display name.

## User Flow

Four linear screens. Designer can exit or back up at any point before Apply.

### Screen 1: Load

- Empty state: "Load your design-system.json" with file picker button
- Drag-and-drop accepted
- On select: parse, validate against schema v1 with Ajv
- **Invalid JSON:** inline error with parse location, stay on screen
- **Schema violation:** list specific validation errors (e.g., `components[2].layout.sizing is required`), stay on screen
- **Schema version mismatch** (JSON `version != "1.0.0"`): hard block with "Plugin needs update or JSON needs downgrade", stay on screen
- **Valid:** check file-level `pluginData.adoptionComplete`
  - Present → skip to Screen 3 (Diff)
  - Absent → advance to Screen 2 (Adopt)

### Screen 2: Adopt (first run per file only)

- Title: "Match existing Figma objects?"
- Plugin snapshots all existing variables, text styles, effect styles, and component sets in the file
- By-name matches against the loaded JSON are listed as proposed adoptions: `color/brand (JSON) ↔ color/brand (Figma)`, each with a checkbox defaulting to checked
- JSON entries without a name match are shown as "Will be created" (informational)
- Figma objects without a name match are shown as "Will be left alone" (informational; they do not become orphans because the plugin never owned them)
- Button: "Continue with N matches" → writes `pluginData` on each accepted match, sets `adoptionComplete` on the file, advances to Screen 3

### Screen 3: Diff

Layout: single scrolling panel, ~320px wide, grouped by entity kind.

- Header: JSON filename and stack, total change count
- Sections in order:
  - Variables (+N)
  - Text Styles (+N)
  - Effects (+N)
  - Components (+N)
  - Orphans (+N): collapsed by default, cream background when expanded
- Each row shows:
  - Change icon: `+` added, `~` updated, `→` renamed, `−` orphaned
  - Entity name (current or new)
  - For updates: inline delta (`#0F766E → #0D9488`, `padding 16→18`)
  - For renames: `PillButton → PrimaryButton`
  - Per-row checkbox (selected rows will be applied); orphan rows have a delete toggle instead (default off)
- Section-level controls: "Select all" / "Deselect all" per section
- Footer: "Apply N changes" primary button, count updates live with selection. Disabled at N=0.
- **Empty diff**: when the JSON produces no changes (including the `lastJsonHash` short-circuit case), Screen 3 shows a single "No changes to apply" message with a "Done" button. No diff sections are rendered.

### Screen 4: Apply and Done

- Progress bar with live count ("Applying 7 of 23…")
- Per-kind status ("Variables ✓ · Text styles ✓ · Components applying…")
- On completion: summary of applied changes, "View in Figma" jump link to the Design System page
- **Partial failure** (any apply op errored): show the failed rows in a second section, offer "Retry failed" (only retries those rows, not the whole set)
- **Cancel during apply:** plugin stops at next safe boundary (between entity kinds). Already-applied writes stay; unapplied writes are simply not attempted. No rollback.

## Sync Semantics Per Entity Kind

### Variables

- JSON `collections[]` → Figma `VariableCollection`, one per JSON collection. Name and modes exactly match.
- JSON `variables[]` → Figma `Variable` inside the specified collection. `resolvedType` derives from JSON `type`:
  - `color` → `COLOR`
  - `number` → `FLOAT`
  - `string` → `STRING`
  - `boolean` → `BOOLEAN`
- `valuesByMode` applied via `setValueForMode(modeId, value)` per mode. Hex color strings parsed to `{r, g, b, a}` for the COLOR type.
- JSON `aliases[]` → Figma `VariableAlias` value pointing at the target variable's id.
- **Rename**: `variable.name = newName`, `setPluginData("jsonName", newName)`. Figma resolves references by id, so bindings survive.

### Text Styles

- JSON `textStyles[]` → Figma `TextStyle`. Font loaded via `figma.loadFontAsync` before assignment.
- Bound properties (e.g., `fontSize: { bind: "size/lg" }`) become Figma variable bindings via `setBoundVariable("fontSize", variable)`, keeping typography reactive to token changes.
- **Missing font** on system: error row during apply, "Install font in Figma and retry" action.

### Effects

- JSON `effects[]` → Figma `EffectStyle` with a single `Effect` (DROP_SHADOW, INNER_SHADOW, LAYER_BLUR, or BACKGROUND_BLUR). Multi-effect stacks are a v2 feature.

### Components

- JSON `components[]` → Figma `ComponentSetNode`. Even components with no VARIANT properties are wrapped in a set, for consistency when variants are later added.
- **Frame shell**, drawn exactly:
  - `layout.direction` → `layoutMode`
  - `layout.sizing` → `primaryAxisSizingMode`, `counterAxisSizingMode`, and explicit `resize()` when FIXED
  - `layout.padding`, `layout.gap`, `layout.alignItems`, `layout.justify` → matching Figma auto-layout props
  - `layout.radius` → `cornerRadius` (or `setBoundVariable("topLeftRadius", ...)` etc. when the JSON provides `{bind}`)
- **Variants**: one `Component` per combination of VARIANT-typed properties. Variant mappings (e.g., `variantMappings["variant=primary"].fill`) applied to the background rect; color bindings via `setBoundVariable("fills", variable)`.
- **Slots** rendered in array order inside the auto-layout frame:
  - TEXT slot: `TextNode` with placeholder text (slot name capitalized, e.g., "Label"), bound text style applied
  - INSTANCE slot: dashed 24×24 frame labeled with the slot name, for the designer to swap for a real icon component
  - FRAME slot: empty labeled frame
- **Property definitions**: BOOLEAN, TEXT, and INSTANCE_SWAP properties registered on the ComponentSet via `addComponentProperty`, defaults from JSON.
- **Placeholder persistence rule**: the plugin writes slot content **only at component creation**. On subsequent re-applications, the plugin only rewrites **shell properties** (size, padding, gap, radius, fills). Slot content is never touched on update. This prevents the plugin from stomping designer edits inside the component.

## Identity and Persistence

All keys are namespaced under `extract-design-system`.

**Per-node pluginData** (on every variable, text style, effect style, component set):

- `jsonName`: canonical name from the JSON at time of adoption/creation. Stable identity.
- `jsonKind`: `"variable" | "textStyle" | "effect" | "component"`
- `lastSyncedAt`: ISO timestamp, for diagnostics
- `schemaVersion`: JSON `version` at sync time, for future migrations

**Per-file pluginData** (on the document):

- `adoptionComplete`: set to `"true"` after first-run adoption, so Screen 2 is skipped thereafter
- `lastJsonHash`: SHA-256 of the last successfully applied JSON, used to short-circuit Load → "no changes" when the same file is re-loaded

**Slot placeholder tag** (`isPlaceholder: "true"`): set at placeholder creation, never read for re-application decisions. Kept only as an optional hint for UI (e.g., a future "needs real content" overlay). Per the placeholder persistence rule, this tag has no functional effect on sync.

**Rename flow end-to-end:**

1. Engineer renames `PillButton` → `PrimaryButton` in code.
2. Extract skill's fuzzy matcher catches the rename, engineer confirms, skill writes `PrimaryButton` to JSON.
3. Designer loads new JSON into plugin.
4. Plugin snapshots file: finds node with `pluginData.jsonName = "PillButton"`. JSON has no "PillButton" entry but has a new "PrimaryButton" with no Figma node.
5. Plugin's rename detector matches the pair, shows `→ PillButton → PrimaryButton` in the diff.
6. On apply: `component.name = "PrimaryButton"`, `setPluginData("jsonName", "PrimaryButton")`. Figma references (id-based) survive.

**Duplicate detection:** If the snapshot finds two Figma nodes with the same `jsonName`, the plugin blocks Apply with an error listing the duplicate pairs. Designer deletes one manually and re-runs. v2 may add in-plugin resolution.

**What the plugin does not persist:**

- User preferences (sort order, expanded sections): plugin is session-scoped
- Local cache of past JSON files: always loaded fresh
- Binding between a specific JSON source and a specific Figma file: any JSON can apply to any file; `pluginData` on the file handles identity

## Architecture

Figma plugins have a two-process model: the **main thread** runs inside Figma with document API access; the **UI thread** runs in an iframe with file picker and network access. They communicate via `postMessage`.

```
extract-design-system-figma-plugin/
├── manifest.json
├── src/
│   ├── main/                       # main thread (Figma document API)
│   │   ├── code.ts                 # entry + message router
│   │   ├── apply/                  # writers, one per entity kind
│   │   │   ├── variables.ts
│   │   │   ├── text-styles.ts
│   │   │   ├── effects.ts
│   │   │   └── components.ts
│   │   ├── read/
│   │   │   └── snapshot.ts         # snapshot current Figma DS state
│   │   ├── identity.ts             # pluginData get/set
│   │   └── messages.ts             # shared typed message protocol
│   ├── ui/                         # UI thread (React)
│   │   ├── index.tsx
│   │   ├── App.tsx                 # state machine: load → adopt → diff → apply
│   │   ├── screens/
│   │   │   ├── LoadScreen.tsx
│   │   │   ├── AdoptScreen.tsx
│   │   │   ├── DiffScreen.tsx
│   │   │   └── ApplyScreen.tsx
│   │   └── components/
│   └── shared/
│       ├── schema.ts               # v1 schema TypeScript types
│       └── diff.ts                 # pure diff (snapshot + JSON → diff)
├── tests/
└── build/                          # esbuild output
```

**Message protocol** (tagged discriminated unions): `LOAD_JSON`, `SNAPSHOT_REQUEST`/`SNAPSHOT_RESULT`, `DIFF_REQUEST`/`DIFF_RESULT`, `APPLY_REQUEST`/`APPLY_PROGRESS`/`APPLY_DONE`.

**Pure separation**: `shared/diff.ts` takes a `Snapshot` and a `DesignSystem` and returns a `Diff`. No Figma dependency. Can be unit-tested on shared fixtures with the extract skill. v1 duplicates diff logic between plugin and skill; v2 worth extracting into a shared npm package if drift becomes a problem.

**Build**: `esbuild` bundles `code.ts` → `code.js` and inlines React UI into `ui.html`. No runtime dependencies in the shipped bundle.

## Error Handling

**JSON-side problems** (Load screen):

- Parse error → inline error with location
- Schema validation failure → list specific Ajv errors
- Schema version mismatch → hard block, no partial apply on version drift

**Figma API constraints** (Apply screen):

- Missing font → per-text-style error row, "Retry failed" action after designer installs
- Variable type change (e.g., existing Figma variable is COLOR, JSON says STRING) → Figma does not allow `resolvedType` changes; plugin blocks with "Type change on `color/foo` requires manual deletion first"
- Variable limits hit (Figma plan-dependent) → surface the error, stop apply, show partial-success summary

**Identity and state**:

- Duplicate `jsonName` on snapshot → block Apply (see Identity section)
- `pluginData` pointing at a deleted node → drop silently, treat as "not yet adopted"
- Stale adoption from a different JSON source → undetectable with current model; documented as a known limitation

**User safety**:

- Apply is always an explicit button, never auto-triggered
- Orphans default to "keep": the designer must tick delete per item
- Partial Apply failures do not roll back (Figma has no transaction primitive; partial rollback risks worse state). The plugin shows applied vs. failed and offers Retry for failed only.
- Cancel during Apply stops at the next entity-kind boundary; already-applied writes stay.

## Testing Strategy

**Pure logic** (vitest, deterministic, fast):

- `shared/diff.ts` against shared fixtures with the extract skill (reuses `flutter-earnwise`, `html-react-earnwise` fixtures)
- Schema parsing and validation (Ajv against `schema.v1.json`)
- Rename detection parity with the extract skill's CLI (regression check)
- Message protocol round-trips

**Figma API writers** (vitest + hand-rolled Figma API mock):

- Each `main/apply/*.ts` tested against a mocked `figma` global. Assertions on the sequence of API calls, not document state.
- Fixtures: snapshot-before + JSON → expected Apply call log. Re-running the writer on the same input produces an identical call log (idempotency check).
- Per-writer edge cases: rename, orphan-kept, type conflict, font-not-loaded.

**UI screens** (vitest + @testing-library/react + jsdom):

- State machine transitions (Load → Adopt → Diff → Apply)
- Diff rendering: given a `Diff` object, assert expected rows and icons
- Selection logic (per-row checkbox, select-all, footer count)

**Integration** (manual, real Figma file):

Checklist `tests/manual-smoke.md`, run before each release:

1. Fresh file, no adoption. Full sync from `flutter-earnwise` fixture JSON.
2. Re-run plugin → "No changes" (idempotency with real Figma).
3. Rename a variable in JSON, re-run → rename applied, references intact.
4. Remove a variable from JSON, re-run → orphan flagged; confirm delete; verify component references still resolve.
5. Second file, adoption flow: pre-seed with matching-name variables, run plugin, confirm adoption, verify `pluginData` written.

**CI**: lint, type-check, vitest (pure + UI + mocked writers). Build artifacts (`code.js`, `ui.html`) uploaded for manual testing. No automated Figma integration test: the plugin runtime is not available in CI.

**Relied on manual review**:

- Visual correctness of rendered components (does `PillButton` look right in Figma?)
- Real Figma API quirks the mock does not capture
- Performance on large systems (100+ components): measured manually before v1 ship

## Open Questions (for implementation plan)

- Exact `pluginData` key names and namespacing (bikeshed during implementation)
- Exact layout grid for the Design System page (row spacing, frame-to-frame gap, whether each tier gets its own sub-grid)
- Whether to expose a "View JSON diff" raw-text view as a debug affordance (deferred to v2 unless a need arises during manual testing)

## Next Step

Invoke `superpowers:writing-plans` to produce the implementation plan.
