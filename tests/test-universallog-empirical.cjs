// ==============================================================================
// EMPIRICAL CHALLENGER 2: UNIVERSAL REAL-TIME LOG DRAWER COMPREHENSIVE SUITE
// ==============================================================================

const assert = require("assert");
const fs = require("fs");
const path = require("path");

const appJsPath = path.join(__dirname, "../src-ui/app.js");
const appJsContent = fs.readFileSync(appJsPath, "utf8");

// Extract the Universal Log Drawer code slice directly from app.js
// We find lines from "--- 16. UNIVERSAL REAL-TIME EXECUTION LOG DRAWER CONTROLLER" to "window.initUniversalLogDrawer"
const markerStart = "let universalLogPollingTimer = null;";
const markerEnd = "document.addEventListener(\"DOMContentLoaded\"";

const startIndex = appJsContent.indexOf(markerStart);
const endIndex = appJsContent.indexOf(markerEnd);

if (startIndex === -1 || endIndex === -1) {
  console.error("FAIL: Could not locate universal log controller block in src-ui/app.js");
  process.exit(1);
}

// Slice code exactly
const controllerCode = appJsContent.substring(startIndex, endIndex);

let passed = 0;
let failed = 0;

function assertCondition(name, cond, details = "") {
  if (cond) {
    console.log(`  [PASS] ${name}`);
    passed++;
  } else {
    console.error(`  [FAIL] ${name} ${details ? "- " + details : ""}`);
    failed++;
  }
}

// Minimal DOM Element Mock
class MockElement {
  constructor(id, tagName = "div") {
    this.id = id;
    this.tagName = tagName.toUpperCase();
    this.classList = {
      _classes: new Set(),
      add: (cls) => this.classList._classes.add(cls),
      remove: (cls) => this.classList._classes.delete(cls),
      contains: (cls) => this.classList._classes.has(cls),
    };
    this.attributes = {};
    this.children = [];
    this._textContent = "";
    this._scrollTop = 0;
    this._scrollHeight = 0;
    this.listeners = {};
  }

  get className() {
    return Array.from(this.classList._classes).join(" ");
  }

  set className(val) {
    this.classList._classes.clear();
    String(val).split(/\s+/).filter(Boolean).forEach(c => this.classList._classes.add(c));
  }

  get firstChild() {
    return this.children.length > 0 ? this.children[0] : null;
  }

  get innerHTML() {
    return this.children.map(c => c.outerHTML || c.textContent).join("");
  }

  set innerHTML(val) {
    if (val === "") {
      this.children = [];
      this._textContent = "";
      this._scrollHeight = 0;
      this._scrollTop = 0;
    }
  }

  get textContent() {
    if (this.children.length > 0) {
      return this.children.map(c => c.textContent).join("");
    }
    return this._textContent;
  }

  set textContent(val) {
    this.children = [];
    this._textContent = val;
  }

  get scrollTop() {
    return this._scrollTop;
  }

  set scrollTop(val) {
    this._scrollTop = val;
  }

  get scrollHeight() {
    return this._scrollHeight;
  }

  set scrollHeight(val) {
    this._scrollHeight = val;
  }

  setAttribute(k, v) {
    this.attributes[k] = String(v);
  }

  getAttribute(k) {
    return this.attributes[k] || null;
  }

  appendChild(child) {
    if (child._isFragment) {
      for (const item of child.children) {
        this.children.push(item);
        this._scrollHeight += 20; // simulate height increase
      }
    } else {
      this.children.push(child);
      this._scrollHeight += 20;
    }
    return child;
  }

  removeChild(child) {
    const idx = this.children.indexOf(child);
    if (idx !== -1) {
      this.children.splice(idx, 1);
      this._scrollHeight = Math.max(0, this._scrollHeight - 20);
    }
    return child;
  }

