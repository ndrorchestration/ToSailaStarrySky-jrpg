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

// Corrupt the primary; loader must recover the previous valid backup.
fs.writeFileSync(first.path, '{"broken":', 'utf8');
const recovered = nwSave.load('manual-3');
assert.strictEqual(recovered.envelope.payload.value, 1);

for (let i = 0; i < 4; i++) {
  nwSave.rotateAutosave({ seq: i }, { gameVersion: '0.2.0' });
}
const auto = nwSave.list().filter(x => x.kind === 'autosave' && x.exists && x.valid);
assert.strictEqual(auto.length, 3, 'autosave rotation must retain exactly three files');

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
