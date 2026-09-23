const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const base = require('../modules/save-system.js');

assert.strictEqual(base.VERSION, '1.1.0');
assert.strictEqual(base.SCHEMA_VERSION, 1);
assert.deepStrictEqual(Object.keys(base.MIGRATIONS), [],
  'schema v1 should have no migration steps yet, but the registry must exist');
assert.strictEqual(typeof base.migrateEnvelope, 'function');
assert.deepStrictEqual(base.MANUAL_SLOTS, ['manual-1','manual-2','manual-3','manual-4','manual-5','manual-6']);
assert.deepStrictEqual(base.AUTOSAVE_SLOTS, ['autosave-0','autosave-1','autosave-2']);

const payload = { runtime: { scene: 'world' }, party: { activeIds: ['ender'] } };
const envelope = base.makeEnvelope('manual-1', payload, {
  gameVersion: '0.2.0',
  playtimeMs: 12345,
  chapter: 'Chapter I — First Wake',
  location: 'Aureate Wake',
  partySummary: ['Ender']
});
assert.strictEqual(base.validateEnvelope(envelope), true);
const tampered = JSON.parse(JSON.stringify(envelope));
tampered.payload.runtime.scene = 'combat';
assert.throws(() => base.validateEnvelope(tampered), /SAVE_CHECKSUM_INVALID/);

function makeLocalStorage() {
  const map = new Map();
  return {
    setItem(k,v){ map.set(k,String(v)); },
    getItem(k){ return map.has(k) ? map.get(k) : null; },
    removeItem(k){ map.delete(k); }
  };
}

const browserRoot = { localStorage: makeLocalStorage() };
const browserSave = base._createForTesting(browserRoot);
browserSave.save('manual-2', payload, { gameVersion: '0.2.0' });
assert.strictEqual(browserSave.load('manual-2').envelope.payload.runtime.scene, 'world');
assert.strictEqual(browserSave.loadBackup('manual-2'), null,
  'browser/localStorage persistence must not invent a backup candidate');
assert.strictEqual(browserSave.latest().slot, 'manual-2');
browserSave.remove('manual-2');
assert.strictEqual(browserSave.load('manual-2'), null);

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'aetherwake-save-'));
const nwRoot = {
  nw: { App: { dataPath: temp } },
  require(name) {
    if (name === 'fs') return fs;
    if (name === 'path') return path;
    throw new Error('unexpected module: ' + name);
  }
};
const nwSave = base._createForTesting(nwRoot);
const first = nwSave.save('manual-3', { value: 1 }, { gameVersion: '0.2.0' });
assert.strictEqual(first.storageType, 'nw-file');
assert(fs.existsSync(first.path), 'desktop save file was not created');

nwSave.save('manual-3', { value: 2 }, { gameVersion: '0.2.0' });
assert.strictEqual(nwSave.load('manual-3').envelope.payload.value, 2);
assert(fs.existsSync(first.path + '.bak'), 'backup was not created before overwrite');
const explicitBackup = nwSave.loadBackup('manual-3');
assert(explicitBackup && explicitBackup.recoveredFromBackup === true,
  'desktop save system must expose the previous primary as an explicit backup candidate');
assert.strictEqual(explicitBackup.envelope.payload.value, 1);
assert.strictEqual(explicitBackup.path, first.path + '.bak');

// Checksum-invalid but parseable primary must recover the previous valid backup
// with explicit provenance rather than silently applying the bad primary.
const checksumBad = nwSave.makeEnvelope('manual-3', { value: 3 }, { gameVersion: '0.2.0' });
checksumBad.checksum = '00000000';
fs.writeFileSync(first.path, JSON.stringify(checksumBad), 'utf8');
const checksumRecovered = nwSave.load('manual-3');
assert.strictEqual(checksumRecovered.envelope.payload.value, 1);
assert.strictEqual(checksumRecovered.recoveredFromBackup, true);
assert.strictEqual(checksumRecovered.path, first.path + '.bak');
assert(/SAVE_CHECKSUM_INVALID/.test(checksumRecovered.primaryLoadError));

// Malformed primary JSON must use the same explicit recovery contract.
fs.writeFileSync(first.path, '{"broken":', 'utf8');
const recovered = nwSave.load('manual-3');
assert.strictEqual(recovered.envelope.payload.value, 1);
assert.strictEqual(recovered.recoveredFromBackup, true);
assert.strictEqual(recovered.path, first.path + '.bak');
assert(recovered.primaryLoadError,
  'backup recovery must retain the primary failure reason');

