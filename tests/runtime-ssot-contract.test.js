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
// README must not revive legacy browser combat, level unlocks or recruitment
// as the current Godot game's authoritative implementation.
assert(readme.includes('## Combat and Resonance — implementation status') &&
       readme.includes('## Party and Chapter I chronology'),
  'README does not separate native combat experiments and revised roster');
assert(readme.includes('canExecute=false') &&
       readme.includes('legacy JavaScript preservation build'),
  'README incorrectly promotes old browser action/Art state');
assert(!readme.includes('The current action surface contains eight slots') &&
       !readme.includes('Current prototype progression unlocks'),
  'README labels obsolete browser ability/level table as current Godot combat');
assert(readme.includes('up to five active protagonists'),
  'README omits the five-protagonist target architecture');
assert(readme.includes('**Ionia joins first**') &&
       readme.includes('**Lyra joins second**'),
  'README does not reflect creator-directed revised Chapter I chronology');
assert(readme.includes('Legacy browser controls (not the Godot combat menu)') &&
       readme.includes('Legacy browser quest slice (historical)'),
  'README fails to distinguish preservation browser UI from native Godot');
assert(readme.includes('modules/'), 
  'README lost reference to historical JavaScript compatibility modules');
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
assert(spec.startsWith('# Aetherwake browser preservation — historical technical specification') &&
       spec.includes('Ionia joins first') &&
       spec.includes('Lyra joins second'),
  'SPEC does not mark the old browser recruit ordering as historical');
assert(!spec.includes('Current action slots:') &&
       !spec.includes('Current prototype level unlocks:'),
  'SPEC still labels old browser ability or unlock lists as current');
assert(spec.includes('modules/first-wake-opening.js'),
  'SPEC does not identify the active First Wake opening controller');

console.log('TSTSS runtime/documentation authority separation: PASS (native vs historical browser)');
