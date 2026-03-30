# Audience Validation Survey — Design Doc

> **Status:** Draft
> **Date:** 2026-03-05
> **Platform:** Maze (Starter plan)
> **Distribution:** MEA existing user base
> **Estimated time:** 6-7 minutes
> **Interview CTA:** Scheduling link on thank-you screen

---

## Goals

1. **Validate personas** — Confirm the "Smart Earner" psychographic is real. Do MEA users match our assumptions about behavior, motivations, and app usage?
2. **Test product-market fit** — Would this audience try a new rewards app built on simplicity and transparency? What would make them download it?
3. **Inform product design** — What earning activities do they prefer? How often? What payout methods and thresholds matter?

---

## Survey Structure

4 sections, 22 questions + thank-you screen. All question types are Maze Starter-compatible. Conditional logic used on Q23.

---

## Section 1: About You (Persona Validation)

### Q1 — Context Screen

> We're working on something new and want to hear from real users first. This takes about 7 minutes. There are no right or wrong answers.

### Q2 — Multiple Choice (single select)

> What is your age?

- 18–24
- 25–34
- 35–44
- 45–54
- 55–64
- 65+

**Why:** Core demographic for validating our 40-65 target. Lets us segment all other responses by age band and confirm whether the "Smart Earner" skews older as assumed.

### Q3 — Multiple Choice (single select)

> How do you describe your gender?

- Woman
- Man
- Non-binary
- Prefer not to say

**Why:** Validates the assumed skew toward women 45+. Inclusive options keep the question comfortable for all respondents.

### Q4 — Multiple Choice (single select)

> What best describes your current situation?

- Working full-time
- Working part-time
- Self-employed / freelance
- Retired or semi-retired
- Stay-at-home parent / caregiver
- Other

**Why:** Maps respondents to our persona archetypes (Lisa = part-time, Diane = retired, Carlos = full-time, Tom = full-time).

### Q5 — Multiple Choice (multi-select)

> What do you typically use your reward app earnings for?

- Everyday expenses (groceries, gas, pharmacy)
- Subscriptions (streaming, phone, etc.)
- Treats for myself or family
- Saving toward something specific
- Gifts
- It just adds up in my account
- Other

**Why:** Validates motivation assumptions. Lisa = everyday expenses. Diane = treats. Carlos = hobbies. Tom = budget optimization.

### Q6 — Multiple Choice (multi-select)

> Which of these apps do you use regularly?

- Amazon
- PayPal
- Rakuten
- Ibotta
- Fetch Rewards
- Facebook
- Pinterest
- Candy Crush or similar puzzle games
- Wordle / NYT Games
- Duolingo
- Other
- None of these

**Why:** Validates app ecosystem assumptions from our personas. Also tells us who our real competitors are in this audience's phone. "Other" catches apps we didn't anticipate.

### Q7 — Multiple Choice (single select)

> How do you usually find out about new apps?

- Saw an ad
- Searched online / read reviews
- A friend or family member told me
- Saw it on Facebook or social media
- It was recommended in another app
- Other

**Why:** Validates our assumption that word-of-mouth is the #1 discovery channel. Critical for go-to-market planning. Word-of-mouth moved to middle position to avoid primacy bias. Randomize order in Maze if supported.

---

## Section 2: What You Value (Brand & Trust Validation)

### Q8 — Multiple Choice (single select)

> In the last year, how many apps have you deleted within the first few minutes of trying them?

- 0
- 1–2
- 3–5
- More than 5

**Why:** Tests whether quick deletion is real behavior, not just an attitude. Behavioral questions are harder to game than agreement scales.

### Q9 — Multiple Choice (single select)

> What matters MOST to you in a rewards app?

- It's simple and easy to understand
- It pays out reliably and on time
- My time feels worth it for what I earn
- It doesn't spam me with notifications
- I trust it with my information
- It has a wide variety of ways to earn
- It's fun to use

**Why:** Force-ranks our brand values against real alternatives. Added "variety" and "fun" as options we don't expect to win — if they do, our assumptions are wrong.

### Q10 — Multiple Choice (single select)

> What would make you stop using a rewards app?

- Earnings feel too small to matter
- It's confusing or hard to navigate
- Too many notifications or pushy messages
- Payouts are slow or unreliable
- It feels scammy or untrustworthy
- The minimum to cash out is too high
- I found a better alternative
- Other

**Why:** Validates guardrails from the negative side. Added real-world churn reasons ("minimum too high", "found better") that aren't in our guardrails — if they rank high, we're missing something.

### Q11 — Multiple Choice (single select)

> How do you prefer to see your earnings?

- Dollar amounts ($0.25, $5.00)
- Points you can convert to dollars (e.g., 150 points = $1.50)
- Doesn't matter to me

