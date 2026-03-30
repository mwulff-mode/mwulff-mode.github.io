# Visual Design Validation Methodology

> **Date:** 2026-03-11
> **Status:** Decided
> **Usage:** Reference for running user research on visual design directions. NN/g-backed methodology for testing with target users before committing to a direction.

---

## Why Test Visual Design

A design people *like looking at* may not be one they can *use*. NN/g is explicit: test behavior before attitudes. We need evidence, not opinions, to choose between visual directions.

---

## Protocol 1: 5-Second Test

**Purpose:** Capture gut-reaction first impressions of visual style and overall aesthetic impact.

**How it works:**
1. Show the design stimulus for exactly 5 seconds
2. Remove it
3. Ask: "What do you remember? How did it make you feel? What kind of app is this?"

**Key recommendation from NN/g:** "Avoid warning participants" — don't tell them they'll only see it briefly. Surprise reveals authentic first impressions; warning triggers analytical scanning.

**When to use:** First round of testing to compare overall aesthetic directions (e.g., Soft Piggy Bank vs Smart & Clean).

**Sample size:** 20–30 participants matching Smart Earner demographic.

**Tool:** [Lyssna](https://www.lyssna.com/) or [Maze](https://maze.co/) (unmoderated, no scheduling needed).

---

## Protocol 2: Microsoft Desirability Toolkit (Reaction Cards)

**Purpose:** Replace subjective free-form commentary with standardized vocabulary. Participants select 5 words from a curated list that best describe the design.

**Setup:**
- Reduce the original 118-word list to ~25 words to minimize fatigue
- Eliminate terms tied solely to functionality, content, or performance
- Balance negative, positive, and neutral terms (**aim for ~40% negative words**)
- Randomize presentation order

**Suggested word list (adapt to brand):**

> Boring · Calm · Cheap · Clean · Cluttered · Confusing · Creative · Cutting-edge · Dated · Easy · Friendly · Fresh · Generic · Grown-up · Intimidating · Inviting · Old · Professional · Relaxing · Simple · Sophisticated · Trendy · Trustworthy · Warm · Welcoming

**Running the study:**
1. Show design prominently (mockup or screenshot — "simply showing participants a screenshot can reduce distractions")
2. No active interaction required
3. Display word list while design is visible
4. Participant selects exactly 5 words
5. **Best practice:** Conduct in moderated sessions where you can ask follow-up questions ("Why did you choose 'trustworthy'?")

**Analysis:**
- Calculate the percentage selecting each word
- Identify the most frequently chosen terms
- Compare results across user groups or design versions
- Report percentages, not raw counts
- Use Venn diagrams to visualize overlapping preferences across directions
- Map selections to intended brand attributes (Simplicity, Reliability, Valuable)

**When to use:** After choosing a winning direction — validate that it evokes the intended brand attributes.

---

## Protocol 3: Preference Test

**Purpose:** Show 2–3 design variations and ask which users prefer.

**Critical guidance from NN/g:**
- "Differences must be significant enough to be immediately detectable"
- "Limit the number of elements changed between versions" — if everything is different, you learn nothing about *which* element drives preference
- "Counterbalance or randomize the order" to prevent position bias
- **Always ask why** — NN/g warns that preference without explanation is nearly useless. The reasons matter more than the votes.

**Running the test:**
1. Show Direction A and Direction B side by side (or sequentially, randomized)
2. Ask: "Which of these feels more like an app you'd trust and use daily?"
3. **Always follow up:** "What made you choose that one?"
4. Record both the choice and the reasoning

**When to use:** Comparing two finalized visual directions head-to-head.

**Sample size:** 20–30 participants.

---

## Protocol 4: Post-Usability Aesthetic Assessment

**Purpose:** Measure aesthetic perception *after* behavioral tasks, avoiding the halo effect.

**Critical timing from NN/g:** "Present behavioral tasks first and aesthetic assessments afterward" — this prevents the halo effect where pretty designs get undeserved usability passes.

**How it works:**
1. Give participants 3–5 real tasks on the prototype (find balance, complete a task, check cashout threshold)
2. Record task success, time, and errors
3. *Then* ask aesthetic questions: desirability words, satisfaction ratings, open-ended impressions

**When to use:** High-fidelity prototype testing phase.

**Sample size:** 5–8 users (NN/g's recommended minimum for usability testing).

---

## Weighted Scorecard Template

Use this to make the final design direction decision as a team, after testing data is collected:

| Criterion | Weight | Direction A | Direction B |
|-----------|--------|-------------|-------------|
| Brand alignment (Smart Earner persona) | 30% | ? | ? |
| Trustworthiness (5-second test results) | 25% | ? | ? |
| Task clarity (usability test results) | 20% | ? | ? |
| Visual differentiation from competitors | 15% | ? | ? |
| Dev feasibility (Flutter complexity) | 10% | ? | ? |
| **Weighted total** | **100%** | **?** | **?** |

Fill this in **together** after testing. The direction that wins does so on evidence, not opinion.

---

## Recommended Tools

| Tool | Best for | Cost |
|------|----------|------|
| [Lyssna](https://www.lyssna.com/) | 5-second tests, preference tests, unmoderated | Low |
| [Maze](https://maze.co/) | Unmoderated usability + preference testing | Low |
| Moderated Zoom sessions | Desirability study, follow-up questions | Free (labor cost) |

---

## Recommended Timeline

| Phase | Activity | Timing |
|-------|----------|--------|
| **1. Quick pulse** | Run unmoderated 5-second tests on both directions (Lyssna or Maze) — 20–30 participants matching Smart Earner demo | This week |
| **2. Workshop** | Present test results alongside Figma mockups — let data lead, not aesthetics | Workshop day |
| **3. Validate winner** | Run desirability study (reaction cards) on the chosen direction to confirm brand attribute alignment | Post-workshop |
| **4. Prototype test** | Usability test the high-fidelity prototype with 5–8 users, then post-task aesthetic assessment | Prototype phase |

---

## Trust-Building Design Patterns (Supporting Research)

From Phenomenon Studio's fintech UX research (2025):
- **82% of users** trust fintech apps more when data is displayed visually (ring progress, sparklines)
- **Green signals growth and positive outcomes** — sage palette is psychologically aligned
- **Grid-adherent layouts score 17% higher** on perceived professionalism
- **Security should be visible, not hidden** — PayPal trust line placement matters
- **Error messages are critical trust moments** — plan for these early

---

## Key Principle

**Separate aesthetic preference from usability.** Test behavior before attitudes. A design people like looking at may not be one they can use. Run usability tasks first, then ask aesthetic questions after. This is NN/g's #1 recommendation for visual design testing.

---

## Sources

- [Testing Visual Design: A Comprehensive Guide — NN/g](https://www.nngroup.com/articles/testing-visual-design/)
- [Using the Microsoft Desirability Toolkit — NN/g](https://www.nngroup.com/articles/microsoft-desirability-toolkit/)
- [Preference Testing for Visual Design — NN/g (2025)](https://www.nngroup.com/videos/preference-testing/)
- [FinTech UX Design Patterns That Build Trust — Phenomenon Studio](https://phenomenonstudio.com/article/fintech-ux-design-patterns-that-build-trust-and-credibility/)
- [5 UX Workshops Cheat Sheet — NN/g](https://www.nngroup.com/articles/5-ux-workshops/)
- [Fintech UX Best Practices 2026 — Eleken](https://www.eleken.co/blog-posts/fintech-ux-best-practices)
