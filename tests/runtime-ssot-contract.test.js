const assert = require('assert');
const fs = require('fs');
const path = require('path');

function read(rel) {
  return fs.readFileSync(path.resolve(__dirname, '..', rel), 'utf8');
}

const pkg = JSON.parse(read('package.json'));
const readme = read('README.md');
const spec = read('SPEC.md');
const uiAdapter = read('modules/ui-adapter.js');
const ui = read('modules/ui.js');
const combatMirror = read('modules/combat.js');
const gap = read('gap_analysis.md');

assert(!/2D6 PbtA JRPG/i.test(pkg.description),
  'package description still brands current game as 2D6/PbtA');
assert(!/pre-alpha 2D6 PbtA JRPG/i.test(readme),
  'README still brands current game as 2D6/PbtA');
assert(readme.includes('conventional JRPG formula model'),
  'README does not state current combat target');
assert(readme.includes('ACTIVE_PARTY[1..5]'),
  'README does not state 1–5 active-party architecture');
assert(readme.includes('First Wake now begins with Ender alone'),
  'README does not state authored First Wake party bootstrap');
assert(readme.includes('Historical compatibility adapter; not the normal New Game path'),
  'README still treats char-create as canonical onboarding');
assert(!uiAdapter.includes('TURN-BASED 2D6 PbtA'),
  'active title UI still advertises 2D6/PbtA');
assert(!ui.includes("'Uncover Truth  (2D6+Wits)'"),
  'active character sheet still shows legacy Uncover Truth dice text');
assert(ui.includes('LEGACY COMPATIBILITY DICE DISPLAY'),
  'remaining dice helper is not explicitly quarantined');
assert(combatMirror.startsWith('// HISTORICAL MIRROR — NOT RUNTIME AUTHORITY.'),
  'legacy combat mirror lacks runtime-authority warning');
assert(gap.startsWith('> **Historical prototype audit — not current runtime SSOT.**'),
  'gap analysis lacks historical-provenance warning');
assert(spec.includes('target production model: conventional JRPG stat/formula resolution'),
  'SPEC does not state production JRPG formula target');
assert(spec.includes('Shared Dream — legacy compatibility residue'),
  'SPEC does not preserve Shared Dream SSOT boundary');
assert(spec.includes('Wind Ward — legacy compatibility residue'),
  'SPEC does not preserve Wind Ward SSOT boundary');
assert(spec.includes('First Wake starts with Ender alone and adds Lyra at Sequence 06'),
  'SPEC does not bind the authored opening recruitment boundary');
assert(spec.includes('modules/first-wake-opening.js'),
  'SPEC does not identify the active First Wake opening controller');

console.log('Aetherwake runtime/documentation SSOT contract: PASS');