**Why:** Validates our dollars-over-points decision. Removed loaded word "real" from dollar option. Both options now include examples for equal weight.

### Q12 — Open Question

> Think of an app you really love using. What makes it great?

**Why:** Qualitative gold. Reveals what "love" looks like in their own words — language we can use in positioning and copy. Also tells us which brands set the bar.

---

## Section 3: Your Earning Habits (Product Design Input)

### Q13 — Multiple Choice (multi-select)

> Which of these earning activities interest you?

- Complete surveys
- Watch short videos
- Try new apps or games
- Shop through the app
- Scan receipts
- Daily check-ins
- Play games within the app
- Other

**Why:** Directly informs product roadmap. Which earning activities do we build first?

### Q14 — Multiple Choice (single select)

> How often would you ideally use a rewards app?

- A few minutes every morning
- A few times a week when I have spare time
- Whenever I get a notification about something new
- Only when I'm specifically shopping or doing errands

**Why:** Tells us whether to design for daily ritual (Wordle model) or occasional use. Critical for retention mechanics.

### Q15 — Multiple Choice (single select)

> What's the minimum you'd need to earn per month for it to feel worth your time?

- $1 – $5
- $5 – $10
- $10 – $25
- $25 – $50
- More than $50

**Why:** Sets the earning threshold we need to hit. If most say $25+, that constrains which activities are viable.

### Q16 — Multiple Choice (single select)

> How do you prefer to get paid out?

- PayPal
- Direct to bank account
- Gift cards (Amazon, Walmart, etc.)
- Doesn't matter to me

**Why:** Informs payout integration priorities for launch.

### Q17 — Multiple Choice (single select)

> How quickly would you expect to receive a payout?

- Instant
- Within 24 hours
- Within a few days
- Within a week
- I don't mind waiting if I know when it's coming

**Why:** Sets payout SLA expectations. The last option tests whether transparency matters more than speed.

---

## Section 4: What's Missing & What's Next

### Q18 — Open Question

> What's missing from the rewards apps you currently use? What would you improve?

**Why:** Surfaces unmet needs without biasing toward our concept. Their frustrations = our opportunities.

### Q19 — Multiple Choice (single select)

> What would make you try a new rewards app?

- A friend recommended it
- I saw proof that it actually pays out
- It looked simple and easy to use
- It offered earning activities I already enjoy
- A sign-up bonus or incentive
- Other

**Why:** Tells us what the #1 acquisition trigger is. Informs launch marketing strategy.

### Q20 — Open Question

> What's the one thing a new rewards app would need to get right for you to switch from what you use now?

**Why:** The switching-cost question. Reveals what our audience considers table stakes vs. differentiators.

### Q21 — Yes/No

> Would you like early access to test our new app before it launches?

**Why:** Builds a pre-launch beta tester pool. Also a soft PMF signal — willingness to test = interest.

### Q22 — Yes/No

> Would you be open to a 15-minute call to share more of your thoughts? We'd love to hear from you.

**Why:** Interview recruitment funnel. Kept separate from beta opt-in.

### Q23 — Open Question (conditional: shows if Q21 = Yes OR Q22 = Yes)

> What's the best email to reach you at?

**Why:** Collects contact info for beta invites and/or interview scheduling. Input type: email.

---

## Thank You Screen

> Thanks for helping us build something for people like you. If you signed up for early access or a call, we'll be in touch soon — your input is already shaping what we create.

Include scheduling link (e.g., Calendly) in the body text for interview respondents.

---

## Maze Implementation Notes

- **Blocks:** 24 blocks total (1 context + 22 questions + 1 thank-you). Well within Starter unlimited.
- **Conditional logic:** Q23 appears if Q21 = Yes OR Q22 = Yes. If Maze doesn't support OR conditions, show Q23 unconditionally with "(optional)" and let respondents skip if they said no to both.
- **No built-in screener needed:** All respondents are MEA users, already pre-qualified.
- **Redirect:** If Starter doesn't support CTA buttons on thank-you screen, embed the scheduling link as a clickable URL in the thank-you text.
- **Response limit:** Starter allows up to 2,000 responses per maze. Should be sufficient.

---

## Analysis Plan

| Section | What we're looking for |
|---------|----------------------|
| Section 1 | Do respondents cluster into our persona archetypes? Any surprises in app usage or discovery channels? |
| Section 2 | Which brand value ranks #1? Does "dollars over points" hold? What does "love" look like in their words? |
| Section 3 | Top earning activities, frequency preference, earning threshold, payout method. |
| Section 4 | Unmet needs / frustrations with current apps. Top download trigger. Switching-cost themes from open question. |
| Beta pool | How many opted in for early access? Email list for beta invites. |
| Interview pool | How many said yes to a call? Email list for scheduling. |
