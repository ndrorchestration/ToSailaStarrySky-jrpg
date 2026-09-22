const assert = require('assert');
const field = require('../modules/magic-field-reactions.js');

assert.strictEqual(field.runtimeStatus, 'DESIGN_STATE_ONLY');

let state = field.createState(['wet']);
assert.deepStrictEqual(state.tags, ['wet']);

let preview = field.preview(state, 'lightning');
assert.strictEqual(preview.length, 1);
assert.strictEqual(preview[0].reaction, 'conduct');
assert.deepStrictEqual(preview[0].add, ['charged']);

let result = field.resolveDesignState(state, 'lightning');
assert.deepStrictEqual(result.reactions, ['conduct']);
assert.deepStrictEqual(result.after.tags.sort(), ['charged','wet'].sort());

result = field.resolveDesignState(field.createState(['wet']), 'frost');
assert.deepStrictEqual(result.reactions, ['freeze']);
assert.deepStrictEqual(result.after.tags, ['frozen']);

result = field.resolveDesignState(field.createState(['wet']), 'fire');
assert.deepStrictEqual(result.reactions, ['flash-steam']);
assert.deepStrictEqual(result.after.tags, ['mist']);

result = field.resolveDesignState(field.createState(['frozen']), 'fire');
assert.deepStrictEqual(result.reactions, ['thermal-shock']);
assert.deepStrictEqual(result.after.tags, ['brittle']);

result = field.resolveDesignState(field.createState(['burning']), 'water');
assert.deepStrictEqual(result.reactions, ['quench']);
assert.deepStrictEqual(result.after.tags, ['wet']);

result = field.resolveDesignState(field.createState(['burning']), 'air');
assert.deepStrictEqual(result.reactions, ['fan-flame']);
assert.deepStrictEqual(result.after.tags, ['burning']);

result = field.resolveDesignState(field.createState(['metallic']), 'lightning');
assert.deepStrictEqual(result.reactions, ['surge']);
assert.deepStrictEqual(result.after.tags.sort(), ['metallic','charged'].sort());

result = field.resolveDesignState(field.createState(['crystal']), 'sonic');
assert.deepStrictEqual(result.reactions, ['harmonic-shatter']);
assert.deepStrictEqual(result.after.tags.sort(), ['crystal','brittle'].sort());

result = field.resolveDesignState(field.createState(['wet-earth']), 'earth');
assert.deepStrictEqual(result.reactions, ['mire']);
assert.deepStrictEqual(result.after.tags, ['mire']);

state = field.withState(field.createState([]), 'wet');
assert.deepStrictEqual(state.tags, ['wet']);
state = field.withoutState(state, 'wet');
assert.deepStrictEqual(state.tags, []);

assert.throws(() => field.createState(['holy']), /MAGIC_FIELD_UNKNOWN_STATE/);
assert.throws(() => field.preview(field.createState(['wet']), 'lumen'), /MAGIC_FIELD_UNKNOWN_APPLIED_TREE/);

for (const rule of Object.values(field.REACTION_RULES)) {
  assert.ok(rule.intent.length > 0, `${rule.id} must declare tactical intent`);
}

console.log('magic-field-reactions contract: PASS');
