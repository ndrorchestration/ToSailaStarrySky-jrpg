'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

assert(runtime.includes("SAVELOAD: 'saveload'"),
  'manual persistence UI state missing');
assert(runtime.includes("keyCode === 116"), 'F5 manual-save shortcut missing');
assert(runtime.includes("keyCode === 120"), 'F9 manual-load shortcut missing');
assert(runtime.includes("openSaveLoadMenu('save')"), 'save menu entry missing');
assert(runtime.includes("openSaveLoadMenu('load')"), 'load menu entry missing');

assert(runtime.includes('function buildLoadableSaveIndex()'),
  'semantic save-slot classification missing');
assert(runtime.includes('prepareSaveEnvelopeForApply(loaded.envelope);'),
  'manual load classification must use the same semantic preflight as restore');
assert(runtime.includes('function saveToSlot(slot)'),
  'manual slot save path missing');
assert(runtime.includes('window.AetherSaveSystem.save(slot, buildSavePayload(), saveMetadata())'),
  'manual save must persist the validated live snapshot');
assert(runtime.includes('function loadFromSlot(slot)'),
  'manual slot load path missing');
assert(runtime.includes('applySaveEnvelope(loaded.envelope);'),
  'manual load must use canonical restore authority');

assert(runtime.includes('window.AetherSaveSystem.MANUAL_SLOTS'),
  'manual UI must use the canonical six-slot registry');
assert(runtime.includes('INVALID SAVE STATE'),
  'semantic-invalid saves must be visible but not represented as valid');
assert(runtime.includes('ORIGINAL RETAINED'),
  'invalid/corrupt save messaging must preserve original evidence');
assert(runtime.includes('gameState !== STATE.WORLD && gameState !== STATE.AIRSHIP'),
  'manual save/load menu must be restricted to stable scene boundaries');

assert(!runtime.includes('function continueLatestSave()'),
  'title Continue is outside this bounded tranche');
assert(!runtime.includes('function autosave('),
  'autosave hooks are outside this bounded tranche');
assert(!runtime.includes("setTimeout(function() { autosave("),
  'opening must not gain an autosave hook in this tranche');

console.log('Aetherwake manual Save/Load boundary contract: PASS');
