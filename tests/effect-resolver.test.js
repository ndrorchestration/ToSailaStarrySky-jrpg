const assert = require('assert');
const vocabulary = require('../modules/effect-vocabulary.js');
const resolver = require('../modules/effect-resolver.js');

function context() {
  return {
    player: {
      vit: 10,
      maxVit: 13,
      scrap: 7,
      aether: { current: 4, max: 6 },
      heat: { current: 1, max: 3 },
      echoes: { current: 3, max: 3 },
      staffCharges: 2,
      maxStaffCharges: 2,
    },
    enemy: {
      hp: 12,
      maxHp: 12,
    },
    reveals: {
      self: {},
      enemy: {},
      field: {},
    },
    staffChargeMax: 2,
  };
}

assert.strictEqual(resolver.VERSION, '0.2.0');

{
  const ctx = context();
  const result = resolver.applyEffect(
    resolver.createDamageEffect(vocabulary.TARGET.SELF, 4),
    ctx
  );
  assert.strictEqual(ctx.player.vit, 6);
  assert.strictEqual(result.delta, -4);
}

{
  const ctx = context();
  resolver.applyEffect(
    resolver.createDamageEffect(vocabulary.TARGET.SELF, 99),
    ctx
  );
  assert.strictEqual(ctx.player.vit, 0, 'player damage must clamp at zero');
}

{
  const ctx = context();
  resolver.applyEffect(
    resolver.createDamageEffect(vocabulary.TARGET.ENEMY, 15, 'emp'),
    ctx
  );
  assert.strictEqual(ctx.enemy.hp, -3,
    'enemy damage must preserve current unclamped HP behavior');
}

{
  const ctx = context();
  resolver.applyEffect(
    resolver.createRestoreEffect(vocabulary.TARGET.SELF, 99),
    ctx
  );
  assert.strictEqual(ctx.player.vit, 13, 'restoration must clamp at max vitality');
}

{
  const ctx = context();
  resolver.applyEffects([
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.HEAT, 10),
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.AETHER, 10),
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.ECHOES, -10),
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.SCRAP, -10),
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.STAFF_CHARGES, -1),
    resolver.createResourceDeltaEffect(vocabulary.RESOURCE.STAFF_CHARGES, 10),
  ], ctx);

  assert.strictEqual(ctx.player.heat.current, 3);
  assert.strictEqual(ctx.player.aether.current, 6);
  assert.strictEqual(ctx.player.echoes.current, 0);
  assert.strictEqual(ctx.player.scrap, 0);
  assert.strictEqual(ctx.player.staffCharges, 2);
}

{
  const ctx = context();
  const declared = {
    kind: vocabulary.EFFECT_KIND.REVEAL,
    target: vocabulary.TARGET.ENEMY,
    operation: vocabulary.OPERATION.REVEAL,
    key: 'weakness',
    runtimeStatus: vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED,
    note: null,
  };

  const result = resolver.applyEffect(declared, ctx);
  assert.strictEqual(result.applied, false);
  assert.strictEqual(result.reason, 'declared_not_applied');
  assert.strictEqual(ctx.enemy.hp, 12);
  assert.strictEqual(ctx.reveals.enemy.weakness, undefined);
}

{
  const ctx = context();
  const reveal = resolver.createRevealEffect(
    vocabulary.TARGET.ENEMY,
    'weakness'
  );
  const first = resolver.applyEffect(reveal, ctx);
  assert.strictEqual(first.applied, true);
  assert.strictEqual(first.before, false);
  assert.strictEqual(first.after, true);
  assert.strictEqual(ctx.reveals.enemy.weakness, true);

  const second = resolver.applyEffect(reveal, ctx);
  assert.strictEqual(second.applied, false);
  assert.strictEqual(second.reason, 'already_applied');
  assert.strictEqual(ctx.reveals.enemy.weakness, true);
}

{
  const ctx = context();
  const unsupported = {
    kind: vocabulary.EFFECT_KIND.MODIFIER,
    target: vocabulary.TARGET.SELF,
    operation: vocabulary.OPERATION.INCREASE,
    key: 'nextAction',
    runtimeStatus: vocabulary.RUNTIME_STATUS.IMPLEMENTED,
    note: null,
  };

  assert.throws(
    () => resolver.applyEffect(unsupported, ctx),
    /EFFECT_KIND_NOT_EXECUTABLE_YET:modifier/
  );
}

assert.throws(
  () => resolver.createDamageEffect(vocabulary.TARGET.SELF, -1),
  /DAMAGE_AMOUNT_INVALID/
);

console.log('Aetherwake effect resolver contract: PASS');
console.log(JSON.stringify({
  version: resolver.VERSION,
  executableKinds: ['damage', 'restore', 'resource', 'reveal'],
  declaredNoOpKinds: ['modifier'],
  failClosedKinds: ['status', 'movement'],
}, null, 2));
