# Mobile UI / UX Evidence Notes

**Date:** 2026-03-26  
**Scope:** High-impact findings only. Fresh external evidence limited to 2024-2026, plus our March 2026 audience research.

## 1. Audience reality

- Our current audience is overwhelmingly **45+**, primarily **Android / Chrome mobile**, and highly sensitive to **trust, payout clarity, and wasted time**.
- In our survey, **"fun to use" scored 0%**. Reliability, value, and transparency dominate product preference.
- This means accessibility and clarity are not polish. They are core conversion and retention requirements.

## 2. Hard UI evidence we should treat as baseline

- **Tap targets:** treat `48x48dp` as the practical floor on Android. Android accessibility recommends at least `48x48dp` with about `8dp` spacing. Apple recommends `44x44pt`. WCAG 2.2 AA requires at least `24x24` CSS px; WCAG AAA raises that to `44x44`.
- **Text scaling:** support at least **200% text enlargement** without overlap, clipping, or unusable truncation. Apple explicitly uses `200%+` as the Larger Text benchmark. Android 14 supports font scaling up to `200%` and tells developers to test there.
- **Contrast:** target at least **4.5:1** for normal text and **3:1** for large text and non-text UI states.
- **Low cognitive load:** for this audience, prefer one primary action per screen, fewer visible choices, and predictable layouts. This matches both our survey and current HCI evidence on older adults.

## 3. Settings: what to support vs. what to assume

- We should **not assume** that **dark mode** or **increased text size** are the predominant default settings for this audience. We did **not** find a strong 2024-2026 public dataset proving either is dominant among adults 45+/50+.
- We **should support** these settings well anyway:
  - **Large text**
  - **Dark mode**
  - **Higher contrast**
  - **Reduced motion**
- Fresh signal we *did* verify: AARP's latest tech trends show **about half of adults 50+ currently use or are interested in a voice assistant** like Siri or Alexa. Voice-friendly labels and clear control names are worth supporting.
- If video remains a core activity, **captions matter**. AP-NORC found adults **45+** are more likely than younger adults to use subtitles because of **accents** or **hearing impairment**.

## 4. What this means for EarnWise

- Design for **clarity first**, not charm first.
- Use **real dollars**, not points or coins.
- Make the main action obvious immediately.
- Avoid small controls, cramped layouts, weak contrast, and anything that breaks at large text sizes.
- Avoid scam-adjacent patterns: countdown urgency, noisy gamification, vague reward mechanics, or pushy notifications.

## 5. How to address this audience

- Voice should feel **straightforward, reliable, respectful, occasionally warm, never condescending**.
- They want to feel **recognized**, but not marketed at.
- Ask for a name only if it helps the experience, and make it **optional**.
- Do **not** build the voice around repeating a first name throughout the app. Use name personalization as a light touch only.
- Stronger personalization lever: let users name their own goals and show progress toward them.

## 6. Best current decisions

- `48dp+` touch targets everywhere important.
- Test the product at **200% text size**.
- Support dark mode, but do not design as if most users prefer it.
- Keep videos caption-ready.
- Use sparse, dignified personalization rather than over-familiar copy.

## Sources

### Internal

- `/Users/markus/Documents/earnapp/research/user-survey-report-2026-03-26.md`
- `/Users/markus/Documents/earnapp/research/strategic-synthesis-2026-03-26.md`
- `/Users/markus/Documents/earnapp/docs/TARGET_AUDIENCE.md`
- `/Users/markus/Documents/earnapp/docs/BRAND.md`

### External

- W3C WCAG 2.2 Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- W3C WCAG Contrast (Minimum): https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum
- W3C WCAG Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast
- Android touch target guidance: https://support.google.com/accessibility/android/answer/7101858?hl=en
- Android 14 font scaling to 200%: https://developer.android.com/about/versions/14/features
- Apple Larger Text criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-accessibility-evaluation-criteria
- Apple Sufficient Contrast criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/sufficient-contrast-evaluation-criteria/
- Apple Reduced Motion criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria
- Apple Dark Interface criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/dark-interface-evaluation-criteria
- CHI 2024 older-adult feature-finding study: https://doi.org/10.1145/3613904.3642796
- AARP 2026 Tech Trends: https://www.aarp.org/pri/topics/technology/internet-media-devices/2026-technology-trends-older-adults/
- AP-NORC captions study (2025): https://apnorc.org/projects/closed-captioning-on-its-a-generational-thing/
