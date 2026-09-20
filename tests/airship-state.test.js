const assert = require('assert');
const Airship = require('../modules/airship-state.js');

function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}`);
    throw error;
  }
}

test('creates the compact Dragonfly-class ship with its bounded systems', () => {
  const state = Airship.createState();

  assert.strictEqual(state.hullVolumeContainers, 3);
  assert.strictEqual(state.power, 6);
  assert.deepStrictEqual(state.shieldMode, 'guard');
  assert.deepStrictEqual(
    Airship.getSystemDefinitions().map(system => system.id),
    ['phaseSlip', 'harmonicVeil', 'resonanceLance', 'rootlineTether', 'patternForge']
  );
});

test('phase-slip uses the shared power budget and a drive charge', () => {
  const state = Airship.createState();
  const result = Airship.resolveAction(state, 'phaseSlip');

  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.state.power, 3);
  assert.strictEqual(result.state.driveCharges, 2);
  assert.strictEqual(result.state.phaseIntegrity, 92);
  assert.strictEqual(result.state.pendingCombat.phaseSlip, true);
  assert.strictEqual(result.state.lastAction, 'phaseSlip');
  assert.strictEqual(state.power, 6);
});

test('slip veil mode reduces propulsion cost without changing ship limits', () => {
  const state = Airship.createState();
  const shield = Airship.cycleShieldMode(state);
  const result = Airship.resolveAction(shield.state, 'phaseSlip');

  assert.strictEqual(shield.state.shieldMode, 'slip');
  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.state.power, 4);
  assert.strictEqual(result.state.hullVolumeContainers, 3);
});

test('resonance lance consumes charge, heats the wakeheart, and marks a target', () => {
  const state = Airship.createState();
  const result = Airship.resolveAction(state, 'resonanceLance');

  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.state.power, 4);
  assert.strictEqual(result.state.lanceCharges, 1);
  assert.strictEqual(result.state.heat, 2);
  assert.strictEqual(result.state.targetIntegrity, 76);
  assert.strictEqual(result.state.pendingCombat.resonanceLanceDamage, 24);
});

test('insufficient power fails atomically without consuming a charge', () => {
  const state = Airship.createState({ power: 1 });
  const result = Airship.resolveAction(state, 'resonanceLance');

  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.state.power, 1);
  assert.strictEqual(result.state.lanceCharges, 2);
  assert.strictEqual(result.state.lastAction, null);
  assert.match(result.message, /power/i);
});

test('rootline tether restores phase integrity and pattern forge repairs the hull', () => {
  const damaged = Airship.createState({ phaseIntegrity: 60, hull: 55 });
  const tether = Airship.resolveAction(damaged, 'rootlineTether');
  const forge = Airship.resolveAction(tether.state, 'patternForge');

  assert.strictEqual(tether.ok, true);
  assert.strictEqual(tether.state.phaseIntegrity, 82);
  assert.strictEqual(tether.state.tetherCharges, 1);
  assert.strictEqual(forge.ok, true);
  assert.strictEqual(forge.state.hull, 71);
  assert.strictEqual(forge.state.forgeCharges, 1);
});

test('venting advances cooldowns, reduces heat, and returns one power cell', () => {
  const state = Airship.createState({
    power: 3,
    heat: 4,
    cooldowns: { phaseSlip: 2, resonanceLance: 1, rootlineTether: 0, patternForge: 3 },
  });
  const result = Airship.resolveAction(state, 'ventWake');

  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.state.power, 4);
  assert.strictEqual(result.state.heat, 2);
  assert.deepStrictEqual(result.state.cooldowns, {
    phaseSlip: 1,
    resonanceLance: 0,
    rootlineTether: 0,
    patternForge: 2,
  });
});

console.log('Airship state tests: PASS');
