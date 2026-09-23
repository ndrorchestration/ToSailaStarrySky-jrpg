const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');

assert(html.includes('modules/save-system.js'), 'save-system module is not loaded by the runtime');
assert(html.includes('modules/save-payload-validator.js'), 'semantic save validator is not loaded by the runtime');
assert(html.indexOf('modules/save-payload-validator.js') < html.indexOf('aetherwake.js'),
  'semantic save validator must load before the runtime');
assert(html.indexOf('modules/save-system.js') < html.indexOf('aetherwake.js'),
  'save-system module must load before aetherwake.js');

assert(runtime.includes("SAVELOAD: 'saveload'"), 'save/load UI state missing');
assert(runtime.includes("CONTINUE — C"), 'title Continue command missing');
assert(runtime.includes("openSaveLoadMenu('save')"), 'manual save UI entry missing');
assert(runtime.includes('let saveOverwritePendingSlot = null;'),
  'save UI must track explicit overwrite confirmation state');
assert(runtime.includes('function setSaveOverwritePending(slot)'),
  'save UI must centralize overwrite confirmation state');
assert(runtime.includes("showToast('OVERWRITE CANCELLED // SAVE PRESERVED'"),
  'canceling overwrite must explicitly preserve the existing save');
assert(runtime.includes("const existing = buildLoadableSaveIndex().find(entry => entry.slot === slot && entry.exists);"),
  'occupied manual slots must require overwrite confirmation before save mutation');
assert(runtime.includes('if (existing && existing.futureSchemaProtected)'),
  'future-version slots must be blocked before overwrite confirmation');
assert(runtime.includes("showToast('NEWER VERSION SAVE DATA — PRESERVED'"),
  'future-version overwrite prevention must be player-visible');
assert(runtime.includes("text('OVERWRITE SLOT ' + slotNumber + '?'"),
  'save overlay must render an explicit overwrite confirmation prompt');
assert(runtime.includes("' keep current save'"),
  'overwrite prompt must expose a clear cancel/preserve action');
assert(runtime.includes("openSaveLoadMenu('load')"), 'manual load UI entry missing');
assert(runtime.includes('function buildSavePayload()'), 'runtime save snapshot missing');
assert(runtime.includes('function validateSavePayloadBeforeWrite(payload)'),
  'runtime must semantic-preflight save snapshots before persistence');
assert(runtime.includes('validateSavePayloadBeforeWrite(payload);'),
  'saveToSlot must validate the snapshot before rotating/replacing save files');
assert(runtime.includes('preserveBackup = Boolean(priorCandidate && priorCandidate.semanticBackupRecovery)'),
  'manual overwrite must preserve the validated backup when the current slot recovered from backup');
assert(runtime.includes('{ preserveBackup }'),
  'manual save write must pass recovery-preservation intent to the storage layer');
assert(runtime.includes('{ candidateResolver: loadSemanticallyValidSaveCandidate }'),
  'autosave rotation must classify existing slots through the same semantic resolver as Load/Continue');
assert(runtime.indexOf('validateSavePayloadBeforeWrite(payload);') <
       runtime.indexOf('window.AetherSaveSystem.rotateAutosave('),
  'autosave rotation must occur only after semantic snapshot validation');
assert(runtime.indexOf('validateSavePayloadBeforeWrite(payload);') <
       runtime.indexOf('window.AetherSaveSystem.save(slot, payload, saveMetadata())'),
  'manual save replacement must occur only after semantic snapshot validation');
assert(runtime.includes('function prepareSaveEnvelopeForApply(envelope)'),
  'semantic preflight stage missing');
assert(runtime.includes('function captureLiveRuntimeForLoadRollback()'),
  'runtime must snapshot live state before mutating load apply');
assert(runtime.includes('function restoreLiveRuntimeAfterFailedLoad(snapshot)'),
  'runtime must rollback partial save application');
assert(runtime.includes("runLoadTestHook('after-party')") &&
       runtime.includes("runLoadTestHook('after-world')") &&
       runtime.includes("runLoadTestHook('before-commit')"),
  'load transaction must expose fault-injection boundaries');
assert(runtime.includes('LOAD_APPLY_AND_ROLLBACK_FAILED:'),
  'load must fail closed if rollback itself fails');
