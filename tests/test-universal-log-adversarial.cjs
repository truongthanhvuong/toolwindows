// ============================================================================
// ADVERSARIAL STRESS TEST: UNIVERSAL LOG DRAWER (M3 EMPIRICAL CHALLENGER)
// ============================================================================
// Tests all adversarial edge cases requested:
// 1. 1000+ log lines stream: DOM node capping logic & ring buffer bounds
// 2. Clearing when buffer is already empty (idempotency)
// 3. Copying when buffer is empty (clean user warning toast, no crash)
// 4. Special characters, unicode, quotes, backslashes, XSS attempts, long strings
// 5. Delta streaming & ring buffer drain recovery
// 6. Null / undefined / empty input robustness
// ============================================================================

const assert = require("assert");

console.log(">>> [ADVERSARIAL HARNESS] M3: UNIVERSAL REAL-TIME LOG DRAWER <<<");

// --- DOM Mock Engine ---
class MockElement {
  constructor(tag, id = "") {
    this.tagName = tag.toUpperCase();
    this.id = id;
    this.className = "";
    this.children = [];
    this.parentElement = null;
    this._textContent = "";
    this._attributes = {};
    this.classList = {
      _classes: new Set(),
      add: (c) => this.classList._classes.add(c),
      remove: (c) => this.classList._classes.delete(c),
      contains: (c) => this.classList._classes.has(c),
      toggle: (c) => {
        if (this.classList._classes.has(c)) {
          this.classList._classes.delete(c);
          return false;
        } else {
          this.classList._classes.add(c);
          return true;
        }
      }
    };
    this.scrollTop = 0;
    this.scrollHeight = 100;
  }

  get textContent() {
    if (this.children.length > 0) {
      return this.children.map(c => c.textContent).join(" ");
    }
    return this._textContent;
  }

  set textContent(v) {
    this._textContent = String(v);
  }

  get firstChild() {
    return this.children.length > 0 ? this.children[0] : null;
  }

  appendChild(child) {
    if (child instanceof MockDocumentFragment) {
      child.children.forEach(c => {
        c.parentElement = this;
        this.children.push(c);
      });
      child.children = [];
      return child;
    }
    child.parentElement = this;
    this.children.push(child);
    return child;
  }

  removeChild(child) {
    const idx = this.children.indexOf(child);
    if (idx !== -1) {
      this.children.splice(idx, 1);
      child.parentElement = null;
      return child;
    }
    throw new Error("Child not found");
  }

  setAttribute(name, val) {
    this._attributes[name] = String(val);
  }

  getAttribute(name) {
    return this._attributes[name] || null;
  }

  set innerHTML(val) {
    if (val === "") {
      this.children.forEach(c => c.parentElement = null);
      this.children = [];
      this.textContent = "";
    } else {
      this._innerHTML = val;
    }
  }

  get innerHTML() {
    return this.children.map(c => c.textContent).join("");
  }
}

class MockDocumentFragment {
  constructor() {
    this.children = [];
  }
  appendChild(child) {
    this.children.push(child);
    return child;
  }
}

// Global DOM Setup
const domElements = new Map();

function setupDOM() {
  domElements.clear();
  const drawer = new MockElement("div", "universal-log-drawer");
  const header = new MockElement("div", "universal-log-header");
  const badge = new MockElement("span", "universal-log-count");
  badge.textContent = "0";
  const btnToggle = new MockElement("button", "btn-toggle-universal-log");
  const toggleIcon = new MockElement("span", "universal-log-toggle-icon");
  toggleIcon.textContent = "keyboard_arrow_up";
  const btnCopy = new MockElement("button", "btn-copy-universal-log");
  const btnClear = new MockElement("button", "btn-clear-universal-log");
  const body = new MockElement("div", "universal-log-body");
  body.classList.add("hidden");

  [drawer, header, badge, btnToggle, toggleIcon, btnCopy, btnClear, body].forEach(el => {
    domElements.set(el.id, el);
  });
}

global.document = {
  getElementById: (id) => domElements.get(id) || null,
  createElement: (tag) => new MockElement(tag),
  createDocumentFragment: () => new MockDocumentFragment(),
  body: new MockElement("body")
};

