// =========================================================================
// EMPIRICAL CHALLENGE SUITE: MILESTONE 2 WINDOWS DEPLOY
// Tests DOM interactions, mode switching, and ISO browse bindings
// =========================================================================

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const appJsPath = path.join(__dirname, '..', 'src-ui', 'app.js');
const indexHtmlPath = path.join(__dirname, '..', 'src-ui', 'index.html');

const appJsContent = fs.readFileSync(appJsPath, 'utf8');
const indexHtmlContent = fs.readFileSync(indexHtmlPath, 'utf8');

console.log('=== EMPIRICAL CHALLENGE: M2 WINDOWS DEPLOY INTERACTIVE VERIFICATION ===\n');

// 1. DOM Mock Implementation
class ClassList {
  constructor() {
    this.set = new Set();
  }
  add(...classes) {
    classes.forEach(c => this.set.add(c));
  }
  remove(...classes) {
    classes.forEach(c => this.set.delete(c));
  }
  contains(c) {
    return this.set.has(c);
  }
  toString() {
    return Array.from(this.set).join(' ');
  }
}

class DOMElement {
  constructor(id, tagName = 'div') {
    this.id = id;
    this.tagName = tagName;
    this.classList = new ClassList();
    this.listeners = {};
    this.value = '';
    this.innerText = '';
    this.innerHTML = '';
    this._checked = false;
    this.disabled = false;
    this.name = '';
  }
  get checked() {
    return this._checked;
  }
  set checked(val) {
    this._checked = !!val;
    if (this._checked && this.name) {
      for (const el of elementsById.values()) {
        if (el !== this && el.name === this.name) {
          el._checked = false;
        }
      }
    }
  }
  addEventListener(evt, fn) {
    if (!this.listeners[evt]) this.listeners[evt] = [];
    this.listeners[evt].push(fn);
  }
  click() {
    if (this.onclick) this.onclick({ target: this, preventDefault: () => {} });
    if (this.listeners['click']) {
      for (const fn of this.listeners['click']) {
        fn({ target: this, preventDefault: () => {} });
      }
    }
  }
}

const elementsById = new Map();
function getOrCreateElement(id, tagName = 'div') {
  if (!elementsById.has(id)) {
    elementsById.set(id, new DOMElement(id, tagName));
  }
  return elementsById.get(id);
}

// Instantiate deploy elements matching index.html
const cardUpgrade = getOrCreateElement('card-mode-upgrade');
cardUpgrade.classList.add('border-2', 'border-primary', 'bg-primary-container/15');

const cardClean = getOrCreateElement('card-mode-clean');
cardClean.classList.add('border', 'border-slate-200', 'bg-slate-50/50');

const radioUpgrade = getOrCreateElement('radio-mode-upgrade', 'input');
radioUpgrade.name = 'deploy-mode';
radioUpgrade.value = 'upgrade';
radioUpgrade.checked = true;

const radioClean = getOrCreateElement('radio-mode-clean', 'input');
radioClean.name = 'deploy-mode';
radioClean.value = 'clean';
radioClean.checked = false;

const dotUpgrade = getOrCreateElement('dot-mode-upgrade', 'span');
dotUpgrade.classList.add('bg-primary-container');

const dotClean = getOrCreateElement('dot-mode-clean', 'span');

const inputIsoPath = getOrCreateElement('input-iso-path', 'input');
inputIsoPath.value = '';

const isoPathText = getOrCreateElement('iso-path-text', 'span');
isoPathText.innerText = 'Chưa chọn file ISO';

const btnBrowseIso = getOrCreateElement('btn-browse-iso', 'button');
const btnStartDeploy = getOrCreateElement('btn-start-deploy', 'button');
const osSelector = getOrCreateElement('os-selector', 'select');
osSelector.value = 'custom-iso';

const cbBypassTpm = getOrCreateElement('cb-deploy-bypass-tpm', 'input');
cbBypassTpm.checked = true;
const cbBypassSb = getOrCreateElement('cb-deploy-bypass-sb', 'input');
cbBypassSb.checked = true;
const cbBackupDrivers = getOrCreateElement('cb-deploy-backup-drivers', 'input');
cbBackupDrivers.checked = true;
const cbBackupSystem = getOrCreateElement('cb-deploy-backup-system', 'input');
cbBackupSystem.checked = true;

// Mock environment
let lastRustInvocation = null;
let mockBrowseIsoResult = { success: true, file_path: 'C:\\Windows_Setup\\Win11_24H2.iso' };
const toastsEmitted = [];

