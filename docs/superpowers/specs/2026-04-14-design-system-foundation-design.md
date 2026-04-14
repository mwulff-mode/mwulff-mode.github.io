# Design System Foundation + Reference Doc

**Date:** 2026-04-14
**Status:** Design approved, ready for implementation planning
**Sub-project:** 1 of 6 in the Design System initiative
**Ships value:** Yes, establishes the canonical UI reference and the reusable primitives that all subsequent screen migrations (sub-projects 2–5) will depend on.

## Context

EarnWise's Flutter prototype (`flutter_app/`) has tokens and widgets, but the scale doesn't match reality and the component library is under-extracted. The result is the user constantly micro-correcting layout: off-grid spacing values (`10`, `14`, `18`), inline re-implementations of the same card/row/tile pattern with subtle drift, and no canonical reference either of us can check against.

### Evidence

- **53** raw `EdgeInsets` calls across 10 screens, many with off-grid values.
- **110** raw `SizedBox(height: N)` / `BorderRadius.circular(N)` calls; the most common values (`2`, `4`, `10`, `12`, `14`, `20`) are **not** in `AppSpacing` (which is `4 / 8 / 16 / 24 / 32`). The scale doesn't match what people actually reach for, so they silently type raw ints.
- The existing `AppCard` doc explicitly says feature cards (task tiles, streak cards, stat bubbles) "intentionally stay inline", that decision is the single largest source of the duplication and drift the user is micro-correcting.
- Painkiller ranking from the user: vertical spacing #1, horizontal alignment #2, component duplication #3, surface consistency #4, typography #5, color #6.

### Root cause

The system isn't missing, it's *under-specified* and *under-enforced*. The scale has wrong granularity. The repeated UI patterns never got extracted into widgets. There is no single source of truth either Claude or the user can point at when arguing about a pixel.

### What this sub-project does

- Rewrites the token layer on a strict 4px base with a two-tier (primitive + semantic) structure.
- Extracts 6 reusable components for the patterns currently duplicated inline.
- Publishes `docs/design-system.md` as the canonical reference.
- Hooks it into `CLAUDE.md` so Claude loads it on every UI task.
- **No screen migrations.** Other screens keep working unchanged. Sub-projects 2–5 will migrate screens one at a time.

### What this sub-project explicitly does NOT do

