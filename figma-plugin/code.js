// =====================================================================
//  Clima Agora — gerador do protótipo no Figma
//  App do tempo Android (futuro Flutter) · Material 3 · pt-BR
//
//  Cria, no arquivo aberto:
//    📱 Protótipo      → 8 telas Android Large 360×800 ligadas por interações (Present ▶)
//    🎨 Design System  → Variables de cor, estilos de texto, ícones, componentes
//    🔌 APIs & Flutter → integrações externas e mapeamento de widgets
//
//  Tudo é feito com Auto Layout: redimensione a largura de uma tela e o
//  conteúdo se reorganiza (Fill container), como fará no Flutter.
// =====================================================================

// ---------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------
const C = {
  'bg/base': '#0A1233',
  'surface/solid': '#141E4A',
  'surface/solid-2': '#1C2860',
  'glass/fill': ['#FFFFFF', 0.12],
  'glass/stroke': ['#FFFFFF', 0.18],
  'divider': ['#FFFFFF', 0.08],
  'text/primary': '#FFFFFF',
  'text/secondary': ['#FFFFFF', 0.74],
  'text/tertiary': ['#FFFFFF', 0.54],
  'brand/primary': '#A8C7FA',
  'brand/on-primary': '#062E6F',
  'accent/sun': '#FFC23D',
  'accent/rain': '#5CC8FF',
  'status/good': '#4ADE80',
  'status/warning': '#FFB020',
  'status/danger': '#FF5A5F',
};

// Fundos dinâmicos por condição do tempo (gradiente vertical)
const SKY = {
  'Ensolarado': ['#0B2A7A', '#1F5FD0', '#4C9BEA'],
  'Parcialmente nublado': ['#0B1646', '#1D3FA0', '#3C7FD8'],
  'Nublado': ['#1E293B', '#334155', '#64748B'],
  'Chuva': ['#0B1026', '#1A2A5E', '#34518F'],
  'Tempestade': ['#0B0A1F', '#2A1B5E', '#4C2C8F'],
  'Noite': ['#020617', '#131A45', '#27306B'],
};

const TS = {
  display:   { size: 96, w: 'Light',   lh: 104, ls: -3, label: 'Display · temperatura' },
  headlineL: { size: 40, w: 'Regular', lh: 48,  ls: -1, label: 'Headline L · relógio' },
  headline:  { size: 28, w: 'Regular', lh: 36,  ls: 0,  label: 'Headline · valores' },
  titleL:    { size: 22, w: 'Regular', lh: 28,  ls: 0,  label: 'Title L · app bar' },
  title:     { size: 18, w: 'Medium',  lh: 24,  ls: 0,  label: 'Title · títulos' },
  titleS:    { size: 16, w: 'Medium',  lh: 22,  ls: 0,  label: 'Title S · destaques' },
  body:      { size: 14, w: 'Regular', lh: 20,  ls: 0,  label: 'Body · texto corrido' },
  bodyS:     { size: 12, w: 'Regular', lh: 16,  ls: 0,  label: 'Body S · apoio' },
  label:     { size: 12, w: 'Medium',  lh: 16,  ls: 2,  label: 'Label · botões/chips' },
  overline:  { size: 11, w: 'Medium',  lh: 16,  ls: 10, label: 'Overline · cabeçalho de card' },
};

const WEIGHTS = ['Light', 'Regular', 'Medium', 'Bold'];
let FAMILY = 'Roboto';
const VARS = {};
const STYLES = {};
const PENDING = [];
const WARN = [];
let UID = 0;

// ---------------------------------------------------------------------
// Utilitários de pintura
// ---------------------------------------------------------------------
function rgb(hex) {
  const h = hex.replace('#', '');
  return {
    r: parseInt(h.slice(0, 2), 16) / 255,
    g: parseInt(h.slice(2, 4), 16) / 255,
    b: parseInt(h.slice(4, 6), 16) / 255,
  };
}
function tok(key) {
  const v = C[key];
  return Array.isArray(v) ? { hex: v[0], a: v[1] } : { hex: v, a: 1 };
}
function hexOf(key) { return C[key] !== undefined ? tok(key).hex : key; }
function alphaOf(key) { return C[key] !== undefined ? tok(key).a : 1; }

// paint('text/primary') → cor ligada à Variable; paint('#FF0000', .5) → cor solta
function paint(key, alpha) {
  if (C[key] !== undefined) {
    const t = tok(key);
    const v = VARS[key];
    if (v && alpha == null) {
      try {
        return figma.variables.setBoundVariableForPaint({ type: 'SOLID', color: rgb(t.hex), opacity: 1 }, 'color', v);
      } catch (e) { /* segue sem variável */ }
    }
    return { type: 'SOLID', color: rgb(t.hex), opacity: t.a * (alpha == null ? 1 : alpha) };
  }
  return { type: 'SOLID', color: rgb(key), opacity: alpha == null ? 1 : alpha };
}
// Gradiente linear: dir 'down' (topo→base) ou 'right' (esq→dir)
function grad(stops, dir) {
  const T = dir === 'right' ? [[1, 0, 0], [0, 1, 0]] : [[0, 1, 0], [-1, 0, 1]];
  return {
    type: 'GRADIENT_LINEAR',
    gradientTransform: T,
    gradientStops: stops.map(function (s) {
      const c = rgb(s[1]);
      return { position: s[0], color: { r: c.r, g: c.g, b: c.b, a: s[2] == null ? 1 : s[2] } };
    }),
  };
}
function sky(cond) {
  const s = SKY[cond] || SKY['Parcialmente nublado'];
  return grad([[0, s[0]], [0.55, s[1]], [1, s[2]]], 'down');
}
function shadow(y, blur, a) {
  return { type: 'DROP_SHADOW', color: { r: 0, g: 0, b: 0, a: a }, offset: { x: 0, y: y }, radius: blur, spread: 0, visible: true, blendMode: 'NORMAL' };
}
function blur(r) { return { type: 'BACKGROUND_BLUR', radius: r, visible: true }; }

// ---------------------------------------------------------------------
// Construtores de nós
// ---------------------------------------------------------------------
function pad4(p) {
  if (p == null) return [0, 0, 0, 0];
  if (typeof p === 'number') return [p, p, p, p];
  if (p.length === 2) return [p[0], p[1], p[0], p[1]];
  return p;
}

// Frame com Auto Layout.
//  dir: 'V' | 'H' | undefined (sem auto layout)
//  sw/sh: 'FIXED' | 'HUG' | 'FILL' (sizing horizontal/vertical)
function F(parent, name, o) {
  o = o || {};
  const f = figma.createFrame();
  f.name = name;
  f.fills = o.fill ? (Array.isArray(o.fill) ? o.fill : [o.fill]) : [];
  if (o.w != null || o.h != null) f.resize(o.w != null ? o.w : 100, o.h != null ? o.h : 100);
  if (o.dir) {
    f.layoutMode = o.dir === 'H' ? 'HORIZONTAL' : 'VERTICAL';
    const p = pad4(o.pad);
    f.paddingTop = p[0]; f.paddingRight = p[1]; f.paddingBottom = p[2]; f.paddingLeft = p[3];
    f.itemSpacing = o.gap || 0;
    f.primaryAxisAlignItems = o.main || 'MIN';
    f.counterAxisAlignItems = o.cross || 'MIN';
  }
  if (o.stroke) {
    f.strokes = [Array.isArray(o.stroke) ? paint(o.stroke[0], o.stroke[1]) : paint(o.stroke)];
    f.strokeWeight = o.strokeW || 1;
    f.strokeAlign = 'INSIDE';
  }
  if (o.radius != null) f.cornerRadius = o.radius;
  if (o.effects) f.effects = o.effects;
  f.clipsContent = !!o.clip;
  if (o.opacity != null) f.opacity = o.opacity;
  if (parent) parent.appendChild(f);
  if (o.abs) f.layoutPositioning = 'ABSOLUTE';
  if (o.x != null) f.x = o.x;
  if (o.y != null) f.y = o.y;
  if (o.constraints) f.constraints = o.constraints;
  if (o.dir) {
    f.layoutSizingHorizontal = o.sw || (o.w != null ? 'FIXED' : 'HUG');
    f.layoutSizingVertical = o.sh || (o.h != null ? 'FIXED' : 'HUG');
  } else {
    if (o.sw) f.layoutSizingHorizontal = o.sw;
    if (o.sh) f.layoutSizingVertical = o.sh;
  }
  if (o.grow) f.layoutGrow = 1;
  if (o.scroll) f.overflowDirection = o.scroll;
  return f;
}

// Texto com estilo tipográfico (ligado ao Text Style do Design System)
function TX(parent, str, st, o) {
  o = o || {};
  const s = TS[st];
  const t = figma.createText();
  t.fontName = { family: FAMILY, style: o.weight || s.w };
  t.characters = str;
  t.fontSize = s.size;
  t.lineHeight = { unit: 'PIXELS', value: s.lh };
  t.letterSpacing = { unit: 'PERCENT', value: s.ls || 0 };
  t.fills = [Array.isArray(o.color) ? paint(o.color[0], o.color[1]) : paint(o.color || 'text/primary')];
  if (o.align) t.textAlignHorizontal = o.align;
  t.name = o.name || str.slice(0, 40);
  if (parent) parent.appendChild(t);
  if (o.w) { t.resize(o.w, s.lh); t.textAutoResize = 'HEIGHT'; }
  if (o.sw === 'FILL') { t.textAutoResize = 'HEIGHT'; t.layoutSizingHorizontal = 'FILL'; }
  if (!o.weight && STYLES[st]) {
    PENDING.push(t.setTextStyleIdAsync(STYLES[st].id).catch(function () {}));
  }
  return t;
}

// Nó vetorial a partir de SVG
function SV(parent, svg, name, o) {
  o = o || {};
  const n = figma.createNodeFromSvg(svg);
  n.name = name;
  n.fills = [];
  n.clipsContent = false;
  if (parent) parent.appendChild(n);
  if (o.abs) n.layoutPositioning = 'ABSOLUTE';
  if (o.x != null) n.x = o.x;
  if (o.y != null) n.y = o.y;
  if (o.constraints) n.constraints = o.constraints;
  return n;
}