  addEventListener(evt, fn) {
    if (!this.listeners[evt]) this.listeners[evt] = [];
    this.listeners[evt].push(fn);
  }

  dispatchEvent(evt) {
    const list = this.listeners[evt.type || evt] || [];
    for (const fn of list) {
      fn(evt);
    }
  }

  click() {
    let stopped = false;
    const evt = {
      type: "click",
      stopPropagation: () => { stopped = true; },
      isPropagationStopped: () => stopped
    };
    this.dispatchEvent(evt);
    return evt;
  }
}

class MockDocumentFragment {
  constructor() {
    this._isFragment = true;
    this.children = [];
  }

  appendChild(child) {
    this.children.push(child);
  }
}

// Build virtual environment
function createEnvironment() {
  const elements = {
    "universal-log-drawer": new MockElement("universal-log-drawer"),
    "universal-log-header": new MockElement("universal-log-header"),
    "universal-log-count": new MockElement("universal-log-count", "span"),
    "btn-copy-universal-log": new MockElement("btn-copy-universal-log", "button"),
    "btn-clear-universal-log": new MockElement("btn-clear-universal-log", "button"),
    "btn-toggle-universal-log": new MockElement("btn-toggle-universal-log", "button"),
    "universal-log-toggle-icon": new MockElement("universal-log-toggle-icon", "span"),
    "universal-log-body": new MockElement("universal-log-body"),
  };

  // Initial state matches index.html
  elements["universal-log-body"].classList.add("hidden");
  elements["universal-log-toggle-icon"].textContent = "keyboard_arrow_up";
  elements["universal-log-count"].textContent = "0";

  let clipboardText = null;
  let backendLogs = [];
  let rustCalls = [];

  const mockDoc = {
    getElementById: (id) => elements[id] || null,
    createElement: (tag) => new MockElement("mock-" + Math.random(), tag),
    createDocumentFragment: () => new MockDocumentFragment(),
    body: {
      appendChild: () => {},
      removeChild: () => {},
    }
  };

  const mockInvokeRust = async (cmd, args) => {
    rustCalls.push({ cmd, args });
    if (cmd === "get_install_logs") {
      return { success: true, logs: [...backendLogs] };
    }
    if (cmd === "clear_install_logs") {
      backendLogs = [];
      return { success: true, message: "Logs cleared" };
    }
    return { success: true };
  };

  const mockNavigator = {
    clipboard: {
      writeText: async (t) => { clipboardText = t; }
    }
  };

  // Sandbox context
  const sandbox = {
    document: mockDoc,
    navigator: mockNavigator,
    invokeRust: mockInvokeRust,
    setInterval: (fn, ms) => {}, // disable real timer
    clearInterval: () => {},
    showToast: () => {},
    console: { log: () => {}, warn: () => {}, error: () => {} },
    window: {},
  };

  // Evaluate the extracted controller code in the sandbox
  const runCode = new Function(
    "document", "navigator", "invokeRust", "setInterval", "clearInterval", "showToast", "console", "window",
    `
    ${controllerCode}
    return {
      expandUniversalLog,
      openUniversalLog,
      collapseUniversalLog,
      toggleUniversalLog,
      appendUniversalLog,
      appendUniversalLogsToBody,
      pollUniversalLogs,
      initUniversalLogDrawer,
      getLastUniversalLogCount: () => lastUniversalLogCount,
      setLastUniversalLogCount: (v) => { lastUniversalLogCount = v; },
      getIsExpanded: () => isUniversalLogExpanded
    };
    `
  );

  const api = runCode(
    sandbox.document,
    sandbox.navigator,
    sandbox.invokeRust,
    sandbox.setInterval,
    sandbox.clearInterval,
    sandbox.showToast,
    sandbox.console,
    sandbox.window
  );

  return {
    elements,
    api,
    getClipboard: () => clipboardText,
    setBackendLogs: (logs) => { backendLogs = logs; },
    getRustCalls: () => rustCalls
  };
}

