// A tiny deterministic synthesizer for games' sound build scripts (Node 18+, no packages): the
// portfolio's effects are synthesized by committed scripts into WAV files the game imports. Same
// script, same bytes. Not a Godot resource; never exported.

export const RATE = 22050;

/** Mulberry32: a seeded random source in [0, 1). */
export function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const samples = (dur) => Math.max(1, Math.round(dur * RATE));

/** An oscillator; freqEnd glides exponentially from freq. */
export function tone({ freq, freqEnd = freq, dur, wave = "sine", gain = 0.5 }) {
  const n = samples(dur);
  const out = new Float32Array(n);
  let phase = 0;
  for (let i = 0; i < n; i++) {
    const f = freq * Math.pow(freqEnd / freq, i / n);
    phase += f / RATE;
    const p = phase - Math.floor(phase);
    let v;
    if (wave === "square") v = p < 0.5 ? 1 : -1;
    else if (wave === "triangle") v = 4 * Math.abs(p - 0.5) - 1;
    else v = Math.sin(2 * Math.PI * p);
    out[i] = v * gain;
  }
  return out;
}

export function noise({ dur, seed, gain = 0.5 }) {
  const r = rng(seed);
  const out = new Float32Array(samples(dur));
  for (let i = 0; i < out.length; i++) out[i] = (r() * 2 - 1) * gain;
  return out;
}

/** A plucked string (Karplus–Strong); damping near 1 rings longer. */
export function pluck({ freq, dur, seed, gain = 0.5, damping = 0.996 }) {
  const r = rng(seed);
  const period = Math.max(2, Math.round(RATE / freq));
  const buf = new Float32Array(period);
  for (let i = 0; i < period; i++) buf[i] = r() * 2 - 1;
  const out = new Float32Array(samples(dur));
  for (let i = 0; i < out.length; i++) {
    const k = i % period;
    const v = buf[k];
    out[i] = v * gain;
    buf[k] = damping * 0.5 * (v + buf[(k + 1) % period]);
  }
  return out;
}

/** Linear fade in and out (seconds), in place; the first and last samples become 0. */
export function envelope(s, { attack = 0.005, release = 0.02 }) {
  const a = Math.max(1, Math.round(attack * RATE));
  const r = Math.max(1, Math.round(release * RATE));
  for (let i = 0; i < s.length; i++) {
    let g = 1;
    if (i < a) g = i / a;
    const fromEnd = s.length - 1 - i;
    if (fromEnd < r) g = Math.min(g, fromEnd / r);
    s[i] = g === 0 ? 0 : s[i] * g;
  }
  return s;
}

/** Sums sounds into a buffer of dur seconds; each part is [samples, offsetSeconds]. */
export function mix(dur, parts) {
  const out = new Float32Array(samples(dur));
  for (const [s, offset] of parts) {
    const o = Math.round(offset * RATE);
    for (let i = 0; i < s.length && o + i < out.length; i++) out[o + i] += s[i];
  }
  return out;
}

/** For a seamless loop: everything past loopLength samples is added onto the start. */
export function loopFold(s, loopLength) {
  const out = new Float32Array(loopLength);
  for (let i = 0; i < s.length; i++) out[i % loopLength] += s[i];
  return out;
}

export function normalize(s, peak) {
  let max = 0;
  for (const v of s) max = Math.max(max, Math.abs(v));
  if (max === 0) return s;
  const g = peak / max;
  return s.map((v) => v * g);
}

/** PCM 16-bit mono WAV at RATE. */
export function wav(s) {
  const data = Buffer.alloc(s.length * 2);
  for (let i = 0; i < s.length; i++) {
    const v = Math.max(-1, Math.min(1, s[i]));
    data.writeInt16LE(Math.round(v < 0 ? v * 32768 : v * 32767), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write("RIFF", 0, "ascii");
  h.writeUInt32LE(36 + data.length, 4);
  h.write("WAVE", 8, "ascii");
  h.write("fmt ", 12, "ascii");
  h.writeUInt32LE(16, 16);
  h.writeUInt16LE(1, 20);
  h.writeUInt16LE(1, 22);
  h.writeUInt32LE(RATE, 24);
  h.writeUInt32LE(RATE * 2, 28);
  h.writeUInt16LE(2, 32);
  h.writeUInt16LE(16, 34);
  h.write("data", 36, "ascii");
  h.writeUInt32LE(data.length, 40);
  return Buffer.concat([h, data]);
}
