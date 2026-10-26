const assert=require('assert');
const economy=require('../modules/economy.js');

assert.strictEqual(economy.VERSION,'0.1.0');
assert.strictEqual(economy.validate(),true);

const wallet={gold:20,scrap:7};
assert.strictEqual(economy.spendGold(wallet,6),true);
assert.strictEqual(wallet.gold,14);
assert.strictEqual(wallet.scrap,7,'ordinary spending must not consume scrap');
assert.strictEqual(economy.spendGold(wallet,99),false);
assert.strictEqual(wallet.gold,14,'failed purchase must not make gold negative');

const seq=[0.5,0.01,0.9];
let i=0;
const reward=economy.resolveEncounterRewards('routine',()=>seq[i++ % seq.length]);
assert(reward.gold>=6&&reward.gold<=14,'routine encounter must award bounded gold');
assert.strictEqual(reward.items.length,1);
assert(economy.ITEMS[reward.items[0].itemId],'loot result must reference a legal item');
assert(reward.items[0].quantity>=1);

const chest=economy.resolveLoot('LOOT-A1-ROUTINE',()=>0.99);
assert(chest.gold>0,'regular loot table must be able to award gold');
assert(['consumable','material','trade_good','weapon','armor'].includes(
  economy.ITEMS[chest.items[0].itemId].kind
),'regular loot table must resolve to an ordinary loot class');

assert.strictEqual(economy.canSell('TRD-A1-001'),true);
assert.strictEqual(economy.canSell('REL-UNIQUE-PROOF'),false,
  'unique/provenance items must not be sellable by default');

console.log('Aetherwake economy and regular loot contract: PASS');
