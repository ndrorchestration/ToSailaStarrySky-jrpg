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

assert(source.includes('window.UI.shopBuyHandler'),
  'live shop purchase handler is missing');
assert(source.includes('world.player.scrap'),
  'shop renderer has no persistent World scrap source');

console.log('Aetherwake runtime contract tests: PASS');
