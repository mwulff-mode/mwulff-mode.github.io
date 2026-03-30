# Presentation Feedback Integration Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate 9 feedback items into the "From Alignment to Direction" presentation HTML to strengthen strategic clarity, reduce bias, and improve the vote/comparison experience.

**Architecture:** All edits are to a single file: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html`. The file is 8.7MB due to base64-embedded images — edits target specific HTML content sections by unique string matching. No CSS or JS changes needed except Task 8 (new comparison rows) which reuses existing `.comparison-grid` styles.

**Tech Stack:** Static HTML, CSS variables, no build system.

**Source file:** `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html`

---

## File Map

- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html`
  - Line ~1823: Audience section title ("Who She Is")
  - Line ~1839-1851: Audience section body copy
  - Line ~1962: EarnWise illustration rationale
  - Line ~1985-1986: EarnWise "In Context" guidance
  - Line ~1947: EarnWise palette caption (add gender note)
  - Line ~1958: EarnWise typography specimen (add expense anchor)
  - Line ~2148: Savi typography specimen (add expense anchor)
  - Line ~2177-2227: After Savi Voice section — add EarnWise Voice subsection in EarnWise direction
  - Line ~2366-2390: Comparison grid (add product behavior rows)
  - Line ~2394-2416: Vote section (add hybrid option + combine prompt)
  - Line ~2425-2430: Next steps (elevate hybrid mention)

---

### Task 1: Fix gendered audience section title and add inclusive framing

**Context:** Feedback #1 — "Who She Is" leans harder into gendering than the alignment decision ("Designed for her, welcoming to all"). Carlos and Tom from TARGET_AUDIENCE.md are invisible. The workshop used 4 balanced persona cards (2F/2M).

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1823`

- [ ] **Step 1: Change section title from "Who She Is" to "Who We're Building For"**

Find and replace at line ~1823:
```html
<!-- OLD -->
<h2 class="section__title">Who She Is</h2>

<!-- NEW -->
<h2 class="section__title">Who We're Building For</h2>
```

- [ ] **Step 2: Add inclusive framing after the callout block**

After the callout div (line ~1847), before the "deletes anything scammy" paragraph, add a bridging sentence that acknowledges the broader audience:

Find the paragraph at line ~1849:
```html
<!-- OLD -->
<p style="max-width: var(--content-width);">
  She deletes anything scammy within 30 seconds. Trust isn't a feature&nbsp;&mdash; it's the baseline.
</p>

<!-- NEW -->
<p style="max-width: var(--content-width);">
  Our primary persona is Lisa, 47&nbsp;&mdash; but the "Smart Earner" mindset spans genders and ages. Carlos (58, AZ) and Tom (52, TX) share the same financial caution and the same 30-second scam filter. The design needs to resonate with her first and welcome them too.
</p>
<p style="max-width: var(--content-width);">
  They all delete anything scammy within 30 seconds. Trust isn't a feature&nbsp;&mdash; it's the baseline.
</p>
```

- [ ] **Step 3: Verify the page renders correctly**

Open the file in a browser and confirm the Audience section reads naturally with the new title and inclusive framing.

---

### Task 2: Soften the audience stats to match "cautious, not desperate"

**Context:** Feedback #5 — The 65% financial stress and 37% emergency stats paint a more distressed picture than the audience actually is. TARGET_AUDIENCE.md says "financially cautious, not desperate."

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1839-1841`

- [ ] **Step 1: Add qualifier before the stats paragraph**

Find at line ~1839:
```html
<!-- OLD -->
<p style="margin-top: 36px; max-width: var(--content-width);">
  She's not desperate&nbsp;&mdash; she's cautious. She wants small, reliable ways to stretch the household budget. $50 a month&nbsp;&mdash; a tank of gas, a week of groceries.
</p>

<!-- NEW -->
<p style="margin-top: 36px; max-width: var(--content-width);">
  These numbers don't mean she's struggling&nbsp;&mdash; they mean she's paying attention. She's cautious, not desperate. She wants small, reliable ways to stretch the household budget. $50 a month&nbsp;&mdash; a tank of gas, a week of groceries, the prescription copay that was stressing her out.
</p>
```

