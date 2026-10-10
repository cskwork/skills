# Choosing the stack

Pick the stack from what is being built, then confirm current setup steps from the library's own docs (versions move). Record the choice and one-line reason in `spec.md`.

## Rule that does not change

Build on a mature, accessible component system. Hand-rolled controls on raw `<input type=date>`, `<select>`, or `<dialog>` look like browser chrome and miss states; that alone makes a build read as a prototype. Plain HTML/CSS is fine only for a single static page with no complex controls.

## Decision order

1. **Existing project:** use its stack, component library, and tokens. Do not introduce a second UI kit.
2. **New project, by surface:**

| Building | Default | Why |
|---|---|---|
| Interactive web app, admin, internal tool | React + Vite + TypeScript, Tailwind CSS, shadcn/ui (Radix primitives); TanStack Table for data grids; dnd-kit for drag; sonner toasts; cmdk command palette | accessible primitives, every state styled, owned source to match the reference |
| App needing SSR, auth, SEO, or API routes | Next.js (App Router) + the same UI layer | server rendering and routing built in |
| Landing / marketing / docs site | Astro (or Next.js static) + Tailwind; islands for interactive bits | fast first paint, content-first |
| Data-heavy dashboard | React + shadcn/ui + a chart library (Recharts, visx, or ECharts for large data) | consistent charts with real axes and tooltips |
| iOS / Android app | SwiftUI or Jetpack Compose with native controls; Expo + React Native when one codebase is required | native affordances users expect |
| 2D web game | Phaser or PixiJS for the scene; DOM/React overlay for menus and HUD text | engine for rendering, DOM for crisp accessible text |
| 3D web game / scene | Three.js or React Three Fiber; DOM overlay UI | |
| Engine game | the project's engine (Godot, Unity) with its UI system and a theme built from the spec tokens | |

3. **Override when the brief says so** (a required framework, no-build constraint, hosting limit). State the trade-off.

## Theme from the spec

Map `spec.md` tokens into the kit's theme layer (CSS variables for shadcn/ui, Theme for Compose/SwiftUI, Godot Theme resource) before building screens, so every component inherits palette, radius, type, and spacing.
