// Executa o plugin no simulador, gera PNGs de prévia e SVGs importáveis no Figma.
import puppeteer from '/home/geronymo/.nvm/versions/node/v24.16.0/lib/node_modules/puppeteer/lib/puppeteer/puppeteer.js';
import fs from 'node:fs'; import path from 'node:path'; import url from 'node:url';
const here = path.dirname(url.fileURLToPath(import.meta.url));
const out = path.resolve(here, '..');
const browser = await puppeteer.launch({ headless: true, executablePath: '/usr/bin/google-chrome', args: ['--allow-file-access-from-files'] });
const page = await browser.newPage();
page.on('console', m => console.log('[page]', m.text()));
page.on('pageerror', e => console.log('[pageerror]', e.message));
await page.setViewport({ width: 1600, height: 1000, deviceScaleFactor: 2 });
await page.goto('file://' + path.join(here, 'render.html'));
await page.evaluate(() => document.fonts.ready);
await page.evaluate(() => document.fonts.load('300 20px Roboto')).catch(()=>{});
const res = await page.evaluate(async () => { window.__start(); return await window.__figmaFinished; });
console.log('closePlugin:', res.msg, res.errors.length ? res.errors : '');
const pages = await page.evaluate(() => __pages());
console.log('pages', pages);
let idx = 0;
for (const d of ['previews', 'figma-import-svg', 'figma-import-svg/extras']) { const f = path.join(out, d); if (fs.existsSync(f)) for (const x of fs.readdirSync(f)) if (/\.(png|svg)$/.test(x)) fs.unlinkSync(path.join(f, x)); }
for (let p = 1; p < pages.length; p++) {
  const names = await page.evaluate((p) => { const h = document.getElementById('host'); h.innerHTML = ''; return __renderPage(p, h).map(n => n.name); }, p);
  await page.evaluate(() => document.fonts.ready);
  for (let i = 0; i < names.length; i++) {
    idx++;
    const slug = (p === 1 ? '' : String(idx).padStart(2, '0') + '-') + names[i].normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^\w]+/g, '-').replace(/^-|-$/g, '').toLowerCase();
    const el = await page.evaluateHandle((i) => document.getElementById('host').children[i].firstElementChild, i);
    await el.screenshot({ path: path.join(out, 'previews', slug + '.png') });
    const svg = await page.evaluate((i, p) => { const h = document.getElementById('host'); return __exportSvg(window.figma.root.children[p].children.filter(n => n.type !== 'TEXT')[i]); }, i, p);
    const dir = p === 1 ? 'figma-import-svg' : path.join('figma-import-svg', 'extras');
    fs.mkdirSync(path.join(out, dir), { recursive: true });
    fs.writeFileSync(path.join(out, dir, slug + '.svg'), svg);
    console.log('ok', slug, (svg.length / 1024).toFixed(0) + 'KB');
  }
}
await browser.close();
