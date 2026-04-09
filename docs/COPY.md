# EarnWise In-App Copy Guide

> **Purpose:** Write in-app strings that sound like EarnWise.
> **Scope:** User-facing strings in `flutter_app/`. Titles, buttons, empty states, errors, celebrations, in-app notifications.
> **How to use:** Load this file before writing any in-app string. Find the recipe that fits. Run the voice check before committing.
> **Not covered:** App store listing, server-side push, marketing, emails.
> **Sources:** `docs/TARGET_AUDIENCE.md`, `docs/BRAND.md`, April 2026 team feedback.
> **Last updated:** 2026-04-09

---

## 1. Who she is

> **Lisa, 47.** Suburban, part-time work, family of four. Checks EarnWise with her morning coffee. Cautious, not desperate. She wants her time to be worth something, and to feel smart, not silly, for it. Scam-aware: if anything feels off, she's gone in 30 seconds.
>
> **She says:** *"I made three bucks with my coffee this morning."*
> **She does not say:** *"I'm grinding on EarnWise."*

Read those two lines before you write. Everything in this guide exists to make her trust the app enough to text a friend about it.

---

## 2. The 7 always-true rules

These apply to every user-facing string in the app. Break any one of them and Lisa feels it.

| # | Rule | Do | Don't |
|---|------|----|-------|
| 1 | **Write like a person talks.** Full sentences. Nothing you wouldn't say out loud to a friend. Master rule. | `This one isn't for you. Try these three instead.` | `Not eligible.` |
| 2 | **Real dollars, never points.** Money is the reward. Never abstract it into coins, XP, or tokens. | `You just earned $0.40.` | `You earned 40 coins.` |
| 3 | **Never minimize the earnings.** Banned: "a little", "a bit extra", "on the side", "pocket money", "spare change". Also no "get rich" in the other direction. The dollars are real and they matter. | `EarnWise turns your spare time into real dollars.` | `Earn a little extra on the side.` |
| 4 | **State the facts, skip the hype.** Acknowledge, give the value, move on. No AMAZING, no KA-CHING, no stacked exclamation marks. | `Nice. That's another $0.25 in the bag.` | `AMAZING! $0.25 EARNED! Keep going!` |
| 5 | **No FOMO, no urgency, no countdowns.** Pressure tactics read as scam signals to her. | `You've got 3 new surveys, about $1.50 total.` | `Don't miss out! 2 hours left!` |
| 6 | **Every "no" has a next step.** Never leave a dead end. | `That one just closed. Try one of these two.` | `Not available.` |
| 7 | **No em-dashes. Ever.** They read as AI-generated and the audience notices. Use a period and a new sentence, or a comma, or a colon. | `Your $10.00 is on its way to PayPal. You'll see it within 24 hours.` | `$10.00 is on its way to PayPal — arrives within 24 hours.` |

**A note on Rule 1.** "Clear and concise" is still the goal. "Human" does not mean long. `You just earned $0.40.` is both human and short. The test is, could Lisa's friend say this sentence to her over coffee without it sounding weird?

---

## 3. Situation recipes

When you are about to write a string, find the recipe that fits and use it. Each recipe has a pattern, two good examples, and one anti-pattern to reject.

### 3.1 Onboarding welcome

**When:** First screen after install.
**Pattern:** `[warm greeting] + [what the app does, plainly] + [first action cue]`

**Do:**
- `Welcome. EarnWise pays real dollars for small, quick tasks. Let's try one.`
- `Glad you're here. EarnWise turns your spare time into real dollars. Takes a minute to set up.`

**Don't:** `🎉 Welcome! Get ready to TURN your spare time into CASH!`

### 3.2 First earn

**When:** User completes their very first task.
**Pattern:** `[warm acknowledgment] + [real dollar amount] + [goal progress if available]`

**Do:**
- `Nice. You just earned $0.25. That's heading straight to your coffee fund.`
- `There's your first $0.40. Another $2.10 and you hit your first goal.`

**Don't:** `🎉 KA-CHING! $0.25! You're ON FIRE!`

### 3.3 Task complete (mid-session)

**When:** Any completed task after the first.
**Pattern:** `[confirmation] + [dollar added] + [what's next]`

**Do:**
- `You're done. Another $0.50 in the bag. Two more like this when you want them.`
- `That's another $0.75. You're $3.50 from your next cashout.`

**Don't:** `GREAT JOB! Keep the streak going to earn even more!`

### 3.4 Cashout confirmation

**When:** User has just cashed out.
**Pattern:** `[amount] + [destination] + [when it arrives]`

**Do:**
- `Your $10.00 is on its way to PayPal. You'll see it within 24 hours.`
- `$25.00 is heading to your Amazon gift card. The code lands in your email within the hour.`

**Don't:** `🎉 YOU DID IT! $10 CASHED OUT! Treat yourself!`

### 3.5 Empty state

**When:** No tasks available right now.
**Pattern:** `[what's happening, warmly] + [when it changes or what's next]`

**Do:**
- `You're all caught up. New tasks usually land in the afternoon.`
- `Nothing waiting right now. We'll let you know as soon as something's here.`

**Don't:** `Oops, nothing here yet!`

### 3.6 Error

**When:** Something failed. Network, task closed, survey full, etc.
**Pattern:** `[what happened, plainly and warmly] + [what to do next]`

**Do:**
- `We couldn't load your tasks. Check your connection and try again.`
- `That survey just closed. Here are two similar ones you can do right now.`

**Don't:** `Error 403. Request could not be processed.` or `Oops! Something went wrong 😞`

---

## 4. Voice check

Before shipping any string, run these four tests. If all four pass, ship it. If any fail, rewrite.

1. **The coffee test.** Could Lisa's friend say this to her over coffee without it sounding weird?
2. **The dollar test.** If the line mentions a number, is it a real dollar amount? Not points, not coins, not an hourly rate.
3. **The respect test.** Did you diminish the amount with words like "a little" or "spare change"? If yes, rewrite.
4. **The exit test.** If this is a "no", an error, or an empty state, did you give her a next step?
