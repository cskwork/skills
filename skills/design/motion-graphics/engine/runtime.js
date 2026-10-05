// Deterministic motion-graphics runtime.
//
// A composition is an HTML page that loads runtime.css + runtime.js, builds its DOM,
// registers scenes with MG.scene(start, end, fn, el) and calls MG.ready(). The
// renderer (render.mjs) calls window.renderAt(t) for every frame and
// screenshots the page, so every visual must be a pure function of t:
//   - no Date, performance.now(), requestAnimationFrame or Math.random (use MG.rng)
//   - CSS @keyframes / Web Animations are allowed: renderAt pauses them and sets
//     currentTime = t, so declare them at load and time them with animation-delay.
// Open the page directly in a browser with ?t=3.2 to inspect one frame, ?play=1 to
// preview in real time, and &guides=1 to see the safe zones (Shorts UI zones on a
// vertical frame, 5% title-safe margins otherwise).
(() => {
  const Q = new URLSearchParams(location.search);
  const MG = (window.MG = {});
  MG.config = window.MG_CONFIG || {};
  const size = MG.config.size || [1080, 1920];
  MG.W = +(Q.get("w") || size[0]);
  MG.H = +(Q.get("h") || size[1]);
  MG.duration = MG.config.duration || +(Q.get("duration") || 30);
  document.documentElement.style.setProperty("--W", MG.W + "px");
  document.documentElement.style.setProperty("--H", MG.H + "px");

  // ---- math -------------------------------------------------------------------
  MG.clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  MG.lerp = (a, b, p) =>
    Array.isArray(a) ? a.map((v, i) => MG.lerp(v, b[i], p)) : a + (b - a) * p;
  MG.map = (x, a, b, c, d) => c + ((x - a) / (b - a)) * (d - c);
  const c1 = 1.70158, c3 = c1 + 1, c4 = (2 * Math.PI) / 3;
  MG.ease = {
    linear: (p) => p,
    inQuad: (p) => p * p,
    outQuad: (p) => 1 - (1 - p) * (1 - p),
    inOutQuad: (p) => (p < 0.5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2),
    inCubic: (p) => p ** 3,
    outCubic: (p) => 1 - (1 - p) ** 3,
    inOutCubic: (p) => (p < 0.5 ? 4 * p ** 3 : 1 - (-2 * p + 2) ** 3 / 2),
    outQuart: (p) => 1 - (1 - p) ** 4,
    inOutQuart: (p) => (p < 0.5 ? 8 * p ** 4 : 1 - (-2 * p + 2) ** 4 / 2),
    inExpo: (p) => (p === 0 ? 0 : 2 ** (10 * p - 10)),
    outExpo: (p) => (p === 1 ? 1 : 1 - 2 ** (-10 * p)),
    inOutExpo: (p) =>
      p === 0 ? 0 : p === 1 ? 1 : p < 0.5 ? 2 ** (20 * p - 10) / 2 : (2 - 2 ** (-20 * p + 10)) / 2,
    inBack: (p) => c3 * p ** 3 - c1 * p * p,
    outBack: (p) => 1 + c3 * (p - 1) ** 3 + c1 * (p - 1) ** 2,
    outElastic: (p) =>
      p === 0 || p === 1 ? p : 2 ** (-10 * p) * Math.sin((p * 10 - 0.75) * c4) + 1,
    outBounce: (p) => {
      const n = 7.5625, d = 2.75;
      if (p < 1 / d) return n * p * p;
      if (p < 2 / d) return n * (p -= 1.5 / d) * p + 0.75;
      if (p < 2.5 / d) return n * (p -= 2.25 / d) * p + 0.9375;
      return n * (p -= 2.625 / d) * p + 0.984375;
    },
  };
  const easeFn = (e) => (typeof e === "function" ? e : MG.ease[e || "outCubic"]);
  // 0..1 progress of t through [a, b] with easing.
  MG.prog = (t, a, b, ease) => easeFn(ease)(MG.clamp((t - a) / (b - a)));
  // Keyframes: [[time, value], ...]; value may be a number or an array.
  MG.tween = (t, keys, ease) => {
    if (t <= keys[0][0]) return keys[0][1];
    for (let i = 1; i < keys.length; i++) {
      const [t1, v1, e1] = keys[i];
      const [t0, v0] = keys[i - 1];
      if (t <= t1) return MG.lerp(v0, v1, MG.prog(t, t0, t1, e1 || ease));
    }
    return keys[keys.length - 1][1];
  };
  // Damped spring from 0 to 1, t seconds after release. Overshoots when damping is low.
  MG.spring = (t, { stiffness = 170, damping = 18, mass = 1 } = {}) => {
    if (t <= 0) return 0;
    const w0 = Math.sqrt(stiffness / mass);
    const z = damping / (2 * Math.sqrt(stiffness * mass));
    if (z < 1) {
      const wd = w0 * Math.sqrt(1 - z * z);
      return 1 - Math.exp(-z * w0 * t) * (Math.cos(wd * t) + ((z * w0) / wd) * Math.sin(wd * t));
    }
    return 1 - Math.exp(-w0 * t) * (1 + w0 * t);
  };
  // Seeded PRNG (mulberry32) and smooth 1-D value noise in [-1, 1].
  MG.rng = (seed = 1) => {
    let a = seed >>> 0;
    return () => {
      a = (a + 0x6d2b79f5) >>> 0;
      let r = Math.imul(a ^ (a >>> 15), 1 | a);
      r = (r + Math.imul(r ^ (r >>> 7), 61 | r)) ^ r;
      return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
    };
  };
  const hash = (i, s) => MG.rng((i * 374761393 + s * 668265263) >>> 0)() * 2 - 1;
  MG.noise = (x, seed = 0) => {
    const i = Math.floor(x), f = x - i, u = f * f * (3 - 2 * f);
    return hash(i, seed) * (1 - u) + hash(i + 1, seed) * u;
  };

  // ---- DOM helpers ------------------------------------------------------------
  MG.$ = (sel, root = document) => root.querySelector(sel);
  MG.$$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  MG.el = (tag, attrs = {}, parent) => {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (k === "text") e.textContent = v;
      else if (k === "html") e.innerHTML = v;
      else if (k === "style") Object.assign(e.style, v);
      else e.setAttribute(k, v);
    }
    if (parent) parent.appendChild(e);
    return e;
  };
  // Split an element's text into grapheme (or word) spans for per-letter animation.
  MG.split = (el, by = "grapheme") => {
    const text = el.textContent;
    el.textContent = "";
    const seg = new Intl.Segmenter(document.documentElement.lang || undefined, {
      granularity: by,
    });
    return [...seg.segment(text)].map(({ segment }) => {
      if (/^\s+$/.test(segment)) {
        el.appendChild(document.createTextNode(segment));
        return null;
      }
      return MG.el("span", { class: "mg-ch", text: segment }, el);
    }).filter(Boolean);
  };
  // Set transform/opacity/filter in one call: x y (px), s sx sy (scale), r (deg),
  // o (opacity), blur (px), plus any other key as a raw style property.
  MG.set = (el, v) => {
    if (!el) return;
    const tr = [];
    if (v.x !== undefined || v.y !== undefined) tr.push(`translate(${v.x || 0}px, ${v.y || 0}px)`);
    if (v.r !== undefined) tr.push(`rotate(${v.r}deg)`);
    if (v.s !== undefined) tr.push(`scale(${v.s})`);
    if (v.sx !== undefined || v.sy !== undefined) tr.push(`scale(${v.sx ?? 1}, ${v.sy ?? 1})`);
    if (tr.length) el.style.transform = tr.join(" ");
    if (v.o !== undefined) el.style.opacity = MG.clamp(v.o);
    if (v.blur !== undefined) el.style.filter = v.blur > 0.01 ? `blur(${v.blur}px)` : "none";
    for (const [k, val] of Object.entries(v))
      if (!["x", "y", "r", "s", "sx", "sy", "o", "blur"].includes(k)) el.style[k] = val;
  };
  MG.fmt = (n, { decimals = 0, locale } = {}) =>
    n.toLocaleString(locale || document.documentElement.lang || "en", {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    });

  // ---- timeline ---------------------------------------------------------------
  const scenes = [];
  const always = [];
  const clips = [];
  // fn(local, t, dur) runs while start <= t < end; el (optional element or array) is
  // hidden outside. Frames render out of order in parallel workers, so fn must set every
  // property it animates on every call; never rely on state left by an earlier frame.
  MG.scene = (start, end, fn, el) => scenes.push({ start, end, fn, el });
  MG.always = (fn) => always.push(fn);
  // Screen recordings: <video src="clip.mp4">. The clip shows its frame at
  // (t - start) * rate, clamped to its length, frame-accurately. H.264 MP4 and VP9 WebM
  // load; when a clip fails (HEVC, some Chromium builds), convert it to VP9 WebM.
  MG.clip = (video, start = 0, rate = 1) => {
    video.muted = true;
    video.preload = "auto";
    clips.push({ video, start, rate });
    return video;
  };
  const seek = (v, time) =>
    Math.abs(v.currentTime - time) < 1e-4
      ? null
      : new Promise((ok) => {
          v.addEventListener("seeked", ok, { once: true });
          v.currentTime = time;
        });

  // Captions from MG_CONFIG.captions ([{start, end, text}]); "\n" breaks lines.
  MG.captions = (cues = MG.config.captions || [], cls = "mg-caption") => {
    if (!cues.length) return;
    const box = MG.el("div", { class: cls }, document.body);
    MG.always((t) => {
      const cue = cues.find((c) => t >= c.start && t < c.end);
      const text = cue ? cue.text : "";
      if (box.dataset.text !== text) {
        box.dataset.text = text;
        box.innerHTML = "";
        for (const line of text.split("\n")) MG.el("span", { text: line }, box);
      }
      box.style.opacity = cue ? 1 : 0;
    });
  };

  window.renderAt = (t) => {
    for (const a of document.getAnimations()) {
      a.pause();
      a.currentTime = t * 1000;
    }
    for (const s of scenes) {
      const on = t >= s.start && t < s.end;
      for (const el of [].concat(s.el || [])) el.style.visibility = on ? "visible" : "hidden";
      if (on) s.fn(t - s.start, t, s.end - s.start);
    }
    for (const fn of always) fn(t);
    const pending = clips
      .map(({ video, start, rate }) =>
        seek(video, MG.clamp((t - start) * rate, 0, Math.max(0, video.duration - 0.001))))
      .filter(Boolean);
    return pending.length ? Promise.all(pending).then(() => true) : true;
  };

  // Vertical frames: Shorts/Reels UI zones (top bar, bottom title/channel block, right
  // action rail). Other frames: 5% title-safe margins. Keep key text out of them.
  const guides = () => {
    const g = MG.el("div", { class: "mg-guides" }, document.body);
    const zone = (style) => MG.el("div", { style }, g);
    if (MG.H > MG.W) {
      zone({ top: 0, left: 0, right: 0, height: "12.5%" });
      zone({ bottom: 0, left: 0, right: 0, height: "25%" });
      zone({ top: "36%", bottom: "25%", right: 0, width: "16.7%" });
    } else {
      zone({ top: 0, left: 0, right: 0, height: "5%" });
      zone({ bottom: 0, left: 0, right: 0, height: "5%" });
      zone({ top: 0, bottom: 0, left: 0, width: "5%" });
      zone({ top: 0, bottom: 0, right: 0, width: "5%" });
    }
  };

  MG.ready = async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map((i) => i.decode().catch(() => {})));
    await Promise.all(clips.map(({ video }) => video.readyState >= 2 ? null
      : new Promise((ok, bad) => {
          video.addEventListener("loadeddata", ok, { once: true });
          video.addEventListener("error", () => bad(new Error(`clip failed: ${video.src}`)), { once: true });
        })));
    if (Q.has("guides")) guides();
    const t0 = +(Q.get("t") || 0);
    await window.renderAt(t0);
    window.__mgReady = true;
    if (Q.has("play")) {
      const start = performance.now() - t0 * 1000;
      const loop = () => {
        window.renderAt(((performance.now() - start) / 1000) % MG.duration);
        requestAnimationFrame(loop);
      };
      requestAnimationFrame(loop);
    }
  };
})();
