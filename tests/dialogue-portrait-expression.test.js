/* eslint-env node */
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'..');
const src=fs.readFileSync(path.join(root,'aetherwake.js'),'utf8');
assert(src.includes('function resolveDialoguePortraitExpression'), 'portrait-expression resolver missing');
assert(src.includes("dialoguePortraitExpression = resolveDialoguePortraitExpression(npc, batch, 0)"), 'opening expression routing missing');
assert(src.includes('activeDialogue.batch || window.UI.dialogueAudioBatch'), 'line-advance expression routing missing');
assert(src.includes("intro: ['concern','focus','concern','concern','focus']"), 'Ionia intro expression schedule missing');
assert(src.includes("generic_follow: ['smile']"), 'Ionia follow-up smile schedule missing');
assert(src.includes("window.UI.dialoguePortraitExpression || 'talk'"), 'dialogue renderer must consume routed expression');
console.log('Aetherwake dialogue portrait expression routing: PASS');