console.log("====================================================================");
console.log("CHALLENGER 2: EMPIRICAL STRESS TESTS - UNIVERSAL LOG DRAWER (M3)");
console.log("====================================================================\n");

// -----------------------------------------------------------------------------
// SECTION 1: TOGGLE & EXPAND/COLLAPSE STATE INVARIANTS
// -----------------------------------------------------------------------------
console.log(">>> SECTION 1: Toggle & Expand/Collapse State Invariants <<<");
{
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];
  const icon = env.elements["universal-log-toggle-icon"];
  const btn = env.elements["btn-toggle-universal-log"];

  // 1. Initial State
  assertCondition("1.1 Initial state has 'hidden' class on body", body.classList.contains("hidden"));
  assertCondition("1.2 Initial icon is 'keyboard_arrow_up'", icon.textContent === "keyboard_arrow_up");
  assertCondition("1.3 Initial expansion state is false", env.api.getIsExpanded() === false);

  // 2. Open / Expand
  env.api.openUniversalLog();
  assertCondition("1.4 openUniversalLog() removes 'hidden'", !body.classList.contains("hidden"));
  assertCondition("1.5 openUniversalLog() switches icon to 'keyboard_arrow_down'", icon.textContent === "keyboard_arrow_down");
  assertCondition("1.6 openUniversalLog() sets aria-expanded true", btn.getAttribute("aria-expanded") === "true");
  assertCondition("1.7 openUniversalLog() sets isUniversalLogExpanded = true", env.api.getIsExpanded() === true);

  // 3. Collapse
  env.api.collapseUniversalLog();
  assertCondition("1.8 collapseUniversalLog() adds 'hidden'", body.classList.contains("hidden"));
  assertCondition("1.9 collapseUniversalLog() switches icon to 'keyboard_arrow_up'", icon.textContent === "keyboard_arrow_up");
  assertCondition("1.10 collapseUniversalLog() sets aria-expanded false", btn.getAttribute("aria-expanded") === "false");
  assertCondition("1.11 collapseUniversalLog() sets isUniversalLogExpanded = false", env.api.getIsExpanded() === false);

  // 4. Repeated toggleUniversalLog() cycles
  let okCycle = true;
  for (let i = 0; i < 6; i++) {
    const expectedOpen = (i % 2 === 0);
    env.api.toggleUniversalLog();
    if (env.api.getIsExpanded() !== expectedOpen) okCycle = false;
    if (body.classList.contains("hidden") === expectedOpen) okCycle = false;
  }
  assertCondition("1.12 toggleUniversalLog() cycles back and forth deterministically (6 cycles)", okCycle);
}

// -----------------------------------------------------------------------------
// SECTION 2: UI CLICK EVENT BINDINGS & PROPAGATION ISOLATION
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 2: Event Listeners & Click Propagation Isolation <<<");
{
  const env = createEnvironment();
  env.api.initUniversalLogDrawer();

  const body = env.elements["universal-log-body"];
  const header = env.elements["universal-log-header"];
  const btnToggle = env.elements["btn-toggle-universal-log"];
  const btnCopy = env.elements["btn-copy-universal-log"];
  const btnClear = env.elements["btn-clear-universal-log"];

  // Click toggle button
  btnToggle.click();
  assertCondition("2.1 Clicking btn-toggle expands drawer", !body.classList.contains("hidden"));
  btnToggle.click();
  assertCondition("2.2 Clicking btn-toggle again collapses drawer", body.classList.contains("hidden"));

  // Click header
  header.click();
  assertCondition("2.3 Clicking header expands drawer", !body.classList.contains("hidden"));
  header.click();
  assertCondition("2.4 Clicking header again collapses drawer", body.classList.contains("hidden"));

  // Propagation check on Copy & Clear
  const evtCopy = btnCopy.click();
  assertCondition("2.5 Copy button stops propagation (does not trigger header toggle)", evtCopy.isPropagationStopped());

  const evtClear = btnClear.click();
  assertCondition("2.6 Clear button stops propagation (does not trigger header toggle)", evtClear.isPropagationStopped());
}

