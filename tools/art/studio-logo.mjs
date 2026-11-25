// The Churrinche Games logo (locked by Juan, 2026-11-25): a churrinche (vermilion flycatcher)
// perched on a twig, in the portfolio's engraving style, one ink on paper. The composition comes
// from a sketch Juan picked; it is drawn here in code, like all the portfolio's art.
// Writes docs/brand/churrinche.svg (square, on paper); the org picture and the website use
// docs/brand/churrinche-500.png:
//   node tools/art/studio-logo.mjs && godot --headless --path . -s tools/art/render_svg.gd -- \
//     docs/brand/churrinche.svg docs/brand/churrinche-500.png 500
// The red parts (cap, chest) are light engraving; the mask, back, wing, tail and bill are dark.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Drawing, FULL, PAPER, clamp, ell } from "../../addons/churrinche_kit/art/engraving.mjs";

export const INK = "#b3302a";
/** The tone of the dark feathers: back, wing, mask and bill. */
const DARK = 0.84;
const PI = Math.PI;

/** An ellipse as path data the engraving library can parse (four cubic curves). */
function oval(cx, cy, rx, ry) {
  const k = 0.5523, f = (n) => Number(n.toFixed(2));
  return `M${f(cx + rx)},${f(cy)} C${f(cx + rx)},${f(cy + ry * k)} ${f(cx + rx * k)},${f(cy + ry)} ${f(cx)},${f(cy + ry)} ` +
    `C${f(cx - rx * k)},${f(cy + ry)} ${f(cx - rx)},${f(cy + ry * k)} ${f(cx - rx)},${f(cy)} ` +
    `C${f(cx - rx)},${f(cy - ry * k)} ${f(cx - rx * k)},${f(cy - ry)} ${f(cx)},${f(cy - ry)} ` +
    `C${f(cx + rx * k)},${f(cy - ry)} ${f(cx + rx)},${f(cy - ry * k)} ${f(cx + rx)},${f(cy)} Z`;
}

export function churrinche(dr, ink = INK) {
  // After the composition Juan picked (2026-11-25, from a generated sketch, redrawn here in code):
  // a round ball of a body leaning right, a smaller round head on top-right, a dark folded wing
  // with pale feather scallops, a fanned dark tail, two legs gripping a rising twig. The crown is a
  // feathered red cap (medium tone, fine lines), never bare paper: bare, it read as bald.
  const BODY_D = oval(122, 114, 50, 48);
  const HEAD = oval(139, 60, 30, 28);
  const WING = "M108,72 C92,80 78,100 70,122 C64,138 60,150 60,158 C74,154 92,140 104,124 C114,108 118,90 114,76 Z";
  const TAIL = "M82,140 C74,162 64,182 58,198 C58,206 66,209 71,204 C74,209 81,209 84,203 C89,186 95,166 99,150 Z";
  const MASK = "M168,55 C150,45 124,44 106,56 L104,71 C124,62 150,63 168,66 Z";
  const EYE = [141, 57];
  const DARK_EYE = (x, y) => Math.hypot(x - EYE[0], y - EYE[1]) < 7;
  // The tail, then the twig behind the body.
  dr.path(TAIL, { fill: PAPER });
  dr.engrave(TAIL, ink, () => DARK, { circles: [200, 176], r0: 100, r1: 150, a0: PI * 0.85, a1: PI * 1.15, sp: 2.3 });
  dr.outline(TAIL, ink);
  dr.line("M70,203 L72,186", PAPER, 0.9); // the split between the two tail feathers
  dr.line("M100,218 L194,138 M186,145 L191,128 M184,147 L200,148", ink, 3);
  // The body: pale chest, darker towards the rim and under the wing.
  dr.path(BODY_D, { fill: PAPER });
  dr.engrave(BODY_D, ink, (x, y) => {
    if (dr.inside(WING, x, y)) return 0;
    const f = clamp(ell(x, y, 132, 106, 50, 50));
    const under = x < 108 && y < 110 ? DARK : 0; // the back, between the head and the wing
    return Math.max(under, 0.12 + 0.5 * f ** 3);
  }, { circles: [122, -130], r0: 186, r1: 300, a0: PI / 2 - 0.6, a1: PI / 2 + 0.6, sp: 2.4 });
  dr.outline(BODY_D, ink);
  // The head: a feathered red cap above the mask, pale throat below it.
  dr.path(HEAD, { fill: PAPER });
  dr.engrave(HEAD, ink, (x, y) => {
    if (dr.inside(MASK, x, y) || DARK_EYE(x, y)) return 0;
    if (y < 56) return 0.42 + 0.3 * clamp(ell(x, y, 142, 58, 30, 28)) ** 3; // the cap
    return 0.08 + 0.4 * clamp(ell(x, y, 142, 62, 30, 28)) ** 4; // the throat
  }, { circles: [139, -90], r0: 120, r1: 182, a0: PI / 2 - 0.5, a1: PI / 2 + 0.5, sp: 1.9 });
  dr.engrave(MASK, ink, (x, y) => (!dr.inside(HEAD, x, y) || DARK_EYE(x, y) ? 0 : DARK), {
    circles: [139, -4000], r0: 4042, r1: 4074, a0: PI / 2 - 0.02, a1: PI / 2 + 0.02, sp: 2.2,
  });
  // Outlined over the top and back only: the throat flows into the chest.
  dr.path("M110,68 C104,50 118,32 139,32 C160,32 172,48 168,66 C167,72 164,77 160,81", {
    fill: "none", stroke: ink, "stroke-width": 2 * dr.L.ow, "stroke-linecap": "round",
  });
  // The bill: short, thin, dark.
  dr.path("M167,57.5 L184,62 L167,64.5 Z", { fill: ink, stroke: ink, "stroke-width": 1, "stroke-linejoin": "round" });
  dr.eye(EYE[0], EYE[1], 3.8, ink);
  // The folded wing over the shoulder, with pale feather scallops.
  dr.path(WING, { fill: PAPER });
  dr.engrave(WING, ink, () => DARK, { circles: [150, 170], r0: 40, r1: 130, a0: PI * 0.9, a1: PI * 1.5, sp: 2.2 });
  dr.outline(WING, ink, 1.4);
  for (const d of ["M78,118 C82,112 88,112 90,116", "M84,110 C88,104 94,104 96,108", "M90,102 C94,96 100,96 102,100", "M96,94 C100,88 106,88 108,92"]) {
    dr.path(d, { fill: "none", stroke: PAPER, "stroke-width": 1.4 * dr.L.ln, "stroke-linecap": "round" });
  }
  // Legs and toes gripping the twig.
  // Back leg to the lower grip, front leg to the upper one.
  // Each leg ends where its foot starts; a foot is one curve over the twig, a toe each side.
  // The twig runs y = 218 - 0.851 (x - 100): each foot's toes reach just below it on both sides.
  dr.line("M112,158 C117,170 122,182 126,193 M140,159 C143,163 147,168 151,171.5", ink, 2);
  dr.line("M120,203 C120,198 123,193 126,193 C130,192 134,189 136,191.5 M145,181 C145,176 148,171.5 151,171.5 C155,171 159,167 161,170", ink, 1.8);
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
    `<g transform="translate(0 0)">\n${body}\n</g>\n</svg>\n`,
);
console.log("wrote docs/brand/churrinche.svg");
