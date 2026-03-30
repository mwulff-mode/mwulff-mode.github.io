# Illustration & Animation Direction

> **Date:** 2026-03-11
> **Status:** Decided
> **Usage:** Brief for illustrators, animators, and AI agents generating visual assets. Feed this to any tool producing illustrations, icons, or Lottie animations for [APP_NAME].

---

## Part 1: Illustration — "Gentle Linework"

### Style Summary

Flowing continuous-line illustrations in deep sage, with transparent watercolor washes in the brand palette. Think elegant editorial line art — confident strokes drawn without lifting the pen, not sketchy doodles. The lines are smooth and deliberate with gentle organic curves and the natural imperfection of a skilled hand.

**Energy levels:** Illustrations split into two modes based on context:
- **Calm/grounded** — task and navigation moments (mailbox, coffee, survey, empty state). Stable compositions, objects at rest.
- **Dynamic/bouncy** — money and reward moments (coin drop, wallet cashout, high five, streak). Floating elements, tilted angles, motion lines. These are the payoff — they should feel alive.

This maps to the emotional arc of the app: calm task → dynamic reward. The dynamic illustrations also pair naturally with the Sage Sparkle Lottie animation.

### Why This Style

Research on [mobile design for older adults](https://pmc.ncbi.nlm.nih.gov/articles/PMC12350549/) emphasizes clarity, high contrast, and meaningful visual elements over decoration. These line illustrations:
- Are **high-contrast** (sage on cream) and legible at small sizes
- **Communicate function** — each one tells you what the screen does before you read a word
- Feel **handcrafted and trustworthy** — the [2026 illustration trend](https://www.creativebloq.com/art/illustration/messy-meaningful-and-made-by-humans-the-biggest-illustration-trends-for-2026) is toward human imperfection as a trust signal
- Stay **warm without being cute** — the piggy bank sprout is charming, not cartoonish
- Build a **consistent visual language** no competitor can copy with a stock library

---

### AI / Illustrator Style Reference Prompt

```
Elegant spot illustration in a flowing continuous-line style.
Confident single-weight strokes in deep sage green (#4A6F4A) on
warm cream (#FAF8F5) background. Lines are smooth and deliberate
with gentle organic curves — not sketchy or wobbly, but with the
natural imperfection of a skilled hand drawing without lifting the
pen. Soft transparent watercolor washes in muted blush pink
(#F2DCD9), pale lavender (#E2DCF0), and sage-light (#D4E6D5) at
30–40% opacity, bleeding slightly past the linework. Rounded stroke
terminals. No faces on people, only hands and simple silhouettes.
No gradients, no hard shadows, no outlines on the color fills.
Minimal, airy composition with generous white space. The feel is:
a confident illustrator drew this in one graceful pass with a
fine-tip pen, then added two breaths of watercolor. Warm, calm,
trustworthy, grown-up. Think modern continuous-line art meets
Matisse — editorial, not cutesy.
```

### Per-Asset Prompts

Append each to the style reference prompt above:

**Dynamic / money illustrations** (floating elements, tilted angles, motion energy):

| Asset | Prompt |
|-------|--------|
| Piggy bank sprout | A piggy bank seen from the side with a small leafy sprout growing from the coin slot. One leaf in blush, one in lavender. A coin floats mid-drop above the slot. |
| Coin drop | A hand gently dropping a coin into a glass jar that is one-third full. The jar has a small heart on it. Coins inside have a slight scattered, lively arrangement. |
| Cashout wallet | An open bifold wallet at a dynamic tilted angle with a card peeking out that has the PayPal logo suggested as two overlapping circles. A few coins float and bounce nearby with small motion lines. |
| High five | Two hands meeting in a high-five, seen from the side. Small motion lines around the contact point. One wrist has a simple watch, the other a bracelet. Energy radiates from the contact. |
| Streak flame | A candle with a steady flame shaped like a leaf, sitting on a small saucer. Three tiny tally marks etched on the candle. The flame has gentle movement lines suggesting warmth rising. |

**Calm / task illustrations** (grounded, stable, objects at rest):

| Asset | Prompt |
|-------|--------|
| Mailbox | A round-topped mailbox with an envelope peeking out, a tiny star next to it suggesting something new. Stable, centered composition. |
| Coffee earning | A coffee cup from above with a subtle dollar sign formed in the steam curl. A small coin rests on the saucer. Calm and centered. |
| Receipt scan | A magnifying glass hovering over a receipt. A small checkmark floats above the glass. Quiet, focused composition. |
| Survey complete | A chat bubble with three small checkmarks inside, a tiny pencil resting against it at an angle. Still and grounded. |
| Empty state | A small bird perched on an empty branch, looking curious. One leaf is starting to bud. Hopeful, not sad. |

---

### Delivery Specs

```
Deliverables:  10 spot illustrations, SVG + PNG @2x
Artboard:      240×240px each, centered with 20% padding
Stroke:        Confident continuous line, ~2px, round cap, round join
Fills:         Max 2 accent washes at full opacity per illustration;
               a 3rd color allowed as subtle background bleed at <20%
               Palette: #F2DCD9 (blush), #E2DCF0 (lavender), #D4E6D5 (sage-light)
               Wash opacity: 30–40%
Line color:    #4A6F4A (deep sage)
Background:    Transparent (cream is applied by the app)
No:            Faces, gradients, hard shadows, outlines on fills
Yes:           Flowing lines, warmth, breathing room, rounded endings
Energy:        Calm/grounded for task illustrations;
               dynamic/bouncy (floating elements, tilted angles) for money illustrations
```

---

### Icon Set Spec

For the 20–30 functional icons (nav, actions, status), use a matching 2px rounded line style but geometrically cleaner than the spot illustrations:

| Property | Value |
|----------|-------|
| Grid | 24×24px |
| Stroke | 2px, rounded caps and joins |
| Active color | Sage (#5E8A60) |
| Inactive color | Neutral (#9E968B) |
| Selected state | Same shape, sage fill at 12% opacity behind stroke |
| Export | SVG |

No emoji in production — the emoji in current Figma mockups are placeholders. Custom icons in this line style are what makes the brand feel owned, not rented.

---

### What to Avoid (With Rationale)

| Style | Why not |
|-------|---------|
| Generic flat illustration (Undraw, Humaaans) | Every fintech uses these — signals "we didn't invest in brand" |
| 3D / Blush renders | Skews young, feels like a gaming app |
| Photographic imagery | Hard to maintain consistency, expensive to produce for every state |
| Mascot character | Risky for 40–65 audience; can feel patronizing if misjudged |
| Overly polished vector art | In 2026, audiences read perfection as AI-generated and lose trust |

### Commissioning Notes

Brief a **single illustrator** (not a team) to draw all 10 spots + the icon set. One hand = one consistent wobble. Budget for 2–3 days of work. Deliver as SVG so Flutter renders them crisply at any scale, and you can programmatically swap stroke color if design direction evolves.

---

## Part 2: Animation — "Sage Sparkle" (Celebration Lottie)

### Concept

A reusable 1.5-second loop-once animation that works as overlay on any success moment — task completed, reward claimed, streak continued, cashout confirmed. A soft burst of organic shapes radiating from center, like a dandelion puff catching light.

### Phase Breakdown

**Phase 1 — Center Origin (0–0.3s):**
A sage circle (#5E8A60) scales from 0% to 100% at ~40px diameter, then fades to 0% opacity by 0.6s. This is the "seed" — gives the eye a focal point before the burst.

**Phase 2 — Petal Burst (0.2–1.0s):**
12 rounded shapes emerge from center in a radial pattern, staggered in 3 waves of 4:
- **Wave 1 (0.2s):** 4 sage ellipses (#D4E6D5), 80% opacity, travel ~60px outward
- **Wave 2 (0.35s):** 4 blush circles (#F2DCD9), 70% opacity, travel ~80px outward
- **Wave 3 (0.5s):** 4 lavender dots (#E2DCF0), 60% opacity, travel ~50px outward

Each shape is a soft ellipse (roughly 1:1.3 ratio), rotating 20–40° as it drifts. All movements use **ease-out-cubic** (start fast, decelerate gently). Each shape scales down from 100% to 40% and fades to 0% opacity by the end of its journey.

**Phase 3 — Shimmer Dots (0.4–1.2s):**
6 tiny circles (3–5px) in sage (#8BAB8D) at 50% opacity drift upward with a gentle left-right wobble (±4px sinusoidal), fading out over 0.6s each. These feel like warmth rising — not sparks.

**Full settle by 1.5s.** Nothing remains on screen.

### Technical Spec

```
Canvas:       300×300px (transparent)
Duration:     1.5s (~45 frames at 30fps)
Total shapes: 19 (1 center + 12 petals + 6 shimmer dots)
Palette:      #5E8A60, #D4E6D5, #F2DCD9, #E2DCF0, #8BAB8D
Easing:       ease-out-cubic on all position/scale
              linear on opacity fade-out
Shape style:  Rounded ellipses, no hard edges, no strokes
Export:       Lottie JSON, bodymovin, <50kb target
```

### Usage Matrix

| Trigger | Placement | Scale |
|---------|-----------|-------|
| Task completed | Centered on task card | 0.6× |
| Daily check-in | Behind the check icon | 0.5× |
| Cashout confirmed | Centered on balance card | 1.0× |
| Streak milestone | Behind streak counter | 0.7× |
| First-time actions | Centered on screen | 1.2× |

**Rule: Scale it, don't redesign it.** One animation, one identity.

---

## Part 3: "Piggy Bloom" — Extended Cashout Animation

### Concept

When a user hits a major milestone (cashout, earnings goal, streak), the ring progress completes and blooms outward — like a piggy bank overflowing with warmth rather than exploding with confetti.

### The Sequence (~2.2 seconds)

**Phase 1 — Ring Fills (0–0.6s):**
Ring progress smoothly animates to 100%. White stroke thickens slightly (7px → 9px) as it completes, with a subtle ease-out that decelerates into the final position. Balance text scales up gently from 100% → 108% → 100% with a soft spring curve.

**Phase 2 — Bloom (0.6–1.2s):**
The completed ring emits 8–10 soft petal shapes — rounded ellipses in sage (#D4E6D5), blush (#F2DCD9), and lavender (#E2DCF0) at 60–80% opacity. They drift outward radially with slow deceleration, rotating 15–30° as they travel. Each petal is slightly different in size (12–24px) and delay (staggered by 40ms). They fade out as they reach ~120px from center.

Simultaneously, 5–6 tiny circles (4–6px) in sage and blush float upward with a gentle sinusoidal wobble — like bubbles, not sparks. They fade over 0.8s.

**Phase 3 — Glow + Message (1.0–2.2s):**
A radial glow (#5E8A60 at 8% opacity, 200px radius) pulses once behind the balance card, then fades. Card shadow briefly intensifies (spread 32px → 48px → 32px).

Success message fades up below the ring:
> "You earned $25.00!"

Nunito Bold 18px, white, with 0.3s fade-in and slight upward drift (8px). Smaller line beneath: "Cashing out to PayPal" in Nunito Regular 13px, white at 65% opacity.

**Phase 4 — Settle (2.0–2.2s):**
Everything returns to resting state. Petals are gone, glow is gone, text remains for 3 seconds then fades.

### Piggy Bloom Design Principles

| Principle | How the animation honors it |
|-----------|-----------------------------|
| Warm, not flashy | Organic petals and bubbles instead of confetti or fireworks |
| Sage/blush/lavender palette | Every particle uses existing brand colors at reduced opacity |
| Rounded and soft | All shapes are ellipses and circles — no sharp edges, no straight-line bursts |
| Trustworthy for 45+ | Slow, legible, no screen shake or strobing |
| Financially grounded | The ring (progress toward a real goal) is the anchor, not a cartoon character |
| Nunito personality | The rounded font carries through to the rounded particle shapes |

---

## Animation: What to Avoid

| Avoid | Why |
|-------|-----|
| Confetti | Reads as frivolous for a money app targeting 45+ |
| Sound effects | Optional gentle chime at most; default to silent |
| Screen takeover | Animation stays contained within/around the balance card |
| Looping | Plays once, settles. Respect for the user's time. |
| Geometric precision | Perfect circles and straight lines feel cold and computed |
| Bouncing/snapping easing | Decelerating motion feels calmer and more natural |

---

## Easing Curves Reference

| Curve | Where used |
|-------|-----------|
| ease-out-cubic | All position and scale movements (start fast, decelerate gently) |
| linear | Opacity fade-outs |
| soft spring (100% → 108% → 100%) | Balance text scale on milestone |

---

## Flutter Implementation Notes

Both animations map cleanly to Lottie or Flutter's `AnimationController` + `CustomPainter`:
- Petals: pre-rendered ellipses on a `Stack` with `SlideTransition` + `FadeTransition` + `RotationTransition`
- Ring fill: `TweenAnimationBuilder` on a `CircularProgressIndicator` or custom arc painter
- Total particle count stays under 16 — lightweight on older devices

---

## Sources

- [Illustration Trends 2026 — Creative Bloq](https://www.creativebloq.com/art/illustration/messy-meaningful-and-made-by-humans-the-biggest-illustration-trends-for-2026)
- [Icon Design Trends 2026 — Envato](https://elements.envato.com/learn/icon-design-trends)
- [Mobile App Design for Older Adults — PMC Systematic Review (2025)](https://pmc.ncbi.nlm.nih.gov/articles/PMC12350549/)
- [Graphic Design Trends 2026 — Kittl](https://www.kittl.com/blogs/graphic-design-trends-2026/)
