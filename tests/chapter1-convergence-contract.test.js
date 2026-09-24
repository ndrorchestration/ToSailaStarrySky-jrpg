'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const opening = require('../modules/first-wake-opening.js');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const worldMirror = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const coreMirror = fs.readFileSync(path.join(root, 'modules', 'core.js'), 'utf8');
const uiMirror = fs.readFileSync(path.join(root, 'modules', 'ui-adapter.js'), 'utf8');
const packageJson = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const chapter1WindowsBuild = fs.readFileSync(
  path.join(root, 'scripts', 'build-chapter1-windows.ps1'), 'utf8'
);
const chapter1Workflow = fs.readFileSync(
  path.join(root, '.github', 'workflows', 'chapter1-convergence.yml'), 'utf8'
);
const smokeWorkflow = fs.readFileSync(
  path.join(root, '.github', 'workflows', 'smoke.yml'), 'utf8'
);

assert.strictEqual(opening.VERSION, '0.7.0',
  'Chapter 1 must use the explorable First Wake opening authority');
assert.strictEqual(opening.validate(), true);
for (const expected of [
  ['lyra_family','wake-free-roam'],
  ['wrong_song','wrong-song'],
  ['ionia_practical','find-ionia'],
  ['core_walk','wake-investigation'],
]) {
  const scene = opening.SCENES.find(entry => entry.id === expected[0]);
  assert(scene && scene.interaction === expected[1],
    expected[0] + ' must remain player-driven');
}
for (const fn of ['moveWake','interactWake','wakeExplorationView','nearbyWakeHotspot']) {
  assert.strictEqual(typeof opening[fn], 'function', 'opening authority missing ' + fn);
}

assert(runtime.includes('const wakeExplorationScene = openingScene && openingScene.sequence >= 5 && openingScene.sequence <= 8'),
  'live runtime must route Sequences 05–08 through exploration input');
assert(runtime.includes('opening.moveWake(openingState, dx, dy)'),
  'live runtime must use authored Wake movement');
assert(runtime.includes('opening.interactWake(openingState)'),
  'live runtime must use authored Wake interactions');
assert(runtime.includes('ANY 2 OF 3 CLUES'),
  'Core investigation guidance must expose the flexible clue gate');

const canonicalHazards = [
  "id: 'sky_predator'",
  "id: 'wind_shear'",
  "id: 'aether_leak'",
  "id: 'corporate_intercept'",
];
for (const marker of canonicalHazards) {
  assert(runtime.includes(marker), 'live runtime missing canonical hazard ' + marker);
  assert(worldMirror.includes(marker), 'world mirror missing canonical hazard ' + marker);
}
assert(runtime.includes('if (quest.hazardsCompleted >= 4)'),
  'Chapter 1 Crossing must require all four hazard victories');
assert(worldMirror.includes('if (quest.hazardsCompleted >= 4)'),
  'world mirror must match four-hazard progression gate');

const proximityStart = runtime.indexOf('function checkHazardProximity(tx, ty)');
const proximityEnd = runtime.indexOf('function completeHazard(index)', proximityStart);
assert(proximityStart >= 0 && proximityEnd > proximityStart,
  'live hazard proximity authority missing');
const proximity = runtime.slice(proximityStart, proximityEnd);
assert(!proximity.includes('Math.random()'),
  'chapter-critical hazard entry must not depend on random rolls');
for (let i = 0; i < 4; i++) {
  assert(proximity.includes('startHazardEncounter(' + i + ')') ||
         proximity.includes('startHazardEncounter(index)'),
    'hazard zone must launch combat through the canonical encounter seam');
}

assert(runtime.includes('Crossing — four hazards on the way to the ship.'),
  'quest log must describe the canonical four-hazard route');
assert(runtime.includes("text('JOURNAL'"),
  'quest log must expose recent Chapter 1 journal state');
assert(runtime.includes('journal: quest.journal.map(entry => ({ ...entry }))'),
  'quest-state projection must expose journal entries');

assert(!runtime.includes('previewEndAt > 0 && millis() >= previewEndAt'),
  'Chapter 1 must not auto-transition into the Preview end card');
assert(!runtime.includes("completedNpcId === 'elder_farmer' && previewEncounterArmed"),
  'Ionia dialogue must not force the old Preview-only Sky-Predator ending');
assert(!runtime.includes("nearest.id === 'elder_farmer' && !previewEncounterStarted"),
  'Ionia contact must not arm the old Preview-only encounter');


assert(runtime.includes('function determineChoiceOutcome(pathId)'),
  'Chapter 1 final choice must use deterministic state-based resolution');