// ---------------------------------------------------------------------
// Ícones (traço 2px, grade 24, estilo Material Symbols Rounded)
// ---------------------------------------------------------------------
function gearIcon() {
  let s = '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="7"/>';
  for (let i = 0; i < 8; i++) {
    const a = (Math.PI / 4) * i;
    const x1 = 12 + Math.cos(a) * 7, y1 = 12 + Math.sin(a) * 7;
    const x2 = 12 + Math.cos(a) * 10, y2 = 12 + Math.sin(a) * 10;
    s += '<line x1="' + x1.toFixed(2) + '" y1="' + y1.toFixed(2) + '" x2="' + x2.toFixed(2) + '" y2="' + y2.toFixed(2) + '"/>';
  }
  return s;
}
function sunIcon() {
  let s = '<circle cx="12" cy="12" r="4"/>';
  for (let i = 0; i < 8; i++) {
    const a = (Math.PI / 4) * i;
    s += '<line x1="' + (12 + Math.cos(a) * 7).toFixed(2) + '" y1="' + (12 + Math.sin(a) * 7).toFixed(2) + '" x2="' + (12 + Math.cos(a) * 9.5).toFixed(2) + '" y2="' + (12 + Math.sin(a) * 9.5).toFixed(2) + '"/>';
  }
  return s;
}
const ICONS = {
  'home': '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  'bookmark': '<path d="M18 21l-6-4-6 4V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2z"/>',
  'settings': gearIcon(),
  'search': '<circle cx="11" cy="11" r="7"/><line x1="20.5" y1="20.5" x2="16" y2="16"/>',
  'bell': '<path d="M6 9a6 6 0 0 1 12 0c0 6.5 3 8 3 8H3s3-1.5 3-8"/><path d="M10 21a2.2 2.2 0 0 0 4 0"/>',
  'pin': '<path d="M19 10c0 6-7 12-7 12S5 16 5 10a7 7 0 0 1 14 0z"/><circle cx="12" cy="10" r="2.5"/>',
  'locate': '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5"/><line x1="12" y1="1.5" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="22.5"/><line x1="1.5" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="22.5" y2="12"/>',
  'layers': '<path d="M12 3 2 8l10 5 10-5z"/><path d="m2 13 10 5 10-5"/><path d="m2 17.5 10 5 10-5"/>',
  'droplet': '<path d="M12 2.5S5.5 9.5 5.5 14.5a6.5 6.5 0 0 0 13 0C18.5 9.5 12 2.5 12 2.5z"/>',
  'wind': '<path d="M3 8h10.5a2.5 2.5 0 1 0-2.5-2.5"/><path d="M3 12h15a3 3 0 1 1-3 3"/><path d="M3 16h6"/>',
  'sun': sunIcon(),
  'gauge': '<path d="M3.5 18a9.5 9.5 0 1 1 17 0"/><line x1="12" y1="13" x2="16" y2="9"/>',
  'eye': '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  'umbrella': '<path d="M2.5 12a9.5 9.5 0 0 1 19 0z"/><path d="M12 12v7a2 2 0 0 1-4 0"/>',
  'sunrise': '<path d="M17 18a5 5 0 0 0-10 0"/><line x1="12" y1="3" x2="12" y2="9"/><path d="m9 6 3-3 3 3"/><line x1="2" y1="21" x2="22" y2="21"/><line x1="4.2" y1="11.2" x2="5.6" y2="12.6"/><line x1="19.8" y1="11.2" x2="18.4" y2="12.6"/>',
  'leaf': '<path d="M5 19c0-9 6-14 15-14 0 9-5 15-14 15"/><path d="M5 19 13 11"/>',
  'alert': '<path d="M10.3 3.9 2.4 17.5A2 2 0 0 0 4.1 20.5h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>',
  'chevron-right': '<path d="m9 18 6-6-6-6"/>',
  'arrow-left': '<path d="M19 12H5"/><path d="m12 19-7-7 7-7"/>',
  'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  'share': '<circle cx="18" cy="5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="19" r="2.5"/><line x1="8.3" y1="13.3" x2="15.7" y2="17.7"/><line x1="15.7" y1="6.3" x2="8.3" y2="10.7"/>',
  'mic': '<rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><line x1="12" y1="18" x2="12" y2="21.5"/>',
  'plus': '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
  'play': '<path d="M8 5v14l11-7z"/>',
  'wifi-off': '<line x1="2" y1="2" x2="22" y2="22"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 12.9a10 10 0 0 1 5.2-2.8"/><path d="M19 12.9a10 10 0 0 0-2.2-1.6"/><path d="M2 8.8a15 15 0 0 1 4.2-2.7"/><path d="M22 8.8A15 15 0 0 0 11 5"/><line x1="12" y1="20" x2="12.01" y2="20"/>',
  'refresh': '<path d="M21 12a9 9 0 1 1-2.6-6.4"/><path d="M21 3v6h-6"/>',
  'thermo': '<path d="M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0z"/>',
  'check': '<path d="M20 6 9 17l-5-5"/>',
};

function iconSvg(name, size, hex, alpha) {
  const op = alpha != null && alpha < 1 ? ' stroke-opacity="' + alpha + '"' : '';
  const fillPlay = name === 'play' ? ' fill="' + hex + '"' : ' fill="none"';
  return '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size + '" viewBox="0 0 24 24"' + fillPlay +
    ' stroke="' + hex + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"' + op + '>' + ICONS[name] + '</svg>';
}
function IC(parent, name, size, colorKey, o) {
  const key = colorKey || 'text/primary';
  return SV(parent, iconSvg(name, size || 24, hexOf(key), alphaOf(key)), 'ic/' + name, o);
}

