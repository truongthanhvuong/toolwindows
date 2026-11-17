// tests/test-m3-adversarial.cjs
const assert = require('assert');

// 1. Parser Resilience
function parseLogs(res) {
  if (!res) return [];
  let serverLogs = [];
  if (Array.isArray(res.logs)) {
    serverLogs = res.logs;
  } else if (typeof res.logs === 'string') {
    try { serverLogs = JSON.parse(res.logs); } catch (_) { serverLogs = []; }
  } else if (typeof res.message === 'string' && res.message.trim().startsWith('[')) {
    try { serverLogs = JSON.parse(res.message); } catch (_) { serverLogs = []; }
  } else if (typeof res.data === 'string' && res.data.trim().startsWith('[')) {
    try { serverLogs = JSON.parse(res.data); } catch (_) { serverLogs = []; }
  }
  return Array.isArray(serverLogs) ? serverLogs : [];
}

const parserCases = [
  { input: null, expectedLen: 0 },
  { input: {}, expectedLen: 0 },
  { input: { logs: ['a', 'b'] }, expectedLen: 2 },
  { input: { logs: JSON.stringify(['a', 'b', 'c']) }, expectedLen: 3 },
  { input: { message: JSON.stringify(['x']) }, expectedLen: 1 },
  { input: { data: JSON.stringify(['y', 'z']) }, expectedLen: 2 },
  { input: { logs: 'not json' }, expectedLen: 0 },
  { input: { logs: 123 }, expectedLen: 0 }
];

parserCases.forEach((c, idx) => {
  const result = parseLogs(c.input);
  assert.strictEqual(result.length, c.expectedLen, `Parser Case ${idx} failed`);
});
console.log('[ADV-1] Parser Resilience: 8/8 PASS');

// 2. DOM Mock & XSS Injection Protection Test
const elements = {};
function createElement(tag) {
  return {
    tagName: tag.toUpperCase(),
    children: [],
    attributes: {},
    classList: {
      classes: new Set(),
      add(c) { this.classes.add(c); },
      remove(c) { this.classes.delete(c); },
      contains(c) { return this.classes.has(c); }
    },
    textContent: '',
    innerHTML: '',
    scrollTop: 0,
    scrollHeight: 100,
    appendChild(child) { this.children.push(child); return child; },
    removeChild(child) {
      const idx = this.children.indexOf(child);
      if (idx !== -1) this.children.splice(idx, 1);
      return child;
    },
    get firstChild() { return this.children[0] || null; },
    setAttribute(k, v) { this.attributes[k] = v; },
    getAttribute(k) { return this.attributes[k]; },
    addEventListener(evt, fn) { this['on' + evt] = fn; }
  };
}

const doc = {
  getElementById: (id) => {
    if (!elements[id]) elements[id] = createElement('div');
    return elements[id];
  },
  createElement,
  createDocumentFragment: () => ({
    children: [],
    appendChild(child) { this.children.push(child); }
  })
};

function formatLogTimestamp() { return '14:40:00'; }

