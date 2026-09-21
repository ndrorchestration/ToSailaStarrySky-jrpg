const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const root = path.join(__dirname, '..');
const onboarding = fs.readFileSync(path.join(root, 'modules', 'char-create.js'), 'utf8');
const partyState = fs.readFileSync(path.join(root, 'modules', 'party-state.js'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const world = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const tts = fs.readFileSync(path.join(root, 'generate_npc_tts.py'), 'utf8');

for (const [label, source] of [['runtime', runtime], ['world mirror', world], ['tts mirror', tts]]) {
  assert(!source.includes('Ionia has watched three hundred years'),
    label + ' reintroduced impossible Ionia chronology');
  assert(!source.includes('captain for three hundred years'),
    label + ' reintroduced impossible Ionia captaincy');
  assert(!source.includes('trying for three centuries'),
    label + ' reintroduced centuries-old Ionia dialogue');
  assert(!source.includes('tired in the way old captains get'),
    label + ' reintroduced elderly-Ionia framing');
  assert(!source.includes('Engineer-in-training'),
    label + ' reintroduced superseded Ender engineering identity');
}

assert(onboarding.includes("name: 'Ender'") &&
  onboarding.includes('age: 22') &&
  onboarding.includes("class: 'Rift Scholar'"),
  'Ender onboarding identity must remain Ender / 22 / Rift Scholar');
assert(!onboarding.includes("class: 'Rift Scholar + Dreamwright'"),
  'superseded Ender Dreamwright job label returned');
assert(!onboarding.includes('Rift Scholar + Dreamwright'),
  'superseded Dreamwright presentation returned elsewhere in onboarding');
assert(!runtime.includes('Young Ender') && !runtime.includes('Rift Scholar + Dreamwright'),
  'runtime reintroduced superseded Ender identity defaults');

for (const expected of [
  "id: 'ender', canonicalName: 'Ender', age: 22",
  "id: 'lyra', canonicalName: 'Lyra', age: 24",
  "id: 'ionia', canonicalName: 'Ionia', age: 28",
  "id: 'reson', canonicalName: 'Reson', age: 25",
  "id: 'aepex', canonicalName: 'Aepex', age: 27",
]) {
  assert(partyState.includes(expected), 'missing canonical roster metadata: ' + expected);
}

assert(runtime.includes('Captain Denith') && world.includes('Captain Denith'),
  'Ionia dialogue must preserve Captain Denith continuity');
assert(world.includes("title: 'Dreamer of the Aureate Wake'"),
  'Lyra must not retain child-prophet presentation in player-facing title text');

console.log('Aetherwake canon reconciliation contract: PASS');
