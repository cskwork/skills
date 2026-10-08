# Performance as UX

Speed is felt as quality. These are user-facing budgets, measured on the smallest supported device, not on a dev Mac.

## Rules

**P-1 Web vitals.** At the 75th percentile of mobile page loads: LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1. `[CWV]`

**P-2 App launch.** Cold launch to first usable screen <= 2 s on the smallest supported device; show the real first screen frame (not a logo splash) as early as possible. Games: playable title screen fast, heavy assets streamed after. Apple: keep a game's initial download to <= 30 min of play-ready content and fetch the rest in the background. `[HIG-Games]`

**P-3 Input latency.** Taps acknowledged within 100 ms (F-1). Scrolling and drags track the finger with no visible lag. `[NNG-Response]`

**P-4 Frame rate.** UI and gameplay hold a steady 60 fps on the smallest supported device (30 fps steady acceptable for heavy 3D games that target it). Drop effects before dropping frames; offer a low-power or low-spec mode in games. `[HIG-Motion]`

**P-5 No jank on first interaction.** Precompile shaders, warm caches, and preload fonts before the first interactive screen, so the first tap is as fast as later ones.

**P-6 Images.** Serve images at the device scale (@2x, @3x) and display size; modern formats on web (AVIF/WebP); reserve dimensions to avoid layout shift. `[CWV]`

**P-7 Battery and heat.** Pause rendering when nothing changes (menus can render on demand). Do not run 120 fps loops on static screens. `[HIG-Motion]`

**P-8 Measure.** Web: Lighthouse mobile profile + field data. iOS: Instruments (Time Profiler, Animation Hitches), MetricKit. Games: in-engine frame time graph on the smallest device.