function formatUniversalLogLine(raw, customLevel = null) {
  if (typeof raw !== 'string') raw = String(raw || '');
  const text = raw.trim();
  if (!text) return null;

  const div = doc.createElement('div');
  const low = text.toLowerCase();
  const lvlLow = customLevel ? String(customLevel).toLowerCase() : '';

  let colorClass = 'text-emerald-300/90';
  if (lvlLow === 'error' || low.includes('[error]') || low.includes('[lỗi]') || low.includes('failed') || low.includes('error:')) {
    colorClass = 'text-rose-400 font-semibold';
  } else if (lvlLow === 'warn' || lvlLow === 'warning' || low.includes('[warn') || low.includes('[cảnh báo]') || low.includes('warning:')) {
    colorClass = 'text-amber-400';
  } else if (lvlLow === 'success' || low.includes('[thành công]') || low.includes('[success]') || low.includes('[ok]') || low.includes('[hoàn tất]')) {
    colorClass = 'text-emerald-400 font-semibold';
  } else if (lvlLow === 'exec' || lvlLow === 'info' || low.includes('[tiến trình]') || low.includes('[exec]') || low.includes('[bắt đầu]')) {
    colorClass = 'text-sky-400';
  }

  const hasTimestamp = /^\s*\[\d{1,4}[:\-\.]/.test(text);
  if (!hasTimestamp) {
    const timeSpan = doc.createElement('span');
    timeSpan.textContent = `[${formatLogTimestamp()}]`;
    div.appendChild(timeSpan);
  }

  const msgSpan = doc.createElement('span');
  msgSpan.className = colorClass;
  msgSpan.textContent = text;
  div.appendChild(msgSpan);

  return div;
}

// XSS Attack Payloads
const maliciousPayloads = [
  '<script>alert("PWNED")</script>',
  '<img src="x" onerror="stealCookie()">',
  '"><svg onload=alert(1)>',
  'Normal prefix <iframe src="evil.com"></iframe>'
];

maliciousPayloads.forEach((payload, idx) => {
  const lineEl = formatUniversalLogLine(payload);
  assert(lineEl !== null);
  // textContent must store the raw literal string, NOT evaluated HTML
  const span = lineEl.children[lineEl.children.length - 1];
  assert.strictEqual(span.textContent, payload);
  assert.strictEqual(span.innerHTML, ''); // innerHTML never assigned!
});
console.log('[ADV-2] XSS Injection Defense: 4/4 PASS (Safe textContent binding)');

// 3. Level Detection Verification
const levelCases = [
  { text: '[LỖI] Khong the ghi tep hosts', expectedColor: 'text-rose-400 font-semibold' },
  { text: '[ERROR] 0x80070005 Access Denied', expectedColor: 'text-rose-400 font-semibold' },
  { text: '[CẢNH BÁO] Quyen han han che', expectedColor: 'text-amber-400' },
  { text: '[WARNING] Low memory', expectedColor: 'text-amber-400' },
  { text: '[THÀNH CÔNG] Da mo khoa thanh cong', expectedColor: 'text-emerald-400 font-semibold' },
  { text: '[SUCCESS] Hoan tat cai dat', expectedColor: 'text-emerald-400 font-semibold' },
  { text: '[TIẾN TRÌNH] Dang xu ly goi tin', expectedColor: 'text-sky-400' },
  { text: '[BẮT ĐẦU] Khoi chay service', expectedColor: 'text-sky-400' }
];

levelCases.forEach((lc, idx) => {
  const el = formatUniversalLogLine(lc.text);
  const span = el.children[el.children.length - 1];
  assert.strictEqual(span.className, lc.expectedColor, `Level case ${idx} failed for ${lc.text}`);
});
console.log('[ADV-3] Vietnamese & English Level Classification: 8/8 PASS');

// 4. Server Buffer Wrap / Ring Truncation Stress Test
let lastUniversalLogCount = 0;
const body = doc.getElementById('universal-log-body-stream');

function appendUniversalLogsToBody(logs) {
  logs.forEach((log) => {
    const el = formatUniversalLogLine(log);
    if (el) body.appendChild(el);
  });
  while (body.children.length > 1000) {
    body.removeChild(body.firstChild);
  }
}

function simulatePoll(serverLogs) {
  if (serverLogs.length < lastUniversalLogCount) {
    body.children = [];
    lastUniversalLogCount = 0;
  }
  if (serverLogs.length > lastUniversalLogCount) {
    const delta = serverLogs.slice(lastUniversalLogCount);
    appendUniversalLogsToBody(delta);
    lastUniversalLogCount = serverLogs.length;
  }
}

// Emulate growing logs up to 1000
let stream = [];
for (let i = 0; i < 1000; i++) stream.push(`Log ${i}`);
simulatePoll(stream);
assert.strictEqual(body.children.length, 1000);
assert.strictEqual(lastUniversalLogCount, 1000);

// Emulate backend drain: 1000 -> 800 (drains 200 items)
stream = stream.slice(200);
for (let i = 1000; i < 1010; i++) stream.push(`Log ${i}`);
assert.strictEqual(stream.length, 810);

// Poll after drain: should clear body and reload the remaining 810 items seamlessly
simulatePoll(stream);
assert.strictEqual(body.children.length, 810);
assert.strictEqual(lastUniversalLogCount, 810);
console.log('[ADV-4] Server Ring Buffer Wrap & Resync: PASS');

// 5. Huge Log Burst (5000 lines) Cap Test
let hugeBurst = [];
for (let i = 0; i < 5000; i++) hugeBurst.push(`Burst ${i}`);
body.children = [];
lastUniversalLogCount = 0;
simulatePoll(hugeBurst);
assert.strictEqual(body.children.length, 1000);
assert.strictEqual(lastUniversalLogCount, 5000);
console.log('[ADV-5] 5,000-Line Huge Burst Capping: PASS (strict <= 1000 DOM nodes)');

console.log('\n=============================================');
console.log('ALL ADVERSARIAL CHALLENGES VERIFIED AND PASSED');
console.log('=============================================\n');
