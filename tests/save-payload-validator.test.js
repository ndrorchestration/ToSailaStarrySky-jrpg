'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const validator = require('../modules/save-payload-validator.js');
const saveSystem = require('../modules/save-system.js');

assert.strictEqual(validator.VERSION, '1.0.0');

const fixturePath = path.join(__dirname, 'fixtures', 'saves', 'schema-v1-manual-1.json');
const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

assert.strictEqual(saveSystem.validateEnvelope(fixture), true,
  'golden schema-v1 fixture must remain envelope-valid');
assert.strictEqual(validator.validatePayload(fixture.payload, {
  validateAirNavigation() { return true; }
}), true, 'golden schema-v1 fixture must remain semantically valid');

const original = JSON.parse(JSON.stringify(fixture.payload));

// Position mismatch: checksum-valid semantics can still be impossible.
const badPosition = JSON.parse(JSON.stringify(original));
badPosition.world.playerPosition.px = 999;
assert.throws(
  () => validator.validatePayload(badPosition, { validateAirNavigation() { return true; } }),
  /SAVE_WORLD_PX_MISMATCH/
);

// Quest counters must agree with owned records.
const badQuest = JSON.parse(JSON.stringify(original));
badQuest.quest.hooksCompleted = 2;
assert.throws(
  () => validator.validatePayload(badQuest, { validateAirNavigation() { return true; } }),
  /SAVE_QUEST_HOOK_COUNTER_MISMATCH/
);

// Canonical roster identity/order cannot drift.
const badParty = JSON.parse(JSON.stringify(original));
badParty.party.roster[1].id = 'reson';
assert.throws(
  () => validator.validatePayload(badParty, { validateAirNavigation() { return true; } }),
  /SAVE_PARTY_IDENTITY_MISMATCH/
);

// Resource values fail closed rather than being clamped silently.
const badResource = JSON.parse(JSON.stringify(original));
badResource.party.roster[0].vit = 999;
assert.throws(
  () => validator.validatePayload(badResource, { validateAirNavigation() { return true; } }),
  /SAVE_PARTY_VIT_OVER_MAX/
);

// AIRSHIP saves must carry validated navigation state.
const missingAir = JSON.parse(JSON.stringify(original));
missingAir.runtime.scene = 'airship';
assert.throws(
  () => validator.validatePayload(missingAir, { validateAirNavigation() { return true; } }),
  /SAVE_AIRSHIP_STATE_MISSING/
);

const badAir = JSON.parse(JSON.stringify(original));
badAir.runtime.scene = 'airship';
badAir.airNavigation = { persistenceVersion: 1 };
assert.throws(
  () => validator.validatePayload(badAir, {
    validateAirNavigation() { throw new Error('AIR_NAV_STATE_INVALID'); }
  }),
  /AIR_NAV_STATE_INVALID/
);

console.log('Aetherwake semantic save-payload validator: PASS');
