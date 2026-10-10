# Category pattern inventory

A screen that matches its reference image but lacks what users expect from the category reads as a toy. Before building, list what the best products in the category do on this screen.

## Method

1. Name 3 best-in-class products for the surface (e.g. task manager: Linear, Todoist, Things; admin table: Stripe Dashboard, Retool, Notion database; game shop: the top 3 grossing games of the genre).
2. List 10-15 concrete patterns they share for this screen, from what you know and, when web access exists, from their docs or screenshots. Patterns, not looks: interactions, states, shortcuts, information shown.
3. Mark each `must` (brief needs it or users will miss it), `should` (cheap and expected), or `skip` (out of scope, with reason). Write the table into `spec.md`.
4. Build every `must` and `should`. The quality gate checks them.

## Common patterns by surface (starting points, verify per product)

- **Lists / boards (tasks, tickets, CRM):** hover row actions (complete, menu); context menu on right-click and `…`; inline title edit; date shortcuts (오늘, 내일, 다음 주) in a date popover; keyboard shortcuts with a `?` help sheet; command palette; drag reorder with keyboard alternative; multi-select with bulk actions; undo toast for complete/delete/move; empty state that teaches the add action; counts that update live; overdue and priority signals; truncation with full title on hover or in detail.
- **Admin tables:** sticky header; sortable columns; filters as chips with clear-all; saved views; pagination or virtual scroll with row count; row selection with bulk bar; column-specific formatting (tabular numbers right-aligned, status badges); loading skeleton rows; empty and no-results states distinct; export.
- **Forms / settings:** grouped sections with descriptions; inline validation on blur; dirty state with save bar; destructive actions separated and confirmed; disabled reasons on hover.
- **Dashboards:** clear time range control; KPI tiles that link to detail; charts with units, legends, and hover values; comparison to previous period; loading and no-data states per widget.
- **Landing:** one clear primary action above the fold; proof (logos, numbers, quotes) near claims; pricing clarity; FAQ; responsive nav; fast first paint.
- **Game menus / HUD:** primary action (Play) dominant; currency always visible in shops; confirm on spend; disabled reasons on locked items; controller/keyboard focus order; pause access.