// -----------------------------------------------------------------------------
// SECTION 3: DELTA STREAMING & DEDUPLICATION (EMPIRICAL VERIFICATION)
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 3: Delta Streaming & Non-Duplication on Repeated Polls <<<");
(async () => {
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];
  const badge = env.elements["universal-log-count"];

  // Step 1: Poll when 0 logs on server
  env.setBackendLogs([]);
  await env.api.pollUniversalLogs();
  assertCondition("3.1 Poll with 0 logs renders 0 elements", body.children.length === 0);
  assertCondition("3.2 Badge remains '0'", badge.textContent === "0");

  // Step 2: Server produces 5 logs -> first batch
  const batch1 = [
    "[10:00:01] Khởi động hệ thống",
    "[10:00:02] Kiểm tra TPM 2.0: OK",
    "[10:00:03] Kiểm tra SecureBoot: OK",
    "[10:00:04] Nạp cấu hình registry",
    "[10:00:05] Hoàn tất nạp"
  ];
  env.setBackendLogs(batch1);
  await env.api.pollUniversalLogs();

  assertCondition("3.3 First poll with 5 logs appends exactly 5 elements", body.children.length === 5);
  assertCondition("3.4 Badge updates to '5'", badge.textContent === "5");
  assertCondition("3.5 lastUniversalLogCount is 5", env.api.getLastUniversalLogCount() === 5);

  // Step 3: Repeated poll with EXACT SAME 5 logs (NO NEW LOGS)
  await env.api.pollUniversalLogs();
  assertCondition("3.6 Repeated poll with identical logs does NOT duplicate (remains 5 elements)", body.children.length === 5);
  assertCondition("3.7 Badge remains 5 on repeated poll", badge.textContent === "5");

  // Step 4: Another repeated poll
  await env.api.pollUniversalLogs();
  assertCondition("3.8 Second repeated poll still does NOT duplicate (remains 5 elements)", body.children.length === 5);

  // Step 5: Server produces 3 NEW logs (total 8 logs)
  const batch2 = [
    ...batch1,
    "[10:00:06] Bắt đầu dọn dẹp bộ nhớ RAM",
    "[10:00:07] Đã giải phóng 520MB Working Set",
    "[10:00:08] [SUCCESS] Tối ưu hóa thành công!"
  ];
  env.setBackendLogs(batch2);
  await env.api.pollUniversalLogs();

  assertCondition("3.9 Incremental poll appends only 3 new items (total 8 elements)", body.children.length === 8);
  assertCondition("3.10 Badge updates to '8'", badge.textContent === "8");
  assertCondition("3.11 Content of 8th element matches last log", body.children[7].textContent.includes("Tối ưu hóa thành công!"));

  // Step 6: Backend logs cleared externally (logs.len() drops from 8 to 0)
  env.setBackendLogs([]);
  await env.api.pollUniversalLogs();
  assertCondition("3.12 Backend buffer truncation/clear resets DOM body to 0 elements", body.children.length === 0);
  assertCondition("3.13 lastUniversalLogCount resets to 0", env.api.getLastUniversalLogCount() === 0);

  // Step 7: New logs arrive after clear
  const batch3 = [
    "[10:01:00] Tác vụ mới sau khi xóa log"
  ];
  env.setBackendLogs(batch3);
  await env.api.pollUniversalLogs();
  assertCondition("3.14 Subsequent logs after clear render correctly (count = 1)", body.children.length === 1);
  assertCondition("3.15 Content matches newly arrived log", body.children[0].textContent.includes("Tác vụ mới"));
})();

