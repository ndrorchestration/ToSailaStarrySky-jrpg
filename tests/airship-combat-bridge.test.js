const assert = require('assert');
const Bridge = require('../modules/airship-combat-bridge.js');

function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}`);
    throw error;
  }
}

test('transfers pending Dragonfly systems and clears one-shot arms', () => {
  const source = {
    shipId: 'aureate-wake',
    classId: 'dragonfly-wake',
    shieldMode: 'slip',
    pendingCombat: {
      phaseSlip: true,
      resonanceLanceDamage: 24,
    },
  };

  const prepared = Bridge.consumeTransfer(source);

  assert.deepStrictEqual(prepared.transfer, {
    shipId: 'aureate-wake',
    classId: 'dragonfly-wake',
    shieldMode: 'slip',
    phaseSlipReady: true,
    resonanceLanceDamage: 24,
  });
  assert.strictEqual(prepared.state.pendingCombat.phaseSlip, false);
  assert.strictEqual(prepared.state.pendingCombat.resonanceLanceDamage, 0);
  assert.strictEqual(source.pendingCombat.phaseSlip, true);
});

test('Guard veil absorbs one point from the first incoming strike', () => {
  const modifiers = Bridge.createCombatModifiers({
    shieldMode: 'guard',
  });

  const first = Bridge.mitigateIncomingDamage(modifiers, 2);
  const second = Bridge.mitigateIncomingDamage(first.modifiers, 2);

  assert.strictEqual(first.damage, 1);
  assert.strictEqual(first.event, 'guard');
  assert.strictEqual(second.damage, 2);
});

test('Phase-Slip makes the first damaging strike miss', () => {
  const modifiers = Bridge.createCombatModifiers({
    shieldMode: 'slip',
    phaseSlipReady: true,
  });

  const first = Bridge.mitigateIncomingDamage(modifiers, 2);
  const second = Bridge.mitigateIncomingDamage(first.modifiers, 2);

  assert.strictEqual(first.damage, 0);
  assert.strictEqual(first.event, 'phaseSlip');
  assert.strictEqual(second.damage, 0);
  assert.strictEqual(second.event, 'slip');
});

test('Resonance veil converts lance integrity into an opening combat strike', () => {
  const modifiers = Bridge.createCombatModifiers({
    shieldMode: 'resonance',
    resonanceLanceDamage: 30,
  });

  assert.strictEqual(modifiers.openingLanceDamage, 4);
  assert.strictEqual(modifiers.firstRollBonus, 1);
});

console.log('Airship combat bridge tests: PASS');
