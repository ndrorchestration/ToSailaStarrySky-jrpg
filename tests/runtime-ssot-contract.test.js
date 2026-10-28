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
const canon = read('docs/CANON_AND_REVEAL_POLICY.md');
const nativeStatus = read('docs/CHAPTER_I_NATIVE_AUTHORITY_STATUS_2026-10-28.md');
const development = read('docs/DEVELOPMENT.md');
const coordination = read('docs/GODOT_MIGRATION_COORDINATION.md');
const handoff = read('docs/AGENT_HANDOFF_INDEX.md');

assert(!/2D6 PbtA JRPG/i.test(pkg.description),
  'package description still brands current game as 2D6/PbtA');
assert(!/pre-alpha 2D6 PbtA JRPG/i.test(readme),
  'README still brands current game as 2D6/PbtA');
assert(readme.includes('conventional JRPG formula model'),
  'README does not state current combat target');
assert(readme.includes('ACTIVE_PARTY[1..5]'),
  'README does not state 1–5 active-party architecture');
// The README now describes the forward Godot candidate. The Lyra-first
// bootstrap belongs ONLY to the immutable historical JS specification.
assert(readme.includes('Captain Ionia, who joins **before**') &&
  readme.includes('Older **Lyra-first** onboarding') &&
  readme.includes('## Legacy reference build'),
  'README must distinguish revised Ionia-first Godot story from legacy Lyra-first runtime');
assert(spec.includes('First Wake starts with Ender alone and adds Lyra at Sequence 06'),
  'legacy SPEC lost the historical JS roster-opening evidence');
assert(readme.includes('Historical compatibility adapter; not the normal New Game path') &&
  readme.includes('modules/char-create.js'),
  'README must quarantine the original character-create adapter inside the legacy reference');
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

// Public canon supersedes the historical JS enrollment order. No test may
// require the author-approved revised Godot story to inherit Lyra-first saves.
assert(canon.includes('Ionia joins before the Aureate Wake') &&
  canon.includes('Lyra joins later, after splashdown') &&
  canon.includes('this enumeration is **not** the recruitment order') &&
  !canon.includes('joined through the story in that order'),
  'public canon policy must distinguish roster IDs from the revised Ionia-first party order');
assert(canon.includes('LEGACY IMPLEMENTATION') &&
  canon.includes('party combat and reveal authorization distinct'),
  'canon policy must quarantine historical Lyra-first code and prevent combat-story energy conflation');
assert(spec.includes('historical JavaScript technical specification') &&
  spec.includes('the forward Godot First Wake story has Ionia recruited before the first flight'),
  'legacy SPEC must explicitly preserve historical behavior without claiming its recruitment order is current');
assert(development.includes('Forward-development authority') &&
  development.includes('Historical JavaScript smoke gate') &&
  development.includes('Defender-on custody') &&
  development.includes('the preserved **JavaScript/p5/NW.js** runtime'),
  'development guide must distinguish native Godot from legacy browser/test/release evidence');
assert(coordination.includes('Native First Wake development state') &&
  coordination.includes('Historical 2026-10-24 branch/track snapshot') &&
  coordination.includes('independent Defender-on security custody failed'),
  'agent coordination must separate current native drafts from superseded historical branch pointers');
assert(handoff.includes('CHAPTER_I_NATIVE_AUTHORITY_STATUS_2026-10-28.md') &&
  handoff.includes('Ionia') && handoff.includes('Lyra-first'),
  'agent routing must point to public-safe native story/evidence authority');
assert(nativeStatus.includes('not in \`main\`') &&
  nativeStatus.includes('Defender-on security') &&
  nativeStatus.includes('SPEC.md') &&
  !nativeStatus.includes('releases/download/'),
  'dated status register must stay source-bound, legacy-aware, security-gated and without fake download links');

console.log('Aetherwake runtime/documentation SSOT contract: PASS');
