# Production scale

Image models draw UI about 1.3-1.6x larger than shipped products, so the reference image's pixels are never CSS pixels. Take proportions, hierarchy ratios, and topology from the image; take absolute sizes from this table.

## Calibrate

1. Measure the image's body text (a list row title or card title) cap height or line height in pixels.
2. Set that text to the category's body size below (at a 1440px desktop viewport).
3. `scale = target body px / image body px`. Apply it to the image's structural measurements (rail width, gaps, radii) to get CSS values, then snap to the 4px grid and clamp to the ranges below.
4. Record the scale and the resulting tokens in `spec.md`. A token outside its range needs a reason from the brief.

## Desktop (1440 wide) ranges

| Token | Operate (admin, app, dashboard) | Persuade (landing) | Read (docs) |
|---|---|---|---|
| Body text | 14-15px | 16-18px | 16-18px |
| Secondary / meta | 12-13px | 14px | 14px |
| Page title | 20-28px | 40-72px | 32-40px |
| Section / column heading | 13-16px semibold | 24-36px | 20-24px |
| Row / list item height | 32-44px | n/a | n/a |
| Card padding | 10-16px | 24-40px | 16-24px |
| Input / button height | 32-40px | 44-52px | 36-40px |
| Sidebar width | 220-264px | n/a | 240-280px |
| Icon | 16-20px, 1.5px stroke | 20-24px | 16-20px |
| Radius | 6-10px | 8-16px | 6-8px |
| Content gutter | 16-24px | 24-64px | 24-48px |

Mobile (390 wide): body 15-17px, touch targets ≥ 44px, gutters 16px.
Game HUD: size from the play distance, not this table; numbers readable at a glance, targets ≥ 44px on touch.

## Density sanity check

At 1440x900 an Operate screen should show real work: a list view shows 12+ rows, a board shows 4+ cards per column, a table shows 12+ rows above the fold. Fewer means the scale is too large.