// ---------------------------------------------------------------------
// Ilustrações do tempo (viewBox 100×100)
// ---------------------------------------------------------------------
function cloudShape(dx, dy, s, fill) {
  const g = '<g transform="translate(' + dx + ' ' + dy + ') scale(' + s + ')">';
  return g +
    '<circle cx="34" cy="58" r="14" fill="' + fill + '"/>' +
    '<circle cx="53" cy="47" r="20" fill="' + fill + '"/>' +
    '<circle cx="71" cy="58" r="13" fill="' + fill + '"/>' +
    '<rect x="20" y="56" width="64" height="18" rx="9" fill="' + fill + '"/></g>';
}
function sunShape(cx, cy, r, id) {
  let s = '<defs><radialGradient id="' + id + '" cx="40%" cy="35%" r="70%"><stop offset="0" stop-color="#FFE68A"/><stop offset="1" stop-color="#FFA41B"/></radialGradient></defs>';
  s += '<circle cx="' + cx + '" cy="' + cy + '" r="' + (r * 1.45) + '" fill="#FFD66B" fill-opacity="0.3"/>';
  s += '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="url(#' + id + ')"/>';
  return s;
}
function wxSvg(kind, size) {
  const id = 'g' + (++UID);
  let b = '';
  if (kind === 'sun') {
    b = sunShape(50, 50, 24, id);
    for (let i = 0; i < 8; i++) {
      const a = (Math.PI / 4) * i;
      b += '<line x1="' + (50 + Math.cos(a) * 36).toFixed(1) + '" y1="' + (50 + Math.sin(a) * 36).toFixed(1) + '" x2="' + (50 + Math.cos(a) * 45).toFixed(1) + '" y2="' + (50 + Math.sin(a) * 45).toFixed(1) + '" stroke="#FFC23D" stroke-width="5" stroke-linecap="round"/>';
    }
  } else if (kind === 'partly') {
    b = sunShape(62, 36, 20, id) + cloudShape(-6, 6, 1, '#F4F7FF');
  } else if (kind === 'cloud') {
    b = cloudShape(-2, -6, 1.04, '#DDE6F8') + cloudShape(10, 4, 0.8, '#F4F7FF');
  } else if (kind === 'rain') {
    b = cloudShape(-2, -14, 1, '#D5DFF3');
    [[34, 70], [50, 74], [66, 70]].forEach(function (p) {
      b += '<line x1="' + p[0] + '" y1="' + p[1] + '" x2="' + (p[0] - 5) + '" y2="' + (p[1] + 14) + '" stroke="#5CC8FF" stroke-width="5" stroke-linecap="round"/>';
    });
  } else if (kind === 'storm') {
    b = cloudShape(-2, -16, 1, '#A9B6D3') +
      '<path d="M54 60 42 80h10l-5 16 16-22H53l6-14z" fill="#FFC23D"/>';
  } else if (kind === 'night') {
    b = '<path d="M60 18a30 30 0 1 0 24 46 24 24 0 1 1-24-46z" fill="#E7EAFF"/>' +
      '<circle cx="26" cy="26" r="2.5" fill="#E7EAFF"/><circle cx="82" cy="24" r="2" fill="#E7EAFF"/><circle cx="20" cy="60" r="1.8" fill="#E7EAFF"/>';
  } else if (kind === 'night-cloud') {
    b = '<path d="M62 12a24 24 0 1 0 20 36 19 19 0 1 1-20-36z" fill="#E7EAFF"/>' + cloudShape(-8, 8, 0.95, '#C8D2EE');
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size + '" viewBox="0 0 100 100">' + b + '</svg>';
}
function WX(parent, kind, size, o) { return SV(parent, wxSvg(kind, size), 'wx/' + kind, o); }

// Mini mapa ilustrativo do diálogo de permissão do Android (precisa × aproximada)
function mapSvg(w, h) {
  let s = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">';
  s += '<rect width="' + w + '" height="' + h + '" fill="#141C3A"/>';
  // parques e rio
  s += '<path d="M' + (w * 0.55) + ' ' + (h * 0.12) + ' l' + (w * 0.22) + ' ' + (h * 0.04) + ' l' + (w * 0.02) + ' ' + (h * 0.12) + ' l-' + (w * 0.26) + ' ' + (h * 0.03) + 'z" fill="#17362F"/>';
  s += '<rect x="' + (w * 0.08) + '" y="' + (h * 0.62) + '" width="' + (w * 0.2) + '" height="' + (h * 0.1) + '" rx="10" fill="#17362F"/>';
  s += '<path d="M-10 ' + (h * 0.28) + ' C ' + (w * 0.3) + ' ' + (h * 0.22) + ', ' + (w * 0.45) + ' ' + (h * 0.42) + ', ' + (w + 10) + ' ' + (h * 0.36) + '" stroke="#1C3766" stroke-width="16" fill="none"/>';
  // ruas
  let seed = 7;
  function rnd() { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; }
  for (let x = -20; x < w + 40; x += 44 + rnd() * 20) {
    s += '<line x1="' + x.toFixed(0) + '" y1="-10" x2="' + (x + 30 - rnd() * 60).toFixed(0) + '" y2="' + (h + 10) + '" stroke="#222C52" stroke-width="' + (rnd() > 0.8 ? 6 : 3) + '"/>';
  }
  for (let y = 0; y < h + 40; y += 40 + rnd() * 24) {
    s += '<line x1="-10" y1="' + y.toFixed(0) + '" x2="' + (w + 10) + '" y2="' + (y + 20 - rnd() * 40).toFixed(0) + '" stroke="#222C52" stroke-width="' + (rnd() > 0.8 ? 6 : 3) + '"/>';
  }
  // avenidas
  s += '<path d="M' + (w * 0.1) + ' ' + (h + 10) + ' L ' + (w * 0.62) + ' -10" stroke="#3A4A86" stroke-width="7"/>';
  s += '<path d="M-10 ' + (h * 0.58) + ' L ' + (w + 10) + ' ' + (h * 0.5) + '" stroke="#3A4A86" stroke-width="7"/>';
  return s + '</svg>';
}

// ---------------------------------------------------------------------
// Dados fictícios (no app virão das APIs — ver página 🔌 APIs)
// ---------------------------------------------------------------------
const NOW = { city: 'São Paulo, SP', hood: 'Vila Mariana', time: '14:32', date: 'Terça-feira, 22 de setembro', temp: 24, cond: 'Parcialmente nublado', kind: 'partly', max: 27, min: 16, feels: 25 };
const HOURLY = [
  ['Agora', 'partly', 24, 0], ['15h', 'sun', 25, 0], ['16h', 'sun', 25, 0], ['17h', 'partly', 23, 10],
  ['18h', 'rain', 21, 60], ['19h', 'storm', 20, 80], ['20h', 'rain', 19, 70], ['21h', 'cloud', 18, 30],
  ['22h', 'night-cloud', 18, 10], ['23h', 'night', 17, 0], ['00h', 'night', 17, 0], ['01h', 'night', 16, 0],
];
const DAILY = [
  ['Hoje', 'partly', 16, 27, 20], ['Qua', 'storm', 17, 23, 90], ['Qui', 'rain', 15, 21, 70],
  ['Sex', 'cloud', 14, 22, 20], ['Sáb', 'sun', 15, 26, 0], ['Dom', 'sun', 17, 29, 0], ['Seg', 'partly', 18, 28, 10],
];
const METRICS = [
  ['droplet', 'UMIDADE', '62%', 'Orvalho 16°', null],
  ['wind', 'VENTO', '14 km/h', 'NE · rajadas 28', null],
  ['sun', 'ÍNDICE UV', '7 · Alto', 'Protetor até 15h', 'status/warning'],
  ['gauge', 'PRESSÃO', '1015', 'hPa · estável', null],
  ['eye', 'VISIBILIDADE', '10 km', 'Céu aberto', null],
  ['umbrella', 'CHUVA', '0 mm', '18h: 4 mm', 'accent/rain'],
];

// ---------------------------------------------------------------------
// Componentes de interface
// ---------------------------------------------------------------------
// Padrão de tela: Android Large (preset do Figma) 360×800 dp
const SCREEN = { W: 360, H: 800 };
const STATUS_H = 32, TOPBAR_H = 64, NAV_H = 80, GESTURE_H = 20;

function statusBar(parent, bg) {
  const s = F(parent, 'Status bar', { dir: 'H', sw: 'FILL', h: STATUS_H, pad: [0, 20, 0, 24], main: 'SPACE_BETWEEN', cross: 'CENTER', fill: bg || null });
  TX(s, NOW.time, 'label', { name: 'Hora do sistema' });
  SV(s, '<svg xmlns="http://www.w3.org/2000/svg" width="62" height="16" viewBox="0 0 62 16">' +
    '<rect x="0" y="10" width="3" height="5" rx="1" fill="#fff"/><rect x="5" y="7" width="3" height="8" rx="1" fill="#fff"/><rect x="10" y="4" width="3" height="11" rx="1" fill="#fff"/><rect x="15" y="1" width="3" height="14" rx="1" fill="#fff"/>' +
    '<path d="M24 6.5a10 10 0 0 1 14 0M26.5 9.5a6 6 0 0 1 9 0" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/><circle cx="31" cy="13" r="1.8" fill="#fff"/>' +
    '<rect x="42" y="3" width="17" height="10" rx="2.5" stroke="#fff" stroke-width="1.5" fill="none"/><rect x="44" y="5" width="11" height="6" rx="1" fill="#fff"/><rect x="59.5" y="6" width="2" height="4" rx="1" fill="#fff"/></svg>', 'Ícones do sistema');
  return s;
}

function gestureBar(parent, bg) {
  const g = F(parent, 'Barra de gestos', { dir: 'H', sw: 'FILL', h: GESTURE_H, main: 'CENTER', cross: 'CENTER', fill: bg || null });
  F(g, 'Indicador', { w: 108, h: 4, radius: 2, fill: paint('#FFFFFF', 0.5) });
  return g;
}

function iconBtn(parent, name, icon, o) {
  o = o || {};
  const b = F(parent, name, { dir: 'H', w: 48, h: 48, radius: 24, main: 'CENTER', cross: 'CENTER', fill: o.fill || null });
  IC(b, icon, 24, o.color || 'text/primary');
  if (o.badge) F(b, 'Badge', { w: 10, h: 10, radius: 5, fill: paint('status/danger'), stroke: '#0A1233', strokeW: 2, abs: true, x: 27, y: 11 });
  return b;
}

function chip(parent, label, o) {
  o = o || {};
  const active = !!o.active;
  const c = F(parent, 'Chip / ' + label, {
    dir: 'H', h: o.h || 32, pad: [0, 12, 0, o.icon ? 10 : 12], gap: 6, radius: (o.h || 32) / 2, cross: 'CENTER',
    fill: active ? paint('brand/primary') : (o.fill || paint('glass/fill')),
    stroke: active ? null : 'glass/stroke',
  });
  if (o.icon) IC(c, o.icon, 16, active ? 'brand/on-primary' : (o.iconColor || 'text/primary'));
  TX(c, label, 'label', { color: active ? 'brand/on-primary' : (o.color || 'text/primary') });
  return c;
}

function button(parent, label, kind, o) {
  o = o || {};
  const styles = {
    primary: { fill: paint('brand/primary'), color: 'brand/on-primary', stroke: null },
    tonal: { fill: paint('brand/primary', 0.16), color: 'brand/primary', stroke: null },
    outline: { fill: null, color: 'brand/primary', stroke: ['brand/primary', 0.5] },
    text: { fill: null, color: 'brand/primary', stroke: null },
  };
  const st = styles[kind || 'primary'];
  const b = F(parent, 'Botão / ' + label, {
    dir: 'H', h: o.h || 48, pad: [0, 20, 0, 20], gap: 8, radius: (o.h || 48) / 2, main: 'CENTER', cross: 'CENTER',
    fill: st.fill, stroke: st.stroke, sw: o.sw,
  });
  if (o.icon) IC(b, o.icon, 18, st.color);
  TX(b, label, o.h && o.h >= 56 ? 'titleS' : 'label', { color: st.color });
  return b;
}

function toggle(parent, on) {
  const t = F(parent, on ? 'Switch / ligado' : 'Switch / desligado', {
    dir: 'H', w: 52, h: 32, radius: 16, pad: [0, 4, 0, 4], cross: 'CENTER', main: on ? 'MAX' : 'MIN',
    fill: on ? paint('brand/primary') : paint('#FFFFFF', 0.06), stroke: on ? null : ['#FFFFFF', 0.45], strokeW: 2,
  });
  F(t, 'Knob', { w: on ? 24 : 16, h: on ? 24 : 16, radius: 12, fill: on ? paint('brand/on-primary') : paint('#FFFFFF', 0.6) });
  return t;
}

function segmented(parent, options, active) {
  const s = F(parent, 'Segmented / ' + options.join('|'), { dir: 'H', h: 36, radius: 18, stroke: ['#FFFFFF', 0.24], clip: true });
  options.forEach(function (op, i) {
    const on = i === active;
    const seg = F(s, op, { dir: 'H', pad: [0, 12, 0, 12], gap: 4, main: 'CENTER', cross: 'CENTER', sh: 'FILL', fill: on ? paint('brand/primary', 0.24) : null });
    if (on) IC(seg, 'check', 14, 'brand/primary');
    TX(seg, op, 'label', { color: on ? 'brand/primary' : 'text/secondary' });
    if (i < options.length - 1) F(s, 'Divisor', { w: 1, sh: 'FILL', dir: 'H', fill: paint('#FFFFFF', 0.24) });
  });
  return s;
}

// Card "vidro" (glassmorphism) com cabeçalho em overline
function card(parent, title, icon, o) {
  o = o || {};
  const c = F(parent, 'Card / ' + title, {
    dir: 'V', sw: o.sw || 'FILL', pad: o.pad != null ? o.pad : 16, gap: 12, radius: 24,
    fill: paint('glass/fill'), stroke: 'glass/stroke', effects: [blur(30)],
  });
  const h = F(c, 'Cabeçalho', { dir: 'H', sw: 'FILL', gap: 6, cross: 'CENTER' });
  IC(h, icon, 16, 'text/tertiary');
  TX(h, title, 'overline', { color: 'text/tertiary', sw: 'FILL' });
  if (o.action) TX(h, o.action, 'label', { color: 'brand/primary' });
  return c;
}

// Barra de navegação inferior (compacto) — Material 3 NavigationBar
const NAV_ITEMS = [['home', 'Início'], ['bookmark', 'Locais'], ['settings', 'Ajustes']];
function bottomNav(parent, active) {
  const n = F(parent, 'Navigation bar', { dir: 'H', sw: 'FILL', h: NAV_H, pad: [12, 8, 16, 8], fill: paint('#0A1233', 0.94), effects: [blur(20)] });
  const refs = {};
  NAV_ITEMS.forEach(function (it) {
    const on = it[1] === active;
    const item = F(n, 'Nav / ' + it[1], { dir: 'V', sw: 'FILL', gap: 4, cross: 'CENTER' });
    const pill = F(item, 'Indicador', { dir: 'H', w: 64, h: 32, radius: 16, main: 'CENTER', cross: 'CENTER', fill: on ? paint('brand/primary', 0.24) : null });
    IC(pill, it[0], 24, on ? 'brand/primary' : 'text/secondary');
    TX(item, it[1], 'label', { color: on ? 'text/primary' : 'text/secondary' });
    refs[it[1]] = item;
  });
  return refs;
}
// Navigation rail (≥ 600dp) — Material 3 NavigationRail
function navRail(parent, active) {
  const n = F(parent, 'Navigation rail', { dir: 'V', w: 80, sh: 'FILL', pad: [20, 0, 20, 0], gap: 16, cross: 'CENTER', fill: paint('#0A1233', 0.6), effects: [blur(20)] });
  const fab = F(n, 'FAB / Buscar', { dir: 'H', w: 56, h: 56, radius: 16, main: 'CENTER', cross: 'CENTER', fill: paint('brand/primary') });
  IC(fab, 'search', 24, 'brand/on-primary');
  F(n, 'Espaço', { w: 10, h: 12 });
  const refs = {};
  NAV_ITEMS.forEach(function (it) {
    const on = it[1] === active;
    const item = F(n, 'Nav / ' + it[1], { dir: 'V', gap: 4, cross: 'CENTER' });
    const pill = F(item, 'Indicador', { dir: 'H', w: 56, h: 32, radius: 16, main: 'CENTER', cross: 'CENTER', fill: on ? paint('brand/primary', 0.24) : null });
    IC(pill, it[0], 24, on ? 'brand/primary' : 'text/secondary');
    TX(item, it[1], 'label', { color: on ? 'text/primary' : 'text/secondary' });
    refs[it[1]] = item;
  });
  return refs;
}

function screenFrame(name, W, H, bg, o) {
  o = o || {};
  const s = F(null, name, { dir: o.dir || 'V', w: W, h: H, fill: bg, clip: true, sh: o.hug ? 'HUG' : 'FIXED' });
  return s;
}

// ---------------------------------------------------------------------
// Telas
// ---------------------------------------------------------------------
function buildSplash(W, H) {
  const s = screenFrame('01 · Splash', W, H, sky('Parcialmente nublado'));
  s.counterAxisAlignItems = 'CENTER';
  statusBar(s);
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  const logo = F(s, 'Logo', { dir: 'H', w: 120, h: 120, radius: 36, main: 'CENTER', cross: 'CENTER', fill: paint('glass/fill'), stroke: 'glass/stroke', effects: [blur(30), shadow(16, 40, 0.3)] });
  WX(logo, 'partly', 88);
  F(s, 'Espaço', { w: 10, h: 24 });
  TX(s, 'Clima Agora', 'headline', { weight: 'Bold', align: 'CENTER' });
  F(s, 'Espaço', { w: 10, h: 8 });
  const row = F(s, 'Detectando', { dir: 'H', gap: 8, cross: 'CENTER' });
  IC(row, 'locate', 16, 'text/secondary');
  TX(row, 'Detectando sua localização…', 'body', { color: 'text/secondary' });
  F(s, 'Espaço', { w: 10, h: 20 });
  const track = F(s, 'Progresso', { w: 160, h: 4, radius: 2, fill: paint('#FFFFFF', 0.2), clip: true });
  F(track, 'Valor', { w: 64, h: 4, radius: 2, fill: paint('brand/primary'), x: 0, y: 0 });
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  TX(s, 'Dados: Open-Meteo · Nominatim', 'bodyS', { color: 'text/tertiary', align: 'CENTER' });
  F(s, 'Espaço', { w: 10, h: 16 });
  gestureBar(s);
  return { frame: s };
}

function onboardingContent(s, W) {
  statusBar(s);
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  const ill = W - 180;
  const illo = F(s, 'Ilustração', { dir: 'H', w: ill, h: ill, main: 'CENTER', cross: 'CENTER' });
  SV(illo, '<svg xmlns="http://www.w3.org/2000/svg" width="' + ill + '" height="' + ill + '" viewBox="0 0 200 200">' +
    '<circle cx="100" cy="100" r="96" fill="#FFFFFF" fill-opacity="0.05"/><circle cx="100" cy="100" r="70" fill="#FFFFFF" fill-opacity="0.07"/><circle cx="100" cy="100" r="44" fill="#FFFFFF" fill-opacity="0.09"/>' +
    '<ellipse cx="100" cy="150" rx="26" ry="7" fill="#000" fill-opacity="0.25"/>' +
    '<path d="M100 150s-34-34-34-62a34 34 0 0 1 68 0c0 28-34 62-34 62z" fill="#A8C7FA"/><circle cx="100" cy="88" r="14" fill="#0A1233"/>' +
    '<circle cx="156" cy="46" r="16" fill="#FFC23D"/><circle cx="156" cy="46" r="24" fill="#FFC23D" fill-opacity="0.2"/>' +
    '<g transform="translate(18 34) scale(0.55)"><circle cx="34" cy="58" r="14" fill="#F4F7FF"/><circle cx="53" cy="47" r="20" fill="#F4F7FF"/><circle cx="71" cy="58" r="13" fill="#F4F7FF"/><rect x="20" y="56" width="64" height="18" rx="9" fill="#F4F7FF"/></g>' +
    '</svg>', 'Ilustração localização');
  F(s, 'Espaço', { w: 10, h: 32 });
  const txt = F(s, 'Texto', { dir: 'V', sw: 'FILL', pad: [0, 28, 0, 28], gap: 12, cross: 'CENTER' });
  TX(txt, 'O clima de onde você está', 'headline', { align: 'CENTER', sw: 'FILL', weight: 'Medium' });
  TX(txt, 'Usamos a localização do aparelho para mostrar temperatura, hora local e alertas da sua região em tempo real.', 'body', { color: 'text/secondary', align: 'CENTER', sw: 'FILL' });
  F(s, 'Espaço', { w: 10, h: 24 });
  const list = F(s, 'Benefícios', { dir: 'V', sw: 'FILL', pad: [0, 32, 0, 32], gap: 12 });
  [['clock', 'Previsão hora a hora e para 7 dias'], ['droplet', 'Umidade, vento, UV e qualidade do ar'], ['bell', 'Alertas da Defesa Civil e INMET']].forEach(function (b) {
    const r = F(list, 'Benefício', { dir: 'H', sw: 'FILL', gap: 12, cross: 'CENTER' });
    const ic = F(r, 'Ícone', { dir: 'H', w: 36, h: 36, radius: 18, main: 'CENTER', cross: 'CENTER', fill: paint('glass/fill') });
    IC(ic, b[0], 18, 'brand/primary');
    TX(r, b[1], 'body', { sw: 'FILL' });
  });
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  const actions = F(s, 'Ações', { dir: 'V', sw: 'FILL', pad: [0, 24, 8, 24], gap: 8, cross: 'CENTER' });
  const allow = button(actions, 'Permitir localização', 'primary', { h: 56, sw: 'FILL', icon: 'pin' });
  const manual = button(actions, 'Escolher cidade manualmente', 'text', { sw: 'FILL' });
  TX(actions, 'Você pode mudar isso depois em Ajustes.', 'bodyS', { color: 'text/tertiary', align: 'CENTER' });
  gestureBar(s);
  return { allow: allow, manual: manual };
}

function buildOnboarding(W, H) {
  const s = screenFrame('02 · Boas-vindas', W, H, sky('Parcialmente nublado'));
  s.counterAxisAlignItems = 'CENTER';
  const r = onboardingContent(s, W);
  return { frame: s, allow: r.allow, manual: r.manual };
}

function buildPermission(W, H) {
  const s = screenFrame('03 · Permissão de localização (Android)', W, H, sky('Parcialmente nublado'));
  s.counterAxisAlignItems = 'CENTER';
  onboardingContent(s, W);
  const scrim = F(s, 'Scrim', { dir: 'V', w: W, h: H, abs: true, x: 0, y: 0, main: 'CENTER', cross: 'CENTER', pad: [0, 24, 0, 24], fill: paint('#000000', 0.6), constraints: { horizontal: 'STRETCH', vertical: 'STRETCH' } });
  const d = F(scrim, 'Diálogo do sistema', { dir: 'V', sw: 'FILL', pad: 24, gap: 20, radius: 28, cross: 'CENTER', fill: paint('#232838'), effects: [shadow(12, 32, 0.4)] });
  IC(d, 'pin', 24, 'brand/primary');
  TX(d, 'Permitir que o Clima Agora acesse a localização deste dispositivo?', 'titleL', { align: 'CENTER', sw: 'FILL' });
  const opts = F(d, 'Precisão', { dir: 'H', sw: 'FILL', gap: 12 });
  [['Precisa', true], ['Aproximada', false]].forEach(function (o) {
    const col = F(opts, 'Opção / ' + o[0], { dir: 'V', sw: 'FILL', gap: 8, cross: 'CENTER' });
    const circ = F(col, 'Mapa', { dir: 'H', w: 96, h: 96, radius: 48, clip: true, main: 'CENTER', cross: 'CENTER', stroke: o[1] ? 'brand/primary' : ['#FFFFFF', 0.12], strokeW: o[1] ? 3 : 1, fill: paint('#141C3A') });
    SV(circ, mapSvg(96, 96), 'Mini mapa', { abs: true, x: 0, y: 0 });
    if (o[1]) F(circ, 'Ponto', { w: 16, h: 16, radius: 8, fill: paint('#4F8BFF'), stroke: '#FFFFFF', strokeW: 3 });
    else F(circ, 'Área', { w: 56, h: 56, radius: 28, fill: paint('#4F8BFF', 0.3), stroke: ['#4F8BFF', 0.8], strokeW: 2 });
    TX(col, o[0], 'label', { color: o[1] ? 'brand/primary' : 'text/secondary' });
  });
  const btns = F(d, 'Botões', { dir: 'V', sw: 'FILL', gap: 8 });
  const b1 = button(btns, 'Durante o uso do app', 'tonal', { sw: 'FILL' });
  const b2 = button(btns, 'Apenas esta vez', 'tonal', { sw: 'FILL' });
  const b3 = button(btns, 'Não permitir', 'tonal', { sw: 'FILL' });
  return { frame: s, whileUsing: b1, once: b2, deny: b3 };
}

// Tela principal — adapta-se à largura (Material window size classes)
function buildHome(W, H, opt) {
  opt = opt || {};
  const medium = W >= 600;
  const name = opt.name || '04 · Início';
  const s = screenFrame(name, W, H, sky(NOW.cond), { hug: opt.full });
  const refs = {};

  statusBar(s);
  let main = s;
  if (medium) {
    const body = F(s, 'Corpo', { dir: 'H', sw: 'FILL', sh: opt.full ? 'HUG' : 'FILL' });
    const r = navRail(body, 'Início');
    refs.nav = r;
    main = F(body, 'Principal', { dir: 'V', sw: 'FILL', sh: opt.full ? 'HUG' : 'FILL' });
  }

  // App bar
  const bar = F(main, 'Top app bar', { dir: 'H', sw: 'FILL', h: TOPBAR_H, pad: [0, 8, 0, 20], gap: 4, cross: 'CENTER' });
  const loc = F(bar, 'Localização', { dir: 'V', sw: 'FILL', gap: 0 });
  const l1 = F(loc, 'Cidade', { dir: 'H', gap: 6, cross: 'CENTER' });
  IC(l1, 'pin', 18, 'text/primary');
  TX(l1, NOW.city, 'titleL', { name: 'Cidade (GPS)' });
  TX(loc, NOW.hood + ' · localização atual', 'bodyS', { color: 'text/secondary', name: 'Bairro (reverse geocoding)' });
  refs.search = iconBtn(bar, 'Buscar', 'search');
  refs.bell = iconBtn(bar, 'Alertas', 'bell', { badge: true });

  const content = F(main, 'Conteúdo (rolagem)', { dir: 'V', sw: 'FILL', sh: opt.full ? 'HUG' : 'FILL', pad: [4, medium ? 24 : 16, 24, medium ? 24 : 16], gap: 16, clip: true, scroll: opt.full ? null : 'VERTICAL' });
  const inner = W - (medium ? 80 + 48 : 32); // largura útil do conteúdo

  // Hero: hora, data e temperatura
  const hero = F(content, 'Hero', { dir: 'V', sw: 'FILL', gap: 4, pad: [4, 4, 8, 4] });
  const dt = F(hero, 'Data e hora', { dir: 'H', sw: 'FILL', cross: 'CENTER', gap: 12 });
  const dtl = F(dt, 'Relógio', { dir: 'V', sw: 'FILL' });
  TX(dtl, NOW.time, 'headlineL', { name: 'Hora local' });
  TX(dtl, NOW.date, 'body', { color: 'text/secondary', name: 'Data' });
  chip(dt, 'Há 2 min', { icon: 'refresh', h: 28 });
  const tr = F(hero, 'Temperatura atual', { dir: 'H', sw: 'FILL', cross: 'CENTER', gap: 8 });
  const tl = F(tr, 'Valor', { dir: 'V', sw: 'FILL' });
  TX(tl, NOW.temp + '°', 'display', { name: 'Temperatura' });
  TX(tl, NOW.cond, 'title', { name: 'Condição' });
  WX(tr, NOW.kind, medium ? 160 : (W < 400 ? 112 : 132));
  F(hero, 'Espaço', { w: 10, h: 8 });
  const chips = F(hero, 'Resumo', { dir: 'H', gap: 8 });
  chip(chips, 'Máx ' + NOW.max + '°', { icon: 'thermo', iconColor: 'accent/sun' });
  chip(chips, 'Mín ' + NOW.min + '°', { icon: 'thermo', iconColor: 'accent/rain' });
  chip(chips, 'Sensação ' + NOW.feels + '°');

  // Alerta
  const alert = F(content, 'Banner de alerta', { dir: 'H', sw: 'FILL', pad: [12, 12, 12, 16], gap: 12, radius: 20, cross: 'CENTER', fill: paint('status/warning', 0.16), stroke: ['status/warning', 0.5] });
  IC(alert, 'alert', 22, 'status/warning');
  const at = F(alert, 'Texto', { dir: 'V', sw: 'FILL', gap: 2 });
  TX(at, 'Alerta amarelo · Chuvas intensas', 'titleS', { sw: 'FILL' });
  TX(at, 'Hoje, 18h–23h · INMET / Defesa Civil', 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  IC(alert, 'chevron-right', 20, 'text/secondary');
  refs.alert = alert;

  // Próximas horas
  const hc = card(content, 'PRÓXIMAS 24 HORAS', 'clock');
  const hl = F(hc, 'Lista horizontal (rolagem)', { dir: 'H', sw: 'FILL', gap: 4, clip: true, scroll: 'HORIZONTAL' });
  HOURLY.forEach(function (h, i) {
    const it = F(hl, 'Hora / ' + h[0], { dir: 'V', w: 60, pad: [10, 0, 10, 0], gap: 6, radius: 18, cross: 'CENTER', fill: i === 0 ? paint('#FFFFFF', 0.14) : null, stroke: i === 0 ? 'glass/stroke' : null });
    TX(it, h[0], 'label', { color: i === 0 ? 'text/primary' : 'text/secondary' });
    WX(it, h[1], 32);
    TX(it, h[2] + '°', 'titleS');
    TX(it, h[3] > 0 ? h[3] + '%' : '—', 'label', { color: h[3] > 0 ? 'accent/rain' : 'text/tertiary' });
  });

  // 7 dias
  const dc = card(content, 'PRÓXIMOS 7 DIAS', 'layers');
  const lo = 14, hi = 29;
  DAILY.forEach(function (d, i) {
    if (i > 0) F(dc, 'Divisor', { dir: 'H', sw: 'FILL', h: 1, fill: paint('divider') });
    const r = F(dc, 'Dia / ' + d[0], { dir: 'H', sw: 'FILL', h: 36, gap: 10, cross: 'CENTER' });
    TX(r, d[0], 'titleS', { w: 48 });
    WX(r, d[1], 28);
    TX(r, d[4] > 0 ? d[4] + '%' : '', 'label', { w: 34, color: 'accent/rain' });
    TX(r, d[2] + '°', 'body', { w: 30, align: 'RIGHT', color: 'text/tertiary' });
    const track = F(r, 'Faixa de temperatura', { w: 100, h: 6, radius: 3, fill: paint('#FFFFFF', 0.14), clip: true });
    F(track, 'Faixa', {
      w: (d[3] - d[2]) / (hi - lo) * 100, h: 6, radius: 3, x: (d[2] - lo) / (hi - lo) * 100, y: 0,
      fill: grad([[0, '#5CC8FF'], [1, '#FFC23D']], 'right'), constraints: { horizontal: 'SCALE', vertical: 'STRETCH' },
    });
    track.layoutSizingHorizontal = 'FILL';
    TX(r, d[3] + '°', 'titleS', { w: 30, align: 'RIGHT' });
  });

  // Detalhes em grade responsiva: 2 colunas (compacto) / 3 colunas (médio)
  const cols = medium ? 3 : 2;
  const grid = F(content, 'Grade de detalhes', { dir: 'V', sw: 'FILL', gap: 12 });
  for (let i = 0; i < METRICS.length; i += cols) {
    const row = F(grid, 'Linha', { dir: 'H', sw: 'FILL', gap: 12 });
    METRICS.slice(i, i + cols).forEach(function (m) {
      const t = F(row, 'Métrica / ' + m[1], { dir: 'V', sw: 'FILL', h: 124, pad: 16, gap: 6, radius: 20, fill: paint('glass/fill'), stroke: 'glass/stroke', effects: [blur(30)] });
      const th = F(t, 'Cabeçalho', { dir: 'H', gap: 6, cross: 'CENTER', sw: 'FILL' });
      IC(th, m[0], 16, 'text/tertiary');
      TX(th, m[1], 'overline', { color: 'text/tertiary', sw: 'FILL' });
      F(t, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
      TX(t, m[2], 'headline', { color: m[4] || 'text/primary', sw: 'FILL' });
      TX(t, m[3], 'bodyS', { color: 'text/secondary', sw: 'FILL' });
    });
  }

  // Sol e qualidade do ar (lado a lado no médio)
  const pair = F(content, 'Sol e ar', { dir: medium ? 'H' : 'V', sw: 'FILL', gap: 12 });
  const pairW = medium ? (inner - 12) / 2 : inner;
  const arcW = pairW - 32;
  const sc = card(pair, 'NASCER E PÔR DO SOL', 'sunrise');
  const arcH = Math.round(arcW * 0.36);
  const p = 0.71; // 14:32 entre 05:52 e 18:01
  const ang = Math.PI * (1 - p);
  const cx = arcW / 2 + Math.cos(ang) * (arcW / 2 - 12);
  const cy = arcH - Math.sin(ang) * (arcH - 12);
  SV(sc, '<svg xmlns="http://www.w3.org/2000/svg" width="' + arcW + '" height="' + (arcH + 8) + '" viewBox="0 0 ' + arcW + ' ' + (arcH + 8) + '">' +
    '<path d="M12 ' + arcH + ' A ' + (arcW / 2 - 12) + ' ' + (arcH - 12) + ' 0 0 1 ' + (arcW - 12) + ' ' + arcH + '" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="2" stroke-dasharray="4 6" fill="none"/>' +
    '<line x1="0" y1="' + arcH + '" x2="' + arcW + '" y2="' + arcH + '" stroke="#FFFFFF" stroke-opacity="0.2" stroke-width="1"/>' +
    '<circle cx="' + cx.toFixed(1) + '" cy="' + cy.toFixed(1) + '" r="16" fill="#FFC23D" fill-opacity="0.25"/>' +
    '<circle cx="' + cx.toFixed(1) + '" cy="' + cy.toFixed(1) + '" r="8" fill="#FFC23D"/></svg>', 'Arco do sol');
  const st = F(sc, 'Horários', { dir: 'H', sw: 'FILL', main: 'SPACE_BETWEEN' });
  const s1 = F(st, 'Nascer', { dir: 'V' });
  TX(s1, 'Nascer', 'bodyS', { color: 'text/secondary' });
  TX(s1, '05:52', 'title');
  const s2 = F(st, 'Pôr', { dir: 'V', cross: 'MAX' });
  TX(s2, 'Pôr do sol', 'bodyS', { color: 'text/secondary' });
  TX(s2, '18:01', 'title');

  const ac = card(pair, 'QUALIDADE DO AR', 'leaf');
  const ar = F(ac, 'Índice', { dir: 'H', sw: 'FILL', gap: 12, cross: 'CENTER' });
  TX(ar, '42', 'headlineL', { color: 'status/good' });
  const arT = F(ar, 'Texto', { dir: 'V', sw: 'FILL' });
  TX(arT, 'Boa', 'title');
  TX(arT, 'PM2.5 9 µg/m³ · IQA (EPA)', 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  const aqW = arcW;
  const aq = F(ac, 'Escala IQA', { w: aqW, h: 16 });
  F(aq, 'Trilho', { w: aqW, h: 6, y: 5, x: 0, radius: 3, fill: grad([[0, '#4ADE80'], [0.25, '#FFE14D'], [0.5, '#FFB020'], [0.75, '#FF5A5F'], [1, '#A855F7']], 'right'), constraints: { horizontal: 'SCALE', vertical: 'CENTER' } });
  F(aq, 'Marcador', { w: 16, h: 16, radius: 8, x: aqW * 0.14 - 8, y: 0, fill: paint('#FFFFFF'), stroke: '#0A1233', strokeW: 3, constraints: { horizontal: 'SCALE', vertical: 'CENTER' } });
  aq.layoutSizingHorizontal = 'FILL';
  TX(ac, 'Bom dia para atividades ao ar livre.', 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  if (medium) { sc.layoutSizingVertical = 'FILL'; ac.layoutSizingVertical = 'FILL'; }

  TX(content, 'Dados: Open-Meteo · Localização: Nominatim\nAtualizado às 14:30 (horário de Brasília, UTC−3)', 'bodyS', { color: 'text/tertiary', align: 'CENTER', sw: 'FILL', name: 'Créditos' });

  if (!medium) {
    refs.nav = bottomNav(s, 'Início');
  }
  gestureBar(s, paint('#0A1233', 0.94));
  refs.frame = s;
  return refs;
}

function cityCard(parent, c) {
  const k = F(parent, 'Local / ' + c.name, { dir: 'H', sw: 'FILL', pad: [16, 20, 16, 20], gap: 12, radius: 24, cross: 'CENTER', fill: sky(c.cond), stroke: 'glass/stroke' });
  const t = F(k, 'Texto', { dir: 'V', sw: 'FILL', gap: 2 });
  const n = F(t, 'Nome', { dir: 'H', gap: 8, cross: 'CENTER' });
  TX(n, c.name, 'title');
  if (c.gps) {
    const g = F(n, 'Selo GPS', { dir: 'H', pad: [2, 8, 2, 6], gap: 4, radius: 10, cross: 'CENTER', fill: paint('brand/primary', 0.24) });
    IC(g, 'locate', 12, 'brand/primary');
    TX(g, 'Atual', 'label', { color: 'brand/primary' });
  }
  TX(t, c.time + ' · ' + c.cond, 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  TX(t, 'Máx ' + c.max + '°  Mín ' + c.min + '°', 'bodyS', { color: 'text/secondary' });
  WX(k, c.kind, 44);
  TX(k, c.temp + '°', 'headlineL', { weight: 'Light' });
  return k;
}

function buildPlaces(W, H) {
  const s = screenFrame('05 · Locais e busca', W, H, paint('bg/base'));
  statusBar(s);
  const head = F(s, 'Cabeçalho', { dir: 'V', sw: 'FILL', pad: [12, 16, 8, 16], gap: 12 });
  TX(head, 'Locais', 'headline', { weight: 'Medium' });
  const sf = F(head, 'Campo de busca', { dir: 'H', sw: 'FILL', h: 56, radius: 28, pad: [0, 8, 0, 20], gap: 12, cross: 'CENTER', fill: paint('surface/solid-2') });
  IC(sf, 'search', 22, 'text/secondary');
  TX(sf, 'Buscar cidade, bairro ou CEP', 'body', { color: 'text/tertiary', sw: 'FILL' });
  iconBtn(sf, 'Voz', 'mic', { color: 'text/secondary' });
  const useLoc = button(head, 'Usar minha localização atual', 'outline', { sw: 'FILL', icon: 'locate' });

  const list = F(s, 'Lista (rolagem)', { dir: 'V', sw: 'FILL', sh: 'FILL', pad: [8, 16, 16, 16], gap: 12, clip: true, scroll: 'VERTICAL' });
  TX(list, 'SALVOS', 'overline', { color: 'text/tertiary' });
  const cities = [
    { name: 'São Paulo', cond: 'Parcialmente nublado', kind: 'partly', temp: 24, max: 27, min: 16, time: '14:32', gps: true },
    { name: 'Rio de Janeiro', cond: 'Ensolarado', kind: 'sun', temp: 29, max: 31, min: 21, time: '14:32' },
    { name: 'Curitiba', cond: 'Chuva', kind: 'rain', temp: 15, max: 17, min: 11, time: '14:32' },
    { name: 'Lisboa', cond: 'Nublado', kind: 'cloud', temp: 19, max: 22, min: 15, time: '18:32 (UTC+1)' },
    { name: 'Tóquio', cond: 'Noite', kind: 'night', temp: 21, max: 26, min: 20, time: '02:32 (UTC+9)' },
  ];
  const refs = { frame: s, useLoc: useLoc };
  cities.forEach(function (c, i) {
    const k = cityCard(list, c);
    if (i === 0) refs.sp = k;
  });
  TX(list, 'SUGESTÕES', 'overline', { color: 'text/tertiary' });
  const r1 = F(list, 'Sugestões 1', { dir: 'H', gap: 8 });
  ['Belo Horizonte', 'Porto Alegre'].forEach(function (c) { chip(r1, c, { icon: 'plus' }); });
  const r2 = F(list, 'Sugestões 2', { dir: 'H', gap: 8 });
  ['Salvador', 'Recife', 'Manaus'].forEach(function (c) { chip(r2, c, { icon: 'plus' }); });
  refs.nav = bottomNav(s, 'Locais');
  gestureBar(s, paint('#0A1233', 0.94));
  return refs;
}

function appBarBack(parent, title) {
  const b = F(parent, 'Top app bar', { dir: 'H', sw: 'FILL', h: TOPBAR_H, pad: [0, 16, 0, 4], gap: 4, cross: 'CENTER' });
  const back = iconBtn(b, 'Voltar', 'arrow-left');
  TX(b, title, 'titleL', { sw: 'FILL' });
  return back;
}

function metaRow(parent, icon, text) {
  const r = F(parent, 'Info', { dir: 'H', sw: 'FILL', gap: 8, cross: 'CENTER' });
  IC(r, icon, 16, 'text/secondary');
  TX(r, text, 'bodyS', { color: 'text/secondary', sw: 'FILL' });
}

function buildAlerts(W, H) {
  const s = screenFrame('06 · Alertas', W, H, paint('bg/base'));
  statusBar(s);
  const back = appBarBack(s, 'Alertas');
  const c = F(s, 'Conteúdo (rolagem)', { dir: 'V', sw: 'FILL', sh: 'FILL', pad: [8, 16, 16, 16], gap: 12, clip: true, scroll: 'VERTICAL' });

  const a = F(c, 'Alerta / Chuvas intensas', { dir: 'V', sw: 'FILL', pad: 16, gap: 10, radius: 24, fill: paint('status/warning', 0.12), stroke: ['status/warning', 0.5] });
  const tag = F(a, 'Nível', { dir: 'H', pad: [4, 10, 4, 8], gap: 6, radius: 12, cross: 'CENTER', fill: paint('status/warning', 0.22) });
  IC(tag, 'alert', 14, 'status/warning');
  TX(tag, 'AMARELO · PERIGO POTENCIAL', 'overline', { color: 'status/warning' });
  TX(a, 'Chuvas intensas', 'title', { sw: 'FILL' });
  TX(a, 'Chuva entre 20 e 30 mm/h ou até 50 mm/dia, com ventos de 40 a 60 km/h. Baixo risco de alagamentos, queda de galhos e falta de energia.', 'body', { color: 'text/secondary', sw: 'FILL' });
  metaRow(a, 'clock', 'Hoje 18:00 → Qua 06:00');
  metaRow(a, 'pin', 'São Paulo — Zona Sul e Centro');
  metaRow(a, 'bell', 'Fonte: INMET · Defesa Civil SP');
  const ab = F(a, 'Ações', { dir: 'H', sw: 'FILL', gap: 8 });
  button(ab, 'Lembrar-me', 'tonal', { icon: 'bell', h: 40 });
  button(ab, 'Compartilhar', 'outline', { icon: 'share', h: 40 });

  [['sun', 'accent/sun', 'Índice UV alto (7)', 'Entre 11h e 15h. Use protetor solar e evite exposição prolongada.'],
   ['thermo', 'accent/rain', 'Frente fria na quinta', 'Queda de até 8° — mínima de 13° na madrugada de quinta-feira.']].forEach(function (x) {
    const k = F(c, 'Aviso / ' + x[2], { dir: 'H', sw: 'FILL', pad: 16, gap: 12, radius: 20, fill: paint('surface/solid'), stroke: 'glass/stroke' });
    const ic = F(k, 'Ícone', { dir: 'H', w: 40, h: 40, radius: 20, main: 'CENTER', cross: 'CENTER', fill: paint(x[1], 0.18) });
    IC(ic, x[0], 20, x[1]);
    const t = F(k, 'Texto', { dir: 'V', sw: 'FILL', gap: 2 });
    TX(t, x[2], 'titleS', { sw: 'FILL' });
    TX(t, x[3], 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  });

  F(c, 'Espaço', { w: 10, h: 4 });
  TX(c, 'NOTIFICAÇÕES', 'overline', { color: 'text/tertiary' });
  const n = F(c, 'Preferências', { dir: 'V', sw: 'FILL', radius: 20, fill: paint('surface/solid'), clip: true });
  [['Alertas severos da região', 'Defesa Civil e INMET', true], ['Chuva nas próximas 2 horas', 'Com base na previsão por hora', true], ['Resumo diário às 07:00', 'Previsão do dia na notificação', false]].forEach(function (p, i) {
    if (i > 0) F(n, 'Divisor', { dir: 'H', sw: 'FILL', h: 1, fill: paint('divider') });
    const r = F(n, 'Linha / ' + p[0], { dir: 'H', sw: 'FILL', pad: [14, 16, 14, 16], gap: 12, cross: 'CENTER' });
    const t = F(r, 'Texto', { dir: 'V', sw: 'FILL' });
    TX(t, p[0], 'body', { sw: 'FILL' });
    TX(t, p[1], 'bodyS', { color: 'text/tertiary', sw: 'FILL' });
    toggle(r, p[2]);
  });
  gestureBar(s);
  return { frame: s, back: back };
}

function settingsGroup(parent, title, rows) {
  TX(parent, title, 'overline', { color: 'text/tertiary' });
  const g = F(parent, 'Grupo / ' + title, { dir: 'V', sw: 'FILL', radius: 20, fill: paint('surface/solid'), clip: true });
  rows.forEach(function (r, i) {
    if (i > 0) F(g, 'Divisor', { dir: 'H', sw: 'FILL', h: 1, fill: paint('divider') });
    const row = F(g, 'Linha / ' + r[0], { dir: 'H', sw: 'FILL', pad: [12, 16, 12, 16], gap: 12, cross: 'CENTER' });
    TX(row, r[0], 'body', { sw: 'FILL' });
    const v = r[1];
    if (v.seg) segmented(row, v.seg, v.on);
    else if (v.toggle != null) toggle(row, v.toggle);
    else {
      const t = F(row, 'Valor', { dir: 'H', gap: 4, cross: 'CENTER' });
      TX(t, v.text, 'body', { color: 'text/secondary' });
      if (v.chevron !== false) IC(t, 'chevron-right', 18, 'text/tertiary');
    }
  });
}

function buildSettings(W, H) {
  const s = screenFrame('07 · Ajustes', W, H, paint('bg/base'));
  statusBar(s);
  const head = F(s, 'Cabeçalho', { dir: 'V', sw: 'FILL', pad: [12, 16, 8, 16] });
  TX(head, 'Ajustes', 'headline', { weight: 'Medium' });
  const c = F(s, 'Conteúdo (rolagem)', { dir: 'V', sw: 'FILL', sh: 'FILL', pad: [8, 16, 16, 16], gap: 10, clip: true, scroll: 'VERTICAL' });
  settingsGroup(c, 'UNIDADES', [
    ['Temperatura', { seg: ['°C', '°F'], on: 0 }],
    ['Vento', { seg: ['km/h', 'm/s', 'mph'], on: 0 }],
    ['Pressão', { text: 'hPa' }],
  ]);
  settingsGroup(c, 'APARÊNCIA', [
    ['Tema', { seg: ['Auto', 'Claro', 'Escuro'], on: 0 }],
    ['Fundo conforme o clima', { toggle: true }],
  ]);
  settingsGroup(c, 'LOCALIZAÇÃO', [
    ['Precisão', { text: 'Precisa (GPS)' }],
    ['Atualizar em segundo plano', { toggle: true }],
    ['Frequência', { text: '30 min' }],
  ]);
  settingsGroup(c, 'DADOS E SOBRE', [
    ['Previsão', { text: 'Open-Meteo' }],
    ['Versão', { text: '0.1.0 · protótipo', chevron: false }],
  ]);
  const nav = bottomNav(s, 'Ajustes');
  gestureBar(s, paint('#0A1233', 0.94));
  return { frame: s, nav: nav };
}

function buildOffline(W, H) {
  const s = screenFrame('08 · Sem conexão', W, H, sky('Nublado'));
  s.counterAxisAlignItems = 'CENTER';
  statusBar(s);
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  const ic = F(s, 'Ícone', { dir: 'H', w: 112, h: 112, radius: 56, main: 'CENTER', cross: 'CENTER', fill: paint('glass/fill'), stroke: 'glass/stroke' });
  IC(ic, 'wifi-off', 48, 'text/primary');
  F(s, 'Espaço', { w: 10, h: 24 });
  const t = F(s, 'Texto', { dir: 'V', sw: 'FILL', pad: [0, 32, 0, 32], gap: 8, cross: 'CENTER' });
  TX(t, 'Sem conexão com a internet', 'titleL', { align: 'CENTER', sw: 'FILL' });
  TX(t, 'Mostrando a última previsão salva. Atualizamos assim que a conexão voltar.', 'body', { color: 'text/secondary', align: 'CENTER', sw: 'FILL' });
  F(s, 'Espaço', { w: 10, h: 24 });
  const wrap = F(s, 'Cache', { dir: 'V', sw: 'FILL', pad: [0, 24, 0, 24] });
  const k = cityCard(wrap, { name: 'São Paulo', cond: 'Parcialmente nublado', kind: 'partly', temp: 23, max: 27, min: 16, time: 'Salvo às 13:05', gps: true });
  k.opacity = 0.85;
  F(s, 'Espaço', { w: 10, h: 24 });
  const retry = button(s, 'Tentar novamente', 'primary', { icon: 'refresh' });
  F(s, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  gestureBar(s);
  return { frame: s, retry: retry };
}

// ---------------------------------------------------------------------
// Design System, APIs
// ---------------------------------------------------------------------
function section(parent, title, sub) {
  const sct = F(parent, 'Seção / ' + title, { dir: 'V', sw: 'FILL', gap: 16 });
  TX(sct, title, 'headline', { weight: 'Medium' });
  if (sub) TX(sct, sub, 'body', { color: 'text/secondary', sw: 'FILL' });
  return sct;
}

function toComponent(node, name) {
  try {
    const c = figma.createComponentFromNode(node);
    c.name = name;
    return c;
  } catch (e) { WARN.push('componente ' + name); return node; }
}

function buildDesignSystem() {
  const d = F(null, 'Design System · Clima Agora', { dir: 'V', w: 1440, pad: 64, gap: 48, fill: paint('bg/base'), sh: 'HUG' });
  const h = F(d, 'Título', { dir: 'V', sw: 'FILL', gap: 8 });
  TX(h, 'Clima Agora — Design System', 'headlineL', { weight: 'Medium' });
  TX(h, 'Material 3 · tema escuro com "vidro" · tokens em Variables (coleção Clima/Tokens) prontos para virar ThemeData no Flutter.', 'body', { color: 'text/secondary', sw: 'FILL' });

  const cs = section(d, 'Cores', 'Cada cor é uma Variable. Nas telas, os preenchimentos estão ligados a elas — troque aqui e tudo atualiza.');
  const grid = F(cs, 'Paleta', { dir: 'H', sw: 'FILL', gap: 16 });
  grid.layoutWrap = 'WRAP';
  grid.counterAxisSpacing = 16;
  Object.keys(C).forEach(function (k) {
    const sw = F(grid, 'Cor / ' + k, { dir: 'V', w: 150, gap: 8 });
    const box = F(sw, 'Amostra', { w: 150, h: 88, radius: 16, fill: sky('Parcialmente nublado'), clip: true });
    F(box, 'Cor', { w: 150, h: 88, x: 0, y: 0, fill: paint(k), stroke: ['#FFFFFF', 0.12] });
    TX(sw, k, 'label');
    const t = tok(k);
    TX(sw, t.hex + (t.a < 1 ? ' · ' + Math.round(t.a * 100) + '%' : ''), 'bodyS', { color: 'text/tertiary' });
  });

  const gs = section(d, 'Fundos dinâmicos', 'O gradiente da tela muda conforme o weather_code retornado pela API.');
  const gr = F(gs, 'Gradientes', { dir: 'H', sw: 'FILL', gap: 16 });
  Object.keys(SKY).forEach(function (k) {
    const g = F(gr, 'Fundo / ' + k, { dir: 'V', w: 200, h: 140, radius: 20, pad: 16, fill: sky(k), main: 'MAX', stroke: 'glass/stroke' });
    TX(g, k, 'titleS');
    TX(g, SKY[k].join(' → '), 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  });

  const ts = section(d, 'Tipografia', 'Roboto (padrão Android). Estilos de texto: Clima/*.');
  Object.keys(TS).forEach(function (k) {
    const r = F(ts, 'Tipo / ' + k, { dir: 'H', sw: 'FILL', gap: 24, cross: 'CENTER' });
    const meta = F(r, 'Meta', { dir: 'V', w: 260 });
    TX(meta, TS[k].label, 'label');
    TX(meta, TS[k].size + ' / ' + TS[k].lh + ' · ' + TS[k].w, 'bodyS', { color: 'text/tertiary' });
    TX(r, k === 'display' ? '24°' : k === 'headlineL' ? '14:32' : 'Parcialmente nublado', k, { sw: 'FILL' });
  });

  const is = section(d, 'Ícones', 'Traço 2px, grade 24dp. No Flutter: pacote material_symbols_icons (Rounded).');
  const ig = F(is, 'Grade de ícones', { dir: 'H', sw: 'FILL', gap: 12 });
  ig.layoutWrap = 'WRAP';
  ig.counterAxisSpacing = 12;
  Object.keys(ICONS).forEach(function (k) {
    const c = F(ig, 'Ícone / ' + k, { dir: 'V', w: 96, h: 88, gap: 8, radius: 16, main: 'CENTER', cross: 'CENTER', fill: paint('surface/solid') });
    IC(c, k, 24, 'text/primary');
    TX(c, k, 'bodyS', { color: 'text/tertiary' });
  });
  const wr = F(is, 'Ícones do tempo', { dir: 'H', sw: 'FILL', gap: 12 });
  ['sun', 'partly', 'cloud', 'rain', 'storm', 'night', 'night-cloud'].forEach(function (k) {
    const c = F(wr, 'Tempo / ' + k, { dir: 'V', w: 120, h: 132, gap: 8, radius: 20, main: 'CENTER', cross: 'CENTER', fill: sky('Parcialmente nublado') });
    WX(c, k, 72);
    TX(c, k, 'bodyS', { color: 'text/secondary' });
  });

  const cps = section(d, 'Componentes', 'Main components — use Assets ▸ Local para arrastar para novas telas.');
  const cr = F(cps, 'Componentes', { dir: 'H', sw: 'FILL', gap: 24, cross: 'CENTER', pad: 24, radius: 24, fill: sky('Parcialmente nublado') });
  cr.layoutWrap = 'WRAP';
  cr.counterAxisSpacing = 24;
  toComponent(button(cr, 'Permitir localização', 'primary', { h: 56, icon: 'pin' }), 'Button/Primary');
  toComponent(button(cr, 'Lembrar-me', 'tonal', { icon: 'bell' }), 'Button/Tonal');
  toComponent(button(cr, 'Compartilhar', 'outline', { icon: 'share' }), 'Button/Outline');
  toComponent(chip(cr, 'Chuva', { icon: 'umbrella', active: true, h: 36 }), 'Chip/Active');
  toComponent(chip(cr, 'Vento', { icon: 'wind', h: 36 }), 'Chip/Default');
  toComponent(toggle(cr, true), 'Switch/On');
  toComponent(toggle(cr, false), 'Switch/Off');
  toComponent(segmented(cr, ['°C', '°F'], 0), 'SegmentedButton');
  toComponent(iconBtn(cr, 'Alertas', 'bell', { badge: true }), 'IconButton/Badge');
  const tile = F(cr, 'Métrica', { dir: 'V', w: 170, h: 124, pad: 16, gap: 6, radius: 20, fill: paint('glass/fill'), stroke: 'glass/stroke', effects: [blur(30)] });
  const th = F(tile, 'Cabeçalho', { dir: 'H', gap: 6, cross: 'CENTER', sw: 'FILL' });
  IC(th, 'droplet', 16, 'text/tertiary');
  TX(th, 'UMIDADE', 'overline', { color: 'text/tertiary', sw: 'FILL' });
  F(tile, 'Espaço', { dir: 'V', sw: 'FILL', sh: 'FILL' });
  TX(tile, '62%', 'headline', { sw: 'FILL' });
  TX(tile, 'Orvalho 16°', 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  toComponent(tile, 'Card/Metric');
  const navWrap = F(cr, 'Nav wrap', { dir: 'V', w: SCREEN.W });
  bottomNav(navWrap, 'Início');
  toComponent(navWrap, 'NavigationBar');

  const bs = section(d, 'Breakpoints (Material window size classes)', 'Mesmos limites usados no Flutter com LayoutBuilder / MediaQuery.sizeOf(context).width.');
  const br = F(bs, 'Breakpoints', { dir: 'H', sw: 'FILL', gap: 16 });
  [['Compacto', '< 600 dp', 'Celulares (360–599). 1 coluna, grade 2×, NavigationBar inferior.'],
   ['Médio', '600–839 dp', 'Dobráveis/tablets pequenos. NavigationRail, grade 3×, cards lado a lado.'],
   ['Expandido', '≥ 840 dp', 'Tablets/landscape. Rail + 2 painéis (lista de locais | detalhes).']].forEach(function (b) {
    const k = F(br, 'Breakpoint / ' + b[0], { dir: 'V', sw: 'FILL', pad: 20, gap: 6, radius: 20, fill: paint('surface/solid'), stroke: 'glass/stroke' });
    TX(k, b[0], 'title');
    TX(k, b[1], 'headline', { color: 'brand/primary' });
    TX(k, b[2], 'body', { color: 'text/secondary', sw: 'FILL' });
  });
  return d;
}

function buildApis() {
  const d = F(null, 'APIs & Flutter · Clima Agora', { dir: 'V', w: 1440, pad: 64, gap: 40, fill: paint('bg/base'), sh: 'HUG' });
  TX(d, 'Integrações externas e handoff para Flutter', 'headlineL', { weight: 'Medium' });
  const apis = [
    ['GPS do aparelho', 'geolocator (Fused Location Provider)', 'Latitude/longitude + precisão. Pede ACCESS_FINE/COARSE_LOCATION.', 'Permissão, Início', 'Sem chave'],
    ['Nome do local', 'Nominatim (OSM) · /reverse?lat=&lon=&format=jsonv2', 'Transforma coordenadas em bairro/cidade ("Vila Mariana, São Paulo").', 'Início', 'Sem chave (1 req/s, User-Agent)'],
    ['Previsão do tempo', 'Open-Meteo · api.open-meteo.com/v1/forecast', 'current + hourly + daily (temperatura, weather_code, vento, UV, chuva, nascer/pôr do sol). timezone=auto devolve fuso e hora local.', 'Início, Locais', 'Sem chave'],
    ['Qualidade do ar', 'Open-Meteo · air-quality-api.open-meteo.com/v1/air-quality', 'us_aqi, pm2_5, pm10.', 'Início', 'Sem chave'],
    ['Busca de cidades', 'Open-Meteo Geocoding · geocoding-api.open-meteo.com/v1/search?name=', 'Autocomplete de cidades com lat/lon e fuso horário.', 'Locais', 'Sem chave'],
    ['Alertas oficiais', 'INMET Alert-AS (CAP/RSS) · alertas2.inmet.gov.br', 'Avisos meteorológicos por município (amarelo/laranja/vermelho).', 'Alertas, Início', 'Sem chave'],
    ['Notificações', 'flutter_local_notifications + workmanager', 'Checagem em segundo plano a cada 30 min e aviso de chuva/alerta.', 'Alertas, Ajustes', 'Local'],
  ];
  const tbl = F(d, 'Tabela de APIs', { dir: 'V', sw: 'FILL', radius: 20, fill: paint('surface/solid'), clip: true });
  const widths = [200, 380, null, 180, 200];
  const head = F(tbl, 'Cabeçalho', { dir: 'H', sw: 'FILL', pad: [14, 20, 14, 20], gap: 16, fill: paint('surface/solid-2') });
  ['Função', 'Serviço / endpoint', 'O que entrega', 'Telas', 'Custo / chave'].forEach(function (h, i) {
    TX(head, h.toUpperCase(), 'overline', { color: 'text/tertiary', w: widths[i] || undefined, sw: widths[i] ? undefined : 'FILL' });
  });
  apis.forEach(function (a) {
    F(tbl, 'Divisor', { dir: 'H', sw: 'FILL', h: 1, fill: paint('divider') });
    const r = F(tbl, 'API / ' + a[0], { dir: 'H', sw: 'FILL', pad: [14, 20, 14, 20], gap: 16 });
    a.forEach(function (v, i) {
      TX(r, v, i === 0 ? 'titleS' : 'body', { color: i === 1 ? 'brand/primary' : i === 0 ? 'text/primary' : 'text/secondary', w: widths[i] || undefined, sw: widths[i] ? undefined : 'FILL' });
    });
  });

  TX(d, 'Fluxo de dados', 'headline', { weight: 'Medium' });
  const flow = F(d, 'Fluxo', { dir: 'H', sw: 'FILL', gap: 12, cross: 'CENTER' });
  [['1', 'GPS', 'geolocator'], ['2', 'Reverse geocoding', 'Nominatim'], ['3', 'Previsão + ar', 'Open-Meteo'], ['4', 'Cache local', 'hive / shared_preferences'], ['5', 'UI reativa', 'Riverpod · Início/Locais']].forEach(function (s, i) {
    if (i > 0) IC(flow, 'chevron-right', 24, 'text/tertiary');
    const k = F(flow, 'Passo ' + s[0], { dir: 'V', sw: 'FILL', pad: 20, gap: 4, radius: 20, fill: paint('surface/solid'), stroke: 'glass/stroke' });
    TX(k, s[0], 'headline', { color: 'brand/primary' });
    TX(k, s[1], 'titleS', { sw: 'FILL' });
    TX(k, s[2], 'bodyS', { color: 'text/secondary', sw: 'FILL' });
  });

  TX(d, 'Do Figma para o Flutter', 'headline', { weight: 'Medium' });
  const map = [
    ['Frame com Auto Layout vertical', 'Column / ListView'], ['Auto Layout horizontal', 'Row'], ['Fill container', 'Expanded / Flexible'],
    ['Hug contents', 'tamanho intrínseco (MainAxisSize.min)'], ['Lista horizontal (rolagem)', 'ListView(scrollDirection: Axis.horizontal)'],
    ['Card de vidro + blur', 'ClipRRect + BackdropFilter(ImageFilter.blur)'], ['Navigation bar / rail', 'NavigationBar / NavigationRail (M3)'],
    ['Variables Clima/Tokens', 'ThemeData + ColorScheme + ThemeExtension'], ['Estilos de texto Clima/*', 'TextTheme (GoogleFonts.roboto)'],
    ['Breakpoints 600/840', 'LayoutBuilder / MediaQuery.sizeOf(context)'], ['Fundo dinâmico', 'AnimatedContainer + LinearGradient por weather_code'],
  ];
  const mt = F(d, 'Mapeamento', { dir: 'V', sw: 'FILL', radius: 20, fill: paint('surface/solid'), clip: true });
  map.forEach(function (m, i) {
    if (i > 0) F(mt, 'Divisor', { dir: 'H', sw: 'FILL', h: 1, fill: paint('divider') });
    const r = F(mt, 'Linha', { dir: 'H', sw: 'FILL', pad: [12, 20, 12, 20], gap: 16 });
    TX(r, m[0], 'body', { w: 420 });
    TX(r, m[1], 'body', { color: 'brand/primary', sw: 'FILL', name: 'Flutter' });
  });
  return d;
}

// ---------------------------------------------------------------------
// Interações do protótipo
// ---------------------------------------------------------------------
function go(dest, kind) {
  return {
    trigger: { type: 'ON_CLICK' },
    actions: [{
      type: 'NODE', destinationId: dest.id, navigation: 'NAVIGATE', preserveScrollPosition: false,
      transition: { type: kind === 'smart' ? 'SMART_ANIMATE' : 'DISSOLVE', easing: { type: 'EASE_OUT' }, duration: 0.3 },
    }],
  };
}
async function link(node, reactions) {
  if (!node) return;
  try { await node.setReactionsAsync(reactions); } catch (e) { WARN.push('interação em "' + node.name + '"'); }
}

// ---------------------------------------------------------------------
// Execução
// ---------------------------------------------------------------------
async function loadFonts() {
  const fams = ['Roboto', 'Inter'];
  for (let i = 0; i < fams.length; i++) {
    try {
      await Promise.all(WEIGHTS.map(function (w) { return figma.loadFontAsync({ family: fams[i], style: w }); }));
      FAMILY = fams[i];
      return;
    } catch (e) { /* tenta a próxima */ }
  }
  throw new Error('Não foi possível carregar Roboto nem Inter.');
}

function createTokens() {
  try {
    const col = figma.variables.createVariableCollection('Clima/Tokens');
    const mode = col.modes[0].modeId;
    col.renameMode(mode, 'Escuro');
    Object.keys(C).forEach(function (k) {
      const v = figma.variables.createVariable(k, col, 'COLOR');
      const t = tok(k);
      const c = rgb(t.hex);
      v.setValueForMode(mode, { r: c.r, g: c.g, b: c.b, a: t.a });
      VARS[k] = v;
    });
    const num = { 'space/xs': 4, 'space/s': 8, 'space/m': 12, 'space/l': 16, 'space/xl': 24, 'radius/chip': 16, 'radius/card': 24, 'radius/sheet': 28 };
    Object.keys(num).forEach(function (k) {
      const v = figma.variables.createVariable(k, col, 'FLOAT');
      v.setValueForMode(mode, num[k]);
    });
  } catch (e) { WARN.push('Variables (usando cores soltas)'); }
}

function createTextStyles() {
  Object.keys(TS).forEach(function (k) {
    try {
      const s = figma.createTextStyle();
      s.name = 'Clima/' + k;
      s.fontName = { family: FAMILY, style: TS[k].w };
      s.fontSize = TS[k].size;
      s.lineHeight = { unit: 'PIXELS', value: TS[k].lh };
      s.letterSpacing = { unit: 'PERCENT', value: TS[k].ls || 0 };
      STYLES[k] = s;
    } catch (e) { WARN.push('estilo ' + k); }
  });
}

function place(page, frames, gap, y) {
  let x = 0;
  frames.forEach(function (f) {
    page.appendChild(f);
    f.x = x; f.y = y || 0;
    x += f.width + (gap || 120);
  });
}

function label(page, text, x, y) {
  const t = TX(null, text, 'titleL', { color: '#8B93B8' });
  page.appendChild(t);
  t.x = x; t.y = y;
  return t;
}

async function main() {
  await loadFonts();
  createTokens();
  createTextStyles();

  const W = SCREEN.W, H = SCREEN.H;

  // ---- Página 1: protótipo navegável
  const pProto = figma.createPage();
  pProto.name = '📱 Protótipo';
  const splash = buildSplash(W, H);
  const onb = buildOnboarding(W, H);
  const perm = buildPermission(W, H);
  const home = buildHome(W, H);
  const places = buildPlaces(W, H);
  const alerts = buildAlerts(W, H);
  const settings = buildSettings(W, H);
  const offline = buildOffline(W, H);
  place(pProto, [splash.frame, onb.frame, perm.frame, home.frame, places.frame, alerts.frame, settings.frame, offline.frame], 120, 80);
  label(pProto, 'Clima Agora · protótipo Android Large 360×800 dp · ▶ Present para navegar (fluxo "Abrir o app")', 0, 0);

  const navs = [[home.nav, 'home'], [places.nav, 'places'], [settings.nav, 'settings']];
  const dest = { 'Início': home.frame, 'Locais': places.frame, 'Ajustes': settings.frame };
  for (let i = 0; i < navs.length; i++) {
    const n = navs[i][0];
    const keys = Object.keys(n);
    for (let j = 0; j < keys.length; j++) await link(n[keys[j]], [go(dest[keys[j]], 'smart')]);
  }
  await link(splash.frame, [{ trigger: { type: 'AFTER_TIMEOUT', timeout: 1.5 }, actions: [go(onb.frame).actions[0]] }]);
  await link(onb.allow, [go(perm.frame)]);
  await link(onb.manual, [go(places.frame)]);
  await link(perm.whileUsing, [go(home.frame)]);
  await link(perm.once, [go(home.frame)]);
  await link(perm.deny, [go(places.frame)]);
  await link(home.bell, [go(alerts.frame)]);
  await link(home.alert, [go(alerts.frame)]);
  await link(home.search, [go(places.frame)]);
  await link(places.sp, [go(home.frame)]);
  await link(places.useLoc, [go(home.frame)]);
  await link(alerts.back, [{ trigger: { type: 'ON_CLICK' }, actions: [{ type: 'BACK' }] }]);
  await link(offline.retry, [go(home.frame)]);
  try { pProto.flowStartingPoints = [{ nodeId: splash.frame.id, name: 'Abrir o app' }, { nodeId: home.frame.id, name: 'Início direto' }]; } catch (e) { WARN.push('flow starting point'); }

  // ---- Página 3: design system
  const pDs = figma.createPage();
  pDs.name = '🎨 Design System';
  pDs.appendChild(buildDesignSystem());

  // ---- Página 4: APIs
  const pApi = figma.createPage();
  pApi.name = '🔌 APIs & Flutter';
  pApi.appendChild(buildApis());

  await Promise.all(PENDING);
  await figma.setCurrentPageAsync(pProto);
  figma.viewport.scrollAndZoomIntoView(pProto.children);
  figma.closePlugin(WARN.length
    ? '✅ Protótipo criado (avisos: ' + WARN.join(', ') + ')'
    : '✅ Protótipo Clima Agora criado — 3 páginas. Aperte ▶ Present na página 📱 Protótipo.');
}

main().catch(function (e) {
  console.error(e);
  figma.closePlugin('❌ Erro: ' + (e && e.message ? e.message : e));
});
