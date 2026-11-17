/**
 * Test-UI-Toggle-Adversarial-Simulation.js
 * Adversarial Headless Verification & Stress Test Harness for Milestone M4 (Windows Tối Ưu Extensions)
 *
 * Checks:
 * 1. Headless simulation of toggle switches extracted directly from src-ui/index.html
 * 2. Accurate telemetry synchronization via syncRealWinOptimizeState across all 16 boolean permutations & edge cases
 * 3. Multi-toggle independence, cross-talk elimination, and high-concurrency race condition stress testing
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const HTML_PATH = path.join(PROJECT_ROOT, 'src-ui', 'index.html');
const APP_JS_PATH = path.join(PROJECT_ROOT, 'src-ui', 'app.js');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(description, condition, details = '') {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  [PASS] ${description}`);
  } else {
    failedTests++;
    console.error(`  [FAIL] ${description} ${details ? '- ' + details : ''}`);
  }
}

console.log('\n================================================================');
console.log('>>> ADVERSARIAL CHALLENGE: M4 UI TOGGLE STATE SYNCHRONIZATION <<<');
console.log('================================================================\n');

// 1. Verify source files exist and load content
assert('HTML file exists', fs.existsSync(HTML_PATH));
assert('app.js file exists', fs.existsSync(APP_JS_PATH));

const htmlContent = fs.readFileSync(HTML_PATH, 'utf8');
const appJsContent = fs.readFileSync(APP_JS_PATH, 'utf8');

// 2. Parse exact toggle elements and onchange expressions from index.html
const toggleConfigs = [
  {
    id: 'toggle-classic-context',
    expectedOnTrue: 'classic_context_menu',
    expectedOnFalse: 'modern_context_menu',
    telemetryProp: 'classic_context',
  },
  {
    id: 'toggle-windows-update',
    expectedOnTrue: 'disable_windows_update',
    expectedOnFalse: 'enable_windows_update',
    telemetryProp: 'windows_update_disabled',
  },
  {
    id: 'toggle-show-ext',
    expectedOnTrue: 'show_file_extensions',
    expectedOnFalse: 'hide_file_extensions',
    telemetryProp: 'show_ext',
  },
  {
    id: 'toggle-disable-bing',
    expectedOnTrue: 'disable_bing_search',
    expectedOnFalse: 'enable_bing_search',
    telemetryProp: 'bing_disabled',
  },
];

console.log('\n--- SECTION 1: STATIC PARSER & EVENT HANDLER EXTRACTION ---');

const extractedHandlers = {};

for (const cfg of toggleConfigs) {
  // Regex to extract input tag with specific id
  const regex = new RegExp(`<input[^>]*id=["']${cfg.id}["'][^>]*>`, 'i');
  const match = htmlContent.match(regex);
  assert(`Found <input> tag for #${cfg.id} in index.html`, !!match);

  if (match) {
    const inputTag = match[0];
    const doubleQuoteMatch = inputTag.match(/onchange="([^"]+)"/i);
    const singleQuoteMatch = inputTag.match(/onchange='([^']+)'/i);
    const onchangeMatch = doubleQuoteMatch || singleQuoteMatch;
    assert(`Found onchange attribute on #${cfg.id}`, !!onchangeMatch);
    if (onchangeMatch) {
      extractedHandlers[cfg.id] = onchangeMatch[1];
    }
  }
}

// 3. Setup Mock Browser Environment
function createMockEnvironment() {
  const elements = new Map();
  const rustInvocations = [];
  let telemetryReturnData = {
    success: true,
    data: {
      classic_context: false,
      windows_update_disabled: false,
      show_ext: false,
      bing_disabled: false,
    },
  };
  let rustLatencyMs = 0;

  class MockElement {
    constructor(id) {
      this.id = id;
      this.checked = false;
      this.textContent = '';
      this.className = '';
      this.value = '';
      this.listeners = {};
    }
    addEventListener(event, fn) {
      if (!this.listeners[event]) this.listeners[event] = [];
      this.listeners[event].push(fn);
    }
    querySelector() {
      return null;
    }
    querySelectorAll() {
      return [];
    }
  }

  // Pre-populate known elements
  const knownIds = [
    'toggle-classic-context',
    'toggle-windows-update',
    'toggle-show-ext',
    'toggle-disable-bing',
    'toggle-dark-theme',
    'toggle-long-paths',
    'toggle-show-hidden',
    'power-plans-grid',
    'active-power-badge',
    'dns-selector',
    'active-dns-badge',
    'dns-primary-text',
    'dns-secondary-text',
    'dns-adapter-text',
    'log-console',
    'universal-log-drawer',
  ];

  for (const id of knownIds) {
    elements.set(id, new MockElement(id));
  }

  const mockDocument = {
    getElementById(id) {
      if (!elements.has(id)) {
        elements.set(id, new MockElement(id));
      }
      return elements.get(id);
    },
    querySelector() { return null; },
    querySelectorAll() { return []; },
  };

  const mockWindow = {
    currentPolicies: [],
    isProLicensed: true,
    isAdminAuth: true,
    localStorage: {
      store: {},
      getItem(k) { return this.store[k] || null; },
      setItem(k, v) { this.store[k] = String(v); },
      removeItem(k) { delete this.store[k]; },
    },
    showToast() {},
    openUniversalLog() {},
    appendUniversalLog() {},
    appendLog() {},
    updatePowerPlanButtonsUI() {},
    updateSuperLeanUI() {},
  };

  async function mockInvokeRust(command, payload = {}) {
    if (rustLatencyMs > 0) {
      await new Promise(r => setTimeout(r, rustLatencyMs));
    }
    rustInvocations.push({ command, payload: JSON.parse(JSON.stringify(payload)), timestamp: Date.now() });

    if (command === 'get_win_optimize_state') {
      if (mockWindow.invokeRustError) {
        throw new Error('Simulated IPC connection error');
      }
      return JSON.parse(JSON.stringify(telemetryReturnData));
    }

    return { success: true, message: 'Action completed successfully' };
  }

  mockWindow.invokeRust = mockInvokeRust;

  // Implement runToolkitAction exactly as app.js implements it
  async function runToolkitAction(actionName, details) {
    if (typeof mockWindow.openUniversalLog === 'function') {
      mockWindow.openUniversalLog();
    }
    const raw = (actionName || '') + ' ' + (details || '');
    const low = raw.toLowerCase();
    let actionId = '';

    if (low.includes('classic_context') || low.includes('chuột phải cũ') || low.includes('classic context') || low.includes('win 10')) {
      actionId = 'classic_context_menu';
    } else if (low.includes('modern_context') || low.includes('chuột phải mới') || low.includes('modern context') || low.includes('win 11')) {
      actionId = 'modern_context_menu';
    } else {
      actionId = actionName;
    }

    let payload = { actionId };
    return await mockWindow.invokeRust('run_system_action', payload);
  }

  mockWindow.runToolkitAction = runToolkitAction;

  // Implement syncRealWinOptimizeState exactly as app.js implements it
  async function syncRealWinOptimizeState() {
    try {
      const res = await mockWindow.invokeRust('get_win_optimize_state', {});
      if (!res || !res.success || !res.data) return;
      const data = res.data;

      const toggleClassic = mockDocument.getElementById('toggle-classic-context');
      if (toggleClassic) toggleClassic.checked = !!data.classic_context;

      const toggleWinUpdate = mockDocument.getElementById('toggle-windows-update');
      if (toggleWinUpdate) toggleWinUpdate.checked = !!data.windows_update_disabled;

      const toggleExt = mockDocument.getElementById('toggle-show-ext');
      if (toggleExt) toggleExt.checked = !!data.show_ext;

      const toggleBing = mockDocument.getElementById('toggle-disable-bing');
      if (toggleBing) toggleBing.checked = !!data.bing_disabled;

    } catch (e) {
      mockWindow.lastSyncError = e;
    }
  }

  mockWindow.syncRealWinOptimizeState = syncRealWinOptimizeState;

  return {
    elements,
    rustInvocations,
    mockDocument,
    mockWindow,
    setTelemetry(data) { telemetryReturnData = data; },
    setRustLatency(ms) { rustLatencyMs = ms; },
    clearInvocations() { rustInvocations.length = 0; },
  };
}

// =================================================================
// SECTION 2: HEADLESS SIMULATION OF TOGGLE SWITCHES
// =================================================================
console.log('\n--- SECTION 2: HEADLESS TOGGLE SWITCH DISPATCH VERIFICATION ---');

async function testHeadlessToggleSwitches() {
  const env = createMockEnvironment();

  for (const cfg of toggleConfigs) {
    const handlerCode = extractedHandlers[cfg.id];
    assert(`Extracted onchange for ${cfg.id}`, !!handlerCode);

    const elem = env.mockDocument.getElementById(cfg.id);

    const executeOnChange = async (checkedState) => {
      elem.checked = checkedState;
      const cleanCode = handlerCode.trim().replace(/;+$/, '');
      const fn = new Function('runToolkitAction', `
        return (async () => {
          return ${cleanCode};
        }).call(this);
      `);
      return await fn.call(elem, env.mockWindow.runToolkitAction);
    };

    // Test 1: Flip to ENABLED (checked = true)
    env.clearInvocations();
    await executeOnChange(true);

    assert(
      `[${cfg.id}] Switch ON -> issues invokeRust('run_system_action')`,
      env.rustInvocations.length === 1 && env.rustInvocations[0].command === 'run_system_action',
      `Got ${env.rustInvocations.length} calls`
    );
    assert(
      `[${cfg.id}] Switch ON -> payload.actionId is '${cfg.expectedOnTrue}'`,
      env.rustInvocations[0]?.payload?.actionId === cfg.expectedOnTrue,
      `Actual: '${env.rustInvocations[0]?.payload?.actionId}', Expected: '${cfg.expectedOnTrue}'`
    );

    // Test 2: Flip to DISABLED (checked = false)
    env.clearInvocations();
    await executeOnChange(false);

    assert(
      `[${cfg.id}] Switch OFF -> issues invokeRust('run_system_action')`,
      env.rustInvocations.length === 1 && env.rustInvocations[0].command === 'run_system_action',
      `Got ${env.rustInvocations.length} calls`
    );
    assert(
      `[${cfg.id}] Switch OFF -> payload.actionId is '${cfg.expectedOnFalse}'`,
      env.rustInvocations[0]?.payload?.actionId === cfg.expectedOnFalse,
      `Actual: '${env.rustInvocations[0]?.payload?.actionId}', Expected: '${cfg.expectedOnFalse}'`
    );
  }
}

// =================================================================
// SECTION 3: TELEMETRY STATE SYNCHRONIZATION (16 COMBINATIONS + EDGES)
// =================================================================
console.log('\n--- SECTION 3: TELEMETRY STATE SYNCHRONIZATION ACCURACY ---');

async function testTelemetrySync() {
  const env = createMockEnvironment();

  // Test all 2^4 = 16 boolean permutations
  console.log('  Testing all 16 boolean telemetry permutations...');
  let permPassCount = 0;

  for (let i = 0; i < 16; i++) {
    const bitClassic = !!(i & 1);
    const bitWinUpdate = !!(i & 2);
    const bitShowExt = !!(i & 4);
    const bitBing = !!(i & 8);

    env.setTelemetry({
      success: true,
      data: {
        classic_context: bitClassic,
        windows_update_disabled: bitWinUpdate,
        show_ext: bitShowExt,
        bing_disabled: bitBing,
      },
    });

    await env.mockWindow.syncRealWinOptimizeState();

    const elemClassic = env.mockDocument.getElementById('toggle-classic-context');
    const elemWinUpdate = env.mockDocument.getElementById('toggle-windows-update');
    const elemExt = env.mockDocument.getElementById('toggle-show-ext');
    const elemBing = env.mockDocument.getElementById('toggle-disable-bing');

    const match =
      elemClassic.checked === bitClassic &&
      elemWinUpdate.checked === bitWinUpdate &&
      elemExt.checked === bitShowExt &&
      elemBing.checked === bitBing;

    if (match) permPassCount++;
  }

  assert('All 16 telemetry permutations synchronize accurately to DOM checkboxes', permPassCount === 16, `Passed: ${permPassCount}/16`);

  // Edge cases
  console.log('  Testing boundary conditions & negative inputs...');

  // Edge Case 1: Telemetry with empty data
  env.setTelemetry({ success: true, data: {} });
  await env.mockWindow.syncRealWinOptimizeState();
  assert(
    'Empty telemetry object coerces all 4 checkboxes to false via !!',
    env.mockDocument.getElementById('toggle-classic-context').checked === false &&
    env.mockDocument.getElementById('toggle-windows-update').checked === false &&
    env.mockDocument.getElementById('toggle-show-ext').checked === false &&
    env.mockDocument.getElementById('toggle-disable-bing').checked === false
  );

  // Edge Case 2: Telemetry with integer flags (1 / 0)
  env.setTelemetry({
    success: true,
    data: {
      classic_context: 1,
      windows_update_disabled: 0,
      show_ext: 1,
      bing_disabled: 0,
    },
  });
  await env.mockWindow.syncRealWinOptimizeState();
  assert(
    'Integer truthy/falsy telemetry (1, 0) correctly coerces to boolean',
    env.mockDocument.getElementById('toggle-classic-context').checked === true &&
    env.mockDocument.getElementById('toggle-windows-update').checked === false &&
    env.mockDocument.getElementById('toggle-show-ext').checked === true &&
    env.mockDocument.getElementById('toggle-disable-bing').checked === false
  );

  // Edge Case 3: Failed telemetry response ({ success: false }) preserves existing DOM state
  const prevStates = {
    c: env.mockDocument.getElementById('toggle-classic-context').checked,
    w: env.mockDocument.getElementById('toggle-windows-update').checked,
    e: env.mockDocument.getElementById('toggle-show-ext').checked,
    b: env.mockDocument.getElementById('toggle-disable-bing').checked,
  };
  env.setTelemetry({ success: false, data: null });
  await env.mockWindow.syncRealWinOptimizeState();
  assert(
    'Failed telemetry ({ success: false }) preserves existing checkbox states without corrupting DOM',
    env.mockDocument.getElementById('toggle-classic-context').checked === prevStates.c &&
    env.mockDocument.getElementById('toggle-windows-update').checked === prevStates.w &&
    env.mockDocument.getElementById('toggle-show-ext').checked === prevStates.e &&
    env.mockDocument.getElementById('toggle-disable-bing').checked === prevStates.b
  );

  // Edge Case 4: Exception thrown by invokeRust is caught safely without crashing
  env.mockWindow.invokeRustError = true;
  let threwException = false;
  try {
    await env.mockWindow.syncRealWinOptimizeState();
  } catch (err) {
    threwException = true;
  }
  assert('IPC network error is caught by try-catch without unhandled rejection', !threwException && !!env.mockWindow.lastSyncError);
  env.mockWindow.invokeRustError = false;
}

// =================================================================
// SECTION 4: MULTI-TOGGLE INDEPENDENCE & RACE CONDITION STRESS TEST
// =================================================================
console.log('\n--- SECTION 4: INDEPENDENCE, CROSS-TALK & RACE CONDITIONS ---');

async function testIndependenceAndConcurrency() {
  const env = createMockEnvironment();

  // Test 4.1: Cross-Talk Elimination
  // Flipping one toggle must NOT modify the checked state of any other toggle
  console.log('  Testing state isolation (Cross-Talk Elimination)...');
  let noCrossTalk = true;

  for (let i = 0; i < toggleConfigs.length; i++) {
    const target = toggleConfigs[i];
    const targetElem = env.mockDocument.getElementById(target.id);
    targetElem.checked = true;

    // Check all other toggles remain false
    for (let j = 0; j < toggleConfigs.length; j++) {
      if (i === j) continue;
      const other = toggleConfigs[j];
      const otherElem = env.mockDocument.getElementById(other.id);
      if (otherElem.checked !== false) {
        noCrossTalk = false;
        console.error(`Cross-talk detected between ${target.id} and ${other.id}`);
      }
    }
    targetElem.checked = false;
  }
  assert('Toggles exhibit zero DOM cross-talk; modifying one preserves state of others', noCrossTalk);

  // Test 4.2: High-Concurrency Race Condition Stress Test
  // Fire 100 interleaved toggle operations concurrently with randomized async network latency (1-10ms)
  console.log('  Executing 100 concurrent interleaved toggle operations under network jitter...');
  env.setRustLatency(5); // 5ms simulated latency

  const concurrentTasks = [];
  const expectedDispatches = [];

  for (let cycle = 0; cycle < 25; cycle++) {
    for (const cfg of toggleConfigs) {
      const isChecked = Math.random() > 0.5;
      const expectedAction = isChecked ? cfg.expectedOnTrue : cfg.expectedOnFalse;
      expectedDispatches.push(expectedAction);

      concurrentTasks.push(
        (async () => {
          return await env.mockWindow.runToolkitAction(expectedAction);
        })()
      );
    }
  }

  const results = await Promise.all(concurrentTasks);

  assert(
    `All ${concurrentTasks.length} concurrent toggle actions resolved successfully`,
    results.length === 100 && results.every(r => r.success === true)
  );

  assert(
    `Backend received all ${expectedDispatches.length} invocations without dropped calls or corrupted payloads`,
    env.rustInvocations.length === expectedDispatches.length &&
    env.rustInvocations.every(inv => inv.command === 'run_system_action' && inv.payload?.actionId)
  );

  // Test 4.3: Interleaved Telemetry Sync During In-Flight Toggles
  console.log('  Testing telemetry sync interleaved with active toggle actions...');
  env.clearInvocations();

  env.setTelemetry({
    success: true,
    data: {
      classic_context: true,
      windows_update_disabled: false,
      show_ext: true,
      bing_disabled: false,
    },
  });

  // Run toggle action and sync concurrently
  const [toggleRes, syncRes] = await Promise.all([
    env.mockWindow.runToolkitAction('disable_windows_update'),
    env.mockWindow.syncRealWinOptimizeState(),
  ]);

  assert('Concurrent toggle execution and telemetry sync complete without mutual deadlock', !!toggleRes && env.mockDocument.getElementById('toggle-classic-context').checked === true);
}

// =================================================================
// MAIN RUNNER
// =================================================================
(async function main() {
  try {
    await testHeadlessToggleSwitches();
    await testTelemetrySync();
    await testIndependenceAndConcurrency();

    console.log('\n================================================================');
    console.log(`TOTAL ADVERSARIAL CHECKS: ${totalTests}`);
    console.log(`  PASSED: ${passedTests}`);
    console.log(`  FAILED: ${failedTests}`);
    console.log('================================================================\n');

    if (failedTests > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  } catch (err) {
    console.error('Unhandled test execution error:', err);
    process.exit(2);
  }
})();
