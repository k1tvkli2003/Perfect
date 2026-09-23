const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');

// Exercise actual filesystem lifecycle in an isolated tree; no browser/model calls.
function harness(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'perfect-stage12-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const source = fs.readFileSync(path.join(__dirname, 'generate_stage12_today_stream.cjs'), 'utf8');
  const context = vm.createContext({ require, __dirname, __filename: path.join(__dirname, 'generate_stage12_today_stream.cjs'), process, console, Buffer });
  const isolated = source.replace(/const outputRoot = path\.join\([\s\S]*?\);/, `const outputRoot = ${JSON.stringify(root)};`).replace(/main\(\);\s*$/, '');
  vm.runInContext(isolated, context);
  return { context, output: vm.runInContext('outputRoot', context) };
}

test('regeneration preserves authored decisions, contracts and nested evidence byte-for-byte', (t) => {
  const { context, output } = harness(t);
  fs.mkdirSync(path.join(output, 'runtime'), { recursive: true });
  const authored = {
    'decision.md': '# Authored decision\r\nUnapproved pending visual inspection.\r\n',
    'layout-contract.json': '{"status":"review-pending","selected_candidate":"a","custom":17}\n',
    'symmetry-ledger.md': '# Authored alignment evidence\n',
    'runtime/evidence.txt': 'Preserved runtime receipt\n',
  };
  for (const [name, body] of Object.entries(authored)) fs.writeFileSync(path.join(output, name), body);
  vm.runInContext('resetOutput(); writeContracts([]);', context);
  for (const [name, body] of Object.entries(authored)) assert.equal(fs.readFileSync(path.join(output, name), 'utf8'), body, name);
});

test('fresh output receives unapproved defaults', (t) => {
  const { context, output } = harness(t);
  vm.runInContext('resetOutput(); writeContracts([]);', context);
  const contract = JSON.parse(fs.readFileSync(path.join(output, 'layout-contract.json'), 'utf8'));
  assert.equal(contract.status, 'mock-preview-not-approved');
  assert.equal(contract.selected_candidate, null);
  assert.match(fs.readFileSync(path.join(output, 'decision.md'), 'utf8'), /not approved/);
});
