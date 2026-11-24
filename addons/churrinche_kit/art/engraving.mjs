// The Churrinche engraving style as a small SVG library (Node 18+, no packages). Games draw their
// subjects with it in a build script and commit the SVGs; Godot imports those (this file is not a
// Godot resource and is never exported). Reference: tools/art/engraving-study.html in the kit, and
// the portfolio design's Art direction section.
//
// The style: one ink per drawing on paper, no tints. Tone is made by a family of parallel lines that
// follow the form; each line swells where the tone is dark (engrave). Pale markings are smooth
// outlined paper shapes (band). The eye is a plain dot with a highlight. Two levels of detail:
// FULL for 56 px and up, SIMPLE for 40 px and below.

export const PAPER = "#f1e6d6";

/** ow outline, sp line spacing, ey eye, st markings, ln stroke widths: multipliers per level. */
export const FULL = Object.freeze({ ow: 1, sp: 1, ey: 1, st: 1, ln: 1, simple: false });
export const SIMPLE = Object.freeze({ ow: 2.2, sp: 1.9, ey: 1.6, st: 1.6, ln: 1.9, simple: true });

export const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
/** Normalized distance from an ellipse's centre: < 1 inside. */
export const ell = (x, y, cx, cy, rx, ry) => Math.hypot((x - cx) / rx, (y - cy) / ry);

const CURVE_STEPS = 16;

/** Number formatting for the SVG: two decimals at most, no trailing zeros, never "-0". */
export function fmt(n) {
  const s = Number(n.toFixed(2)).toString();
  return s === "-0" ? "0" : s;
}

/**
 * Parses SVG path data (M L C Q Z, absolute and relative, implicit repeats) into closed polygons
 * (arrays of [x, y]); curves are flattened. Anything else throws, so a hand-written silhouette
 * never silently draws wrong.
 */
export function parsePath(d) {
  const tokens = d.match(/[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?/g) || [];
  const polys = [];
  let poly = null;
  let x = 0, y = 0, sx = 0, sy = 0, cmd = null, i = 0;
  const num = () => {
    if (i >= tokens.length || /[a-zA-Z]/.test(tokens[i])) throw new Error(`path data ends early: ${d}`);
    return Number(tokens[i++]);
  };
  const close = () => {
    if (poly && poly.length > 1) polys.push(poly);
    poly = null;
  };
  while (i < tokens.length) {
    if (/[a-zA-Z]/.test(tokens[i])) cmd = tokens[i++];
    else if (cmd === null) throw new Error(`path data must start with a command: ${d}`);
    const rel = cmd === cmd.toLowerCase();
    const ox = rel ? x : 0, oy = rel ? y : 0;
    switch (cmd.toUpperCase()) {
      case "M": {
        close();
        x = ox + num(); y = oy + num();
        sx = x; sy = y;
        poly = [[x, y]];
        cmd = rel ? "l" : "L"; // further pairs are line-tos
        break;
      }
      case "L": {
        x = ox + num(); y = oy + num();
        poly.push([x, y]);
        break;
      }
      case "C": {
        const x1 = ox + num(), y1 = oy + num(), x2 = ox + num(), y2 = oy + num();
        const ex = ox + num(), ey = oy + num();
        for (let k = 1; k <= CURVE_STEPS; k++) {
          const t = k / CURVE_STEPS, u = 1 - t;
          poly.push([
            u * u * u * x + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * ex,
            u * u * u * y + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * ey,
          ]);
        }
        x = ex; y = ey;
        break;
      }
      case "Q": {
        const x1 = ox + num(), y1 = oy + num(), ex = ox + num(), ey = oy + num();
        for (let k = 1; k <= CURVE_STEPS; k++) {
          const t = k / CURVE_STEPS, u = 1 - t;
          poly.push([u * u * x + 2 * u * t * x1 + t * t * ex, u * u * y + 2 * u * t * y1 + t * t * ey]);
        }
        x = ex; y = ey;
        break;
      }
      case "Z": {
        close();
        x = sx; y = sy;
        cmd = null;
        break;
      }
      default:
        throw new Error(`unsupported path command ${cmd}`);
    }
  }
  close();
  return polys;
}

/** Even-odd inside test against parsed polygons. */
export function inside(polys, px, py) {
  let odd = false;
  for (const poly of polys) {
    for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) {
      const [xa, ya] = poly[a], [xb, yb] = poly[b];
      if (ya > py !== yb > py && px < ((xb - xa) * (py - ya)) / (yb - ya) + xa) odd = !odd;
    }
  }
  return odd;
}

