// Simulador mínimo da Plugin API do Figma, rodando no navegador.
// Valida as regras que o Figma impõe (FILL só dentro de Auto Layout, fonte
// carregada antes de texto etc.), renderiza as telas com flexbox (equivalente
// ao Auto Layout) e exporta cada frame para SVG com posições medidas.
(function () {
  let nid = 0;
  const loaded = new Set();
  const errors = [];
  function fail(msg) { errors.push(msg); throw new Error(msg); }

  class Node {
    constructor(type) {
      this.id = '1:' + (++nid);
      this.type = type;
      this.name = type;
      this.children = [];
      this.parent = null;
      this.x = 0; this.y = 0; this.width = 100; this.height = 100;
      this.fills = type === 'TEXT' ? [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 }, opacity: 1 }] : (type === 'FRAME' ? [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 1 }] : []);
      this.strokes = []; this.strokeWeight = 1; this.effects = []; this.opacity = 1;
      this.cornerRadius = 0; this.clipsContent = true;
      this.layoutMode = 'NONE';
      this.paddingTop = this.paddingRight = this.paddingBottom = this.paddingLeft = 0;
      this.itemSpacing = 0; this.counterAxisSpacing = 0; this.layoutWrap = 'NO_WRAP';
      this.primaryAxisAlignItems = 'MIN'; this.counterAxisAlignItems = 'MIN';
      this._sw = 'FIXED'; this._sh = 'FIXED'; this._pos = 'AUTO';
      this.constraints = { horizontal: 'MIN', vertical: 'MIN' };
      this.reactions = [];
    }
    appendChild(c) {
      if (c.parent) c.parent.children.splice(c.parent.children.indexOf(c), 1);
      c.parent = this; this.children.push(c);
    }
    resize(w, h) {
      if (!(w > 0) || !(h > 0)) fail('resize inválido em "' + this.name + '": ' + w + '×' + h);
      this.width = w; this.height = h;
    }
    get layoutSizingHorizontal() { return this._sw; }
    set layoutSizingHorizontal(v) { this._checkSizing(v, 'H'); this._sw = v; }
    get layoutSizingVertical() { return this._sh; }
    set layoutSizingVertical(v) { this._checkSizing(v, 'V'); this._sh = v; }
    _checkSizing(v, axis) {
      if (v === 'FILL' && (!this.parent || this.parent.layoutMode === 'NONE' || this._pos === 'ABSOLUTE'))
        fail('FILL sem pai com Auto Layout em "' + this.name + '"');
      if (v === 'HUG' && this.type !== 'TEXT' && this.layoutMode === 'NONE')
        fail('HUG em frame sem Auto Layout "' + this.name + '"');
    }
    get layoutPositioning() { return this._pos; }
    set layoutPositioning(v) {
      if (v === 'ABSOLUTE' && (!this.parent || this.parent.layoutMode === 'NONE')) fail('ABSOLUTE sem pai com Auto Layout "' + this.name + '"');
      this._pos = v;
    }
    async setReactionsAsync(r) {
      r.forEach(function (x) {
        if (!x.trigger || !x.actions) fail('reaction inválida');
        x.actions.forEach(function (a) { if (a.type === 'NODE' && !a.destinationId) fail('destino ausente'); });
      });
      this.reactions = r;
    }
    async setTextStyleIdAsync() {}
    remove() { if (this.parent) this.parent.children.splice(this.parent.children.indexOf(this), 1); }
  }

  class TextNode extends Node {
    constructor() {
      super('TEXT');
      this._font = { family: 'Inter', style: 'Regular' };
      this._chars = ''; this.fontSize = 12; this.textAutoResize = 'WIDTH_AND_HEIGHT'; this._sw = 'HUG'; this._sh = 'HUG';
      this.textAlignHorizontal = 'LEFT'; this.lineHeight = { unit: 'AUTO' }; this.letterSpacing = { unit: 'PERCENT', value: 0 };
    }
    get fontName() { return this._font; }
    set fontName(f) { if (!loaded.has(f.family + '|' + f.style)) fail('fonte não carregada: ' + f.family + ' ' + f.style); this._font = f; }
    get characters() { return this._chars; }
    set characters(s) { if (!loaded.has(this._font.family + '|' + this._font.style)) fail('characters antes de carregar fonte'); this._chars = s; }
    set layoutSizingHorizontal(v) { this._checkSizing(v, 'H'); this._sw = v; if (v === 'FILL' || v === 'FIXED') this.textAutoResize = 'HEIGHT'; }
    get layoutSizingHorizontal() { return this._sw; }
    resize(w, h) { super.resize(w, h); this._sw = 'FIXED'; }
  }

  class PageNode {
    constructor() { this.id = '0:' + (++nid); this.type = 'PAGE'; this.name = 'Page'; this.children = []; this.flowStartingPoints = []; }
    appendChild(c) { if (c.parent) c.parent.children.splice(c.parent.children.indexOf(c), 1); c.parent = this; this.children.push(c); }
  }

  const root = { children: [] };
  const first = new PageNode(); first.name = 'Page 1'; root.children.push(first);
  let current = first;

  function parseSize(svg) {
    const w = /<svg[^>]*\swidth="([\d.]+)"/.exec(svg), h = /<svg[^>]*\sheight="([\d.]+)"/.exec(svg);
    if (!w || !h) fail('SVG sem width/height');
    return [parseFloat(w[1]), parseFloat(h[1])];
  }

  let done;
  const finished = new Promise(function (r) { done = r; });

  window.figma = {
    root: root,
    get currentPage() { return current; },
    set currentPage(p) { fail('dynamic-page: use setCurrentPageAsync'); },
    setCurrentPageAsync: async function (p) { current = p; },
    loadFontAsync: async function (f) {
      const ok = ['Roboto', 'Inter'];
      if (ok.indexOf(f.family) < 0) throw new Error('fonte inexistente');
      loaded.add(f.family + '|' + f.style);
    },
    createPage: function () { const p = new PageNode(); root.children.push(p); return p; },
    createFrame: function () { const n = new Node('FRAME'); current.appendChild(n); return n; },
    createText: function () { const n = new TextNode(); current.appendChild(n); return n; },
    createNodeFromSvg: function (svg) {
      const n = new Node('FRAME'); n._svg = svg; const s = parseSize(svg); n.width = s[0]; n.height = s[1];
      current.appendChild(n); return n;
    },
    createComponentFromNode: function (n) { n.type = 'COMPONENT'; return n; },
    createTextStyle: function () { return { id: 'S:' + (++nid) }; },
    variables: {
      createVariableCollection: function (name) {
        return { name: name, modes: [{ modeId: 'm1', name: 'Mode 1' }], renameMode: function () {} };
      },
      createVariable: function (name, col, type) {
        const v = { id: 'V:' + (++nid), name: name, type: type, values: {} };
        v.setValueForMode = function (m, val) { v.values[m] = val; };
        return v;
      },
      setBoundVariableForPaint: function (p, field, v) {
        if (p.type !== 'SOLID') fail('bind em paint não sólido');
        const val = v.values.m1;
        return { type: 'SOLID', color: { r: val.r, g: val.g, b: val.b }, opacity: val.a, boundVariables: { color: { type: 'VARIABLE_ALIAS', id: v.id } } };
      },
    },
    viewport: { scrollAndZoomIntoView: function () {} },
    closePlugin: function (msg) { done({ msg: msg, errors: errors }); },
    notify: function () {},
  };
  window.__figmaFinished = finished;
  window.__figmaErrors = errors;

  // ------------------------------------------------------------------
  // Renderização DOM (Auto Layout → flexbox)
  // ------------------------------------------------------------------
  function css(c, a) { return 'rgba(' + Math.round(c.r * 255) + ',' + Math.round(c.g * 255) + ',' + Math.round(c.b * 255) + ',' + a + ')'; }
  function gradDir(t) { return Math.abs(t[0][0]) > 0.5 ? 'to right' : 'to bottom'; }
  function paintCss(p) {
    if (p.type === 'SOLID') return css(p.color, p.opacity == null ? 1 : p.opacity);
    if (p.type === 'GRADIENT_LINEAR') {
      return 'linear-gradient(' + gradDir(p.gradientTransform) + ',' + p.gradientStops.map(function (s) { return css(s.color, s.color.a) + ' ' + (s.position * 100) + '%'; }).join(',') + ')';
    }
    return 'transparent';
  }
  const WEIGHT = { Light: 300, Regular: 400, Medium: 500, Bold: 700 };

  function render(n, parentEl) {
    const el = document.createElement('div');
    n._el = el;
    el.dataset.name = n.name;
    const st = el.style;
    st.boxSizing = 'border-box';
    st.flexShrink = '0';
    const p = n.parent && n.parent.type !== 'PAGE' ? n.parent : null;
    const pAuto = p && p.layoutMode !== 'NONE';
    const abs = p && (!pAuto || n._pos === 'ABSOLUTE');
    if (abs) {
      st.position = 'absolute';
      const c = Object.assign({}, n.constraints || {});
      const pw = p.width, ph = p.height;
      const hugW = n.layoutSizingHorizontal === 'HUG', hugH = n.layoutSizingVertical === 'HUG';
      if (hugW && c.horizontal !== 'STRETCH') c.horizontal = 'MIN';
      if (hugH && c.vertical !== 'STRETCH') c.vertical = 'MIN';
      if (c.horizontal === 'SCALE') { st.left = (n.x / pw * 100) + '%'; st.width = (n.width / pw * 100) + '%'; }
      else if (c.horizontal === 'MAX') { st.right = (pw - n.x - n.width) + 'px'; }
      else if (c.horizontal === 'STRETCH') { st.left = n.x + 'px'; st.right = (pw - n.x - n.width) + 'px'; }
      else if (c.horizontal === 'CENTER') { st.left = 'calc(50% + ' + (n.x + n.width / 2 - pw / 2 - n.width / 2) + 'px)'; }
      else st.left = n.x + 'px';
      if (c.vertical === 'SCALE') { st.top = (n.y / ph * 100) + '%'; st.height = (n.height / ph * 100) + '%'; }
      else if (c.vertical === 'MAX') { st.bottom = (ph - n.y - n.height) + 'px'; }
      else if (c.vertical === 'STRETCH') { st.top = n.y + 'px'; st.bottom = (ph - n.y - n.height) + 'px'; }
      else if (c.vertical === 'CENTER') { st.top = 'calc(50% + ' + (n.y + n.height / 2 - ph / 2 - n.height / 2) + 'px)'; }
      else st.top = n.y + 'px';
    } else if (!p) {
      st.position = 'relative';
    }
    // tamanho
    const pH = pAuto && p.layoutMode === 'HORIZONTAL';
    const sw = n.layoutSizingHorizontal, sh = n.layoutSizingVertical;
    function axis(size, mode, isPrimary, prop) {
      if (abs && st[prop]) return;
      if (mode === 'FILL' && !abs) {
        if (isPrimary) { st.flex = '1 1 0'; st[prop === 'width' ? 'minWidth' : 'minHeight'] = '0'; }
        else { st.alignSelf = 'stretch'; }
      } else if (mode === 'HUG') {
        /* auto */
      } else {
        st[prop] = size + 'px';
      }
    }
    if (!(abs && n.constraints && (n.constraints.horizontal === 'STRETCH'))) axis(n.width, sw, pAuto && pH, 'width');
    if (!(abs && n.constraints && (n.constraints.vertical === 'STRETCH'))) axis(n.height, sh, pAuto && !pH, 'height');

    if (n.type === 'TEXT') {
      st.fontFamily = n._font.family + ', sans-serif';
      st.fontWeight = WEIGHT[n._font.style] || 400;
      st.fontSize = n.fontSize + 'px';
      if (n.lineHeight.unit === 'PIXELS') st.lineHeight = n.lineHeight.value + 'px';
      st.letterSpacing = (n.letterSpacing.value / 100) + 'em';
      st.textAlign = n.textAlignHorizontal.toLowerCase();
      st.color = n.fills.length ? paintCss(n.fills[0]) : 'transparent';
      st.whiteSpace = n.textAutoResize === 'WIDTH_AND_HEIGHT' ? 'pre' : 'pre-wrap';
      if (n.textAutoResize !== 'WIDTH_AND_HEIGHT') st.height = '';
      st.overflowWrap = 'break-word';
      el.textContent = n._chars;
    } else {
      const bgs = n.fills.slice().reverse().map(paintCss);
      if (bgs.length) st.background = bgs.join(',');
      if (n.cornerRadius) st.borderRadius = n.cornerRadius + 'px';
      const sh2 = [];
      n.effects.forEach(function (e) {
        if (e.type === 'DROP_SHADOW') sh2.push(e.offset.x + 'px ' + e.offset.y + 'px ' + e.radius + 'px ' + css(e.color, e.color.a));
        if (e.type === 'BACKGROUND_BLUR') st.backdropFilter = 'blur(' + (e.radius / 2) + 'px)';
      });
      if (n.strokes.length) sh2.push('inset 0 0 0 ' + n.strokeWeight + 'px ' + paintCss(n.strokes[0]));
      if (sh2.length) st.boxShadow = sh2.join(',');
      if (n.clipsContent && !n._svg) st.overflow = 'hidden';
      if (n.layoutMode !== 'NONE') {
        st.display = 'flex';
        st.flexDirection = n.layoutMode === 'HORIZONTAL' ? 'row' : 'column';
        st.padding = n.paddingTop + 'px ' + n.paddingRight + 'px ' + n.paddingBottom + 'px ' + n.paddingLeft + 'px';
        st.gap = (n.layoutWrap === 'WRAP' ? n.counterAxisSpacing : n.itemSpacing) + 'px ' + n.itemSpacing + 'px';
        if (n.layoutMode === 'VERTICAL') st.gap = n.itemSpacing + 'px';
        st.flexWrap = n.layoutWrap === 'WRAP' ? 'wrap' : 'nowrap';
        st.justifyContent = { MIN: 'flex-start', CENTER: 'center', MAX: 'flex-end', SPACE_BETWEEN: 'space-between' }[n.primaryAxisAlignItems];
        st.alignItems = { MIN: 'flex-start', CENTER: 'center', MAX: 'flex-end', BASELINE: 'baseline' }[n.counterAxisAlignItems];
      }
      if (!abs) st.position = 'relative';
      if (n._svg) {
        el.innerHTML = n._svg;
        const s = el.firstElementChild; s.style.display = 'block'; s.setAttribute('width', '100%'); s.setAttribute('height', '100%');
        s.setAttribute('preserveAspectRatio', 'none');
      }
    }
    if (n.opacity < 1) st.opacity = n.opacity;
    parentEl.appendChild(el);
    n.children.forEach(function (c) { render(c, el); });
    return el;
  }
  window.__renderPage = function (pageIndex, host) {
    const page = root.children[pageIndex];
    const out = [];
    page.children.forEach(function (n) {
      if (n.type === 'TEXT') return; // rótulos soltos no canvas
      const wrap = document.createElement('div');
      wrap.style.cssText = 'display:inline-block;margin:0 40px 40px 0;vertical-align:top';
      host.appendChild(wrap);
      render(n, wrap);
      out.push(n);
    });
    return out;
  };
  window.__pages = function () { return root.children.map(function (p) { return p.name; }); };

  // ------------------------------------------------------------------
  // Exportação SVG (posições medidas do DOM)
  // ------------------------------------------------------------------
  const esc = function (s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); };
  function fillAttr(p, defs, ctx, w, h) {
    if (p.type === 'SOLID') {
      const c = p.color; const a = p.opacity == null ? 1 : p.opacity;
      const hex = '#' + [c.r, c.g, c.b].map(function (v) { return ('0' + Math.round(v * 255).toString(16)).slice(-2); }).join('');
      return 'fill="' + hex + '"' + (a < 1 ? ' fill-opacity="' + (+a.toFixed(3)) + '"' : '');
    }
    const id = 'lg' + (++ctx.n);
    const right = gradDir(p.gradientTransform) === 'to right';
    defs.push('<linearGradient id="' + id + '" x1="0" y1="0" x2="' + (right ? 1 : 0) + '" y2="' + (right ? 0 : 1) + '">' +
      p.gradientStops.map(function (s) {
        const c = s.color;
        const hex = '#' + [c.r, c.g, c.b].map(function (v) { return ('0' + Math.round(v * 255).toString(16)).slice(-2); }).join('');
        return '<stop offset="' + s.position + '" stop-color="' + hex + '"' + (c.a < 1 ? ' stop-opacity="' + c.a + '"' : '') + '/>';
      }).join('') + '</linearGradient>');
    return 'fill="url(#' + id + ')"';
  }
  function uniq(ctx, name) {
    let base = name.replace(/[^\wÀ-ÿ\-·×]+/g, '_').replace(/^_+|_+$/g, '') || 'layer';
    if (/^\d/.test(base)) base = 'n' + base;
    const k = ctx.names[base] = (ctx.names[base] || 0) + 1;
    return k > 1 ? base + '_' + k : base;
  }
  let fontCanvas;
  function ascent(font) {
    fontCanvas = fontCanvas || document.createElement('canvas').getContext('2d');
    fontCanvas.font = font;
    return fontCanvas.measureText('Hg').fontBoundingBoxAscent;
  }
  function exportNode(n, origin, defs, ctx, out) {
    const r = n._el.getBoundingClientRect();
    const x = +(r.left - origin.left).toFixed(2), y = +(r.top - origin.top).toFixed(2), w = +r.width.toFixed(2), h = +r.height.toFixed(2);
    if (w <= 0 || h <= 0) return;
    const op = n.opacity < 1 ? ' opacity="' + n.opacity + '"' : '';
    if (n.type === 'TEXT') {
      if (!n._chars) return;
      const cs = getComputedStyle(n._el);
      const fontStr = cs.fontWeight + ' ' + cs.fontSize + ' ' + n._font.family;
      const asc = ascent(fontStr);
      // agrupa caracteres por linha
      const tn = n._el.firstChild; const lines = [];
      const range = document.createRange();
      let cur = null;
      for (let i = 0; i < tn.length; i++) {
        range.setStart(tn, i); range.setEnd(tn, i + 1);
        const rr = range.getClientRects()[0];
        const ch = tn.data[i];
        if (ch === '\n') { cur = null; continue; }
        if (!rr) continue;
        if (!cur || Math.abs(rr.top - cur.top) > 2) { cur = { top: rr.top, left: rr.left, text: '' }; lines.push(cur); }
        cur.text += ch;
      }
      const p = n.fills[0];
      const fa = fillAttr(p, defs, ctx);
      let s = '<text id="' + uniq(ctx, n.name) + '" font-family="' + n._font.family + '" font-size="' + n.fontSize + '" font-weight="' + (WEIGHT[n._font.style] || 400) + '"' +
        (n.letterSpacing.value ? ' letter-spacing="' + (n.fontSize * n.letterSpacing.value / 100).toFixed(2) + '"' : '') + ' ' + fa + op + ' xml:space="preserve">';
      lines.forEach(function (l) {
        const t = l.text.replace(/\s+$/, '');
        s += '<tspan x="' + (l.left - origin.left).toFixed(2) + '" y="' + (l.top - origin.top + asc).toFixed(2) + '">' + esc(t) + '</tspan>';
      });
      out.push(s + '</text>');
      return;
    }
    const id = uniq(ctx, n.name);
    const parts = [];
    const rad = n.cornerRadius ? ' rx="' + Math.min(n.cornerRadius, w / 2, h / 2) + '"' : '';
    n.fills.forEach(function (p) {
      parts.push('<rect x="' + x + '" y="' + y + '" width="' + w + '" height="' + h + '"' + rad + ' ' + fillAttr(p, defs, ctx) + '/>');
    });
    if (n.strokes.length) {
      const sw = n.strokeWeight;
      const sp = n.strokes[0];
      const fa = fillAttr(sp, defs, ctx).replace('fill=', 'stroke=').replace('fill-opacity', 'stroke-opacity');
      parts.push('<rect x="' + (x + sw / 2) + '" y="' + (y + sw / 2) + '" width="' + (w - sw) + '" height="' + (h - sw) + '"' + (n.cornerRadius ? ' rx="' + Math.max(0, Math.min(n.cornerRadius, w / 2, h / 2) - sw / 2) + '"' : '') + ' fill="none" ' + fa + ' stroke-width="' + sw + '"/>');
    }
    if (n._svg) {
      const sv = n._el.firstElementChild;
      const vb = (sv.getAttribute('viewBox') || ('0 0 ' + n.width + ' ' + n.height)).split(/\s+/).map(Number);
      let inner = sv.innerHTML.replace(/id="([^"]+)"/g, function (m, g) { return 'id="' + ctx.pfx + ctx.n + g + '"'; })
        .replace(/url\(#([^)]+)\)/g, function (m, g) { return 'url(#' + ctx.pfx + ctx.n + g + ')'; });
      ctx.n++;
      const rootAttrs = ['fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'stroke-opacity'].map(function (a) {
        const v = sv.getAttribute(a); return v ? ' ' + a + '="' + v + '"' : '';
      }).join('');
      parts.push('<g id="' + id + '_vetor" transform="translate(' + x + ' ' + y + ') scale(' + (w / vb[2]).toFixed(4) + ' ' + (h / vb[3]).toFixed(4) + ')"' + rootAttrs + '>' + inner + '</g>');
    }
    // filhos
    const kids = [];
    n.children.forEach(function (c) { exportNode(c, origin, defs, ctx, kids); });
    let clip = '';
    if (n.clipsContent && !n._svg && kids.length && n.parent && n.parent.type !== 'PAGE') {
      const overflow = n._el.scrollWidth > n._el.clientWidth + 1 || n._el.scrollHeight > n._el.clientHeight + 1 ||
        Array.prototype.some.call(n._el.querySelectorAll('*'), function (e) { const q = e.getBoundingClientRect(); return q.right > r.right + 1 || q.bottom > r.bottom + 1 || q.left < r.left - 1 || q.top < r.top - 1; });
      if (overflow) {
        const cid = 'clip' + (++ctx.n);
        defs.push('<clipPath id="' + cid + '"><rect x="' + x + '" y="' + y + '" width="' + w + '" height="' + h + '"' + rad + '/></clipPath>');
        clip = ' clip-path="url(#' + cid + ')"';
      }
    }
    out.push('<g id="' + id + '"' + op + '>' + parts.join('') + (kids.length ? (clip ? '<g' + clip + '>' + kids.join('') + '</g>' : kids.join('')) : '') + '</g>');
  }
  window.__exportSvg = function (n) {
    const r = n._el.getBoundingClientRect();
    const defs = [], out = [];
    const ctx = { n: 0, names: {}, pfx: 'i' };
    exportNode(n, r, defs, ctx, out);
    const W = Math.round(r.width), H = Math.round(r.height);
    return '<svg xmlns="http://www.w3.org/2000/svg" width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '">' +
      '<defs>' + defs.join('') + '</defs>' +
      '<clipPath id="tela"><rect width="' + W + '" height="' + H + '"/></clipPath><g clip-path="url(#tela)">' + out.join('') + '</g></svg>';
  };
})();