Note: This adds the expense-anchoring language from BRAND.md ("prescription copay") directly into the audience framing, reinforcing it early.

- [ ] **Step 2: Verify rendering**

Confirm the paragraph flows naturally in context with the metric cards above it.

---

### Task 3: Add "no faces" rationale to EarnWise illustration section

**Context:** Feedback #7 — "No faces — hands and silhouettes only" is stated but the *why* isn't explained. The team will wonder.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1962`

- [ ] **Step 1: Expand the illustration description**

Find at line ~1961-1962:
```html
<!-- OLD -->
<h3 style="margin-top: 56px;" data-animate>The Illustration Style</h3>
<p>Continuous-line illustrations in deep sage with watercolor washes. No faces&nbsp;&mdash; hands and silhouettes only. Two energy levels: calm for tasks, dynamic for rewards.</p>

<!-- NEW -->
<h3 style="margin-top: 56px;" data-animate>The Illustration Style</h3>
<p>Continuous-line illustrations in deep sage with watercolor washes. No faces&nbsp;&mdash; hands and silhouettes only, so every user sees themselves. Two energy levels: calm for tasks, dynamic for rewards.</p>
```

The addition is minimal: "so every user sees themselves" — explains the universality rationale in six words.

- [ ] **Step 2: Verify rendering**

Confirm the paragraph reads naturally.

---

### Task 4: Sharpen EarnWise "In Context" viewing guidance

**Context:** Feedback #8 — Savi's guidance says "Notice the conversational flow" but EarnWise says "just notice how it feels" which is vague. Tell the team what to notice.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1985-1986`

- [ ] **Step 1: Replace the EarnWise "In Context" lede**

Find at line ~1985-1986:
```html
<!-- OLD -->
<p class="section__lede">
  Don't analyze individual screens&nbsp;&mdash; just notice how it feels.
</p>

<!-- NEW -->
<p class="section__lede">
  Notice the calm. Every screen has one clear action, generous space, and a dollar amount you can read from across the room.
</p>
```

- [ ] **Step 2: Verify rendering**

---

### Task 5: Add EarnWise Voice subsection to match Savi's

**Context:** Feedback #3 — Savi has a dedicated "Voice" section with 4 examples and a comparison table. EarnWise has nothing equivalent. This asymmetry could unconsciously bias toward Savi.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html` — insert after the illustration caption (line ~1979), before the "See It Together" section.

- [ ] **Step 1: Add a Voice subsection to the EarnWise direction**

Insert between line ~1979 (end of illustration caption) and line ~1980 (start of "See It Together" section):

```html
      <h3 style="margin-top: 56px;" data-animate>The Voice</h3>
      <p>EarnWise speaks like a helpful neighbor&nbsp;&mdash; clear, warm, never pushy. The app stays out of the way and lets the numbers do the talking.</p>

      <div class="voice-examples" data-animate>
        <div class="voice-bubble">
          <div class="voice-bubble__context">First open</div>
          <p class="voice-bubble__text">"Welcome to EarnWise. Let's set up your first earning goal."</p>
        </div>
        <div class="voice-bubble">
          <div class="voice-bubble__context">Task complete</div>
          <p class="voice-bubble__text">"$2.50 earned. Your grocery fund is now $47.20."</p>
        </div>
        <div class="voice-bubble">
          <div class="voice-bubble__context">Milestone</div>
          <p class="voice-bubble__text">"$25 this month&nbsp;&mdash; that covers a week of gas."</p>
        </div>
        <div class="voice-bubble">
          <div class="voice-bubble__context">Re-engagement</div>
          <p class="voice-bubble__text">"3 new tasks available. Estimated: $4.75 in 12 minutes."</p>
        </div>
      </div>
```

- [ ] **Step 2: Verify rendering**

