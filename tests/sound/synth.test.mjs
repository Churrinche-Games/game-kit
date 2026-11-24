import { test } from "node:test";
import assert from "node:assert/strict";
import { RATE, rng, tone, noise, pluck, envelope, mix, loopFold, normalize, wav } from "../../addons/churrinche_kit/sound/synth.mjs";

test("wav header", () => {
  const b = wav(new Float32Array([0, 0.5, -0.5, 1]));
  assert.equal(b.toString("ascii", 0, 4), "RIFF");
  assert.equal(b.toString("ascii", 8, 12), "WAVE");
  assert.equal(b.readUInt16LE(20), 1); // PCM
  assert.equal(b.readUInt16LE(22), 1); // mono
  assert.equal(b.readUInt32LE(24), RATE);
  assert.equal(b.readUInt16LE(34), 16);
  assert.equal(b.toString("ascii", 36, 40), "data");
  assert.equal(b.readUInt32LE(40), 8);
  assert.equal(b.length, 44 + 8);
  assert.equal(b.readInt16LE(44 + 2), 16384);
  assert.equal(b.readInt16LE(44 + 6), 32767);
});

test("tone has its frequency", () => {
  const s = tone({ freq: 440, dur: 1, wave: "sine", gain: 0.5 });
  assert.equal(s.length, RATE);
  let crossings = 0;
  for (let i = 1; i < s.length; i++) if ((s[i - 1] < 0) !== (s[i] < 0)) crossings++;
  assert.ok(Math.abs(crossings - 880) <= 2, String(crossings));
});

test("tone glides", () => {
  const s = tone({ freq: 200, freqEnd: 400, dur: 1, wave: "sine", gain: 0.5 });
  let first = 0, last = 0;
  for (let i = 1; i < RATE / 10; i++) if ((s[i - 1] < 0) !== (s[i] < 0)) first++;
  for (let i = RATE - RATE / 10 + 1; i < RATE; i++) if ((s[i - 1] < 0) !== (s[i] < 0)) last++;
  assert.ok(last > first * 1.6, `${first} ${last}`);
});

test("envelope starts and ends at zero", () => {
  const s = envelope(tone({ freq: 300, dur: 0.2, wave: "square", gain: 0.6 }), { attack: 0.01, release: 0.05 });
  assert.equal(s[0], 0);
  assert.equal(s[s.length - 1], 0);
});

test("seeded noise is reproducible", () => {
  assert.deepEqual(noise({ dur: 0.05, seed: 7, gain: 0.5 }), noise({ dur: 0.05, seed: 7, gain: 0.5 }));
  assert.notDeepEqual(noise({ dur: 0.05, seed: 7, gain: 0.5 }), noise({ dur: 0.05, seed: 8, gain: 0.5 }));
  const r = rng(1);
  assert.ok(r() >= 0 && r() < 1);
});

test("pluck decays", () => {
  const s = pluck({ freq: 220, dur: 1, seed: 3, gain: 0.5, damping: 0.996 });
  const energy = (a, b) => s.slice(a, b).reduce((t, v) => t + v * v, 0);
  assert.ok(energy(0, 2000) > 10 * energy(RATE - 2000, RATE));
});

test("mix places sounds at their offsets", () => {
  const one = new Float32Array([1, 1]);
  const m = mix(1, [[one, 0], [one, 0.5]]);
  assert.equal(m.length, RATE);
  assert.equal(m[0], 1);
  assert.equal(m[Math.round(RATE / 2)], 1);
  assert.equal(m[10], 0);
});

test("normalize sets the peak", () => {
  const s = normalize(new Float32Array([0.1, -0.4, 0.2]), 0.8);
  assert.ok(Math.abs(Math.max(...s.map(Math.abs)) - 0.8) < 1e-6);
});

test("loopFold moves the tail onto the start", () => {
  const s = new Float32Array([0, 0, 0, 0, 0.5, 0.25]);
  const f = loopFold(s, 4);
  assert.deepEqual(Array.from(f), [0.5, 0.25, 0, 0]);
});
