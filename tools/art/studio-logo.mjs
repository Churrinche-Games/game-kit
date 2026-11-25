// The Churrinche Games logo: a churrinche (vermilion flycatcher) perched on a twig, in the
// portfolio's engraving style, one ink on paper. Writes docs/brand/churrinche.svg (the bird on
// paper, square) for the GitHub org picture and the website; render it with
//   node tools/art/studio-logo.mjs && godot --headless --path . -s tools/art/render_svg.gd -- \
//     docs/brand/churrinche.svg build/churrinche-500.png 500
// The red of the bird is the light engraving; its brown back, wings and mask the heavy one.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Drawing, FULL, PAPER, clamp, ell } from "../../addons/churrinche_kit/art/engraving.mjs";

export const INK = "#b3302a";
const PI = Math.PI;
const BODY = (cx, a = 0.75) => ({ circles: [cx, -160], r0: 190, r1: 360, a0: PI / 2 - a, a1: PI / 2 + a, sp: 2.4 });

export function churrinche(dr, ink = INK) {
  const L = dr.L;
  const sil =
    "M94,70 C98,52 110,36 126,36 C138,36 148,42 154,52 C156,56 157,60 156,64 " +
    "C160,70 162,76 161,80 L182,85 L161,91 C164,122 154,150 132,166 C118,176 102,178 90,172 " +
    "L58,206 L46,198 L76,160 C66,140 68,106 80,88 C86,80 90,74 94,70 Z";
  const WING = "M80,96 C100,94 118,110 120,132 C122,152 108,166 92,170 C82,160 74,140 76,118 C76,108 78,100 80,96 Z";
  dr.path(sil, { fill: PAPER });
  dr.engrave(sil, ink, (x, y) => {
    if (Math.hypot(x - 138, y - 78) < 8) return 0; // the eye's paper ring
    if (ell(x, y, 134, 78, 30, 10) < 1 && x > 106) return 1; // dark mask through the eye
    if (ell(x, y, 84, 104, 24, 42) < 1) return 0.75; // brown nape and back
    if (dr.inside(WING, x, y)) return 0.82; // brown wing
    if (x < 82 && y > 150) return 0.85; // brown tail
    if (x < 96 && y < 120) return 0.7; // brown back
    if (y < 58) return 0.28; // red crest
    const f = clamp(ell(x, y, 126, 118, 42, 62));
    return 0.18 + 0.4 * f ** 3; // red breast, shaded at the edges
  }, BODY(118));
  dr.outline(sil, ink);
  dr.outline(WING, ink, 0.8);
  dr.line("M88,120 C96,134 100,148 98,162 M98,112 C108,126 112,142 110,156", ink, 1.1); // feathers
  dr.line("M108,48 C112,44 116,42 120,41 M130,41 C136,42 142,45 146,49", ink, 1.1); // crest feathers
  dr.line("M161,85 L176,85", ink, 1.1);
  dr.eye(138, 78, 4.6, ink);
  dr.line("M30,190 C70,184 130,184 196,188 M168,186 L180,176", ink, 2.6); // the twig
  dr.line("M110,176 L108,187 M102,188 L116,187 M124,172 L127,186 M120,187 L134,186", ink, 1.8); // feet
}

const out = join(dirname(fileURLToPath(import.meta.url)), "../../docs/brand");
mkdirSync(out, { recursive: true });
const dr = new Drawing(FULL);
churrinche(dr);
// Square, with the bird centred on paper (the org picture is shown in a circle or a rounded square).
const body = dr.items.join("\n");
writeFileSync(
  join(out, "churrinche.svg"),
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" width="240" height="240">\n` +
    `<rect x="0" y="0" width="100%" height="100%" fill="${PAPER}"/>\n` +
    `<g transform="translate(7 0)">\n${body}\n</g>\n</svg>\n`,
);
console.log("wrote docs/brand/churrinche.svg");
