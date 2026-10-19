'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'..');
const policy=require(path.join(root,'modules','combat-system-policy.js'));
const runtime=fs.readFileSync(path.join(root,'aetherwake.js'),'utf8');
const stage=fs.readFileSync(path.join(root,'modules','combat-visual-stage.js'),'utf8');
assert.strictEqual(policy.TARGET.turnStructure,'turn-based','Aetherwake combat direction must remain turn-based');
assert.strictEqual(policy.TARGET.primaryResolution,'stats+ability-formulas','combat must preserve JRPG stats and ability formulas');
assert.strictEqual(policy.TARGET.visibleDice,false,'obsolete visible PbtA dice are not the production target');
assert(runtime.includes('else if (gameState === STATE.WORLD)') &&
       runtime.includes('else if (gameState === STATE.COMBAT)'),
       'world exploration and combat must use separate runtime states');
assert(runtime.includes('combat.drawCombatScene(') &&
       runtime.includes("domain: skyCombat ? 'sky' : 'ground'"),
       'active combat state must render a dedicated scene with ground/sky domain');
assert(runtime.includes("combatReturnState === STATE.AIRSHIP"),
       'combat return context must support airship encounters');
assert(stage.includes('function drawBackdrop(ctx)') &&
       stage.includes('function stage(width, height)'),
       'battle visuals must have a distinct stage and backdrop');
assert(runtime.includes("drawCombatPanel(combat.getState()"),
       'active combat must expose a command/status panel');
assert(!/turnStructure:\s*['"](?:hybrid|realtime|real-time)['"]/.test(fs.readFileSync(path.join(root,'modules','combat-system-policy.js'),'utf8')),
       'withdrawn hybrid combat must not be the production target');
console.log('Aetherwake turn-based dedicated battle arena target/source contract: PASS');
