import { test } from "node:test";
import assert from "node:assert/strict";
import { parsePath, inside, Drawing, FULL, SIMPLE, PAPER } from "../../addons/churrinche_kit/art/engraving.mjs";

const SQUARE = "M10,10 L90,10 L90,90 L10,90 Z";
const CIRCLE = "M50,10 C72,10 90,28 90,50 C90,72 72,90 50,90 C28,90 10,72 10,50 C10,28 28,10 50,10 Z";
const RING = CIRCLE + " M50,30 C61,30 70,39 70,50 C70,61 61,70 50,70 C39,70 30,61 30,50 C30,39 39,30 50,30 Z";

test("inside a square", () => {
  const p = parsePath(SQUARE);
  assert.ok(inside(p, 50, 50));
  assert.ok(!inside(p, 5, 50));
  assert.ok(!inside(p, 95, 95));
});

test("inside a circle made of curves", () => {
  const p = parsePath(CIRCLE);
  assert.ok(inside(p, 50, 50));
  assert.ok(inside(p, 85, 50));
  assert.ok(!inside(p, 15, 15));
});

test("a ring has a hole", () => {
  const p = parsePath(RING);
  assert.ok(inside(p, 20, 50));
  assert.ok(!inside(p, 50, 50));
});

test("relative commands equal their absolute forms", () => {
  assert.deepEqual(parsePath("m10,10 l80,0 l0,80 l-80,0 z"), parsePath(SQUARE));
  assert.deepEqual(
    parsePath("M10,10 c10,0 20,10 20,20 q0,10 -10,10 Z"),
    parsePath("M10,10 C20,10 30,20 30,30 Q30,40 20,40 Z")
  );
});

test("implicit repeated coordinates after L", () => {
  assert.deepEqual(parsePath("M10,10 L90,10 90,90 10,90 Z"), parsePath(SQUARE));
});

test("unsupported command throws", () => {
  assert.throws(() => parsePath("M0,0 A10,10 0 0 1 20,20"), /unsupported path command A/);
});

function bbox(d) {
  const nums = [...d.matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
  const xs = nums.filter((_, i) => i % 2 === 0), ys = nums.filter((_, i) => i % 2 === 1);
  return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
}

function engraved(level) {
  const dr = new Drawing(level);
  dr.engrave(SQUARE, "#123456", () => 0.8, { circles: [50, -100], r0: 100, r1: 200, a0: Math.PI / 2 - 0.6, a1: Math.PI / 2 + 0.6, sp: 2.6 });
  return dr;
}

test("engraving stays inside the shape", () => {
  const svg = engraved(FULL).toSvg("0 0 100 100");
  const d = svg.match(/<path d="([^"]+)" fill="#123456"/)[1];
  const [x0, y0, x1, y1] = bbox(d);
  assert.ok(x0 >= 8 && y0 >= 8 && x1 <= 92 && y1 <= 92, `${x0},${y0},${x1},${y1}`);
});

test("same input, same output", () => {
  assert.equal(engraved(FULL).toSvg(), engraved(FULL).toSvg());
});

test("the simple level has fewer lines", () => {
  const runs = (dr) => (dr.toSvg().match(/M/g) || []).length;
  assert.ok(runs(engraved(SIMPLE)) < runs(engraved(FULL)));
});

test("svg document", () => {
  const dr = new Drawing(FULL);
  dr.outline(SQUARE, "#123456");
  dr.eye(50, 50, 4, "#123456");
  const svg = dr.toSvg();
  assert.match(svg, /^<svg xmlns="http:\/\/www.w3.org\/2000\/svg" viewBox="10 20 200 196" width="200" height="196">/);
  assert.match(svg, /<\/svg>\n$/);
  assert.equal((svg.match(/<svg/g) || []).length, 1);
  assert.ok(svg.includes(PAPER));
});
