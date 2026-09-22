const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const source = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');

function extractFunction(name) {
  const marker = `function ${name}(`;
  const start = source.indexOf(marker);
  assert(start >= 0, `missing ${name} implementation`);
  const bodyStart = source.indexOf('{', start);
  let depth = 0;
  let inString = null;
  let escaped = false;
  for (let i = bodyStart; i < source.length; i++) {
    const ch = source[i];
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === inString) inString = null;
      continue;
    }
    if (ch === "'" || ch === '"' || ch === '`') {
      inString = ch;
      continue;
    }
    if (ch === '{') depth++;
    if (ch === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unterminated ${name} implementation`);
}

assert(source.includes('let overlayReturnState = null;'),
  'overlay return state must not rely on the frame-transition variable');
assert(source.includes('else if (gameState === STATE.DIALOGUE)'),
  'dialogue input must have a reachable state branch');
assert(source.includes('window.UI.shopBuyHandler = function'),
  'shop number-key input must be wired to a purchase handler');
assert(source.includes('getLedger'),
  'ledger data must be exposed to the active overlay');
assert(!/function\s+closeDialogue\s*\(/.test(source),
  'world dialogue cleanup must not be shadowed by the legacy UI helper');
assert((source.match(/function\s+drawCovenantField\s*\(/g) || []).length === 1,
  'world Covenant Field renderer must not be shadowed by the legacy HUD helper');
assert(!source.includes('player.aether.current ='),
  'world shop must not treat numeric aether as a combat resource object');

const sandbox = {
  shop: {
    items: [
      { kind: 'scrap', effect: 'aether', cost: 3, name: 'Aether' },
      { kind: 'scrap', effect: 'staffCharges', cost: 2, name: 'Staff' },
    ],
  },
  player: {
    scrap: 7,
    aether: 4,
    aetherMax: 6,
    staffCharges: 1,
    maxStaffCharges: 2,
  },
  quest: { hullIntegrity: 100 },
  addLedgerEntry() {},
};
sandbox.globalThis = sandbox;
vm.runInNewContext(extractFunction('purchaseItem'), sandbox);

assert.strictEqual(sandbox.purchaseItem(0), true,
  'aether recharge should be purchasable with scrap');
assert.strictEqual(sandbox.player.scrap, 4,
  'aether recharge should spend scrap');
assert.strictEqual(sandbox.player.aether, 5,
  'aether recharge should increase numeric world aether');

assert.strictEqual(sandbox.purchaseItem(1), true,
  'staff polish should be purchasable with scrap');
assert.strictEqual(sandbox.player.scrap, 2,
  'staff polish should spend scrap');
assert.strictEqual(sandbox.player.staffCharges, 2,
  'staff polish should restore a staff charge');

console.log('Aetherwake runtime overlay/economy contract: PASS');