assert(runtime.includes("return score >= 60 ? 'strong' : 'strained';"),
  'Chapter 1 final choice must resolve to deterministic strong/strained outcomes');
assert(!runtime.includes('Simulate 2D6 roll for variant'),
  'Chapter 1 must not use the legacy hidden 2d6 choice roll');
assert(!runtime.includes("quest.choiceVariant = roll >= 10 ? '10+' : '7-9';"),
  'Chapter 1 must not preserve dice-derived choice variants');
assert(!runtime.includes('start combat encounter (dev/testing)'),
  'normal Chapter 1 world input must not expose the developer combat shortcut');
assert(!runtime.includes("else if (keyCode === 67) {\n      if (combat && typeof combat.beginEncounter === 'function')"),
  'normal Chapter 1 world input must not retain the C-key combat injection path');
assert(!runtime.includes("Three hazards between you and the core's last stable chamber"),
  'Chapter 1 journal must not retain the stale three-hazard route');
assert(!runtime.includes("Three voices on the ship"),
  'Chapter 1 journal must not retain stale three-contact copy');

for (const staleCanon of [
  '"Holt. Acquisition officer, Copper Syndicate.',
  'Meridian has provisions for betrayal.',
  'Meridian offers you a place in the world',
  'the kid who hears wrong, or the kid who saves the ship by hearing right.',
]) {
  assert(!worldMirror.includes(staleCanon),
    'Chapter 1 character dialogue contains stale canon: ' + staleCanon);
}
assert(worldMirror.includes('"Verrick. Acquisition officer, Copper Syndicate.'),
  'Verrick must introduce himself with his current canonical name');
assert(!worldMirror.includes('Meridian'),
  'world mirror must not retain superseded Meridian naming');
assert(worldMirror.includes("id: 'ender'") &&
       worldMirror.includes('window.AetherPartyState.refreshProductionStats(player);'),
  'world mirror must preserve Ender production-stat initialization');
assert(!coreMirror.includes('start combat encounter (dev/testing)') &&
       !coreMirror.includes("if (key === 'c' || key === 'C')"),
  'core mirror must not retain direct developer combat shortcuts');
for (const staleUi of ['2D6+Wits','2D6+Spirit','2D6+Presence','EMP 1d6+2']) {
  assert(!uiMirror.includes(staleUi),
    'UI mirror must not advertise legacy dice combat: ' + staleUi);
}


assert(runtime.includes("function getChoiceOutcomeText()"),
  'Chapter 1 must expose the authored path consequence during WAKE');
assert(runtime.includes("'epiline_10',  // best path-C ending: First Note"),
  'First Note must have explicit high-priority ending resolution');
assert(runtime.includes('const choiceOutcome = getChoiceOutcomeText();'),
  'WAKE presentation must render the selected path consequence');
assert(runtime.includes("} else if (quest.state === QUEST_STATES.CONTACT)"),
  'SIGNAL and CONTACT conversation progress must be separate');


assert(runtime.includes('quest.choicePath = path.id;'),
  'numeric Chapter 1 choice must persist the canonical path ID before WAKE resolution');

assert(runtime.includes("resolution.model === 'jrpg-stat-formula'"),
  'live Chapter 1 combat must route admitted production actions through formula resolution');
assert(runtime.includes('window.AetherCombatFormula.resolveAction('),
  'live Chapter 1 combat must invoke the production formula engine');
assert(runtime.includes("id: 'ender'") &&
       runtime.includes('window.AetherPartyState.refreshProductionStats(player);'),
  'Ender production stats must be attached before the first Chapter 1 combat');
assert(runtime.includes("throw new Error('WORLD_PLAYER_PRODUCTION_STATS_UNAVAILABLE')"),
  'Chapter 1 must fail visibly rather than silently fall back when production stats are unavailable');
assert(!runtime.includes("'Uncover Truth  (2D6+Wits)'"),
  'Chapter 1 character sheet must not advertise legacy 2D6 resolution');
assert(!runtime.includes("'Shared Dream   (2D6+Spirit)'"),
  'Chapter 1 character sheet must not advertise blocked legacy Shared Dream resolution');
assert(!runtime.includes("'Resonator Staff: EMP 1d6+2'"),
  'Chapter 1 character sheet must not advertise legacy die damage');
assert(runtime.includes("'Stats + ability formula resolve the action'"),
  'Chapter 1 turn UI must describe the production formula model');
assert(runtime.includes('abils.forEach((a, i) => {'),
  'Chapter 1 character sheet ability list must iterate its actual local ability data');


assert(runtime.includes('if (gameOver && keyCode === 82)'),
  'epilogue [R] replay prompt must have a live input handler');