// Downgrade protection: a newer-schema save must never be overwritten by this build.
function futureEnvelope(slot, value) {
  const next = nwSave.makeEnvelope(slot, { value }, { gameVersion: '9.9.9' });
  next.schemaVersion = nwSave.SCHEMA_VERSION + 1;
  const body = { ...next };
  delete body.checksum;
  next.checksum = nwSave.checksum(body);
  return next;
}

const saveDir = path.join(temp, 'saves');
const futureManualPath = path.join(saveDir, 'manual-4.json');
fs.writeFileSync(futureManualPath, JSON.stringify(futureEnvelope('manual-4', 99)), 'utf8');
assert.throws(
  () => nwSave.save('manual-4', { value: 4 }, { gameVersion: '0.2.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-4:2:primary/
);
assert.strictEqual(JSON.parse(fs.readFileSync(futureManualPath, 'utf8')).schemaVersion, 2,
  'future-schema manual primary must remain untouched');

// A future backup is also protected even when the primary itself is corrupt.
const protectedPrimary = path.join(saveDir, 'manual-5.json');
const protectedBackup = protectedPrimary + '.bak';
fs.writeFileSync(protectedPrimary, '{"broken":', 'utf8');
fs.writeFileSync(protectedBackup, JSON.stringify(futureEnvelope('manual-5', 88)), 'utf8');
assert.throws(
  () => nwSave.save('manual-5', { value: 5 }, { gameVersion: '0.2.0' }),
  /SAVE_SLOT_FUTURE_SCHEMA_PROTECTED:manual-5:2:backup/
);
assert.strictEqual(JSON.parse(fs.readFileSync(protectedBackup, 'utf8')).schemaVersion, 2,
  'future-schema backup must remain untouched behind a corrupt primary');

for (let i = 0; i < 4; i++) {
  nwSave.rotateAutosave({ seq: i }, { gameVersion: '0.2.0' });
}
const auto = nwSave.list().filter(x => x.kind === 'autosave' && x.exists && x.valid);
assert.strictEqual(auto.length, 3, 'autosave rotation must retain exactly three files');

// Autosave rotation must skip protected future-schema slots.
for (const slot of nwSave.AUTOSAVE_SLOTS) nwSave.remove(slot);
const protectedAuto0 = path.join(saveDir, 'autosave-0.json');
fs.writeFileSync(protectedAuto0, JSON.stringify(futureEnvelope('autosave-0', 70)), 'utf8');
const rotated = nwSave.rotateAutosave({ seq: 100 }, { gameVersion: '0.2.0' });
assert.notStrictEqual(rotated.envelope.slot, 'autosave-0',
  'autosave rotation must not overwrite a protected future-schema slot');
assert.strictEqual(JSON.parse(fs.readFileSync(protectedAuto0, 'utf8')).schemaVersion, 2);

// If every autosave slot belongs to a newer schema, fail closed instead of deleting one.
for (const slot of nwSave.AUTOSAVE_SLOTS) {
  const target = path.join(saveDir, slot + '.json');
  fs.writeFileSync(target, JSON.stringify(futureEnvelope(slot, 80)), 'utf8');
}
assert.throws(
  () => nwSave.rotateAutosave({ seq: 101 }, { gameVersion: '0.2.0' }),
  /SAVE_AUTOSAVE_ALL_SLOTS_FUTURE_PROTECTED/
);

fs.rmSync(temp, { recursive: true, force: true });
console.log('Aetherwake save-system contract: PASS');

const fixture = JSON.parse(fs.readFileSync(
  path.join(__dirname, 'fixtures', 'saves', 'schema-v1-manual-1.json'),
  'utf8'
));
assert.strictEqual(base.validateEnvelope(fixture), true,
  'golden schema-v1 fixture stopped validating');
assert.strictEqual(base.migrateEnvelope(fixture).schemaVersion, 1,
  'current historical fixture must normalize to current schema');
const future = JSON.parse(JSON.stringify(fixture));
future.schemaVersion = 2;
const futureBody = { ...future };
delete futureBody.checksum;
future.checksum = base.checksum(futureBody);
assert.throws(() => base.migrateEnvelope(future), /SAVE_SCHEMA_FUTURE_UNSUPPORTED/);
