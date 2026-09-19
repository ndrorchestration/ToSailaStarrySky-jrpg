const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vocabulary = require('../modules/effect-vocabulary.js');
const resolver = require('../modules/effect-resolver.js');

assert.strictEqual(vocabulary.VERSION, '0.2.0');
assert.strictEqual(resolver.VERSION, '0.2.0');

const uncover = vocabulary.ACTION_EFFECT_PROFILES.uncoverTruth.success;
const modifier = uncover.find(effect =>
  effect.kind === vocabulary.EFFECT_KIND.MODIFIER &&
  effect.key === 'nextRoll'
);
const reveal = uncover.find(effect =>
  effect.kind === vocabulary.EFFECT_KIND.REVEAL &&
  effect.key === 'weakness'
);

assert(modifier, 'Uncover Truth nextRoll modifier profile missing');
assert.strictEqual(
  modifier.runtimeStatus,
  vocabulary.RUNTIME_STATUS.IMPLEMENTED,
  'Uncover Truth nextRoll modifier is not marked executable'
);
assert(reveal, 'Uncover Truth reveal profile missing');
assert.strictEqual(
  reveal.runtimeStatus,
  vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED,
  'Uncover Truth reveal must remain explicit semantic debt'
);

const sharedDreamModifier = vocabulary.ACTION_EFFECT_PROFILES.sharedDream.success.find(
  effect => effect.kind === vocabulary.EFFECT_KIND.MODIFIER
);
assert(sharedDreamModifier, 'Shared Dream modifier profile missing');
assert.strictEqual(
  sharedDreamModifier.runtimeStatus,
  vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED,
  'Shared Dream ally modifier must remain deferred until ally combat exists'
);

const context = { player: { nextRollBonus: 0 } };
resolver.applyEffect(
  resolver.createModifierDeltaEffect(
    vocabulary.TARGET.SELF,
    'nextRoll',
    1
  ),
  context
);
assert.strictEqual(context.player.nextRollBonus, 1);

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);
assert(source.includes('state._lastRoll = null;'),
  'combat init does not clear the previous roll trace');

console.log('Aetherwake modifier-effect contract: PASS');
