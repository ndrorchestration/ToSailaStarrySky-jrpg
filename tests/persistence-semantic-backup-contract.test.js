'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

assert(runtime.includes('function loadSemanticallyValidSaveCandidate(slot)'),
  'runtime must centralize semantic primary/backup candidate selection');
assert(runtime.includes('window.AetherSaveSystem.loadBackup(slot)'),
  'semantic-invalid primary must be allowed to fall back to backup');
assert(runtime.includes('semanticBackupRecovery: true'),
  'semantic backup recovery must remain explicit');
assert(runtime.includes('SAVE_PRIMARY_AND_BACKUP_UNLOADABLE:'),
  'primary+backup semantic failure must fail closed with combined evidence');
assert(runtime.includes('{ candidateResolver: loadSemanticallyValidSaveCandidate }'),
  'autosave rotation must classify existing slots through semantic recovery');
assert(runtime.includes('preserveBackup = Boolean(priorCandidate && priorCandidate.semanticBackupRecovery)'),
  'manual save must preserve a validated recovery backup');
assert(runtime.includes('{ preserveBackup }'),
  'manual save must pass backup-preservation intent to storage');
assert(runtime.includes('window._lastLoadRecovery'),
  'player/runtime evidence must expose semantic backup recovery');
assert(runtime.includes('RECOVERED PREVIOUS SAVE // PRIMARY INVALID'),
  'semantic recovery must be player-visible');
assert(runtime.includes('NEWER VERSION SAVE DATA — PRESERVED'),
  'future-version write protection must remain player-visible');
assert(runtime.includes('window._lastSaveResult = null;'),
  'failed writes must clear stale save-success evidence');
assert(runtime.includes('window._lastLoadResult = null;'),
  'failed loads must clear stale load-success evidence');

console.log('Aetherwake semantic backup coordinator contract: PASS');