// -----------------------------------------------------------------------------
// SECTION 4: AUTO-SCROLL TO BOTTOM VERIFICATION
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 4: Auto-Scroll to Bottom Verification <<<");
(async () => {
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];

  // 1. Single appendUniversalLog
  env.api.appendUniversalLog("Test log line 1", "info");
  assertCondition("4.1 appendUniversalLog sets scrollTop equal to scrollHeight", body.scrollTop === body.scrollHeight && body.scrollTop > 0);

  // 2. Batch append via delta streaming
  env.setBackendLogs(["Log A", "Log B", "Log C"]);
  await env.api.pollUniversalLogs();
  assertCondition("4.2 Batch appendUniversalLogsToBody maintains scrollTop == scrollHeight", body.scrollTop === body.scrollHeight);

  // 3. Auto-scroll on openUniversalLog
  body.scrollTop = 0; // user scrolled up
  env.api.openUniversalLog();
  assertCondition("4.3 openUniversalLog() scrolls back to bottom", body.scrollTop === body.scrollHeight);
})();

// -----------------------------------------------------------------------------
// SECTION 5: BUFFER CAPACITY LIMIT (1000 NODES RING BUFFER TRUNCATION)
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 5: DOM Memory Protection (1000 Max Nodes Cap) <<<");
{
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];

  // Emits 1200 log items
  const massiveLogs = [];
  for (let i = 1; i <= 1200; i++) {
    massiveLogs.push(`Log message #${i}`);
  }
  env.api.appendUniversalLogsToBody(massiveLogs);

  assertCondition("5.1 Body children capped strictly at 1000 nodes", body.children.length === 1000);
  assertCondition("5.2 Oldest 200 nodes removed; first node is Log message #201", body.children[0].textContent.includes("Log message #201"));
  assertCondition("5.3 Last node is Log message #1200", body.children[999].textContent.includes("Log message #1200"));
}

// -----------------------------------------------------------------------------
// SECTION 6: SANITIZATION & SECURITY (XSS PREVENTION VIA textContent)
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 6: XSS Prevention & Safe Escaping <<<");
{
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];

  const malicious = "<script>alert('XSS')</script><img src=x onerror=alert(1)>";
  env.api.appendUniversalLog(malicious, "error");

  const renderedLine = body.children[0];
  assertCondition("6.1 Child elements are created via DOM textContent (safe)", renderedLine.textContent.includes("<script>alert('XSS')</script>"));
  assertCondition("6.2 Error message receives rose styling", renderedLine.children[renderedLine.children.length - 1].classList.contains("text-rose-400"));
}

// -----------------------------------------------------------------------------
// SECTION 7: BUFFER DRAIN / RING BUFFER SELF-HEALING (SHRINK BEHAVIOR)
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 7: Buffer Drain & Self-Healing on Log Shrink <<<");
(async () => {
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];
  const badge = env.elements["universal-log-count"];

  // Backend starts with 10 logs
  const initial10 = Array.from({ length: 10 }, (_, i) => `Initial Log #${i + 1}`);
  env.setBackendLogs(initial10);
  await env.api.pollUniversalLogs();
  assertCondition("7.1 Initial 10 logs rendered", body.children.length === 10);

  // Backend drains to 6 logs (serverLogs.length < lastUniversalLogCount)
  const drained6 = initial10.slice(4); // logs #5 to #10
  env.setBackendLogs(drained6);
  await env.api.pollUniversalLogs();

  assertCondition("7.2 When backend buffer shrinks, DOM re-syncs to 6 items", body.children.length === 6);
  assertCondition("7.3 Badge updates to 6", badge.textContent === "6");
  assertCondition("7.4 First item is Initial Log #5", body.children[0].textContent.includes("Initial Log #5"));
  assertCondition("7.5 lastUniversalLogCount re-synchronized to 6", env.api.getLastUniversalLogCount() === 6);
})();

