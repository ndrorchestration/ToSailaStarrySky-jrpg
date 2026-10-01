'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

for (const marker of [
  'function latestLoadableSave()',
  'function continueLatestSave()',
  "text('CONTINUE — C'",
  "key === 'c' || key === 'C'",
  'function requestAutosave(reason)',
  'function flushPendingAutosaveIfStable()',
  "window.AetherSaveSystem.rotateAutosave(",
  "{ candidateResolver: loadSemanticallyValidSaveCandidate }",
  "validateSavePayloadBeforeWrite(payload);",
  "requestAutosave('chapter-handoff')",
  "requestAutosave('quest-advance')",
  "requestAutosave('combat-resolution')",
]) {
  assert(runtime.includes(marker), 'Chapter 1 persistence UX missing: ' + marker);
}

assert(runtime.includes("chapter: 'Chapter I — First Wake'"),
  'save metadata must identify Chapter I');
assert(runtime.includes("['signal', 'crossing', 'contact', 'choice'].includes(questState.state)"),
  'manual/autosave snapshot eligibility must reject WAKE/DONE');
assert(/if \(!canSnapshotPersistentState\(\)\) \{\s*pendingAutosaveReason = null;/.test(runtime),
  'deferred autosave must discard non-persistable ending states cleanly');

const autosaveStart = runtime.indexOf('function flushPendingAutosaveIfStable()');
const autosaveEnd = runtime.indexOf('function saveMetadata()', autosaveStart);
const autosaveFn = runtime.slice(autosaveStart, autosaveEnd);
assert(autosaveFn.indexOf('validateSavePayloadBeforeWrite(payload);') <
       autosaveFn.indexOf('window.AetherSaveSystem.rotateAutosave('),
  'deferred autosave must semantic-preflight before rotating save slots');
assert(autosaveFn.includes('{ candidateResolver: loadSemanticallyValidSaveCandidate }'),
  'deferred autosave must classify existing slots through semantic recovery');

const continueStart = runtime.indexOf('function continueLatestSave()');
const continueEnd = runtime.indexOf('function requestAutosave(reason)', continueStart);
const continueFn = runtime.slice(continueStart, continueEnd);
assert(continueFn.includes('latestLoadableSave()'),
  'Continue must resolve the newest semantically loadable save');
assert(continueFn.includes('loadFromSlot(latest.slot)'),
  'Continue must use canonical load/restore path');

const latestStart = runtime.indexOf('function latestLoadableSave()');
const latestEnd = runtime.indexOf('function continueLatestSave()', latestStart);
const latestFn = runtime.slice(latestStart, latestEnd);
assert(latestFn.includes('semanticValid === true'),
  'Continue must ignore semantically invalid saves');
assert(latestFn.includes('savedAt'),
  'Continue must choose a timestamped save');
assert(latestFn.includes('localeCompare'),
  'Continue must choose newest save deterministically');

console.log('Aetherwake Chapter 1 persistence UX contract: PASS');