/** A smooth pale marking: a band along an elliptical arc, thickest in the middle. */
export function band(cx, cy, rx, ry, a0, a1, w) {
  const L = [], R = [];
  for (let i = 0; i <= 48; i++) {
    const t = i / 48, a = a0 + (a1 - a0) * t;
    const hw = (w / 2) * Math.pow(Math.sin(Math.PI * t), 0.6) + 0.4, c = Math.cos(a), s = Math.sin(a);
    L.push(`${fmt(cx + c * (rx + hw))},${fmt(cy + s * (ry + hw))}`);
    R.push(`${fmt(cx + c * (rx - hw))},${fmt(cy + s * (ry - hw))}`);
  }
  return `M${L.join("L")}L${R.reverse().join("L")}Z`;
}

const esc = (v) => String(v).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");

/** One drawing at one level of detail; add shapes in painting order, then toSvg(). */
export class Drawing {
  constructor(level) {
    this.L = level;
    this.items = [];
    this._parsed = new Map();
  }

  /** Parsed polygons of a path, cached (tone functions test the same markings many times). */
  polys(d) {
    if (!this._parsed.has(d)) this._parsed.set(d, parsePath(d));
    return this._parsed.get(d);
  }

  /** Inside test against path data, for tone functions. */
  inside(d, x, y) {
    return inside(this.polys(d), x, y);
  }

  add(tag, attrs) {
    const a = Object.entries(attrs).map(([k, v]) => ` ${k}="${esc(typeof v === "number" ? fmt(v) : v)}"`);
    this.items.push(`<${tag}${a.join("")}/>`);
  }

  path(d, attrs = {}) {
    this.add("path", { d, ...attrs });
  }

  circle(cx, cy, r, attrs = {}) {
    this.add("circle", { cx, cy, r, ...attrs });
  }

  ellipse(cx, cy, rx, ry, attrs = {}) {
    this.add("ellipse", { cx, cy, rx, ry, ...attrs });
  }

  /** A stroke; its width scales with the level (w × ln). */
  line(d, ink, w = 1.6) {
    this.path(d, {
      stroke: ink, "stroke-width": w * this.L.ln, fill: "none",
      "stroke-linecap": "round", "stroke-linejoin": "round",
    });
  }

  /** The silhouette's outline (2 units × ow). */
  outline(d, ink, w = 2) {
    this.path(d, { fill: "none", stroke: ink, "stroke-width": w * this.L.ow, "stroke-linejoin": "round" });
  }

  /** The plain dot eye: a paper ring, the ink dot, a highlight. r is the dot's horizontal radius. */
  eye(cx, cy, r, ink) {
    const e = this.L.ey;
    this.circle(cx, cy, r * 1.7 * e, { fill: PAPER });
    this.ellipse(cx, cy, r * e, r * 1.14 * e, { fill: ink });
    this.circle(cx + r * 0.36 * e, cy - r * 0.38 * e, r * 0.34 * e, { fill: PAPER });
  }

  /**
   * Engraves the shape d: a family of lines (concentric arcs {circles:[ox,oy], r0, r1, a0, a1, sp}
   * or rays {rays:[ox,oy], n, r0, r1, sp}) clipped to the shape; at each point the line is
   * sp × 0.92 × tone(x, y) wide (tone 0..1), and gaps where it is too thin.
   */
  engrave(d, ink, tone, fam) {
    const P = this.polys(d);
    const sp = fam.sp * this.L.sp;
    const runs = [];
    let run = [];
    const flush = () => {
      if (run.length > 1) runs.push(run);
      run = [];
    };
    const push = (x, y, nx, ny) => {
      const w = inside(P, x, y) ? sp * 0.92 * tone(x, y) : 0;
      if (w > 0.22) run.push([x, y, w, nx, ny]);
      else flush();
    };
    if (fam.circles) {
      const [ox, oy] = fam.circles;
      for (let r = fam.r0; r <= fam.r1; r += sp) {
        for (let a = fam.a0; a <= fam.a1; a += 0.7 / r) push(ox + Math.cos(a) * r, oy + Math.sin(a) * r, Math.cos(a), Math.sin(a));
        flush();
      }
    }
    if (fam.rays) {
      const [ox, oy] = fam.rays;
      for (let k = 0; k < fam.n; k++) {
        const a = (k / fam.n) * Math.PI * 2;
        for (let r = fam.r0; r <= fam.r1; r += 0.7) push(ox + Math.cos(a) * r, oy + Math.sin(a) * r, -Math.sin(a), Math.cos(a));
        flush();
      }
    }
    let out = "";
    for (const s of runs) {
      const L = [], R = [];
      for (const [x, y, w, nx, ny] of s) {
        L.push(`${fmt(x + (nx * w) / 2)},${fmt(y + (ny * w) / 2)}`);
        R.push(`${fmt(x - (nx * w) / 2)},${fmt(y - (ny * w) / 2)}`);
      }
      out += `M${L.join("L")}L${R.reverse().join("L")}Z`;
    }
    if (out) this.path(out, { fill: ink });
  }

  toSvg(viewBox = "10 20 200 196") {
    const [, , w, h] = viewBox.split(/\s+/);
    return (
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" width="${w}" height="${h}">\n` +
      this.items.join("\n") +
      "\n</svg>\n"
    );
  }
}