// -----------------------------------------------------------------------------
// SECTION 8: CLIPBOARD COPY & CLEAR BUTTON WORKFLOW
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 8: Clipboard Copy & Clear Button Workflow <<<");
(async () => {
  const env = createEnvironment();
  env.api.initUniversalLogDrawer();
  const body = env.elements["universal-log-body"];
  const badge = env.elements["universal-log-count"];
  const btnCopy = env.elements["btn-copy-universal-log"];
  const btnClear = env.elements["btn-clear-universal-log"];

  // 1. Copy when empty
  btnCopy.click();
  assertCondition("8.1 Copy on empty body does not write empty junk to clipboard", env.getClipboard() === null);

  // 2. Add logs and copy
  env.api.appendUniversalLog("First task line", "info");
  env.api.appendUniversalLog("Second task line", "success");
  await btnCopy.click();
  const copied = env.getClipboard();
  assertCondition("8.2 Copied text contains first task line", copied && copied.includes("First task line"));
  assertCondition("8.3 Copied text contains second task line", copied && copied.includes("Second task line"));

  // 3. Clear button click
  await btnClear.click();
  assertCondition("8.4 Clear button cleans DOM body", body.children.length === 0);
  assertCondition("8.5 Clear button resets badge to 0", badge.textContent === "0");
  assertCondition("8.6 Clear button resets lastUniversalLogCount to 0", env.api.getLastUniversalLogCount() === 0);
  const clearRustCalls = env.getRustCalls().filter(c => c.cmd === "clear_install_logs");
  assertCondition("8.7 Clear button called Rust clear_install_logs command", clearRustCalls.length >= 1);
})();

// -----------------------------------------------------------------------------
// SECTION 9: HETEROGENEOUS & MALFORMED LOG INPUT HANDLING
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 9: Heterogeneous & Malformed Log Input Handling <<<");
(async () => {
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];

  // 1. Array containing non-string primitives and empty strings
  const mixedLogs = [
    null,
    undefined,
    "",
    "   ",
    12345,
    "Valid entry after junk"
  ];
  env.setBackendLogs(mixedLogs);
  await env.api.pollUniversalLogs();
  // null, undefined, "", "   " are empty after trim -> skipped
  // 12345 -> String(12345) -> "12345"
  // "Valid entry..." -> rendered
  assertCondition("9.1 Mixed primitives handled safely without exception", body.children.length === 2);
  assertCondition("9.2 Numeric log rendered as '12345'", body.children[0].textContent.includes("12345"));
  assertCondition("9.3 Valid string entry rendered", body.children[1].textContent.includes("Valid entry after junk"));
})();

// -----------------------------------------------------------------------------
// SECTION 10: RAPID ASYNC CONCURRENCY (50 RAPID POLL CYCLES)
// -----------------------------------------------------------------------------
console.log("\n>>> SECTION 10: Rapid Async Polling Concurrency <<<");
(async () => {
  const env = createEnvironment();
  const body = env.elements["universal-log-body"];

  const currentLogs = [];
  for (let cycle = 1; cycle <= 50; cycle++) {
    currentLogs.push(`Concurrent log event #${cycle}`);
    env.setBackendLogs([...currentLogs]);
    await env.api.pollUniversalLogs();
  }

  assertCondition("10.1 Exactly 50 logs rendered after 50 rapid sequential poll updates", body.children.length === 50);
  assertCondition("10.2 Final badge count is '50'", env.elements["universal-log-count"].textContent === "50");
  assertCondition("10.3 No duplicates: child 49 matches event #50", body.children[49].textContent.includes("Concurrent log event #50"));
})();

// -----------------------------------------------------------------------------
// SECTION 11: SUMMARY & EXIT CODE
// -----------------------------------------------------------------------------
setTimeout(() => {
  console.log("\n====================================================================");
  console.log(`CHALLENGER 2 SUMMARY: ${passed} PASS, ${failed} FAIL`);
  console.log("====================================================================");

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}, 150);

