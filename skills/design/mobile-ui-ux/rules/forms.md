# Forms and input

## Rules

**I-1 Labels are visible.** Every field has a persistent label (above or leading). Placeholder text is an example, never the label. `[NNG-Forms]`

**I-2 Right keyboard and autofill.** Set the input type so the right keyboard appears (email, number pad, phone, URL) and set content type / `autocomplete` so iOS can autofill names, emails, one-time codes, passwords, and addresses. `[HIG-A11y]`

**I-3 Few fields.** Ask only for what the task needs now. Do not make users re-enter information they already gave in the same flow. `[WCAG-3.3.7]`

**I-4 Validate kindly.** Validate on blur or submit, not on every keystroke. Error text sits next to the field, says what is wrong and how to fix it, in plain words, at >= 4.5:1 contrast with an icon (C-4, C-9). Keep the user's input. `[NNG-Forms]`

**I-5 Keyboard does not cover the field.** The focused field and the submit button stay visible above the keyboard. The return key moves to the next field or submits. A tap outside dismisses the keyboard.

**I-6 Easy authentication.** No puzzles or memory tests to log in. Allow paste and password managers; offer Sign in with Apple / passkeys where accounts exist. `[WCAG-3.3.8]`

**I-7 Pickers over typing.** Prefer pickers, steppers, segmented controls, and toggles for bounded values. Use platform controls rather than custom look-alikes.

**I-8 Web input size.** See TY-2: inputs >= 16 CSS px.

**I-9 Primary button state.** The submit button is enabled and explains what is missing on tap, or disabled with a visible reason. A disabled button with no explanation is not allowed.

**I-10 Toggles apply immediately.** Settings toggles take effect without a Save button. A toggle shows its state with position and color plus a label; avoid glyphs inside switches that read as stray characters. `[Field]`