- Does **not** introduce `ThemeExtension`. Rationale: EarnWise has one theme today, static classes are simpler and well-known to the existing codebase. Dark mode (flagged as "soon" by the user) will migrate `AppColors` only to `ThemeExtension<AppColorPalette>`; `AppSpacing`/`AppRadius`/`AppElevation`/`AppText` will stay static because they are brightness-invariant. See [Dark mode migration path](#dark-mode-migration-path) below.
- Does **not** refactor `AppCard` internally to wrap `Surface`. `AppCard`'s implementation stays as-is; a later cleanup can rebuild it on top of `Surface`. One small change does land: its hardcoded `BorderRadius.circular(18)` becomes `BorderRadius.circular(AppRadius.card)` (16). This is a localized visible shift explicitly approved by the user, see Section 1.2.
- Does **not** touch any screen file in `lib/screens/`. No file in `lib/screens/` is edited in this sub-project, and no screen should visibly shift as a result of it (the only visible pixel shift in the whole sub-project is the `AppCard` radius change above, which takes effect wherever `AppCard` is used). Screen migrations happen one screen at a time in sub-projects 2–5.
- Does **not** replace or edit the existing `docs/earnwise-design-system.html` (which is a presenter-template design doc, not the Flutter app reference). The new `docs/design-system.md` is specifically the Flutter app's canonical reference.
- Does **not** add lint rules or custom analyzers to enforce token use. Enforcement is convention-first in this sub-project; a lint rule is sub-project 6 (optional).

## Design

### 1. Token structure (primitive + semantic, two tiers)

Two layers is the industry-standard sweet spot for a non-enterprise design system. Primitive tokens define the scale; semantic tokens carry intent. **Components and screens must reference semantic tokens only.** Primitives are for the semantic layer to consume.

#### 1.1 Spacing scale

**Primitive layer** (private `const` values in `app_theme.dart`, referenced by the semantic layer below, not a public class, and not referenced from screen/component code):

| Internal const | Value |
|------|-------|
| `_s2` | 2 |
| `_s4` | 4 |
| `_s8` | 8 |
| `_s12` | 12 |
| `_s16` | 16 |
| `_s20` | 20 |
| `_s24` | 24 |
| `_s32` | 32 |
| `_s40` | 40 |
| `_s48` | 48 |

(Private to avoid polluting `AppSpacing`'s public API and to keep the semantic layer the single entry point.)

**Semantic layer** (what screens and components reference, all live on the existing `AppSpacing` class):

| Name | Value | Purpose |
|------|-------|---------|
| `AppSpacing.tight` | 2 | Intra-component title → subtitle stacks only. **Named exception** to the 4px grid. |
| `AppSpacing.xs` | 4 | Icon → label gap inside a single unit (unchanged from today) |
| `AppSpacing.sm` | 8 | Tight horizontal gap (unchanged from today) |
| `AppSpacing.inner` | 12 | Intra-card content step (e.g., gap between an icon and its title in a stacked tile) |
| `AppSpacing.rowGap` | 12 | Between consecutive rows/cards in a list |
| `AppSpacing.cardPad` | 16 | Default card inner padding |
| `AppSpacing.titleGap` | 20 | Around titles / space above a big stack element |
| `AppSpacing.sectionGap` | 24 | Between sections on a page |
| `AppSpacing.pageGutter` | 24 | Left/right page gutter (set by `ScreenScaffold`) |
| `AppSpacing.blockGap` | 32 | Between major page blocks |
| `AppSpacing.heroGap` | 40 | Around hero elements |
| `AppSpacing.pageTop` | 48 | Top of scrollable pages (replaces current `32 + safeArea` hack) |

**Naming rationale (important, this supersedes an earlier design decision).** The first draft reused the generic `xs/sm/md/lg/xl` names for the new semantic layer, which would have forced `md: 16 → 12`, `lg: 24 → 16`, `xl: 32 → 20`. A re-count showed this actually affects ~36 call sites across six screens (`home_screen.dart`, `wallet_screen.dart`, `game_detail_screen.dart`, `profile_screen.dart`, `trust_carousel_screen.dart`, `welcome_screen.dart`), much larger than the 5-site scope presented during brainstorming. Since sub-project 1 is supposed to land the foundation *without* visibly shifting any screen, the correct fix is to give the new rungs their own intent-specific names (`inner`, `cardPad`, `titleGap`) and leave `md`/`lg`/`xl` as deprecated aliases at their original values. Screens then migrate to the new names one at a time in sub-projects 2–5, where each pixel shift is reviewed per screen. **Flag this to the user during the spec review gate.**

**Rules:**

- Raw ints in `SizedBox(height: N)` or `EdgeInsets.all(N)` / `symmetric(...)` are not allowed in new code.
- `AppSpacing.tight` (2px) is the only sub-4 value, and it is restricted to intra-component title/subtitle stacks.
- Existing off-grid values (`10`, `14`, `18`) get rounded during later migrations (sub-projects 2–5). Rounding rule: prefer the nearest rung, round up on ties. So `10 → 12`, `14 → 16`, `18 → 16` (tie → 16, the less-spacious option, keeps density honest).
- Migrated screens will shift 1–2 pixels in places *during their respective migration sub-projects* (2–5). This sub-project itself does not shift any screen.

#### 1.2 Radius scale

**Primitive** (private `const` values inside `app_theme.dart`):

| Internal const | Value |
|------|-------|
| `_r0` | 0 |
| `_r8` | 8 |
| `_r12` | 12 |
| `_r16` | 16 |
| `_r20` | 20 |
| `_r24` | 24 |
| `_rFull` | 9999 |

Private-const because `Radius` is already a public class in `dart:ui`, and a top-level `Radius` in our library would shadow it everywhere both are imported. Private constants sidestep this entirely.

**Semantic:**

| Name | Value | Use |
|------|-------|-----|
| `AppRadius.chip` | 8 | Chips, small pills, icon-tile squares |
| `AppRadius.card` | 16 | Default raised card, including `AppCard` (was 18) |
| `AppRadius.feature` | 20 | Feature tiles, earn tiles, stat bubbles |
| `AppRadius.modal` | 24 | Modals, bottom sheets, celebration cards |
| `AppRadius.pill` | 9999 | True pills, circular elements |

**Visible change:** `AppCard`'s current `BorderRadius.circular(18)` rounds to `16` via `AppRadius.card`. This is a real but small geometric shift on any screen using `AppCard` (onboarding preference picker, profile list, selectable rows). The user explicitly approved this.

#### 1.3 Elevation scale

| Name | BoxShadow |
|------|-----------|
| `AppElevation.none` | `const <BoxShadow>[]` |
| `AppElevation.card` | `[BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black.withValues(alpha: 0.04))]` |
| `AppElevation.raised` | `[BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Colors.black.withValues(alpha: 0.08))]` |
| `AppElevation.modal` | `[BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Colors.black.withValues(alpha: 0.12))]` |

`AppElevation.card` exactly matches the shadow used everywhere today, so it is backwards-compatible, screens that pick up the new token via migration see no shadow change.

#### 1.4 Typography

Two changes to `AppText`:

1. **Consolidate `sectionTitle` (22/700) and `sheetTitle` (20/700)** into a single `AppText.title` (22/700). The two are close enough that "which do I use?" becomes a drift vector. Keep both styles' call sites mapped to `AppText.title` during the rewrite. `sectionTitle` and `sheetTitle` stay as `@deprecated` getters that forward to `title` so existing screens don't break.
2. **Document each style's purpose** inline (already mostly done) and link from `docs/design-system.md`.

Otherwise no scale rewrite. Typography is the least-broken part of the system.

#### 1.5 Color, reorganized for future dark mode

Colors move from raw names to semantic roles. The existing raw names stay as `@deprecated` aliases so nothing breaks, but new code must use the semantic names.

**Surface (backgrounds):**

| Semantic | Today's primitive |
|----------|-------------------|
| `AppColors.surface` | `cream` (#FAF8F5) |
| `AppColors.surfaceRaised` | `white` (#FFFFFF) |
| `AppColors.surfaceSelected` | `primaryPale` (#F0FDFA) |
| `AppColors.surfaceSubtle` | `creamDeep` (#F2EDE6) |

**Ink (text, icons):**

| Semantic | Today's primitive |
|----------|-------------------|
| `AppColors.ink` | (#3B3230) |
| `AppColors.inkSecondary` | (#6B5E58) |
| `AppColors.inkTertiary` | (#8A7D76) |
| `AppColors.inkInverse` | `cream` (reserved for future dark surfaces) |

**Brand:**

| Semantic | Today's primitive |
|----------|-------------------|
| `AppColors.brand` | `primary` / teal (#0D9488) |
| `AppColors.brandSubtle` | `primaryPale` (#F0FDFA) |
| `AppColors.brandStrong` | `primaryDark` (#0F766E) |

(The new semantic is named `brand`, not `accent`. The existing `AppColors.accent` is the warm gold `#F59E0B` used in nine places across five files, ``reward_glow.dart``, `games.dart`, `app_state.dart`, `home_screen.dart`, `conv_card_content.dart`. Re-using the name `accent` would have silently repainted those call sites teal. `AppColors.accent` stays as-is, pointing to warm gold, and is not deprecated.)

**Category tints (task categories):**

Eight pairs, renamed from `task*` / `task*Bg` to `category*` / `category*Bg` for semantic consistency:

- `categoryGame` / `categoryGameBg`
- `categorySurvey` / `categorySurveyBg`
- `categoryOffers` / `categoryOffersBg`
- `categoryReceipts` / `categoryReceiptsBg`
- `categoryVideo` / `categoryVideoBg`
- `categoryCheckin` / `categoryCheckinBg`

(Raw values unchanged, we're only renaming.)

**Feedback:**

- `AppColors.success`, green check (#10B981, was `taskReceipts`)
- `AppColors.flame` / `AppColors.flameBg`, streak
- `AppColors.gold`, celebration (#D4A843)

**Deprecated aliases** (kept in place so nothing breaks):

```dart
@Deprecated('Use AppColors.accent')
static const primary = Color(0xFF0D9488);
@Deprecated('Use AppColors.surface')
static const cream = Color(0xFFFAF8F5);
// ...etc for every raw name currently in AppColors
```

Flutter's analyzer will flag any remaining uses in new code. Existing screen code stays functional until each screen is migrated in sub-projects 2–5.

### 2. File layout

```
lib/theme/
  app_theme.dart        EXISTING, gets rewritten to expose primitives + semantic tokens
  app_text.dart         EXISTING, small edits: add `title`, deprecate sectionTitle/sheetTitle
  motion.dart           UNCHANGED

lib/widgets/
  app_card.dart         EXISTING, unchanged in this sub-project
  surface.dart          NEW, raised-card primitive
  list_row.dart         NEW, horizontal icon + title + subtitle + trailing
  vertical_tile.dart    NEW, icon-on-top + title + subtitle
  section_header.dart   NEW, title + optional subtitle + optional action
  stat_bubble.dart      NEW, icon + formatted value + label
  category_icon_square.dart  NEW, the 44/48 icon tile helper
  (others unchanged: app_toast, bottom_sheet_shell, breathing, fade_route,
   physical_press, press_scale, reward_glow, screen_scaffold, teal_header,
   top_glow, typewriter_text, animated_counter, animated_gradient_bg)

docs/
  design-system.md      NEW, canonical reference, linked from CLAUDE.md
  earnwise-design-system.html  EXISTING, untouched (presenter-template, not the Flutter ref)

CLAUDE.md               EXISTING, add a "Design System" section that points to docs/design-system.md
```

**One file per component.** Not a monolithic `components.dart`. Matches how Polaris/Carbon/Material organize their libraries and keeps each file small enough for Claude to hold in context.

### 3. Component APIs

Every component has these common traits:
- Reads only semantic tokens, never primitives.
- Uses `PressScale` for tap feedback when interactive.
- `haptic` defaults to `null` (chrome interactions don't fire haptics unless the caller explicitly opts in).
- `disabled: true` applies `0.45` opacity and disables `onTap`.

#### 3.1 `Surface`, raised-card primitive

```dart
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> elevation;
  final Color color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final HapticIntensity? haptic;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),  // 16
    this.radius = AppRadius.card,                              // 16
    this.elevation = AppElevation.card,
    this.color = AppColors.surfaceRaised,                      // white
    this.border,
    this.onTap,
    this.haptic,
  });
}
```

**Purpose:** the underlying raised-box primitive (`Container(decoration: BoxDecoration(color: ..., borderRadius: ..., boxShadow: ...))`) that every feature card is built on. Replaces the inline `Container(decoration: BoxDecoration(...))` pattern that recurs across the codebase (`flutter analyze` shows 66 `BoxDecoration` usages in `lib/`; most are task/category tiles, a good chunk are plain raised cards, the latter are Surface's consumers).

**Relationship to `AppCard`:** they have different jobs. `AppCard` is the *selectable choice* card with `selected: true` primary-pale fill + primary border, that's a different widget class entirely. A later cleanup can refactor `AppCard` internally to use `Surface`, but that is not part of this sub-project.

#### 3.2 `ListRow`, horizontal list item

```dart
class ListRow extends StatelessWidget {
  final Widget leading;        // usually a CategoryIconSquare
  final String title;
  final String? subtitle;
  final Widget? trailing;      // defaults to PhosphorIcons.caretRight
  final VoidCallback? onTap;
  final bool disabled;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.disabled = false,
  });
}
```

**Anatomy:**
```
┌─────────────────────────────────────────────────┐
│  [leading 48]  Title                            │
│                subtitle                    [>]  │
└─────────────────────────────────────────────────┘
       ← cardPad (16) →  ← tight (2) →   ← sm (8) →
```

**Internal composition:** `Surface(padding: EdgeInsets.all(AppSpacing.cardPad), onTap: onTap)` wrapping a `Row` with `leading`, an expanded title/subtitle column, and trailing. Title uses `AppText.bodyStrong` with `FontWeight.w700`; subtitle uses `AppText.caption.copyWith(color: AppColors.inkSecondary)`.

**Replaces:** `_taskCard` (home_screen.dart), `_buildContinueCard` (home_screen.dart), and the old `_buildSectionCard` (already removed).

#### 3.3 `VerticalTile`, icon-on-top tile

```dart
class VerticalTile extends StatelessWidget {
  final Widget leading;         // 44x44 icon square usually
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  const VerticalTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabled = false,
  });
}
```

**Anatomy:**
```
┌─────────────┐
│ [44] icon   │
│             │  ← inner (12)
│ Title       │
│             │  ← tight (2)
│ Subtitle    │
└─────────────┘
```

**Does not wrap in `Expanded`.** Callers are responsible for sizing. Typical usage: `Row(children: [Expanded(child: VerticalTile(...)), SizedBox(width: AppSpacing.rowGap), Expanded(child: VerticalTile(...)), ...])`. This is documented as the "Tile trio" pattern in `docs/design-system.md`.

**Uses:** `Surface(padding: EdgeInsets.all(AppSpacing.cardPad), radius: AppRadius.feature, onTap: onTap)`. Title uses `AppText.bodyStrong`; subtitle uses `AppText.caption.copyWith(fontWeight: FontWeight.w400)`.

**Replaces:** `_earnTile` (home_screen.dart).

#### 3.4 `SectionHeader`, section title row

```dart
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
}
```

**Anatomy:**
```
Title                              [action]
Optional subtitle                          
```

**No built-in bottom margin.** The caller picks `SizedBox(height: AppSpacing.inner)` (12) or `AppSpacing.cardPad` (16) after it depending on context. Rationale: some sections want 12, others 16, forcing one value would reintroduce the drift we're fixing. Let the caller be explicit.

Title uses `AppText.title` (the consolidated 22/700 style). Subtitle uses `AppText.caption`.

**Replaces:** inline section title `Text` widgets across all screens.

#### 3.5 `StatBubble`, stat indicator with icon, number, label

```dart
class StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;              // pre-formatted, e.g., "$12.40"
  final String label;              // e.g., "Balance", "Today"
  final Color accentColor;

  const StatBubble({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor = AppColors.brand,
  });
}
```

**Decoupled from the `starsToDollars` helper.** Caller formats the value string, so `StatBubble` has no knowledge of stars, cents, or currencies. This keeps the component reusable for future stats (streak days, goals completed, etc.).

**Replaces:** `_buildStatBubble` (home_screen.dart).

#### 3.6 `CategoryIconSquare`, colored rounded icon tile

```dart
class CategoryIconSquare extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;
  final double radius;

  const CategoryIconSquare({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 48,
    this.iconSize = 24,
    this.radius = AppRadius.chip,  // 8
  });
}
```

**Purpose:** the repeating "colored rounded square with a category icon inside" pattern used in `ListRow.leading` and `VerticalTile.leading`. Small primitive, two consumers, one source of truth.

**Typical usage:**
```dart
CategoryIconSquare(
  icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
  foreground: AppColors.categorySurvey,
  background: AppColors.categorySurveyBg,
)
```

`size: 44` is the VerticalTile default; `size: 48` (default) is the ListRow default.

### 4. `docs/design-system.md` structure

```markdown
# EarnWise Design System

> Single source of truth for EarnWise UI. Read this file before building
> or modifying any UI in `flutter_app/`. All new UI must use the semantic
> tokens and components defined here. If a pattern doesn't exist in this
> system, add it to the system BEFORE using it in a screen.

## Principles
  - Cream surface, warm voice
  - Generous whitespace; content breathes
  - Soft, physical pressability on every tap target
  - Animation serves comprehension, never decoration
  - See Voice & Writing (bottom of this file) for copy rules

## Layout & Grid
  - Page gutter (24px, managed by ScreenScaffold)
  - Vertical rhythm (4px baseline, tight exception at 2px for intra-stack)
  - Content max-width (640, reserved for tablet/desktop)

## Tokens
  ### Spacing
    - Full semantic table (from Section 1.1 of the design spec)
    - Do: use AppSpacing.rowGap between cards; AppSpacing.sectionGap between sections;
      AppSpacing.cardPad inside a Surface.
    - Don't: use raw SizedBox(height: 10) or off-grid values (10, 14, 18);
      don't use the deprecated md/lg/xl aliases in new code.
  ### Radius
    - Full semantic table
    - Do / Don't
  ### Elevation
    - Table
  ### Typography
    - Each style with size/weight and a live example phrase
  ### Color
    - Semantic palette grouped by role (surface, ink, accent, category, feedback)
    - Dark-mode migration note (future)

## Components

  Each component follows the same mini-template:

  ### ComponentName
    Purpose:   one sentence, when to reach for it
    Anatomy:   labeled ASCII diagram
    Props:     → link to lib/widgets/<name>.dart
    Variants:  only if real
    Do:        three concrete do's
    Don't:     three concrete don'ts

  Covered:
    - Surface
    - AppCard (choice card)
    - ListRow
    - VerticalTile
    - SectionHeader
    - StatBubble
    - CategoryIconSquare

## Patterns
  ### Section + card list       (SectionHeader + rowGap-separated ListRows)
  ### Hero stat row             (two StatBubbles flanking a central ring)
  ### Tile trio                 (three VerticalTiles in an Expanded row)

## Voice & Writing
  - No em-dashes (,). Use commas, periods, or semicolons.
  - Every line reads like a person spoke it. No telegraphic fragments.
  - Never minimize earnings ("a little", "pocket money"). Frame cumulative or straight.

## Migration notes (for sub-projects 2–6)
  - Replace inline Container(decoration: BoxDecoration(...)) with Surface
  - Replace _taskCard / _earnTile / _buildContinueCard with ListRow / VerticalTile
  - Replace raw SizedBox(height: N) / EdgeInsets.all(N) with AppSpacing.*
  - Dark mode: AppColors migrates to ThemeExtension<AppColorPalette>;
    AppSpacing / AppRadius / AppElevation / AppText stay static.
```

### 5. `CLAUDE.md` hook

Add a new section to `CLAUDE.md` (near the top, above "Presenter"):

```markdown
# Design System

When building or modifying UI in `flutter_app/`, read `docs/design-system.md`
before writing code. It defines the grid, spacing scale, typography, colors,
and reusable components for the Flutter app. All new UI must use the
semantic tokens and components defined there.

If a pattern doesn't exist in the system, add it to the system BEFORE using
it in a screen. This is non-negotiable.
```

That single addition is what makes `docs/design-system.md` load into Claude's context on every UI task: CLAUDE.md is pinned as project instructions, and the new section points Claude at the design-system file as a mandatory second read.

## Dark mode migration path

Flagged by the user: dark mode is coming soon. This sub-project does not implement it, but does structure tokens so the migration is surgical.

**What migrates** when dark mode lands:

- **`AppColors` only** moves to `ThemeExtension<AppColorPalette>`.
- A second palette (`AppColorPaletteDark`) is defined with dark primitives mapped to the same semantic names.
- Widgets change their color reads from `AppColors.surface` to `Theme.of(context).extension<AppColorPalette>()!.surface` (or a `context.colors` extension method for ergonomics).

**What does NOT migrate:**

- `AppSpacing`, brightness-invariant.
- `AppRadius`, brightness-invariant.
- `AppElevation`, brightness-invariant (shadow opacity might tweak, but that's one token, not the whole class).
- `AppText`, font stays the same; only text *color* changes, and color lives in `AppColors`.

So the dark mode migration surface is exactly one file (`app_theme.dart`'s color section) plus every widget that reads a color. Structuring the colors semantically now means that second part becomes a mechanical rename, not a redesign.

## Backwards compatibility

This sub-project is designed so that **no existing screen shifts pixels** except for the localized `AppCard` radius change (18 → 16). Everything else routes through deprecated aliases that preserve current values.

- **Colors.** All existing `AppColors.*` raw names (`primary`, `cream`, `creamDeep`, `taskGame`, etc.) become `@deprecated` aliases that forward to the new semantic names. Values unchanged. Existing screens keep working.
- **Spacing.** Every existing `AppSpacing.*` name stays, at its original value:
  - `AppSpacing.xs = 4` (unchanged)
  - `AppSpacing.sm = 8` (unchanged)
  - `AppSpacing.md = 16` (unchanged, marked `@deprecated`, forwards conceptually to `cardPad`)
  - `AppSpacing.lg = 24` (unchanged, marked `@deprecated`, forwards conceptually to `sectionGap`)
  - `AppSpacing.xl = 32` (unchanged, marked `@deprecated`, forwards conceptually to `blockGap`)
  New names (`tight`, `inner`, `rowGap`, `cardPad`, `titleGap`, `sectionGap`, `pageGutter`, `blockGap`, `heroGap`, `pageTop`) are added alongside. `xs` and `sm` are kept without deprecation because their values are identical in the new scale.
- **Typography.** `AppText.sectionTitle` and `AppText.sheetTitle` become `@deprecated` aliases forwarding to `AppText.title`. No size changes, so no visible shift.
- **Radius.** `AppCard` updates from hardcoded `18` to `AppRadius.card` (`16`). This is the **one** pixel shift in this sub-project and is intentional, it lives wherever `AppCard` is rendered (onboarding preference picker, profile list rows, selectable choice cards). User explicitly approved.

**What this trades off.** The cleaner long-term scale would force `md → 12` / `lg → 16` / `xl → 20`, re-anchoring the old generic names. That was the first-draft approach. Re-counting found ~36 call sites across six screens would shift simultaneously (`home_screen.dart`, `wallet_screen.dart`, `game_detail_screen.dart`, `profile_screen.dart`, `trust_carousel_screen.dart`, `welcome_screen.dart`), which violates the sub-project 1 principle of "no screen migrations, no per-screen visible shifts." The deprecated-alias approach preserves values today and lets each screen opt into the new names during its own migration in sub-projects 2–5, where a reviewer can check that one screen's pixel shifts one screen at a time.

## Testing / verification

- **Unit tests for each new component.** One test file per component in `flutter_app/test/widgets/` that:
  - Pumps the component with minimal props
  - Asserts the expected text/icon is present
  - Asserts `onTap` fires when the component is interactive
  - Asserts `disabled: true` prevents `onTap`
- **Token file tests.** A small `theme_tokens_test.dart` that:
  - Verifies every `AppSpacing.*` value is a multiple of 4 (or is `tight = 2`).
  - Verifies every `AppRadius.*` value is one of `{0, 8, 12, 16, 20, 24, 9999}`.
- **Deprecation lint.** Run `flutter analyze` after the rewrite. The deprecated aliases should *not* produce warnings in existing screen code (because the aliases are valid, just deprecated). New code in the 6 new components must not reference any deprecated name, verify by grep before merging.
- **Whole-suite regression.** `flutter test` must pass. Existing 52 screen tests must stay green because no screen is touched in this sub-project.
- **Visual smoke test.** Run `flutter run -d chrome` and verify:
  - Onboarding flow (welcome, trust carousel, onboarding) still renders correctly, `AppCard` radius change from 18 → 16 is visible on the preference choice cards.
  - Home, wallet, profile, game-detail all render identically to before, since the existing `AppSpacing.xs/sm/md/lg/xl` values are preserved. Spot-check each for any unexpected spacing drift.
  - Profile screen and any screen using `AppCard` picks up the new 16-radius correctly.

## Out of scope (explicit)

These are intentionally left for later sub-projects:

1. **Screen migrations.** No file in `lib/screens/` is modified at all.
2. **`AppCard` internal refactor** to wrap `Surface`. Later cleanup.
3. **Lint rules / custom analyzers** that flag raw `EdgeInsets.all(10)` etc. Sub-project 6.
4. **`ThemeExtension` migration.** Happens when dark mode lands, not now.
5. **Dark palette definitions.** Happens when dark mode lands.
6. **Deleting or moving `docs/earnwise-design-system.html`.** Untouched, that's a presenter-template file, not the Flutter app reference.

## Non-goals

- **Pixel-perfect parity with the current app long-term.** The whole point is that the current app has drift; preserving that drift defeats the purpose. `AppCard` radius changes 18 → 16 in this sub-project, and during sub-projects 2–5 more small shifts will happen as each screen migrates off the deprecated `xs/sm/md/lg/xl` aliases onto `inner`/`cardPad`/`titleGap`/etc. This is the fix, not a regression.
- **A designer-facing doc.** `docs/design-system.md` is a developer reference optimized for Claude and the developer to read while building. It is not a style-guide website.
- **Comprehensive coverage of every widget in the app.** This sub-project extracts the 6 widgets that currently have the most duplication pain. More widgets may be added later as new patterns emerge.

## Open questions

One item needs user confirmation at the spec review gate:

- **Spacing-scale naming reversal.** The first draft reused `xs/sm/md/lg/xl` for the new 4/8/12/16/20 rungs, which meant `md`, `lg`, and `xl` would have shifted values (16→12, 24→16, 32→20). On self-review this was found to affect ~36 call sites across six screens, larger than the 5-site scope the user approved during brainstorming. This spec now preserves `md/lg/xl` at their current values as `@deprecated` aliases and uses new intent-specific names (`inner`, `cardPad`, `titleGap`) for the new rungs. Result: **sub-project 1 produces zero spacing-driven pixel shifts**, and per-screen migrations in sub-projects 2–5 each opt into the new names screen-by-screen. Confirm this is the desired trade-off, or ask to revert to the original "shift the generic names" approach.

## Decomposition reference

This sub-project is #1 of 6 in the Design System initiative. The full list:

| # | Sub-project | Touches |
|---|---|---|
| **1 (this one)** | Foundation + Reference Doc | `lib/theme/`, `lib/widgets/` (new files), `docs/design-system.md`, `CLAUDE.md` |
| 2 | Home migration | `lib/screens/home_screen.dart` |
| 3 | Wallet migration | `lib/screens/wallet_screen.dart` |
| 4 | Onboarding flow migration | `welcome_screen.dart`, `trust_carousel_screen.dart`, `onboarding_screen.dart` |
| 5 | Secondary screens migration | `profile_screen.dart`, `game_detail_screen.dart`, `journey_screen.dart`, `placeholder_list_screen.dart` |
| 6 | (optional) Enforcement tooling | Custom lint rule or test that fails on off-grid values in `lib/screens/` |

Each subsequent sub-project is independent and small enough for its own spec + plan cycle. They do not have to happen in order, and they do not have to happen back-to-back.