const sandbox = {
  document: {
    getElementById: (id) => elementsById.get(id) || null,
    querySelector: (selector) => {
      if (selector === 'input[name="deploy-mode"][value="upgrade"]') return radioUpgrade;
      if (selector === 'input[name="deploy-mode"][value="clean"]') return radioClean;
      if (selector === 'input[name="deploy-mode"]:checked') {
        return radioUpgrade.checked ? radioUpgrade : (radioClean.checked ? radioClean : null);
      }
      return null;
    },
    createElement: (tag) => new DOMElement('', tag),
    body: { appendChild: () => {}, removeChild: () => {} },
    addEventListener: () => {}
  },
  window: {},
  showToast: (title, msg, type) => {
    toastsEmitted.push({ title, msg, type });
  },
  invokeRust: async (cmd, args) => {
    lastRustInvocation = { cmd, args };
    if (args && args.actionId === 'browse_iso') {
      return mockBrowseIsoResult;
    }
    if (args && args.actionId === 'start_win_deploy') {
      return { success: true, message: 'Deployment initiated for ' + args.iso_path };
    }
    return { success: true, message: 'OK' };
  },
  backupSystemFromDeploy: async () => ({ success: true, message: "System backup complete" }),
  backupDriverFromDeploy: async () => ({ success: true, message: "Driver backup complete" }),
  console: {
    log: () => {},
    warn: () => {},
    error: console.error
  },
  setTimeout: (fn) => fn(),
  navigator: { clipboard: { writeText: async () => {} } }
};
sandbox.window = sandbox;

// Run script in sandbox to extract deploy controller functions
vm.createContext(sandbox);

// Extract the deploy controller section from app.js to run cleanly in sandbox
const deployCodeMatch = appJsContent.match(/async\s+function\s+browseIsoFile[\s\S]*?window\.initDeploySubTabs\s*=\s*initDeploySubTabs;/);
if (!deployCodeMatch) {
  console.error('FATAL: Could not locate deploy controller block in app.js');
  process.exit(1);
}

// Also grab startWinDeploy
const startWinDeployMatch = appJsContent.match(/async\s+function\s+startWinDeploy[\s\S]*?window\.startWinDeploy\s*=\s*startWinDeploy;/);
if (!startWinDeployMatch) {
  console.error('FATAL: Could not locate startWinDeploy in app.js');
  process.exit(1);
}

const fullDeployCode = `
  ${deployCodeMatch[0]}
  ${startWinDeployMatch[0]}
  this.selectDeployMode = selectDeployMode;
  this.browseIsoFile = browseIsoFile;
  this.initDeployModeSwitcher = initDeployModeSwitcher;
  this.startWinDeploy = startWinDeploy;
`;

vm.runInContext(fullDeployCode, sandbox);

// Initialize switcher
sandbox.initDeployModeSwitcher();

let passed = 0;
let failed = 0;

function assert(description, condition, details = '') {
  if (condition) {
    console.log(`  [PASS] ${description}`);
    passed++;
  } else {
    console.log(`  [FAIL] ${description} -> ${details}`);
    failed++;
  }
}

