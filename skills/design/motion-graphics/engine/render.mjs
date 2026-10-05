#!/usr/bin/env node
// Render a motion composition frame by frame with headless Chromium (Playwright).
//
//   node engine/render.mjs --html motion.html --config motion.json --out out/video.mp4 [--workers 4] [--crf 16]
//   node engine/render.mjs --html motion.html --config motion.json --stills 0.8,4.2 --stills-dir out/stills
//
// motion.json ({"size": [W, H], "fps": 30, "duration": 24, ...}) is injected as
// window.MG_CONFIG before the page loads. Each worker renders a contiguous frame range
// to its own H.264 segment; segments are joined with the concat demuxer (stream copy).
// The output is silent; mux audio afterwards (SKILL.md).
import { chromium } from "playwright";
import { spawn } from "node:child_process";
import { mkdir, readFile, writeFile, rm } from "node:fs/promises";
import { dirname, resolve, join } from "node:path";
import { pathToFileURL } from "node:url";

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => {
    if (a.startsWith("--")) acc.push([a.slice(2), all[i + 1]?.startsWith("--") ? "1" : all[i + 1]]);
    return acc;
  }, []),
);
const need = (k) => {
  if (!args[k]) throw new Error(`missing --${k}`);
  return args[k];
};

const html = resolve(need("html"));
const config = JSON.parse(await readFile(resolve(need("config")), "utf8"));
const [W, H] = config.size || [1080, 1920];
const fps = config.fps || 30;
const duration = config.duration;
if (!duration) throw new Error("motion.json needs duration (seconds)");
const url = `${pathToFileURL(html).href}?w=${W}&h=${H}&render=1`;

const browser = await chromium.launch({ args: ["--allow-file-access-from-files", "--font-render-hinting=none"] });

async function openPage() {
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  await ctx.addInitScript((cfg) => { window.MG_CONFIG = cfg; }, config);
  const page = await ctx.newPage();
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  await page.goto(url);
  await page.waitForFunction(() => window.__mgReady === true, null, { timeout: 30000 });
  if (errors.length) throw new Error(`composition errors:\n${errors.join("\n")}`);
  return { page, errors };
}

async function frame(page, t) {
  await page.evaluate((t) => window.renderAt(t), t);
  return page.screenshot({ type: "png", animations: "allow", caret: "initial" });
}

function ffmpeg(out) {
  const p = spawn("ffmpeg", [
    "-hide_banner", "-loglevel", "error", "-y",
    "-f", "image2pipe", "-framerate", String(fps), "-c:v", "png", "-i", "-",
    "-c:v", "libx264", "-preset", args.preset || "medium", "-crf", args.crf || "16",
    "-pix_fmt", "yuv420p", "-r", String(fps), "-movflags", "+faststart", out,
  ], { stdio: ["pipe", "inherit", "inherit"] });
  const done = new Promise((ok, bad) => p.on("close", (c) => (c === 0 ? ok() : bad(new Error(`ffmpeg exit ${c}`)))));
  const write = (buf) => new Promise((ok) => (p.stdin.write(buf) ? ok() : p.stdin.once("drain", ok)));
  return { write, end: () => (p.stdin.end(), done) };
}

if (args.stills) {
  const dir = resolve(need("stills-dir"));
  await mkdir(dir, { recursive: true });
  const { page, errors } = await openPage();
  const times = args.stills.split(",").map(Number);
  for (const [i, t] of times.entries()) {
    await writeFile(join(dir, `still-${String(i + 1).padStart(2, "0")}-${t}s.png`), await frame(page, t));
  }
  if (errors.length) throw new Error(errors.join("\n"));
  console.log(JSON.stringify({ stills: times.length, dir }));
} else {
  const out = resolve(need("out"));
  await mkdir(dirname(out), { recursive: true });
  const total = Math.round(duration * fps);
  const workers = Math.max(1, Math.min(Number(args.workers || 4), total));
  const per = Math.ceil(total / workers);
  const segDir = `${out}.segments`;
  await mkdir(segDir, { recursive: true });
  let rendered = 0;
  const started = Date.now();
  const segments = await Promise.all(
    [...Array(workers).keys()].map(async (w) => {
      const from = w * per, to = Math.min(total, from + per);
      if (from >= to) return null;
      const seg = join(segDir, `seg-${String(w).padStart(2, "0")}.mp4`);
      const { page, errors } = await openPage();
      const enc = ffmpeg(seg);
      for (let f = from; f < to; f++) {
        await enc.write(await frame(page, f / fps));
        if (++rendered % fps === 0)
          process.stderr.write(`\r${rendered}/${total} frames ${((Date.now() - started) / 1000).toFixed(0)}s`);
      }
      await enc.end();
      if (errors.length) throw new Error(`worker ${w}: ${errors.join("\n")}`);
      return seg;
    }),
  );
  process.stderr.write("\n");
  const list = join(segDir, "list.txt");
  await writeFile(list, segments.filter(Boolean).map((s) => `file '${s}'`).join("\n") + "\n");
  await new Promise((ok, bad) =>
    spawn("ffmpeg", ["-hide_banner", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", "-movflags", "+faststart", out], { stdio: "inherit" })
      .on("close", (c) => (c === 0 ? ok() : bad(new Error(`concat exit ${c}`)))),
  );
  await rm(segDir, { recursive: true, force: true });
  console.log(JSON.stringify({ out, frames: total, fps, size: [W, H], seconds: (Date.now() - started) / 1000 }));
}
await browser.close();
