const fs = require('fs');
const path = require('path');
const vm = require('vm');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const root = path.join(__dirname, '..');
const charCreateSrc = fs.readFileSync(path.join(root, 'modules', 'char-create.js'), 'utf8');
const partyStateSrc = fs.readFileSync(path.join(root, 'modules', 'party-state.js'), 'utf8');

const sandbox = {
  window: {},
  console,
};
vm.createContext(sandbox);
vm.runInContext(charCreateSrc, sandbox, { filename: 'modules/char-create.js' });

const charCreate = sandbox.window.AetherCharCreate;
assert(charCreate, 'AetherCharCreate was not exposed');

charCreate.start();
assert(charCreate.phase === 'title', 'onboarding should start at title');

charCreate.handleInput({}, { 13: true });
assert(charCreate.phase === 'class', 'title should route directly to authored field-role selection');
assert(charCreate.slot === 0 && charCreate.nameInput === 'Lyra',
  'first authored onboarding slot must be Lyra');
assert(charCreate.authoredSlots.map(slot => slot.id).join('|') === 'lyra|ionia',
  'authored companion slot identities are incorrect');

// Lyra receives a temporary Sky-Sailor mechanics template.
charCreate.handleInput({}, { 49: true });
charCreate.handleInput({}, { 13: true });
assert(charCreate.phase === 'class' && charCreate.slot === 1,
  'Lyra confirmation should advance to Ionia field-role selection');
assert(charCreate.party[1].name === 'Lyra',
  'Lyra identity must not be player-renamable');
assert(charCreate.party[1].mechanicsTemplateId === 'skySailor',
  'Lyra temporary mechanics template was not recorded');

// Ionia receives a different temporary template.
charCreate.handleInput({}, { 51: true });
charCreate.handleInput({}, { 13: true });
assert(charCreate.phase === 'review',
  'Ionia confirmation should advance to authored party review');
assert(charCreate.party[2].name === 'Ionia',
  'Ionia identity must not be player-renamable');
assert(charCreate.party[2].mechanicsTemplateId === 'aetherWeaver',
  'Ionia temporary mechanics template was not recorded');

vm.runInContext(partyStateSrc, sandbox, { filename: 'modules/party-state.js' });
const partyState = sandbox.window.AetherPartyState;
assert(partyState, 'AetherPartyState was not exposed');

const worldPlayer = {};
partyState.bootstrap(worldPlayer);
partyState.commitPrototypeParty(charCreate.party);
partyState.validate();

const roster = sandbox.window.ROSTER;
const active = sandbox.window.ACTIVE_PARTY;

assert(roster.length === 5, 'canonical roster must contain five authored identities');
assert(active.length === 3, 'active party must contain three canonical references');
assert(roster.map(character => character.id).join('|') === 'ender|lyra|ionia|reson|aepex',
  'canonical roster order changed');
assert(active.map(character => character.id).join('|') === 'ender|lyra|ionia',
  'initial active party identity set changed');
assert(active[0] === roster[0] && active[1] === roster[1] && active[2] === roster[2],
  'active party must contain direct canonical roster references');

assert(roster[1].canonicalName === 'Lyra' && roster[1].name === 'Lyra',
  'Lyra canonical/display identity diverged');
assert(roster[2].canonicalName === 'Ionia' && roster[2].name === 'Ionia',
  'Ionia canonical/display identity diverged');
assert(roster[1].nativeJob === null && roster[2].nativeJob === null,
  'unresolved authored companion native jobs must remain null');
assert(roster[1].implementationSource === 'authored-identity+prototype-mechanics' &&
  roster[2].implementationSource === 'authored-identity+prototype-mechanics',
  'authored/prototype implementation provenance must remain explicit');
assert(roster[1].mechanicsTemplateId === 'skySailor' &&
  roster[2].mechanicsTemplateId === 'aetherWeaver',
  'temporary mechanics templates were not preserved separately from canon');

assert(!/this\.phase = 'name';[\s\S]{0,180}this\.slot = 0/.test(
  charCreateSrc.match(/if \(this\.phase === 'title'\) \{[\s\S]*?\n    \}/)?.[0] || ''
), 'title flow must not reopen free-form companion naming');

console.log('Aetherwake authored onboarding contract: PASS');
