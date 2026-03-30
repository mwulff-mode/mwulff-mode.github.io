# Team Handover Presentation: From Feedback to Direction

**Date:** 2026-03-30
**Type:** Self-contained HTML presentation (presenter skill)
**Audience:** Core product team (6 people: Valentina, Corinna, Matt T, Jamil, Aditya, Matt R)
**Output:** `docs/from-feedback-to-direction.html`

---

## Purpose

Hand over the new MVP onboarding prototype to the team in a way that:
1. Shows how their specific input (plus user survey data) shaped design decisions
2. Makes them feel heard and involved
3. Collects structured feedback on each screen and the overall direction

## Design Approach: "The Mirror"

Every section traces a line from **what the team said + what users said → what we built**. The team should recognize their own words in the rationale for each screen.

---

## Sections

### 1. Hero

- **Title:** "From Feedback to Direction"
- **Subtitle:** One line connecting the journey — workshop, survey, prototype
- **Meta line:** March 2026, EarnWise team
- **Aside box:** "6 team responses, 60 user survey responses, 1 new prototype"

### 2. Survey Snapshot

6 metric cards with animated counters:

| Metric | Value | Label |
|--------|-------|-------|
| Fun as priority | 0% | Users who said "fun to use" matters |
| #1 priority | 37% | Reliable payouts — top-ranked by a wide margin |
| Dollar preference | 51% | Prefer real dollar amounts over points |
| Payout speed | 73% | Expect payout in under 24 hours |
| Proof needed | 35% | Need "proof it pays" before trying a new app |
| Early access | 46/50 | Want early access to test |

Brief narrative paragraph below: "This audience is practical, trust-sensitive, and allergic to gimmicks. They want dependable payouts, real dollars, and proof before commitment."

### 3. What We Heard (Team + Users Combined)

3-4 callout blocks. Each has:
- **Theme title** (e.g., "Trust is the foundation")
- **Team voice** — attributed quotes from team members
- **User voice** — corresponding survey data point
- **Resolution** — the design decision that emerged

#### Block 1: Trust is the foundation
- **Team:** 5 of 6 rated trust "just right" on at least one direction
- **Users:** 37% top priority is reliable payouts; 43% would leave if it feels scammy
- **Resolution:** Trust-building is the entire brand strategy. Every screen passes the test: "Does this make us feel more trustworthy?"

#### Block 2: Professional warmth, not playfulness
- **Team:** EarnWise critiqued as "too serious/dry" (Aditya, Matt R); Savi as "too cute/childish" (Matt R, Matt T)
- **Users:** "Fun to use" = 0% priority. 65% want reliability + value.
- **Resolution:** Warm professionalism — like a trusted credit union, not a game. Personality through copy tone, not visual playfulness. Savi's conversational warmth; EarnWise's visual clarity.

#### Block 3: Real dollars, always
- **Team:** Valentina: "I love the opportunity to see the real balance you have earned in money equivalent"
- **Users:** 51% prefer dollar amounts; only 11% want points
- **Resolution:** Show actual money. No coins, no tokens, no conversion math.

#### Block 4: Goals over expense anchoring
- **Team:** Matt T: "I don't like the references to gas and groceries. It adds to my stress."
- **Users:** 55% use earnings for everyday expenses, 41% for treats — both are real motivations
- **Resolution:** Goal-based framing is the primary system. Expense context is optional, never system-imposed.

### 4. Screen-by-Screen Walkthrough

Each screen gets its own subsection with three layers:

#### Screen 1: Welcome
- **Derivation callout:** "35% of users need proof it pays → social proof strip with real dollar figure. Valentina wanted fewer clicks → single-screen sign-up with Google/Apple/Email."
- **Screenshot:** Base64-encoded capture of the welcome screen from the prototype
- **Feedback widget:** 5-dot scales for Clarity, Trust feel, "Would this land with our users?" + text area "What would you change?"

#### Screen 2: Trust & Value Carousel
- **Derivation callout:** "User churn drivers: 'feels scammy' (43%), 'earnings too small' (52%). Team unanimously rated trust as critical → 3-slide carousel addressing the top three concerns: real earnings, fast payout, no tricks."
- **Screenshot:** Base64-encoded capture showing the carousel
- **Feedback widget:** Same structure as above

#### Screen 3: Conversational Profile (4 steps)
- **Derivation callout:** "Corinna loved 'When do you have time to play?' Valentina wanted all questions on one page with fewer clicks. Resolution: 4 conversational steps — feels personal like Savi, but streamlined like EarnWise. Each question maps to personalization: downtime habits → activity recommendations, time preference → notification timing, earnings goal → progress ring calibration."
- **Screenshots:** Base64-encoded captures of each of the 4 conversational steps
- **Feedback widget:** Same structure

#### Screen 4: Home with Welcome Gift
- **Derivation callout:** "Users' #1 churn driver: 'earnings feel too small' (52%). 35% need proof it pays. Team wanted gamification to feel 'rewarding, not entertaining' (Aditya's concern resolved). → $1.00 welcome gift visible immediately. Progress ring toward user-chosen goal. Today's picks personalized from profile answers."
- **Screenshot:** Base64-encoded capture of home screen (with gift overlay and final state)
- **Feedback widget:** Same structure

### 5. Try It Yourself

- Prototype link card with play icon
- Opens the onboarding prototype in a new tab (relative link to `../output/prototypes/03_MVP_Onboarding/onboarding.html` or hosted URL — to be confirmed)
- Instruction: "Tap through the full flow — then come back here to share your thoughts below."
- Link opens with `target="_blank"` to preserve feedback state

### 6. Overall Feedback

- **Direction slider:** "Too safe ← → Too bold"
- **Text area:** "What's the one thing we should change before moving forward?"
- **Floating feedback panel:** Appears on first interaction with any feedback widget. Accumulates all feedback (per-screen ratings, per-screen comments, direction slider value, final comment) in real time. Single "Copy to clipboard" button. No other copy buttons anywhere in the doc.

---

## Technical Notes

- Self-contained HTML file using the presenter starter template
- Screenshots captured from the prototype and base64-encoded inline
- D3.js for metric card animated counters
- Feedback state held in JS, accumulated in the floating panel
- All external links use `target="_blank"`
- Dark/light mode toggle
- Sticky left TOC sidebar

## Resolved Questions

1. **Prototype link:** Relative file path — `../output/prototypes/03_MVP_Onboarding/onboarding.html`
2. **Screenshots:** Capture from the prototype HTML using headless browser (Puppeteer/Playwright), then base64-encode inline

---

*Spec for team handover presentation — designed to make the team see their input reflected in every design decision and collect structured feedback on the MVP onboarding prototype.*
