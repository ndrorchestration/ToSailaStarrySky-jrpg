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

// Current First Wake Crossing has four hazards and 4/4 is a valid persisted state.
const fourHazards = JSON.parse(JSON.stringify(original));
fourHazards.quest.state = 'contact';
fourHazards.quest.act = 'contact';
fourHazards.quest.hazardsCompleted = 4;
fourHazards.quest.crossingHazards.forEach(hazard => { hazard.done = true; });
assert.strictEqual(
  validator.validatePayload(fourHazards, { validateAirNavigation() { return true; } }),
  true,
  '4/4 Crossing completion must remain a valid save payload'
);

const previewThreeHazards = JSON.parse(JSON.stringify(original));
previewThreeHazards.quest.crossingHazards = [
  previewThreeHazards.quest.crossingHazards[0],
  previewThreeHazards.quest.crossingHazards[1],
  previewThreeHazards.quest.crossingHazards[3],
];
previewThreeHazards.quest.hazardsCompleted =
  previewThreeHazards.quest.crossingHazards.filter(hazard => hazard.done).length;
assert.strictEqual(
  validator.validatePayload(previewThreeHazards, { validateAirNavigation() { return true; } }),
  true,
  'current Preview three-hazard layout must remain save-compatible'
);

const unknownThreeHazards = JSON.parse(JSON.stringify(previewThreeHazards));
unknownThreeHazards.quest.crossingHazards[2].id = 'unknown_hazard';
assert.throws(
  () => validator.validatePayload(unknownThreeHazards, { validateAirNavigation() { return true; } }),
  /SAVE_QUEST_CROSSING_HAZARD_LAYOUT_DRIFT/
);

// Persisted quest state must match the runtime's stable-save policy.
const wakeState = JSON.parse(JSON.stringify(original));
wakeState.quest.state = 'wake';
wakeState.quest.act = 'wake';
assert.throws(
  () => validator.validatePayload(wakeState, { validateAirNavigation() { return true; } }),
  /SAVE_QUEST_STATE_NOT_PERSISTABLE/
);

const unknownContact = JSON.parse(JSON.stringify(original));
unknownContact.quest.npcsMet = ['engine_spirit', 'not_a_real_contact'];
assert.throws(
  () => validator.validatePayload(unknownContact, { validateAirNavigation() { return true; } }),
  /SAVE_QUEST_NPC_UNKNOWN/
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

// Active-party membership must be fully admissible before commit.
const inactivePlayable = JSON.parse(JSON.stringify(original));
inactivePlayable.party.roster.find(record => record.id === 'lyra').playable = false;
assert.throws(
  () => validator.validatePayload(inactivePlayable, { validateAirNavigation() { return true; } }),
  /SAVE_PARTY_ACTIVE_NOT_PLAYABLE:lyra/
);

const missingPlayableFlag = JSON.parse(JSON.stringify(original));
delete missingPlayableFlag.party.roster[0].playable;
assert.throws(
  () => validator.validatePayload(missingPlayableFlag, { validateAirNavigation() { return true; } }),
  /SAVE_PARTY_PLAYABLE_FLAG_INVALID:ender/
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
