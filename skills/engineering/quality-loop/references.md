# References

All sources accessed 2026-10-09. Numbers in `standard.md` are short quotes or summaries; re-check a source before a store submission, because platform rules change.

## Quality model and heuristics

| Topic | Source |
|---|---|
| ISO/IEC 25010:2023 product quality model: nine characteristics (functional suitability, performance efficiency, compatibility, interaction capability, reliability, security, maintainability, flexibility, safety) | https://www.iso.org/standard/78176.html · characteristic list: https://iso25000.com/en/iso-25000-standards/iso-25010 |
| Nielsen's 10 usability heuristics (1994, reviewed 2024) | https://www.nngroup.com/articles/ten-usability-heuristics/ |
| Testing with 5 users per qualitative round | https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/ |
| System Usability Scale: average 68 across 500 studies; 80 a common industry goal | https://measuringu.com/sus/ |
| HEART framework (Happiness, Engagement, Adoption, Retention, Task success) and goals → signals → metrics, Rodden, Hutchinson & Fu, CHI 2010 | https://research.google/pubs/measuring-the-user-experience-on-a-large-scale-user-centered-metrics-for-web-applications/ |

## Apple

| Topic | Source |
|---|---|
| App Review Guidelines (1.5 contact, 2.1 completeness, 2.3 accuracy, 4 design, 4.2 minimum functionality, 5.1 privacy, 5.1.1(v) account deletion) | https://developer.apple.com/app-store/review/guidelines/ |
| Account deletion inside the app | https://developer.apple.com/support/offering-account-deletion-in-your-app/ |
| Human Interface Guidelines (accessibility: 44x44 pt controls, 11 pt minimum text) | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| Hangs: delay under 100 ms rarely noticeable; Apple tools report main run loop busy > 250 ms | https://developer.apple.com/documentation/xcode/understanding-hangs-in-your-app |
| Launch time: time to first frame in Organizer and MetricKit, p50/p90, watchdog | https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time |
| First frame within 400 ms (WWDC 2019, Optimizing App Launch) | https://developer.apple.com/videos/play/wwdc2019/423/ |

## Web

| Topic | Source |
|---|---|
| WCAG 2.2 (1.4.3 contrast 4.5:1, 1.4.10 reflow 320 CSS px, 2.5.7 dragging, 2.5.8 target 24x24 CSS px) | https://www.w3.org/TR/WCAG22/ |
| Core Web Vitals at p75: LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1 | https://web.dev/articles/defining-core-web-vitals-thresholds |

## Stability, security, services

| Topic | Source |
|---|---|
| Google Play bad-behavior thresholds: user-perceived crash 1.09 %, ANR 0.47 % overall; 8 % per phone model | https://developer.android.com/topic/performance/vitals · https://android-developers.googleblog.com/2022/10/raising-bar-on-technical-quality-on-google-play.html |
| OWASP MASVS v2.1 (mobile; adds MASVS-PRIVACY) | https://mas.owasp.org/MASVS/ |
| OWASP ASVS 5.0.0 (web apps and services, released 2025-05-30) | https://asvs.dev/ · https://owasp.org/www-project-application-security-verification-standard/ |
| Service level objectives and error budgets | https://sre.google/sre-book/service-level-objectives/ |

## Consumer protection

| Topic | Source |
|---|---|
| Korea, Act on Consumer Protection in Electronic Commerce Art. 21-2 (in force 2025-02-14): six banned dark patterns (drip pricing, hidden renewal, pre-selection, false hierarchy, cancel/withdraw obstruction, repeated interference) | https://www.law.go.kr/법령/전자상거래등에서의소비자보호에관한법률 |
| US FTC staff report, Bringing Dark Patterns to Light (2022) | https://www.ftc.gov/reports/bringing-dark-patterns-light |
