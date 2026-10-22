// VEX Health — سێرڤەری نموونە بۆ سکانی خواردن (Node.js 18 یان نوێتر، بێ هیچ پاکێجێکی زیادە)
//
// کارپێکردن:
//   ANTHROPIC_API_KEY=sk-ant-...  APP_KEY=وشەیەکی-نهێنی  node food_server.mjs
//
// پاشان لە ئەپەکەدا (lib/scan/scan_ai.dart):
//   AiConfig.endpoint = 'https://ناونیشانی-سێرڤەرەکەت/food'
//   AiConfig.appKey   = 'وشەیەکی-نهێنی'
//
// ئەپەکە {task, prompt, image?, text?} دەنێرێت؛ ئەم سێرڤەرە دەینێرێت بۆ Claude
// و تەنها JSON ـی ئەنجامەکە دەگەڕێنێتەوە. کلیلی API تەنها لێرە دەمێنێتەوە.
import http from 'node:http';

const KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = process.env.MODEL || 'claude-sonnet-5-5';
const APP_KEY = process.env.APP_KEY || '';
const PORT = Number(process.env.PORT || 8787);
const MAX_BODY = 12 * 1024 * 1024; // وێنەی گەورە: 12MB

if (!KEY) {
  console.error('ANTHROPIC_API_KEY دانەنراوە');
  process.exit(1);
}

function send(res, code, obj) {
  res.writeHead(code, { 'content-type': 'application/json; charset=utf-8' });
  res.end(typeof obj === 'string' ? obj : JSON.stringify(obj));
}

http
  .createServer(async (req, res) => {
    if (req.method !== 'POST') return send(res, 405, { error: 'method' });
    if (APP_KEY && req.headers['x-app-key'] !== APP_KEY) return send(res, 401, { error: 'key' });
    let size = 0;
    const chunks = [];
    for await (const c of req) {
      size += c.length;
      if (size > MAX_BODY) return send(res, 413, { error: 'too_big' });
      chunks.push(c);
    }
    let j;
    try {
      j = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch {
      return send(res, 400, { error: 'json' });
    }
    const content = [];
    if (j.image && j.image.data) {
      content.push({
        type: 'image',
        source: { type: 'base64', media_type: j.image.media_type || 'image/jpeg', data: j.image.data },
      });
    }
    content.push({ type: 'text', text: String(j.prompt || '').slice(0, 12000) });
    try {
      const r = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': KEY,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ model: MODEL, max_tokens: 1500, messages: [{ role: 'user', content }] }),
      });
      if (!r.ok) return send(res, r.status === 429 ? 429 : 502, { error: await r.text() });
      const out = await r.json();
      const text = (out.content || []).filter((b) => b.type === 'text').map((b) => b.text).join('');
      const m = text.match(/\{[\s\S]*\}/);
      if (!m) return send(res, 502, { error: 'no_json' });
      return send(res, 200, m[0]);
    } catch (e) {
      return send(res, 502, { error: String(e) });
    }
  })
  .listen(PORT, () => console.log('VEX food server on :' + PORT));
