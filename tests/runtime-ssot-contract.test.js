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
// Current root README is the native Godot entrypoint. Do not force the
// public-facing page to reproduce the legacy browser run/controls/manual.
const godotReadme = read('godot/README.md');
const browserArchive = read('docs/archive/AETHERWAKE_BROWSER_PRESERVATION_README_2026-10-28.md');
const currentStatus = read('docs/CURRENT_GODOT_STATUS_2026-10-28.md');
assert(readme.startsWith('# To Sail the Starry Sky') &&
       readme.includes('## Open and play the native Chapter I preview'),
  'README does not prioritize the current Godot project and playable launch');
assert(readme.includes('## Combat, party and Resonance — what is actually implemented') &&
       readme.includes('up to five active protagonists'),
  'README fails to separate current combat scope from five-character design target');
assert(readme.includes('canExecute=false') &&
       readme.includes('canUnlockArt=false'),
  'README incorrectly implies a live playable Resonance Art');
assert(readme.includes('**Ionia joins first**') &&
       readme.includes('**Lyra joins second**'),
  'README does not reflect revised creator-directed Chapter I chronology');
assert(!readme.includes('The current action surface contains eight slots') &&
       !readme.includes('Current prototype progression unlocks') &&
       !readme.includes('Current published Preview 0.1 candidate:'),
  'README still presents old browser combat/unlocks/installer as current');
assert(readme.includes('docs/archive/AETHERWAKE_BROWSER_PRESERVATION_README_2026-10-28.md') &&
       !readme.includes('## Legacy browser controls (not the Godot combat menu)') &&
       browserArchive.includes('## Legacy browser controls'),
  'obsolete browser instructions were not correctly separated into the archive');
assert(readme.includes('chapter1-six-native-stage-frames.svg') &&
       readme.includes('960×640') &&
       readme.includes('not a public release'),
  'README gallery provenance or release boundary is absent');
assert(/Godot\s+(?:\*\*)?4\.7\.2(?:\*\*)?/.test(currentStatus) &&
       currentStatus.includes('Defender custody') &&
       currentStatus.includes('canExecute=false'),
  'current native implementation register is missing required security/authority boundaries');
assert(godotReadme.startsWith('# To Sail the Starry Sky — native Godot') &&
       godotReadme.includes('**Ionia-first**') &&
       godotReadme.includes('GODOT_FEASIBILITY_VISUAL_LOG_2026-10-28.md') &&
       read('docs/archive/GODOT_FEASIBILITY_VISUAL_LOG_2026-10-28.md')
          .includes('Godot 4.7.2 / GDScript migration feasibility pilot'),
  'nested Godot README still competes with the current launch or lost historical notes');

// Check local README/asset links against the checked-out source tree.
const sourceRoot = path.resolve(__dirname, '..');
const targets = [
  ...readme.matchAll(/\]\(([^)]+)\)/g),
  ...readme.matchAll(/\b(?:href|src)="([^"]+)"/g),
].map(match => match[1]);
for (const raw of targets) {
  const target = raw.split('#')[0];
  if (!target || /^(?:https?:|mailto:|#)/i.test(target)) continue;
  const absolute = path.resolve(sourceRoot, target);
  assert(absolute.startsWith(sourceRoot + path.sep),
    'README link escapes checked-out repository: ' + target);
  assert(fs.existsSync(absolute),
    'README links to missing repository file or image: ' + target);
}
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