assert(runtime.includes('window._lastLoadRollback'),
  'rollback outcome must remain machine-visible');
assert(runtime.includes('AetherSavePayloadValidator.validatePayload(payload'),
  'runtime must validate payload semantics before apply');
assert(runtime.indexOf('function prepareSaveEnvelopeForApply(envelope)') <
       runtime.indexOf('function applySaveEnvelope(envelope)'),
  'preflight must be defined before the mutating apply path');
assert(runtime.includes('const prepared = prepareSaveEnvelopeForApply(envelope);'),
  'apply path does not require successful preflight');
assert(runtime.includes('function loadSemanticallyValidSaveCandidate(slot)'),
  'runtime must centralize primary/backup semantic candidate selection');
assert(runtime.includes('window.AetherSaveSystem.loadBackup(slot)'),
  'semantic-invalid primaries must be allowed to try the previous desktop backup');
assert(runtime.includes('semanticBackupRecovery: true'),
  'runtime must mark semantic backup recovery explicitly');
assert(runtime.includes('if (loaded.recoveredFromBackup)'),
  'integrity-level backup recovery must be promoted into the same runtime recovery evidence path');
assert(runtime.includes('primaryLoadError'),
  'runtime recovery evidence must retain the primary integrity/migration failure reason');
assert(runtime.includes('SAVE_PRIMARY_AND_BACKUP_UNLOADABLE:'),
  'runtime must fail closed when both primary and backup are semantically unloadable');
assert(runtime.includes('function buildLoadableSaveIndex()'),
  'Continue must classify semantic loadability, not envelope validity alone');
assert(runtime.includes('prepareSaveEnvelopeForApply(loaded.envelope)'),
  'save index must use the same semantic preflight as explicit Load');
assert(runtime.includes('semanticValid: false'),
  'semantic failures must be excluded from Continue candidates');
assert(runtime.includes('savedAt: envelope.savedAt'),
  'Continue metadata must use the semantically selected envelope rather than an invalid primary');
assert(runtime.includes('if (!meta.exists) return meta;'),
  'Continue must try the semantic candidate chain for every existing slot, including envelope-invalid primaries');
assert(!runtime.includes('if (!meta.exists || meta.valid === false) return meta;'),
  'Continue must not suppress backup recovery solely because the primary listing is invalid');
assert(runtime.includes('RECOVERED PREVIOUS SAVE // PRIMARY INVALID'),
  'player must receive a visible recovery notice when backup semantics rescue a slot');
assert(runtime.includes('NEWER VERSION SAVE — PRESERVED'),
  'save UI must clearly distinguish protected future-version saves from corrupt saves');
assert(runtime.includes('RECOVERY BACKUP // NEWER V'),
  'save UI must label an older recovery backup when a newer primary is preserved');
assert(runtime.includes('RECOVERED OLDER SAVE // NEWER PRIMARY PRESERVED'),
  'load recovery must explain mixed-version fallback to the player');
assert(runtime.includes('futureSchemaProtected'),
  'save index must classify future-schema protection explicitly');
assert(runtime.includes('function applySaveEnvelope(envelope)'), 'runtime restore path missing');
assert(runtime.includes('window.AetherPartyState.setActivePartyIds(ids)'),
  'load path must restore canonical active-party references');
assert(runtime.includes('window.AetherPartyState.validate()'),
  'load path must validate canonical party invariants');
assert(runtime.includes('restorePersistentState(payload.airNavigation)'),
  'air-navigation persistence must be restored through its validated contract');
assert(runtime.includes("autosave('chapter-handoff')"), 'chapter handoff autosave missing');
assert(runtime.includes("autosave('quest-advance')"), 'quest-transition autosave missing');
assert(runtime.includes("autosave('combat-resolution')"), 'combat-resolution autosave missing');
assert(runtime.includes('if (!world || !world.player || gameOver) return false;'),
  'saving must fail closed when the world is unavailable or game is over');
assert(runtime.includes('quest.state === QUEST_STATES.WAKE'),
  'saving must account for the transient Wake resolution state');
assert(runtime.includes("return gameState === STATE.WORLD || gameState === STATE.AIRSHIP"),
  'manual saving must be limited to stable world/airship states');

console.log('Aetherwake save-runtime contract: PASS');
