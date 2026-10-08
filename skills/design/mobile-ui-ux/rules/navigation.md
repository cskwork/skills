# Navigation and flows

## Rules

**N-1 Use platform structure.** Tab bar for 2 to 5 top-level sections; navigation stack for drill-down; sheet for a self-contained task. Tab bars navigate, they never perform actions. `[HIG-TabBars]` `[LawsUX-Jakob]`

**N-2 Tabs stay put.** The tab bar stays visible across its sections (modals may cover it). Do not hide or disable tabs when a section is empty; show an empty state instead. Avoid a "More" overflow tab. Tab labels are single words where possible. `[HIG-TabBars]`

**N-3 One primary action per screen.** Each screen has one visually dominant action. Secondary actions are visually weaker. If two actions compete, the screen does too much. `[LawsUX-Hick]` `[LawsUX-VonRestorff]`

**N-4 Fewer choices at decision points.** Keep choice sets short (about 5 to 7 visible options); group or progressive-disclose the rest. `[LawsUX-Hick]` `[LawsUX-Miller]` `[LawsUX-Choice]`

**N-5 Where am I, how do I go back.** Every non-root screen shows its title and a back or close control >= 44 pt with an arrow or X glyph (not text alone). Tapping the current user's own item in a scouting or compare view also returns home. `[Field]` `[HIG-Layout]`

**N-6 Modals are dismissible and honest.** Sheets close via a visible Close/Done and swipe-down, unless closing would lose data, in which case ask. Close and Cancel are on the leading side or top; the confirm action on the trailing side or bottom. `[HIG-Layout]`

**N-7 Destructive actions confirm or undo.** Delete, sell, reset, leave match: either a confirm step that names the consequence ("Sell for 3 gold?") or an undo window of at least 5 s. Destructive buttons are red-tinted and placed per T-10. `[Field]`

**N-8 Preserve state.** Switching tabs, backgrounding, or rotating keeps scroll position, inputs, and selection. Returning from a detail view restores the list position. `[HIG-TabBars]`

**N-9 Short paths to the core.** Core task or "Play" reachable from launch in <= 2 taps. Games start without navigating multiple menu levels. `[GAG]` `[HIG-Games]`

**N-10 Defer permissions.** Ask for notifications, tracking, camera, etc. at the moment the feature needs it, with a one-line reason first. Ask for ratings only after a positive moment and meaningful use. `[HIG-Games]`

**N-11 Consistent placement.** The same action lives in the same place on every screen (Close top-left or top-right, never both across screens). `[LawsUX-Jakob]`

**N-12 Search and filters (content apps).** Lists over ~20 items get search or filters; show the active filter and a one-tap clear.
