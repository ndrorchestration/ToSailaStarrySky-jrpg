/* eslint-env node */
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const src=fs.readFileSync(path.resolve(__dirname,'..','aetherwake.js'),'utf8');
const start=src.indexOf('function drawPlayer()');
const end=src.indexOf('// --- NPCs',start);
assert(start>=0&&end>start,'drawPlayer boundary missing');
const block=src.slice(start,end);
assert(block.includes("characters.draw('ender'"),'player field renderer must prefer canonical Ender authority');
assert(block.includes("action: moving ? 'walk' : 'idle'"),'player renderer must map movement to shared animation states');
assert(block.includes("drawPlayer._facing"),'player renderer must preserve horizontal facing between frames');
assert(block.includes('if (!rendered)'),'player renderer must preserve a fail-safe sprite fallback');
assert(block.includes("throw new Error('AETHER_ENDER_VISUAL_UNAVAILABLE')"),'player fallback must fail visibly if all visual authorities are unavailable');
console.log('Aetherwake Ender world visual authority: PASS');