// Clipboard & Toast Mocks
let clipboardWritten = null;
Object.defineProperty(navigator, "clipboard", {
  value: {
    writeText: async (text) => {
      clipboardWritten = text;
    }
  },
  configurable: true,
  writable: true
});

let toastHistory = [];
global.showToast = (title, msg, type) => {
  toastHistory.push({ title, msg, type });
};

// --- Extract implementation functions directly identical to app.js ---
let isUniversalLogExpanded = false;
let lastUniversalLogCount = 0;

function formatLogTimestamp() {
  return "12:00:00";
}

function formatUniversalLogLine(raw, customLevel = null) {
  if (typeof raw !== "string") raw = String(raw || "");
  const text = raw.trim();
  if (!text) return null;

  const div = document.createElement("div");
  div.className = "py-0.5 px-1 font-mono text-[11px] leading-relaxed break-all hover:bg-slate-800/60 rounded flex items-start gap-1.5 transition-colors";

  const low = text.toLowerCase();
  const lvlLow = customLevel ? String(customLevel).toLowerCase() : "";

  let colorClass = "text-emerald-300/90";
  if (lvlLow === "error" || low.includes("[error]") || low.includes("[lỗi]") || low.includes("failed") || low.includes("error:")) {
    colorClass = "text-rose-400 font-semibold";
  } else if (lvlLow === "warn" || lvlLow === "warning" || low.includes("[warn") || low.includes("[cảnh báo]") || low.includes("warning:")) {
    colorClass = "text-amber-400";
  } else if (lvlLow === "success" || low.includes("[thành công]") || low.includes("[success]") || low.includes("[ok]") || low.includes("[hoàn tất]")) {
    colorClass = "text-emerald-400 font-semibold";
  } else if (lvlLow === "exec" || lvlLow === "info" || low.includes("[tiến trình]") || low.includes("[exec]") || low.includes("[bắt đầu]")) {
    colorClass = "text-sky-400";
  }

  const hasTimestamp = /^\s*\[\d{1,4}[:\-\.]/.test(text);
  if (!hasTimestamp) {
    const timeSpan = document.createElement("span");
    timeSpan.className = "text-slate-500 shrink-0 select-none";
    timeSpan.textContent = `[${formatLogTimestamp()}]`;
    div.appendChild(timeSpan);
  }

  const msgSpan = document.createElement("span");
  msgSpan.className = colorClass;
  msgSpan.textContent = text;
  div.appendChild(msgSpan);

  return div;
}

function appendUniversalLogsToBody(logs) {
  const bodyEl = document.getElementById("universal-log-body");
  if (!bodyEl || !Array.isArray(logs) || logs.length === 0) return;

  const fragment = document.createDocumentFragment();
  logs.forEach((log) => {
    const el = formatUniversalLogLine(log);
    if (el) fragment.appendChild(el);
  });
  bodyEl.appendChild(fragment);

  while (bodyEl.children.length > 1000) {
    bodyEl.removeChild(bodyEl.firstChild);
  }

  bodyEl.scrollTop = bodyEl.scrollHeight;

  const badge = document.getElementById("universal-log-count");
  if (badge) {
    badge.textContent = `${bodyEl.children.length}`;
  }
}

function appendUniversalLog(msg, level = "info") {
  const bodyEl = document.getElementById("universal-log-body");
  if (!bodyEl) return;

  const el = formatUniversalLogLine(msg, level);
  if (el) {
    bodyEl.appendChild(el);
    while (bodyEl.children.length > 1000) {
      bodyEl.removeChild(bodyEl.firstChild);
    }
    bodyEl.scrollTop = bodyEl.scrollHeight;
  }

  const badge = document.getElementById("universal-log-count");
  if (badge) {
    badge.textContent = `${bodyEl.children.length}`;
  }
}

function expandUniversalLog(forceOpen) {
  const drawer = document.getElementById("universal-log-drawer");
  const body = document.getElementById("universal-log-body");
  const icon = document.getElementById("universal-log-toggle-icon");
  const toggleBtn = document.getElementById("btn-toggle-universal-log");
  if (!body) return;

  if (forceOpen) {
    body.classList.remove("hidden");
    if (icon) icon.textContent = "keyboard_arrow_down";
    if (toggleBtn) {
      toggleBtn.setAttribute("aria-expanded", "true");
      toggleBtn.setAttribute("title", "Thu gọn nhật ký");
    }
    if (drawer) drawer.classList.remove("collapsed");
    isUniversalLogExpanded = true;
    body.scrollTop = body.scrollHeight;
  } else {
    body.classList.add("hidden");
    if (icon) icon.textContent = "keyboard_arrow_up";
    if (toggleBtn) {
      toggleBtn.setAttribute("aria-expanded", "false");
      toggleBtn.setAttribute("title", "Mở rộng nhật ký");
    }
    if (drawer) drawer.classList.add("collapsed");
    isUniversalLogExpanded = false;
  }
}

function openUniversalLog() {
  expandUniversalLog(true);
}

function collapseUniversalLog() {
  expandUniversalLog(false);
}

function toggleUniversalLog() {
  expandUniversalLog(!isUniversalLogExpanded);
}

async function triggerCopyLog() {
  const body = document.getElementById("universal-log-body");
  if (!body) return;
  const text = Array.from(body.children)
    .map((child) => child.textContent || "")
    .filter(Boolean)
    .join("\r\n");

  if (!text.trim()) {
    if (typeof showToast === "function") showToast("Console Log", "Không có nội dung log để sao chép.", "info");
    return;
  }

  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
    }
    if (typeof showToast === "function") showToast("Console Log", "Đã sao chép toàn bộ nhật ký vào Clipboard!", "success");
  } catch (err) {
    if (typeof showToast === "function") showToast("Lỗi", "Không thể sao chép nhật ký: " + err, "error");
  }
}