Confirm the voice bubbles render correctly using the existing `.voice-examples` and `.voice-bubble` CSS classes (already defined for Savi's section).

---

### Task 6: Add expense-anchoring to both type specimens

**Context:** Feedback #4 — The "$47.20 earned this month" is shown in both directions but neither demonstrates the expense-anchoring technique that BRAND.md calls critical. Add a contextual line.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1955` and `:2148`

- [ ] **Step 1: Add expense anchor to EarnWise type specimen**

Find at line ~1953-1956:
```html
<!-- OLD -->
<div class="type-specimen" data-animate>
  <div class="type-specimen__headline">Your Grocery Fund</div>
  <div class="type-specimen__display">$47.20</div>
  <div class="type-specimen__body">earned this month</div>
</div>

<!-- NEW -->
<div class="type-specimen" data-animate>
  <div class="type-specimen__headline">Your Grocery Fund</div>
  <div class="type-specimen__display">$47.20</div>
  <div class="type-specimen__body">earned this month&nbsp;&mdash; that's a week of groceries</div>
</div>
```

- [ ] **Step 2: Add expense anchor to Savi type specimen**

Find at line ~2145-2149:
```html
<!-- OLD -->
<div class="type-specimen type-specimen--savi" data-animate>
  <div class="type-specimen__headline">Hi, I'm Savi!</div>
  <div class="type-specimen__display">$47.20</div>
  <div class="type-specimen__body">earned together this month</div>
</div>

<!-- NEW -->
<div class="type-specimen type-specimen--savi" data-animate>
  <div class="type-specimen__headline">Hi, I'm Savi!</div>
  <div class="type-specimen__display">$47.20</div>
  <div class="type-specimen__body">earned together this month&nbsp;&mdash; that covers your Netflix + Hulu</div>
</div>
```

- [ ] **Step 3: Verify both specimens render correctly**

---

### Task 7: Add palette gender note to EarnWise

**Context:** Feedback #6 — EarnWise's sage/blush/lavender palette reads more feminine than Savi's orange/amber/cocoa, which is ironic given positioning. Worth calling out so the team can react consciously.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:1947`

- [ ] **Step 1: Expand the EarnWise palette caption**

Find at line ~1947:
```html
<!-- OLD -->
<p class="caption">Nothing shouts. Nothing competes for attention. Only dollar amounts, cash, and progress feel dynamic and energetic.</p>

<!-- NEW -->
<p class="caption">Nothing shouts. Nothing competes for attention. Only dollar amounts, cash, and progress feel dynamic and energetic. Worth noting: sage and blush skew softer than the "welcoming to all" positioning implies&nbsp;&mdash; something to pressure-test with the broader audience.</p>
```

- [ ] **Step 2: Verify rendering**

---

### Task 8: Add product behavior rows to comparison grid

**Context:** Feedback #10 — The comparison table is purely aesthetic. The team (PM, backend) needs to understand how the direction choice affects product behavior.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:2387-2389`

- [ ] **Step 1: Add three product behavior rows to the comparison grid**

Find the last row of the grid (line ~2387-2389):
```html
<!-- OLD -->
<div class="comparison-grid__cell" style="text-align: right; border-bottom: none;">App stays invisible</div>
<div class="comparison-grid__row-label" style="border-bottom: none;">Personality</div>
<div class="comparison-grid__cell" style="border-bottom: none;">App has a face</div>

<!-- NEW -->
<div class="comparison-grid__cell" style="text-align: right;">App stays invisible</div>
<div class="comparison-grid__row-label">Personality</div>
<div class="comparison-grid__cell">App has a face</div>

<div class="comparison-grid__cell" style="text-align: right;">Self-serve&nbsp;&mdash; user explores tasks</div>
<div class="comparison-grid__row-label">Onboarding</div>
<div class="comparison-grid__cell">Guided&nbsp;&mdash; Savi recommends first task</div>

<div class="comparison-grid__cell" style="text-align: right;">Minimal&nbsp;&mdash; milestones and payouts only</div>
<div class="comparison-grid__row-label">Notifications</div>
<div class="comparison-grid__cell">Conversational&nbsp;&mdash; re-engagement via Savi</div>

<div class="comparison-grid__cell" style="text-align: right; border-bottom: none;">Dashboard check&nbsp;&mdash; habitual, brief</div>
<div class="comparison-grid__row-label" style="border-bottom: none;">Retention model</div>
<div class="comparison-grid__cell" style="border-bottom: none;">Relationship&nbsp;&mdash; return to continue the conversation</div>
```

- [ ] **Step 2: Verify the grid renders correctly**

Confirm all rows align in the 3-column layout and the last row has `border-bottom: none`.

---

### Task 9: Improve vote section — add hybrid option and combine prompt

**Context:** Feedback #2 and #9 — The slider is binary but a hybrid is the most likely outcome. Add explicit hybrid acknowledgment and a dedicated prompt asking what to combine.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:2398-2414`

- [ ] **Step 1: Update the vote lede to acknowledge hybrid**

Find at line ~2398-2400:
```html
<!-- OLD -->
<p class="section__lede">
  Drag the slider toward the direction that feels right for our audience. Then add any thoughts below.
</p>

<!-- NEW -->
<p class="section__lede">
  Drag the slider toward the direction that feels right for our audience. The middle isn't a cop-out&nbsp;&mdash; a hybrid is a real option. Tell us what you'd combine.
</p>
```

- [ ] **Step 2: Update the textarea prompt**

Find at line ~2413-2414:
```html
<!-- OLD -->
<label for="compare-comment" style="display: block; font-size: 0.88rem; color: var(--ink-light); margin-bottom: 12px;">What elements from each direction resonate? What feels off?</label>
<textarea id="compare-comment" class="feedback-words__input" rows="3" placeholder="e.g. I like Savi's warmth but prefer EarnWise's illustration style..." style="resize: vertical;"></textarea>

<!-- NEW -->
<label for="compare-comment" style="display: block; font-size: 0.88rem; color: var(--ink-light); margin-bottom: 12px;">What would you keep from each direction? What would you drop?</label>
<textarea id="compare-comment" class="feedback-words__input" rows="4" placeholder="e.g. Savi's conversational warmth + EarnWise's linework illustrations + EarnWise's calm palette. Drop the fox mascot..." style="resize: vertical;"></textarea>
```

- [ ] **Step 3: Verify rendering**

---

### Task 10: Elevate hybrid mention in Next Steps

**Context:** Feedback #2 — "or a hybrid" is an afterthought in next steps. Make it a first-class option.

**Files:**
- Modify: `/Users/markus/Documents/Presenter/docs/from-alignment-to-direction.html:2425-2430`

- [ ] **Step 1: Rewrite the next steps list**

Find at line ~2425-2430:
```html
<!-- OLD -->
<ul class="next-steps">
  <li>We pick a direction (or a hybrid) based on your feedback</li>
  <li>Direction refinement&nbsp;&mdash; deeper into the chosen approach</li>
  <li>Voice &amp; tone deep dive&nbsp;&mdash; how we talk across key moments</li>
  <li>Name &amp; tagline brainstorm&nbsp;&mdash; a separate session, informed by this work</li>
</ul>

<!-- NEW -->
<ul class="next-steps">
  <li>We pick a direction&nbsp;&mdash; A, B, or a hybrid that takes the best of both&nbsp;&mdash; based on your feedback and the Maze study results</li>
  <li>Direction refinement&nbsp;&mdash; deeper into the chosen approach</li>
  <li>Voice &amp; tone deep dive&nbsp;&mdash; how we talk across key moments</li>
  <li>Name &amp; tagline brainstorm&nbsp;&mdash; a separate session, informed by this work</li>
</ul>
```

- [ ] **Step 2: Verify rendering**

---

## Execution Order

Tasks are independent and can be executed in any order or in parallel. Each task modifies a different section of the HTML. Recommended order for sequential execution: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10.

## Final Verification

After all tasks are complete:
- [ ] Open the full page in a browser and scroll through completely
- [ ] Confirm all new content appears in the correct sections
- [ ] Confirm the TOC (auto-generated from section headings) still works
- [ ] Confirm the feedback sliders and "Copy to Slack" button still function
- [ ] Check dark mode renders correctly for new content
