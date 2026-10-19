'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules/first-wake-visual-stage.js'), 'utf8');
const opening = require('../modules/first-wake-opening.js');
let ink = null;
const panels = [], copy = [];
const sandbox = { window: { AetherFirstWakeOpening: opening }, globalThis: {}, width: 960, height: 640,
  fill(...values) { ink = values; },
  rect(x,y,w,h) { panels.push({x,y,w,h,ink}); },
  text(value) { copy.push(value); },
  textWidth(value) { return String(value).length * 9; },
  CENTER:'center', LEFT:'left', TOP:'top', BOTTOM:'bottom', CLOSE:'close',
};
for (const name of ['push','pop','noStroke','noFill','stroke','strokeWeight','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','line']) sandbox[name] = () => {};
vm.runInNewContext(source,sandbox);
const visual=sandbox.window.AetherFirstWakeVisual;
const state=opening.createState(), scene=opening.currentScene(state);
assert.strictEqual(visual.drawSceneTransition(scene,state),true,
  'fresh opening state must start its scene transition using the live presentation clock');
opening.tickPresentation(state,40);
panels.length=0; copy.length=0; visual.draw(scene,state,{now:1000});
const horizon=panels.find(p=>p.x===0&&p.y===0&&p.w===960&&p.h===640&&p.ink[0]===3&&p.ink[1]===7&&p.ink[2]===14);
assert(horizon && horizon.ink[3]===0,'arrival veil must clear after 34 live presentation ticks');
assert(!copy.some(value => String(value).includes('Dawn gathers')),'arrival narration must wait for its authored reveal');
opening.tickPresentation(state,60);
copy.length=0; visual.draw(scene,state,{now:2000});
assert(copy.includes(scene.title),'arrival location title must appear at live tick 100');
opening.tickPresentation(state,50);
copy.length=0; visual.draw(scene,state,{now:2500});
assert(copy.includes('Dawn gathers beneath'),'first arrival narration must appear at live tick 150');
opening.tickPresentation(state,50);
copy.length=0; visual.draw(scene,state,{now:3000});
assert(copy.includes('A small patched vessel hangs'),'second arrival narration must appear at live tick 200');
assert(!Object.prototype.hasOwnProperty.call(state,'sceneTicks'),'renderer must not mutate the controller state with another clock');
console.log('Aetherwake live opening presentation clock: PASS');