async function triggerClearLog() {
  const body = document.getElementById("universal-log-body");
  if (body) {
    body.innerHTML = "";
  }
  lastUniversalLogCount = 0;
  const badge = document.getElementById("universal-log-count");
  if (badge) {
    badge.textContent = "0";
  }
  if (typeof showToast === "function") {
    showToast("Console Log", "Đã xóa toàn bộ nhật ký thực thi.", "info");
  }
}

async function simulatePollLogs(serverLogs) {
  const body = document.getElementById("universal-log-body");
  const countBadge = document.getElementById("universal-log-count");
  if (!body) return;

  if (serverLogs.length < lastUniversalLogCount) {
    body.innerHTML = "";
    lastUniversalLogCount = 0;
  }

  if (serverLogs.length > lastUniversalLogCount) {
    const deltaLogs = serverLogs.slice(lastUniversalLogCount);
    appendUniversalLogsToBody(deltaLogs);
    lastUniversalLogCount = serverLogs.length;
    if (countBadge) {
      countBadge.textContent = `${body.children.length}`;
    }
  }
}

// Test Runner
const tests = [];
let passedCount = 0;
let failedCount = 0;

function runTest(name, fn) {
  setupDOM();
  isUniversalLogExpanded = false;
  lastUniversalLogCount = 0;
  clipboardWritten = null;
  toastHistory = [];

  try {
    fn();
    console.log(`  [PASS] ${name}`);
    passedCount++;
  } catch (err) {
    console.error(`  [FAIL] ${name}: ${err.message}`);
    failedCount++;
  }
}

async function runAsyncTest(name, fn) {
  setupDOM();
  isUniversalLogExpanded = false;
  lastUniversalLogCount = 0;
  clipboardWritten = null;
  toastHistory = [];

  try {
    await fn();
    console.log(`  [PASS] ${name}`);
    passedCount++;
  } catch (err) {
    console.error(`  [FAIL] ${name}: ${err.message}`);
    failedCount++;
  }
}

