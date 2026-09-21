const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const worldStart = source.indexOf('World = {');
assert(worldStart >= 0, 'World export is missing');
const worldExport = source.slice(worldStart, worldStart + 1200);

assert(worldExport.includes('getLedger'), 'World does not export getLedger');
assert(worldExport.includes('getShopItems'), 'World does not export getShopItems');
assert(worldExport.includes('purchaseItem'), 'World does not export purchaseItem');
assert(worldExport.includes('closeShop'), 'World does not export closeShop');
assert(worldExport.includes('senseAether'), 'World does not export senseAether');
assert(worldExport.includes('getAetherSenseState'), 'World does not export getAetherSenseState');

assert(/window\.UI\.shopBuyHandler\s*=/.test(source),
  'live shop purchase handler assignment is missing');
assert(source.includes('world.player.scrap'),
  'shop renderer has no persistent World scrap source');

assert(/return \{\s*ok: true,\s*kind: 'dialogue'/.test(source),
  'dialogue interaction does not return a structured success result');
assert(source.includes('world.closeDialogue()'),
  'overlay cleanup does not close World dialogue state');
assert(source.includes('world.closeShop()'),
  'overlay cleanup does not close World shop state');

assert(source.includes('if (keyCode === 113)'),
  'F2 quick-save key binding is missing');
assert(source.includes('if (keyCode === 114)'),
  'F3 quick-load key binding is missing');
assert(source.includes("gameState !== STATE.WORLD"),
  'quick save is not restricted to safe WORLD state');
assert(source.includes("gameState === STATE.MENU") &&
  source.includes("gameState === STATE.CHARCREATE") &&
  source.includes("gameState === STATE.WORLD"),
  'quick load safe-state allowlist is incomplete');
assert(source.includes('syncCombatFromWorldPlayer()'),
  'quick load does not resynchronize combat from restored canonical state');
assert(source.includes('window.quickSaveGame = quickSaveGame') &&
  source.includes('window.quickLoadGame = quickLoadGame'),
  'player persistence actions are not exposed for integration verification');

assert(source.includes('function hasStoredSave()'),
  'stored-save discovery helper is missing');
assert(source.includes('window._saveState.legacyStorageKeys'),
  'stored-save discovery does not include legacy migration keys');
assert(!source.includes('millis() - menuAutoStartTimer > 3000'),
  'JRPG title menu must not auto-start a game');
assert(source.includes("label: 'NEW GAME'") &&
  source.includes("label: 'CONTINUE'"),
  'title screen does not expose explicit New Game / Continue commands');
assert(source.includes('handleTitleMenuInput({ ok, up, down })'),
  'MENU state does not route through the JRPG title command surface');

console.log('Aetherwake save discovery/title contracts: PASS');

console.log('Aetherwake player save/load input contracts: PASS');

console.log('Aetherwake runtime contract tests: PASS');


const combatStart = source.indexOf('function AetherCombat(p, C) {');
assert(combatStart >= 0, 'AetherCombat constructor is missing');
const combatSource = source.slice(combatStart);

assert(combatSource.includes('options.maxVit'),
  'combat init does not accept maxVit');
assert(combatSource.includes('options.wits'),
  'combat init does not accept primary stat fields');
assert(combatSource.includes('state.player.maxStaffCharges'),
  'combat player snapshot does not synchronize maxStaffCharges');
assert(combatSource.includes('while (p.xp >= p.xpToNext)'),
  'multi-level XP award path is missing');

console.log('Aetherwake combat snapshot contracts: PASS');


const handoffStart = source.indexOf('const activeParty = window.AetherPartyState.commitPrototypeParty');
const handoffEnd = source.indexOf('gameState = STATE.WORLD', handoffStart);
assert(handoffStart >= 0 && handoffEnd > handoffStart,
  'character-creation combat handoff block is missing');
const handoff = source.slice(handoffStart, handoffEnd);
assert(handoff.includes('combat.init(buildCombatPlayerSnapshot())'),
  'character-creation handoff does not use the canonical combat snapshot builder');
assert(source.includes('partyContext: buildPartyCombatContext()'),
  'canonical combat snapshot omits validated party context');
assert(source.includes('const playerSnapshot = buildCombatPlayerSnapshot();') &&
  source.includes('playerSnapshot.airshipTransfer = airshipTransfer'),
  'encounter launch does not reuse canonical combat snapshot builder');

console.log('Aetherwake character handoff contracts: PASS');


const requiredScripts = [
  'modules/combat-system-policy.js',
  'modules/combat-formula.js',
  'modules/effect-vocabulary.js',
  'modules/effect-resolver.js',
  'modules/ability-defs.js',
  'modules/progression-defs.js',
  'modules/mastery-defs.js',
  'modules/magic-access.js',
  'modules/aether-sense.js',
  'modules/field-role-defs.js',
  'modules/party-state.js',
  'modules/party-combat-bridge.js',
  'modules/save-state.js',
  'modules/airship-state.js',
  'modules/airship-combat-bridge.js',
  'modules/airship-ui.js',
  'modules/audio.js',
  'aetherwake.js',
  'modules/char-create.js',
  'p5.min.js',
];

for (const entrypoint of ['index-embedded.html', 'index.html']) {
  const html = fs.readFileSync(
    path.resolve(__dirname, '..', entrypoint),
    'utf8'
  );
  assert(html.includes('id="aetherwake-init-error"'),
    entrypoint + ' has no initialization failure surface');
  let previous = -1;
  for (const script of requiredScripts) {
    const index = html.indexOf('src="' + script + '"');
    assert(index >= 0, entrypoint + ' is missing ' + script);
    assert(index > previous,
      entrypoint + ' loads ' + script + ' out of dependency order');
    previous = index;
  }
}

assert(source.includes('AETHER_COMBAT_SYSTEM_POLICY_UNAVAILABLE'),
  'runtime boot does not fail closed when combat-system policy is missing');
assert(source.includes('window.AetherCombatSystemPolicy.validate()'),
  'runtime boot does not validate combat-system policy');
assert(source.includes('AETHER_COMBAT_FORMULA_UNAVAILABLE'),
  'runtime boot does not fail closed when combat formula resolver is missing');
assert(source.includes('window.AetherCombatFormula.validateAgainstAbilityDefs(window.AetherAbilityDefs)'),
  'runtime boot does not validate combat formula against ability definitions');
assert(source.includes('window._combatFormula = window.AetherCombatFormula'),
  'validated combat formula is not exposed to runtime');

assert(source.includes('AETHER_MASTERY_DEFS_UNAVAILABLE'),
  'runtime boot does not fail closed when mastery definitions are missing');
assert(source.includes('window.AetherMasteryDefs.validate()'),
  'runtime boot does not validate mastery definitions');
assert(source.includes('window._masteryDefs = window.AetherMasteryDefs'),
  'validated mastery definitions are not exposed to the runtime');

assert(source.includes('AETHER_MAGIC_ACCESS_UNAVAILABLE'),
  'runtime boot does not fail closed when magic access is missing');
assert(source.includes('window.AetherMagicAccess.validate()'),
  'runtime boot does not validate magic access');
assert(source.includes('window._magicAccess = window.AetherMagicAccess'),
  'validated magic access is not exposed to runtime');

assert(source.includes('AETHER_SENSE_UNAVAILABLE'),
  'runtime boot does not fail closed when Aether Sense runtime is missing');
assert(source.includes('window.AetherSense.validate()'),
  'runtime boot does not validate Aether Sense runtime');
assert(source.includes('window._aetherSense = window.AetherSense'),
  'validated Aether Sense runtime is not exposed to runtime');
assert(source.includes('keysPressed[86]'),
  'WORLD input does not bind V to Aether Sense');
assert(source.includes("addLedgerEntry('aether-sense'"),
  'Aether Sense does not record an exploration ledger entry');

assert(source.includes('AETHER_FIELD_ROLE_DEFS_UNAVAILABLE'),
  'runtime boot does not fail closed when field-role definitions are missing');
assert(source.includes('window.AetherFieldRoleDefs.validate()'),
  'runtime boot does not validate field-role definitions');
assert(source.includes('window._fieldRoleDefs = window.AetherFieldRoleDefs'),
  'validated field-role definitions are not exposed to the runtime');

assert(source.includes('AETHER_PARTY_COMBAT_BRIDGE_UNAVAILABLE'),
  'runtime boot does not fail closed when party combat bridge is missing');
assert(source.includes('window._partyCombatBridge = window.AetherPartyCombatBridge'),
  'validated party combat bridge is not exposed to runtime');
assert(source.includes('function buildPartyCombatContext()'),
  'canonical party combat context builder is missing');
assert(combatSource.includes('state.partyContext = JSON.parse(JSON.stringify(options.partyContext))'),
  'combat init does not detach validated party context');
assert(combatSource.includes('partyContext: state.partyContext'),
  'combat public state does not expose party context');

console.log('Aetherwake party combat context contracts: PASS');

console.log('Aetherwake field-role boot contracts: PASS');

console.log('Aetherwake Aether Sense boot/input contracts: PASS');

console.log('Aetherwake mastery boot contracts: PASS');

console.log('Aetherwake entrypoint contracts: PASS');


assert(source.includes('const nightFactor = isNight()'),
  'world renderer does not apply time-of-day shading');
assert(source.includes('stroke(color(80, 120, 60, 80))'),
  'world renderer does not draw the vegetation layer');

console.log('Aetherwake visual contracts: PASS');
