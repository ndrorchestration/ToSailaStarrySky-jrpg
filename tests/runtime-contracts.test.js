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

assert(/window\\.UI\\.shopBuyHandler\\s*=/.test(source),
  'live shop purchase handler assignment is missing');
assert(source.includes('world.player.scrap'),
  'shop renderer has no persistent World scrap source');

assert(/return \{\s*ok: true,\s*kind: 'dialogue'/.test(source),
  'dialogue interaction does not return a structured success result');
assert(source.includes('world.closeDialogue()'),
  'overlay cleanup does not close World dialogue state');
assert(source.includes('world.closeShop()'),
  'overlay cleanup does not close World shop state');

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


const requiredScripts = [
  'modules/effect-vocabulary.js',
  'modules/effect-resolver.js',
  'modules/ability-defs.js',
  'modules/progression-defs.js',
  'modules/party-state.js',
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

console.log('Aetherwake entrypoint contracts: PASS');
