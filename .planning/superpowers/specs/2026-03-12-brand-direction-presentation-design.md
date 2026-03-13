# Brand Direction Presentation — Design Spec

**Date:** 2026-03-12
**Source:** "From Alignment to Direction" brand brief
**Audience:** Internal team (same group from the core alignment session)
**Approach:** Show, Don't Tell — visual-forward, ~5 minute read
**Output:** `output/from-alignment-to-direction.html`

---

## Structure: 8 Sections

### 1. Hero
- Title: "From Alignment to Direction"
- Subtitle: "We aligned on who we're building for and what we stand for. This is what those decisions look like."
- Meta: ~5 min read, feedback requested at the end

### 2. Quick Recap — What We Aligned On
- Four compact cards, one per alignment decision:
  - **Who**: Smart Earners, 40–65
  - **What we stand for**: Simplicity · Reliability · Valuable
  - **What we're not**: Confusing · Spammy · Cold
  - **How we communicate**: Encouraging, real dollars, soft & rounded
- No narrative — just a reference anchor

### 3. Who She Is
Three beats, compact:
1. **The Financial Reality** — 2-3 stats as metric cards (65% finances as top stressor, 37% can't cover $400 emergency). Summary: "She's not desperate — she's cautious. $50/month changes her week."
2. **The "Being Seen" Insight** — Callout. "She feels invisible. Undervalued at work, overlooked by products built for younger demographics. Our opportunity: make her feel recognized and smart for what she does."
3. **The Trust Threshold** — One line: "She deletes anything scammy within 30 seconds. Trust isn't a feature — it's the baseline."

### 4. From Values to Visual
- Intro: "Our alignment decisions already answered most of the design questions. We just had to follow them."
- Two-column table:

| Because we said… | The direction… |
|---|---|
| Simplicity | Generous white space, big type, one action per screen |
| Reliability | Grounded and calm. Real dollars always the largest element |
| Valuable | Earnings anchored to real expenses she recognizes |
| Encouraging | Speaks like a helpful neighbor, not a corporation |
| Soft & rounded | Warm palette, rounded type, gentle shadows |
| Not spammy | Celebrates with warmth, not fireworks |
| Not cold | Hand-drawn illustration and human touch |

### 5. The Design Direction
Three sub-areas in one section:

**Palette**
- Color swatches rendered in CSS with labels:
  - Sage green — trust, calm, growth
  - Blush & lavender — warmth without "pink"
  - Warm cream — paper, not screen
- Note: "Nothing shouts. The only thing that pops is the dollar amount."

**Typography**
- Outfit specimen at headline and body sizes
- Dollar amounts displayed largest
- Caption: "The type does the work so the design doesn't have to be loud."

**Illustration**
- User-provided illustration examples embedded as images
- Caption: Continuous-line in deep sage, watercolor washes at 30-40% opacity, no faces, two energy levels (calm task → dynamic reward)

### 6. The Voice
- Comparison table (our voice vs. not our voice):

| Moment | Our voice | Not our voice |
|---|---|---|
| First earning | "Nice — you just earned $0.25. It adds up faster than you think." | "Ka-ching! $0.25 earned! Keep going to unlock more!" |
| Balance | "$12.40 earned — that's half a tank of gas." | "Balance: $12.40" |
| Cashout | "Your $10.00 is on its way to PayPal." | "Woohoo! $10 cashed out! Treat yourself!" |
| Re-engagement | "You have 3 new surveys. Estimated: $1.50." | "Don't miss out! Your rewards are waiting!" |

- Callout with earnings rule: "Never let her do the math. Anchor to real expenses, lead with cumulative totals, frame time as context not labor."

### 7. See It Together
- Onboarding screenshots embedded (grid or sequence)
- Link to clickable prototype
- Framing: "Don't analyze individual screens — just notice how it feels."

### 8. Your Feedback + Next Steps
**Feedback grid** — 5-dimension scale:

| Dimension | Too much ← | Just right | → Not enough |
|---|---|---|---|
| Warmth | Too cozy / soft | | Too cold / clinical |
| Professionalism | Too corporate | | Too casual |
| Playfulness | Too cute / childish | | Too serious / dry |
| Trust | Too cautious / boring | | Untrustworthy / gimmicky |
| Energy | Too calm / sleepy | | Too loud / hyped |

Open question: "If you had to describe how this app feels in 3 words, what would they be?"

**Next steps:**
- Direction refinement based on feedback
- Name & tagline brainstorm (separate session, informed by this feedback)

---

## Assets (in `assets/earnwise_v01/`)

**Onboarding screenshots (Section 7):**
- `01_Start.png`
- `02_Info.png`
- `03_Questionnaire.png`
- `04_First Task.png`
- `05_Home.png`

**Illustration examples (Section 5):**
- `wallet.png` — calm task moment
- `jar.png` — reward moment
- `surveys.png` — task moment

**Clickable prototype (Section 7):**
- `onboarding.html` — linked from the presentation

All assets will be base64-encoded inline to keep the presentation self-contained, except the prototype which will be a relative link.

## Technical Notes
- Single HTML file, inline CSS/JS, D3.js v7 from CDN
- Follow template.html patterns and CSS variables
- Black & white design language per CLAUDE.md
- Responsive, accessible, prefers-reduced-motion support
- Scroll-triggered animations via IntersectionObserver
- Sticky TOC auto-generated from h2 elements

## Design Language Note
This presentation is *about* a warm, colorful brand direction — but the presentation *itself* follows the Presenter system's editorial B&W design language. The brand's sage/blush/lavender palette appears only within the palette swatches section (Section 5) as rendered examples, not as the presentation's own styling. Similarly, the Outfit typeface appears only as a rendered specimen — the presentation itself uses the template's serif/sans hierarchy.

## Interactivity Note
The feedback grid (Section 8) is a **static visual layout** — a reference for the team to discuss, not an interactive form. The prototype link is a simple styled anchor.
