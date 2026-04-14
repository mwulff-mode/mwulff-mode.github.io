# EarnWise Design System

> Single source of truth for EarnWise Flutter UI. Read this file before
> building or modifying any UI in `flutter_app/`. All new UI must use the
> semantic tokens and components defined here. If a pattern does not
> exist in this system, add it to the system before using it in a screen.

## Principles

- Cream surface, warm voice.
- Generous whitespace; content breathes.
- Soft, physical pressability on every tap target.
- Animation serves comprehension, never decoration.
- Every line of copy sounds like a person spoke it. See Voice & Writing.

## Layout & Grid

- Page gutter: 24px (`AppSpacing.pageGutter`, applied by `ScreenScaffold`).
- Vertical rhythm: 4px baseline grid. The only sub-4 value is
  `AppSpacing.tight` (2px), reserved for intra-component title to
  subtitle stacks.
- Content max width: 640px (`AppLayout.maxContentWidth`), reserved for
  tablet and desktop viewports.

## Tokens

### Spacing

| Name | Value | Purpose |
|------|-------|---------|
| `AppSpacing.tight` | 2 | Title to subtitle intra-stack (named exception) |
| `AppSpacing.xs` | 4 | Icon to label gap inside a single unit |
| `AppSpacing.sm` | 8 | Tight horizontal gap |
| `AppSpacing.inner` | 12 | Intra-card content step |
| `AppSpacing.rowGap` | 12 | Between consecutive rows or cards in a list |
| `AppSpacing.cardPad` | 16 | Default card inner padding |
| `AppSpacing.titleGap` | 20 | Around titles / above a big stack element |
| `AppSpacing.sectionGap` | 24 | Between sections on a page |
| `AppSpacing.pageGutter` | 24 | Page left/right gutter |
| `AppSpacing.blockGap` | 32 | Between major page blocks |
| `AppSpacing.heroGap` | 40 | Around hero elements |
| `AppSpacing.pageTop` | 48 | Top of a scrollable page |

**Do:**
- Use `AppSpacing.rowGap` between consecutive list rows or cards.
- Use `AppSpacing.sectionGap` between sections on a page.
- Use `AppSpacing.cardPad` inside a `Surface`.

**Do not:**
- Use raw ints in `SizedBox(height: N)` or `EdgeInsets.all(N)` in new code.
- Use off-grid values (`10`, `14`, `18`). Round to the nearest rung; on a
  tie, round up.
- Use the deprecated `AppSpacing.md`, `lg`, `xl` aliases in new code. Their
  new semantic homes are `cardPad`, `sectionGap` (or `pageGutter`), and
  `blockGap` respectively.

### Radius

| Name | Value | Use |
|------|-------|-----|
| `AppRadius.chip` | 8 | Chips, small pills, `CategoryIconSquare` |
| `AppRadius.card` | 16 | Default raised card, `AppCard`, `Surface` |
| `AppRadius.feature` | 20 | Feature tiles, earn tiles, stat bubbles |
| `AppRadius.modal` | 24 | Modals, bottom sheets, celebration cards |
| `AppRadius.pill` | 9999 | True pills and circular elements |

### Elevation

| Name | Shape |
|------|-------|
| `AppElevation.none` | Empty list (no shadow) |
| `AppElevation.card` | 1 drop: offset(0, 2), blur 8, `black.withAlpha(.04)` |
| `AppElevation.raised` | 1 drop: offset(0, 4), blur 16, `black.withAlpha(.08)` |
| `AppElevation.modal` | 1 drop: offset(0, 8), blur 24, `black.withAlpha(.12)` |

`AppElevation.card` matches the shadow used everywhere in the app today;
migrating to it never changes a pixel.

### Typography

See `lib/theme/app_text.dart`. The canonical styles are:

| Style | Size / weight | Use |
|-------|---------------|-----|
| `AppText.heroAmount` | 64 / 800 | Welcome gift, hero amounts |
| `AppText.display` | 48 / 800 | Name input, hero numbers |
| `AppText.brandMark` | 38 / 800 | "EarnWise" brand mark |
| `AppText.ringGoal` | 32 / 800 | Progress ring center number |
| `AppText.gameTitle` | 28 / 800 | Game detail page title |
| `AppText.slideTitle` | 26 / 800 | Trust carousel slide title |
| `AppText.prompt` | 24 / 700 | Onboarding prompt questions |
| `AppText.title` | 22 / 700 | **Section and page titles** (canonical heading) |
| `AppText.statNumber` | 20 / 800 | Stat bubble number |
| `AppText.ctaLabel` | 20 / 600 (white) | Primary button label |
| `AppText.listItem` | 17 / 600 | List row titles, tagline, primary body |
| `AppText.bodyStrong` | 16 / 600 | Emphasized body, toast title |
| `AppText.body` | 15 / 500 | Subcopy, descriptions, secondary text |
| `AppText.caption` | 14 / 600 | Meta labels, pill labels, captions |

`AppText.sectionTitle` and `AppText.sheetTitle` are deprecated forwarders
that return `AppText.title`. Use `title` directly in new code.

