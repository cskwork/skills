# Profile: media

Use when the product's core records, plays or edits audio, video or photos: voice recorders, podcasts, camera and gallery apps, music players.

## Vocabulary

| Core term | Here |
|---|---|
| phase | recorder or player state: idle, requesting permission, recording, paused, saving, playing, seeking |
| command | record, stop, pause, play, seek, trim, delete, share |
| entity | recording or asset: the file on disk plus its library entry |

## Fixtures

Feed known input. Web: Chromium `--use-fake-device-for-media-stream` with `--use-file-for-fake-audio-capture=<file>`. iOS Simulator: microphone and camera behave unlike devices, so recording, route changes and phone-call interruptions need the device layer. Keep short, long (30 min+) and silent sample files with known durations.

## Personas

| Core ID | Runs as | Stress |
|---|---|---|
| `new-player` | `new-user` | Permission prompt → allow → first recording → playback. Deny path → explanation and a way to Settings. |
| `masher` | as written | Record/stop, play/pause and seek bursts. |
| `save-resume` | as written | Kill during recording and during save; cold launch recovers or discards by contract. Playback position resumes. |
| `interruptions` | as written | Phone call, Siri or alarm (device), headphone or Bluetooth route change, backgrounding while recording, another app taking the audio session; tab hidden on web. |
| `resize` | as written | Waveform and timeline hit targets at both sizes and in landscape. |
| `slow-player` | `long-session` | A 30–60 minute recording, storage nearly full, low battery. |
| `speed-changer` | as written | Playback rates (0.5x–2x) where shipped. |
| `monkey` | as written | Scrub the timeline, delete while playing, share while saving. |
| `localization` | as written | Korean titles and file names, exported and shared. |
| `low-power-motion` | as written | As written. |

## Oracle bindings

| ID | Holds here when |
|---|---|
| O-2 | One record tap starts one capture session; one stop produces one file. |
| O-3 | The UI shows recording only while audio is actually captured; the first second is not clipped (check leading samples against the fixture). |
| O-5 | Library entries equal files on disk; durations match file metadata within 0.5 s; no orphan temp files; deleting an entry removes its file. |
| O-6 | Replay with the same input file; compare durations and decoded-audio hashes within a stated tolerance. |
| O-7 | Saving or encoding finishes within a deadline proportional to length; the player never stays loading. |
| O-8 | Recordings survive cold launch and app update. A recording cut by a kill is recovered as playable or removed, never left as a zero-byte entry. |
| O-9 permissions | Denied or revoked microphone, camera or photo access gives an explanatory state and no crash. |
| O-10 audio-session | When an interruption ends, the app is in the documented state (paused, not silently recording or playing). |