(async () => {
  console.log("\n--- TEST GROUP 1: 1000+ LOG LINES STREAM & DOM NODE CAPPING ---");

  runTest("ADV-1.01: Streaming 1500 individual logs caps DOM children at exactly 1000", () => {
    const body = document.getElementById("universal-log-body");
    const badge = document.getElementById("universal-log-count");

    for (let i = 1; i <= 1500; i++) {
      appendUniversalLog(`Log entry #${i}: system execution step`);
      assert(body.children.length <= 1000, `DOM children exceeded 1000 at iteration ${i}: got ${body.children.length}`);
    }

    assert.strictEqual(body.children.length, 1000, "Body children should be exactly 1000");
    assert.strictEqual(badge.textContent, "1000", "Badge counter should display 1000");
    // Verify FIFO eviction: first child should be #501 (1500 - 1000 + 1)
    assert(body.children[0].textContent.includes("#501"), `Oldest log should be #501, got: ${body.children[0].textContent}`);
    assert(body.children[999].textContent.includes("#1500"), `Newest log should be #1500, got: ${body.children[999].textContent}`);
  });

  runTest("ADV-1.02: Batch appending 2500 logs in chunks caps DOM children at 1000", () => {
    const body = document.getElementById("universal-log-body");
    const badge = document.getElementById("universal-log-count");

    // Chunk 1: 600 logs
    const chunk1 = Array.from({ length: 600 }, (_, i) => `Chunk 1 Log #${i + 1}`);
    appendUniversalLogsToBody(chunk1);
    assert.strictEqual(body.children.length, 600);
    assert.strictEqual(badge.textContent, "600");

    // Chunk 2: 700 logs -> Total 1300 -> capped at 1000
    const chunk2 = Array.from({ length: 700 }, (_, i) => `Chunk 2 Log #${i + 1}`);
    appendUniversalLogsToBody(chunk2);
    assert.strictEqual(body.children.length, 1000);
    assert.strictEqual(badge.textContent, "1000");

    // Chunk 3: 1200 logs in single batch -> capped at 1000
    const chunk3 = Array.from({ length: 1200 }, (_, i) => `Chunk 3 Log #${i + 1}`);
    appendUniversalLogsToBody(chunk3);
    assert.strictEqual(body.children.length, 1000);
    assert.strictEqual(badge.textContent, "1000");
  });

  console.log("\n--- TEST GROUP 2: CLEARING WHEN BUFFER IS EMPTY (IDEMPOTENCY) ---");

  await runAsyncTest("ADV-2.01: Clearing an already empty buffer does not throw and preserves 0 state", async () => {
    const body = document.getElementById("universal-log-body");
    const badge = document.getElementById("universal-log-count");

    assert.strictEqual(body.children.length, 0);
    assert.strictEqual(badge.textContent, "0");

    // First clear
    await triggerClearLog();
    assert.strictEqual(body.children.length, 0);
    assert.strictEqual(badge.textContent, "0");
    assert.strictEqual(lastUniversalLogCount, 0);
    assert.strictEqual(toastHistory.length, 1);
    assert.strictEqual(toastHistory[0].title, "Console Log");

    // Second clear in a row (idempotency check)
    await triggerClearLog();
    assert.strictEqual(body.children.length, 0);
    assert.strictEqual(badge.textContent, "0");
    assert.strictEqual(toastHistory.length, 2);

    // 10 rapid clears
    for (let k = 0; k < 10; k++) {
      await triggerClearLog();
    }
    assert.strictEqual(body.children.length, 0);
    assert.strictEqual(badge.textContent, "0");
  });

  console.log("\n--- TEST GROUP 3: COPYING WHEN BUFFER IS EMPTY ---");

  await runAsyncTest("ADV-3.01: Copying when buffer is empty shows warning toast and does not crash", async () => {
    const body = document.getElementById("universal-log-body");
    assert.strictEqual(body.children.length, 0);

    await triggerCopyLog();

    assert.strictEqual(clipboardWritten, null, "Clipboard should NOT be populated with empty string");
    assert.strictEqual(toastHistory.length, 1);
    assert.strictEqual(toastHistory[0].title, "Console Log");
    assert(toastHistory[0].msg.includes("Không có nội dung log"), `Toast message should indicate empty log: got "${toastHistory[0].msg}"`);
    assert.strictEqual(toastHistory[0].type, "info");
  });

  await runAsyncTest("ADV-3.02: Copying when buffer has non-empty logs copies clean multiline text", async () => {
    appendUniversalLog("[12:00:01] Bắt đầu tối ưu hóa hệ thống");
    appendUniversalLog("[12:00:02] Hoàn tất 100%");

    await triggerCopyLog();

    assert(clipboardWritten !== null, "Clipboard should be written");
    assert(clipboardWritten.includes("Bắt đầu tối ưu hóa"), "Clipboard must contain log line 1");
    assert(clipboardWritten.includes("Hoàn tất 100%"), "Clipboard must contain log line 2");
    assert(clipboardWritten.includes("\r\n"), "Clipboard must join lines with CRLF");
    assert.strictEqual(toastHistory.length, 1);
    assert.strictEqual(toastHistory[0].type, "success");
  });

  console.log("\n--- TEST GROUP 4: SPECIAL CHARACTERS, UNICODE, QUOTES & BACKSLASHES ---");

  runTest("ADV-4.01: Paths with backslashes, double/single quotes, and backticks render safely", () => {
    const body = document.getElementById("universal-log-body");

    const edgeLog = `Path: C:\\Windows\\System32\\cmd.exe /c "echo 'hello' and \`test\` \\\\server\\share"`;
    appendUniversalLog(edgeLog);

    assert.strictEqual(body.children.length, 1);
    assert(body.children[0].textContent.includes("C:\\Windows\\System32\\cmd.exe"));
    assert(body.children[0].textContent.includes('"echo \'hello\' and `test` \\\\server\\share"'));
  });

  runTest("ADV-4.02: Full Vietnamese unicode and emoji characters are preserved", () => {
    const body = document.getElementById("universal-log-body");

    const unicodeLog = `[THÀNH CÔNG] Sửa lỗi máy in 0x0000011b & Cứu hộ IT Helpdesk 547 sự cố Ổ đĩa C:! 🚀 ✨ 🔥`;
    appendUniversalLog(unicodeLog);

    assert.strictEqual(body.children.length, 1);
    assert(body.children[0].textContent.includes("Sửa lỗi máy in 0x0000011b"));
    assert(body.children[0].textContent.includes("547 sự cố Ổ đĩa C:"));
    assert(body.children[0].textContent.includes("🚀 ✨ 🔥"));
  });

  runTest("ADV-4.03: HTML and script injection attempts are treated as plain text (no XSS)", () => {
    const body = document.getElementById("universal-log-body");

    const xssLog = `<script>alert('XSS')</script><img src="x" onerror="alert(1)"/><b>bold</b>`;
    appendUniversalLog(xssLog);

    assert.strictEqual(body.children.length, 1);
    // Since textContent is used, the exact markup is escaped text, not raw HTML DOM elements
    assert(body.children[0].textContent.includes("<script>alert('XSS')</script>"));
    assert(body.children[0].textContent.includes('<img src="x" onerror="alert(1)"/>'));
  });

  runTest("ADV-4.04: Extremely long single log string (10,000 characters) does not crash", () => {
    const body = document.getElementById("universal-log-body");

    const longLog = "A".repeat(10000);
    appendUniversalLog(longLog);

    assert.strictEqual(body.children.length, 1);
    assert(body.children[0].textContent.length >= 10000);
  });

  runTest("ADV-4.05: Null, undefined, empty, and whitespace strings do not add corrupt DOM nodes", () => {
    const body = document.getElementById("universal-log-body");

    appendUniversalLog(null);
    appendUniversalLog(undefined);
    appendUniversalLog("");
    appendUniversalLog("   \t  \r\n  ");

    assert.strictEqual(body.children.length, 0, "No corrupt DOM nodes should be added for empty/falsy inputs");
  });

  console.log("\n--- TEST GROUP 5: DELTA POLLING & SERVER RING-BUFFER DRAIN RECOVERY ---");

  await runAsyncTest("ADV-5.01: Delta polling streams new items without re-rendering existing DOM nodes", async () => {
    const body = document.getElementById("universal-log-body");

    // Initial server batch of 3 logs
    const serverLogs = [
      "[10:00:01] Log 1",
      "[10:00:02] Log 2",
      "[10:00:03] Log 3"
    ];
    await simulatePollLogs(serverLogs);
    assert.strictEqual(body.children.length, 3);
    assert.strictEqual(lastUniversalLogCount, 3);

    // Save reference to first node to ensure it is NOT re-rendered on next delta
    const firstNodeRef = body.children[0];

    // Server adds 2 more logs
    serverLogs.push("[10:00:04] Log 4");
    serverLogs.push("[10:00:05] Log 5");
    await simulatePollLogs(serverLogs);

    assert.strictEqual(body.children.length, 5);
    assert.strictEqual(lastUniversalLogCount, 5);
    // Check node identity
    assert.strictEqual(body.children[0], firstNodeRef, "First node reference must be preserved (delta rendering, no full re-render)");
  });

  await runAsyncTest("ADV-5.02: Server ring-buffer drain (serverLogs.length < lastUniversalLogCount) recovers cleanly", async () => {
    const body = document.getElementById("universal-log-body");

    // Simulate 1000 logs received
    const serverLogs = Array.from({ length: 1000 }, (_, i) => `[10:00:00] Server Log #${i + 1}`);
    await simulatePollLogs(serverLogs);
    assert.strictEqual(body.children.length, 1000);
    assert.strictEqual(lastUniversalLogCount, 1000);

    // Now server ring-buffer reaches 1001 and drains 200 items in Rust -> length becomes 801
    const drainedServerLogs = serverLogs.slice(200); // 800 items
    drainedServerLogs.push("[10:01:00] Server Log #1001 (new)"); // 801 items
    assert.strictEqual(drainedServerLogs.length, 801);

    // Poll with drained logs: serverLogs.length (801) < lastUniversalLogCount (1000)
    await simulatePollLogs(drainedServerLogs);

    // Must reset body and re-render all 801 logs cleanly without crash
    assert.strictEqual(body.children.length, 801);
    assert.strictEqual(lastUniversalLogCount, 801);
    const badge = document.getElementById("universal-log-count");
    assert.strictEqual(badge.textContent, "801");
  });

  console.log("\n--- TEST GROUP 6: DRAWER EXPAND / COLLAPSE UI CONTROLLER ---");

  runTest("ADV-6.01: expand, collapse, and toggle manage classes and icons properly", () => {
    const body = document.getElementById("universal-log-body");
    const icon = document.getElementById("universal-log-toggle-icon");
    const toggleBtn = document.getElementById("btn-toggle-universal-log");

    // Initially collapsed
    assert(body.classList.contains("hidden"));
    assert.strictEqual(isUniversalLogExpanded, false);

    // Open
    openUniversalLog();
    assert(!body.classList.contains("hidden"), "Body should not have 'hidden' after open");
    assert.strictEqual(icon.textContent, "keyboard_arrow_down");
    assert.strictEqual(toggleBtn.getAttribute("aria-expanded"), "true");
    assert.strictEqual(isUniversalLogExpanded, true);

    // Collapse
    collapseUniversalLog();
    assert(body.classList.contains("hidden"), "Body should have 'hidden' after collapse");
    assert.strictEqual(icon.textContent, "keyboard_arrow_up");
    assert.strictEqual(toggleBtn.getAttribute("aria-expanded"), "false");
    assert.strictEqual(isUniversalLogExpanded, false);

    // Toggle 1: opens
    toggleUniversalLog();
    assert(!body.classList.contains("hidden"));
    assert.strictEqual(isUniversalLogExpanded, true);

    // Toggle 2: closes
    toggleUniversalLog();
    assert(body.classList.contains("hidden"));
    assert.strictEqual(isUniversalLogExpanded, false);
  });

  console.log("\n========================================================");
  console.log(` ADVERSARIAL STRESS TEST SUMMARY:`);
  console.log(`  PASSED: ${passedCount}`);
  console.log(`  FAILED: ${failedCount}`);
  console.log("========================================================\n");

  if (failedCount > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
})();