### Color

Grouped by role. Every semantic name has a stable meaning, do not assume
any two names with the same current value are interchangeable, since they
may diverge when dark mode lands.

**Surface (backgrounds):**
- `AppColors.surface`, cream (#FAF8F5). The default page background.
- `AppColors.surfaceRaised`, white (#FFFFFF). Default card background.
- `AppColors.surfaceSelected`, brand pale (#F0FDFA). Selected-state fill.
- `AppColors.surfaceSubtle`, cream deep (#F2EDE6). Secondary surfaces,
  dividers.

**Ink (text, icons):**
- `AppColors.ink`, primary (#3B3230)
- `AppColors.inkSecondary`, #6B5E58
- `AppColors.inkTertiary`, #8A7D76
- `AppColors.inkInverse`, cream (reserved for future dark surfaces)

**Brand (teal):**
- `AppColors.brand`, #0D9488
- `AppColors.brandSubtle`, #F0FDFA
- `AppColors.brandStrong`, #0F766E

**Category tints** (each has a foreground and background):
- `AppColors.categoryGame` / `categoryGameBg`
- `AppColors.categorySurvey` / `categorySurveyBg`
- `AppColors.categoryOffers` / `categoryOffersBg`
- `AppColors.categoryReceipts` / `categoryReceiptsBg`
- `AppColors.categoryVideo` / `categoryVideoBg`
- `AppColors.categoryCheckin` / `categoryCheckinBg`

**Feedback:**
- `AppColors.success`, #10B981 (same value as `categoryReceipts`,
  semantically distinct)
- `AppColors.flame` / `AppColors.flameBg`, streak
- `AppColors.gold`, celebration (#D4A843)

**Dark-mode note.** When dark mode lands, `AppColors` migrates to a
`ThemeExtension<AppColorPalette>` so each semantic name points at a
different primitive under `Theme.of(context).brightness == dark`. Spacing,
radius, elevation, and typography stay static because they are
brightness-invariant.

## Components

Each component follows the same mini-template:

- **Purpose:** one sentence, when to reach for it
- **Anatomy:** labeled diagram
- **Props:** link to the source file
- **Do / Don't:** three each

### Surface

**Purpose:** raised-card primitive. The foundation every feature card is
built on.

**Props:** `lib/widgets/surface.dart`. Fields: `child`, `padding`
(default `cardPad`), `radius` (default `AppRadius.card`), `elevation`
(default `AppElevation.card`), `color` (default `surfaceRaised`), `border`,
`onTap`, `haptic`.

**Do:**
- Use as the base for any new card-shaped container.
- Override `radius: AppRadius.feature` for feature tiles.
- Wire `onTap` to get PressScale feedback for free.

**Don't:**
- Use for selectable choice cards, use `AppCard` instead.
- Reach into `BoxDecoration` directly in new screen code. Let `Surface`
  own the decoration.
- Use raw shadow objects. Compose with `AppElevation.*` only.

### AppCard

**Purpose:** the selectable "choice card" pattern, with an active
`selected` state (brand-pale fill, brand border). Used in multi-select
lists like the onboarding preference picker.

**Props:** `lib/widgets/app_card.dart`. Fields: `child`, `padding`,
`onTap`, `selected`, `constraints`, `haptic`.

**Do:**
- Use for list items that have a checked state.
- Use `selected: true` to apply the active fill and border.
- Leave `haptic: null` on purely navigational choice cards.

**Don't:**
- Use as a generic card. Reach for `Surface` instead, `Surface` has no
  border and composes cleaner.
- Override the border color inline. If you need a different border, you
  likely need a different component.
- Nest `AppCard` inside `Surface` or vice versa.

### ListRow

**Purpose:** horizontal list item with leading icon, title, optional
subtitle, optional trailing (defaults to a caret-right chevron).

**Props:** `lib/widgets/list_row.dart`. Fields: `leading`, `title`,
`subtitle`, `trailing`, `onTap`, `disabled`.

**Do:**
- Use `CategoryIconSquare` as the `leading` for category rows.
- Let the default caret-right chevron show for navigational rows.
- Use `disabled: true` for rows the user cannot act on yet.

**Don't:**
- Hardcode a `Surface` around a `ListRow`, `ListRow` is already a
  `Surface` under the hood.
- Use for complex multi-control rows (toggle + text + detail link). That
  is a custom composition, not a ListRow.
- Mix a subtitle with multi-line custom `trailing`. Keep trailing simple.

### VerticalTile

**Purpose:** icon-on-top tile used as the unit of the Tile-trio pattern
(three tiles in a row).

**Props:** `lib/widgets/vertical_tile.dart`. Fields: `leading`, `title`,
`subtitle`, `onTap`, `disabled`.

**Do:**
- Wrap in `Expanded` at the call site so three tiles share a row evenly.
- Separate tiles with `SizedBox(width: AppSpacing.rowGap)`.
- Use a 44-size `CategoryIconSquare` as the `leading`.

**Don't:**
- Put four or more tiles in one row. Three is the pattern.
- Override the radius. `VerticalTile` uses `AppRadius.feature` on
  purpose.
- Let `subtitle` line-wrap more than once. Rewrite the copy.

### SectionHeader

**Purpose:** title row at the top of a section, optionally with a
subtitle and/or a trailing action (e.g., "See all").

**Props:** `lib/widgets/section_header.dart`. Fields: `title`, `subtitle`,
`action`.

**Do:**
- Use for every section on every screen.
- Pair with `SizedBox(height: AppSpacing.inner)` or `AppSpacing.cardPad`
  below it depending on how dense the section content is.
- Keep titles 1 to 3 words. Subtitles one short sentence.

**Don't:**
- Add a bottom margin inside `SectionHeader`. Let the caller decide.
- Use for the page title at the very top of a screen. That is
  `ScreenScaffold` territory.
- Put more than one trailing action. One action, one choice.

### StatBubble

**Purpose:** stat indicator: accent icon, pre-formatted value,
caption label. Used for Balance and Today bubbles flanking the ring on
the home screen.

**Props:** `lib/widgets/stat_bubble.dart`. Fields: `icon`, `value`,
`label`, `accentColor` (default `AppColors.brand`).

**Do:**
- Pre-format the `value` string at the call site. The widget is
  currency-agnostic.
- Override `accentColor` for non-earnings stats (flame for streak, for
  example).
- Keep labels one word.

**Don't:**
- Pass a number to `value`. Format it first.
- Use for the ring center number. That is `AppText.ringGoal`.
- Add a background. `StatBubble` is intentionally chrome-less.

### CategoryIconSquare

**Purpose:** colored rounded square with a category icon inside. Used as
the `leading` of `ListRow` (48x48) and `VerticalTile` (typically 44x44).

**Props:** `lib/widgets/category_icon_square.dart`. Fields: `icon`,
`foreground`, `background`, `size` (default 48), `iconSize` (default 24),
`radius` (default `AppRadius.chip`).

**Do:**
- Pair `foreground` and `background` from the same category (e.g.,
  `categorySurvey` and `categorySurveyBg`).
- Override `size: 44, iconSize: 22` for `VerticalTile`.
- Reuse across screens, this is a pure primitive with no state.

**Don't:**
- Pass mismatched foreground and background (e.g., survey foreground on
  game background). Pick one category.
- Use for a circular badge. That is a different widget.
- Override radius unless you are building a new variant with a good
  reason.

## Patterns

### Section + card list

```dart
SectionHeader(title: 'Today\'s tasks'),
const SizedBox(height: AppSpacing.inner),
ListRow(leading: ..., title: 'Daily survey', subtitle: '+\$0.50', onTap: ...),
const SizedBox(height: AppSpacing.rowGap),
ListRow(leading: ..., title: 'Quick video', subtitle: '+\$0.25', onTap: ...),
```

### Hero stat row

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    StatBubble(icon: ..., value: '\$12.40', label: 'Balance'),
    const DailyGoalRing(...),
    StatBubble(icon: ..., value: '4', label: 'Today'),
  ],
),
```

### Tile trio (Earn More)

```dart
Row(
  children: [
    Expanded(child: VerticalTile(leading: ..., title: 'Offers', subtitle: 'Save & earn', onTap: ...)),
    const SizedBox(width: AppSpacing.rowGap),
    Expanded(child: VerticalTile(leading: ..., title: 'Receipts', subtitle: 'Cashback', onTap: ...)),
    const SizedBox(width: AppSpacing.rowGap),
    Expanded(child: VerticalTile(leading: ..., title: 'Games', subtitle: 'Play & earn', onTap: ...)),
  ],
),
```

## Voice & Writing

- No em-dashes (the long-dash character). Use commas, periods, or
  semicolons. This is a hard rule in the EarnWise project.
- Every line of copy reads like a person spoke it. No telegraphic
  fragments ("Not eligible.", "Coming soon.").
- Never minimize earnings. No "a little", "pocket money", or "spare
  change". Frame earnings straight or cumulative.

## Migration notes (sub-projects 2 through 6)

- Replace inline `Container(decoration: BoxDecoration(...))` raised cards
  with `Surface`.
- Replace inline `_taskCard`, `_earnTile`, `_buildContinueCard`, and
  `_buildSectionCard` helpers with `ListRow` / `VerticalTile`.
- Replace raw `SizedBox(height: N)` and `EdgeInsets.all(N)` with
  `AppSpacing.*`. Round off-grid values per the rules above.
- Migrate call sites away from `AppSpacing.md`, `lg`, `xl` (deprecated)
  onto `cardPad`, `sectionGap`, `blockGap`.
- Migrate call sites away from `AppColors.task*`, `primary`, `cream`,
  `creamDeep`, `white`, `primaryPale`, `primaryDark` (all deprecated)
  onto the semantic names.
- When dark mode lands, `AppColors` migrates to
  `ThemeExtension<AppColorPalette>`; `AppSpacing`, `AppRadius`,
  `AppElevation`, and `AppText` stay static.
