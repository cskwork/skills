# Profile: crud-app

Use when the product's core is creating, reading, updating and deleting the user's records: to-do lists, notes, forms, bookings, settings, admin screens, accounts. Applies to web and native clients alike.

## Vocabulary

| Core term | Here |
|---|---|
| player | user (one harness-owned test account per case) |
| phase | screen or route, plus the record's state: empty, draft, saving, saved, error |
| command | mutation (create, update, delete, reorder), identified by its request ID or idempotency key where the API has one; otherwise count writes per user action |
| entity | record, as stored on the server or in local storage |

## Personas

| Core ID | Runs as | Stress |
|---|---|---|
| `new-player` | `new-user` | Empty state → first record → edit → delete → undo. Sign-up and sign-in when accounts exist. |
| `masher` | as written | Double Save/Create/Delete, Enter plus click, rapid complete/uncomplete toggles, reorder drag bursts. |
| `save-resume` | `draft-resume` | Type into a form, then close the tab or kill the app mid-edit and mid-save. Reopen: the draft is restored or discarded by the documented contract, and the next Save succeeds. |
| `interruptions` | as written | Offline then online mid-save, request timeout, session expiry (401) mid-edit, tab or app backgrounded during a save. |
| `resize` | as written | Smallest and largest viewport; the soft keyboard must leave the focused field and the submit button reachable. |
| `slow-player` | `slow-user` | Idle past the session timeout, then save; keep editing while a fixture holds the previous save for 3 s. |
| `speed-changer` | `latency` | Fixture-controlled responses at 0, 500 and 3000 ms, and responses returned out of order. |
| `monkey` | as written | Seeded taps across list, detail, filters, search, pagination, back/forward and deep links. |
| `localization` | as written | Korean IME: Enter during composition must not submit half-composed text. Drive composition with Chromium CDP `Input.imeSetComposition` then `Input.insertText`, or a real device keyboard, and record which; dispatching composition events by hand tests only the handler. Long Korean titles, local date and number formats. |
| `low-power-motion` | as written | As written. |

Extra cases:

| Case | Stress |
|---|---|
| `two-sessions` | Edit the same record in two tabs or two devices. The documented conflict rule holds and no edit vanishes silently. |
| `input-edges` | Empty, whitespace-only, maximum length, emoji, pasted rich text, 1,000 records, page boundaries, search with no result, sort ties. |

## Oracle bindings

| ID | Holds here when |
|---|---|
| O-2 | Each enabled Save sends exactly one mutation; an in-flight or disabled Save sends none. A rejected mutation shows an error and keeps the user's input. |
| O-3 | A screen accepts input only after its data has loaded. No refetch, background sync or autosave overwrites an edit in progress; a stale response never replaces newer state. |
| O-5 | Record IDs are unique; a double submit never creates two records. The visible list count equals the server count for the test account. An optimistic update settles to the server result or rolls back with a message. A deleted record is gone from list, detail, search and badge counts. |
| O-6 | Replay on the fixture layer with a fixed clock; normalise server-generated IDs and timestamps. |
| O-7 | Every spinner ends in success or an error with a retry within its deadline. |
| O-8 | A saved record survives reload, cold launch and sign-out/sign-in. Sign-out clears the user's data from local storage, including the SDK's offline cache (IndexedDB), unless the documented contract keeps it. A deleted record stays deleted after sync. |
| O-9 isolation | Two fixture accounts: user A never sees, edits or counts user B's records. |
| O-10 validation | Every server rejection maps to a field-level message and the user's input stays in the form. |

## Fixtures

Seed a test account and its records per case through the project's seed script or API, and reset between cases. Production accounts and data stay outside the harness.

- **Fixture layer** (the matrix, both clean passes, O-6 replay): the backend's local emulator where one exists (Firebase Emulator Suite, `supabase start`), else mocked or recorded responses. Observe mutations through the emulator's request log or a read-only client probe; HAR replay rarely fits realtime SDK transports such as Firestore's. Create test accounts in the emulator, not through real sign-up.
- **`live` layer**: one run of `new-user`, `masher` and `draft-resume` on seed 1000 against a staging backend, reported separately. It is outside the two-pass count and O-6. With no staging backend, report the layer as not run.