async function runTests() {
  console.log('--- Test Suite 1: Interactive Mode Switch Selection ---');

  // Initial state check
  assert('Default initial mode is "upgrade"', radioUpgrade.checked === true && radioClean.checked === false);
  assert('card-mode-upgrade initially has active border-primary class', cardUpgrade.classList.contains('border-primary'));
  assert('card-mode-upgrade initially has active background primary container', cardUpgrade.classList.contains('bg-primary-container/15'));
  assert('card-mode-clean initially does NOT have active border-secondary', !cardClean.classList.contains('border-secondary'));

  // Click card-mode-clean
  console.log('\n  >> Simulating user click on card-mode-clean...');
  cardClean.click();
  assert('radio-mode-clean is now checked', radioClean.checked === true);
  assert('radio-mode-upgrade is no longer checked', radioUpgrade.checked === false);
  assert('card-mode-clean has active border-secondary class', cardClean.classList.contains('border-secondary'));
  assert('card-mode-clean has active bg-secondary-container/15', cardClean.classList.contains('bg-secondary-container/15'));
  assert('card-mode-upgrade border-primary removed', !cardUpgrade.classList.contains('border-primary'));
  assert('dot-mode-clean has active bg-secondary-container', dotClean.classList.contains('bg-secondary-container'));
  assert('dot-mode-upgrade active class removed', !dotUpgrade.classList.contains('bg-primary-container'));

  // Click card-mode-upgrade
  console.log('\n  >> Simulating user click on card-mode-upgrade...');
  cardUpgrade.click();
  assert('radio-mode-upgrade is now checked', radioUpgrade.checked === true);
  assert('radio-mode-clean is no longer checked', radioClean.checked === false);
  assert('card-mode-upgrade has active border-primary class', cardUpgrade.classList.contains('border-primary'));
  assert('card-mode-upgrade has active bg-primary-container/15', cardUpgrade.classList.contains('bg-primary-container/15'));
  assert('card-mode-clean border-secondary removed', !cardClean.classList.contains('border-secondary'));
  assert('dot-mode-upgrade has active bg-primary-container', dotUpgrade.classList.contains('bg-primary-container'));
  assert('dot-mode-clean active class removed', !dotClean.classList.contains('bg-secondary-container'));

  // Stress test: 50 rapid alternating clicks
  console.log('\n  >> Stress testing 50 rapid alternating clicks...');
  let rapidOk = true;
  for (let i = 0; i < 50; i++) {
    cardClean.click();
    if (!radioClean.checked || radioUpgrade.checked) { rapidOk = false; break; }
    cardUpgrade.click();
    if (!radioUpgrade.checked || radioClean.checked) { rapidOk = false; break; }
  }
  assert('State consistency preserved after 50 rapid alternating clicks', rapidOk);

  console.log('\n--- Test Suite 2: ISO File Browser Dual-Binding ---');

  // Verify initial state
  inputIsoPath.value = '';
  isoPathText.innerText = 'Chưa chọn file ISO';

  // Trigger browseIso via button click
  mockBrowseIsoResult = { success: true, file_path: 'D:\\ISOs\\Windows11_24H2_Official.iso' };
  console.log('  >> Simulating user click on btn-browse-iso...');
  btnBrowseIso.click();
  await new Promise(r => setTimeout(r, 20));

  assert('Backend browse_iso action was invoked', lastRustInvocation && lastRustInvocation.args.actionId === 'browse_iso');
  assert('btn-browse-iso sets input-iso-path to selected ISO path', inputIsoPath.value === 'D:\\ISOs\\Windows11_24H2_Official.iso', `Got: "${inputIsoPath.value}"`);
  assert('btn-browse-iso sets iso-path-text to selected ISO path', isoPathText.innerText === 'D:\\ISOs\\Windows11_24H2_Official.iso', `Got: "${isoPathText.innerText}"`);
  assert('os-selector value set to "custom-iso"', osSelector.value === 'custom-iso');

  // Second browse with different path containing spaces and symbols
  mockBrowseIsoResult = { success: true, file_path: 'E:\\Downloads\\Win 11 (24H2) Pro & Enterprise [x64].iso' };
  console.log('  >> Simulating second browse with spaces and special characters in path...');
  btnBrowseIso.click();
  await new Promise(r => setTimeout(r, 20));

  assert('input-iso-path updated with path containing spaces & brackets', inputIsoPath.value === 'E:\\Downloads\\Win 11 (24H2) Pro & Enterprise [x64].iso');
  assert('iso-path-text updated with path containing spaces & brackets', isoPathText.innerText === 'E:\\Downloads\\Win 11 (24H2) Pro & Enterprise [x64].iso');

  console.log('\n--- Test Suite 3: Manual Input Override vs Dialog Path ---');

  // User manually edits input-iso-path without clicking browse
  console.log('  >> Simulating user manual typing in input-iso-path...');
  inputIsoPath.value = 'F:\\Direct_Custom_Build\\setup.exe';
  cardClean.click(); // Select clean mode

  await sandbox.startWinDeploy();
  assert('startWinDeploy invoked with backend action start_win_deploy', lastRustInvocation && lastRustInvocation.args.actionId === 'start_win_deploy');
  assert('startWinDeploy correctly reads manual input-iso-path value', lastRustInvocation.args.iso_path === 'F:\\Direct_Custom_Build\\setup.exe');
  assert('startWinDeploy correctly passes selected deployMode "clean"', lastRustInvocation.args.deployMode === 'clean' || lastRustInvocation.args.mode === 'clean', `Got: mode=${lastRustInvocation.args.mode}, deployMode=${lastRustInvocation.args.deployMode}`);
  assert('startWinDeploy correctly passes backup_system flag', lastRustInvocation.args.backup_system === 'true');
  assert('startWinDeploy correctly passes backup_drivers flag', lastRustInvocation.args.backup_drivers === 'true');

  console.log('\n--- Test Suite 4: index.html DOM Attribute Integrity ---');
  // Check index.html markup
  assert('index.html contains card-mode-upgrade with selectDeployMode("upgrade")',
    indexHtmlContent.includes('id="card-mode-upgrade"') && indexHtmlContent.includes("selectDeployMode('upgrade')"));
  assert('index.html contains card-mode-clean with selectDeployMode("clean")',
    indexHtmlContent.includes('id="card-mode-clean"') && indexHtmlContent.includes("selectDeployMode('clean')"));
  assert('index.html contains radio-mode-upgrade with name="deploy-mode"',
    indexHtmlContent.includes('id="radio-mode-upgrade"') && indexHtmlContent.includes('name="deploy-mode"'));
  assert('index.html contains radio-mode-clean with name="deploy-mode"',
    indexHtmlContent.includes('id="radio-mode-clean"') && indexHtmlContent.includes('name="deploy-mode"'));
  assert('index.html contains input-iso-path', indexHtmlContent.includes('id="input-iso-path"'));
  assert('index.html contains iso-path-text', indexHtmlContent.includes('id="iso-path-text"'));
  assert('index.html contains btn-browse-iso with browseIsoFile()',
    indexHtmlContent.includes('id="btn-browse-iso"') && indexHtmlContent.includes('browseIsoFile()'));

  console.log('\n==========================================================');
  console.log(`EMPIRICAL RESULTS: ${passed} PASSED / ${failed} FAILED (TOTAL: ${passed + failed})`);
  console.log('==========================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
