const test = require('node:test');
const assert = require('node:assert/strict');
const {
  cases,
  fixtures,
  render,
  selection,
} = require('./stage12_responsive_preview.cjs');

test('complete matrix: 3 candidates x 3 device classes x 4 states', () => {
  assert.equal(cases.length, 36);
  assert.equal(new Set(cases.map(c => c.id)).size, 36);
  for (const candidate of ['a','b','c']) for (const device of ['phone','tablet','windows']) for (const state of ['sparse','dense','empty','settled']) {
    assert.equal(cases.filter(c => c.candidate===candidate && c.device===device && c.state===state).length,1);
  }
});
test('same fixtures and exactly one next emphasis in every actionable composition', () => {
  for (const c of cases) {
    const html = render(c);
    const ids = [...html.matchAll(/data-row-id="([^"]+)"/g)].map(m=>m[1]);
    assert.deepEqual(ids, fixtures[c.state].map(r=>r.id),c.id);
    assert.equal((html.match(/data-next="true"/g)||[]).length,['empty','settled'].includes(c.state)?0:1,c.id);
    assert.match(html,/Mock preview/);
    assert.match(html,/id="capture"/);
    assert.match(html,/id="footer"/);
    assert.equal(/>[^<]*\d+%[^<]*</.test(html.split('<body>')[1]), false, c.id);
  }
});
test('candidate structures distinct; shared data, semantics and settled review retained', () => {
  const html = ['a','b','c'].map(candidate=>render({...cases[0],candidate,state:'dense'}));
  assert.match(html[0],/class="stream time-ribbon"/);
  assert.match(html[1],/class="stream attention-gate"/);
  assert.match(html[2],/class="stream day-lanes"/);
  for (const h of html) assert.match(h,/Settled/);
});

test('canonical selection freezes guided time stream across responsive states', () => {
  assert.deepEqual(selection, {
    id: 'guided-time-stream-v1',
    status: 'accepted-for-implementation',
    selectedCandidate: 'a',
    rejectedCandidates: ['b', 'c'],
    canonicalCases: [
      'a-phone-sparse',
      'a-phone-dense',
      'a-phone-empty',
      'a-phone-settled',
      'a-tablet-dense',
      'a-windows-dense',
    ],
  });
  const html = render(cases.find(c => c.id === 'a-phone-dense'));
  for (const label of ['Needs a decision', 'Scheduled', 'Habits', 'Flexible', 'Settled']) {
    assert.match(html, new RegExp(`data-group="${label}"`));
  }
  assert.equal((html.match(/data-next="true"/g) || []).length, 1);
  assert.match(html, /<time>09:00<\/time>/);
  assert.match(html, /<time>Anytime<\/time>/);
  assert.match(html, /End of today · all items remain reviewable/);
});