assert(runtime.includes('window.location.reload()'),
  'Chapter 1 replay must perform a clean runtime restart');


assert(runtime.includes('const regroupVit = Math.max(1, Math.ceil((world.player.maxVit || 13) * 0.5));'),
  'mandatory hazard defeat must recover enough vitality for a real retry');
assert(runtime.includes('world.player.staffCharges = world.player.maxStaffCharges || 2;'),
  'mandatory hazard defeat must restore the staff to a retryable state');
assert(runtime.includes('Ender regroups before trying again.'),
  'hazard defeat journal must describe the retry boundary');

assert.strictEqual(
  packageJson.scripts['build:chapter1:windows'],
  'powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\build-chapter1-windows.ps1',
  'Chapter 1 must expose a one-command Windows candidate build'
);
for (const marker of [
  'npm run test:chapter1-core',
  'npm run test:chapter1-browser',
  'npm run test:chapter1-title-audio-ready',
  'npm run package:windows',
  'CHAPTER1_DESKTOP_RENDER_READINESS=PASS',
  'sourceCommit = $gitHead',
  'windowsSaveCloseRelaunchContinue = "PASS"',
  'AETHERWAKE_SAVE_ROOT_OVERRIDE',
  'AETHERWAKE_CHAPTER1_PERSISTENCE_MODE',
  'Invoke-Chapter1PersistencePhase "create"',
  'Invoke-Chapter1PersistencePhase "continue"',
  'CHAPTER1_WINDOWS_SAVE_CLOSE_RELAUNCH_CONTINUE=PASS',
]) {
  assert(chapter1WindowsBuild.includes(marker),
    'Chapter 1 Windows candidate lane missing evidence marker: ' + marker);
}
assert(chapter1WindowsBuild.includes('git status --porcelain --untracked-files=no'),
  'Chapter 1 Windows candidate must reject tracked source drift');
assert(runtime.includes('function runChapter1PersistenceSmokeOnce()'),
  'desktop runtime must expose the isolated Chapter 1 persistence smoke seam');
assert.strictEqual(packageJson.scripts['admit:title-audio'], 'node scripts/admit-title-audio.js',
  'Chapter 1 must expose governed title-audio admission');
assert.strictEqual(packageJson.scripts['test:chapter1-title-audio-ready'],
  'node tests/chapter1-title-audio-ready.test.js',
  'Chapter 1 candidate must expose strict title-audio readiness');
assert.strictEqual(packageJson.scripts['admit:chapter1-soundtrack'],
  'node scripts/admit-chapter1-soundtrack.js',
  'Chapter 1 must expose governed soundtrack admission');
assert.strictEqual(packageJson.scripts['test:chapter1-soundtrack-ready'],
  'node tests/chapter1-soundtrack-ready.test.js',
  'Chapter 1 candidate must expose strict soundtrack readiness');
assert.strictEqual(packageJson.scripts['admit:chapter1-soundtrack:windows'],
  'powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\admit-chapter1-soundtrack.ps1',
  'Chapter 1 must expose one-command Windows soundtrack admission');
assert.strictEqual(packageJson.scripts['admit:chapter1-audio:windows'],
  'powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\admit-chapter1-audio.ps1',
  'Chapter 1 must expose one-command unified Windows audio admission');
assert.strictEqual(packageJson.scripts['verify:chapter1:local'],
  'powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\verify-chapter1-local.ps1',
  'Chapter 1 must expose one-command exact-head local verification');
assert(runtime.includes("saveToSlot('manual-6')") &&
       runtime.includes('continueLatestSave()'),
  'desktop persistence smoke must exercise real save and Continue paths');

for (const [workflowName, workflow] of [
  ['chapter1-convergence', chapter1Workflow],
  ['smoke', smokeWorkflow],
]) {
  assert(!workflow.includes('actions/checkout@v4'),
    workflowName + ' must not use mutable checkout tag');
  assert(!workflow.includes('actions/setup-node@v4'),
    workflowName + ' must not use mutable setup-node tag');
  assert(workflow.includes('actions/checkout@11d5960a326750d5838078e36cf38b85af677262'),
    workflowName + ' must pin checkout v4');
  assert(workflow.includes('actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020'),
    workflowName + ' must pin setup-node v4');
}
assert(!smokeWorkflow.includes('actions/upload-artifact@v4'),
  'smoke visual-evidence lane must not use mutable upload-artifact tag');
assert(smokeWorkflow.includes('actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02'),
  'smoke visual-evidence lane must pin upload-artifact v4');

console.log('Aetherwake Chapter 1 convergence contract: PASS');
