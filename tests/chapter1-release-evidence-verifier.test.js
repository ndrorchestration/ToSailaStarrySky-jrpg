'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'aetherwake-release-evidence-test-'));
const verifier = path.join(__dirname, '..', 'scripts', 'verify-chapter1-release-evidence.js');

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function writeStoredZip(file, entries) {
  const localRecords = [];
  const centralRecords = [];
  let offset = 0;

  for (const entry of entries) {
    const name = Buffer.from(entry.name, 'utf8');
    const data = Buffer.isBuffer(entry.data) ? entry.data : Buffer.from(entry.data, 'utf8');
    const checksum = crc32(data);

    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0, 6);
    local.writeUInt16LE(0, 8);
    local.writeUInt16LE(0, 10);
    local.writeUInt16LE(0, 12);
    local.writeUInt32LE(checksum, 14);
    local.writeUInt32LE(data.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(name.length, 26);
    local.writeUInt16LE(0, 28);
    const localRecord = Buffer.concat([local, name, data]);
    localRecords.push(localRecord);

    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0, 8);
    central.writeUInt16LE(0, 10);
    central.writeUInt16LE(0, 12);
    central.writeUInt16LE(0, 14);
    central.writeUInt32LE(checksum, 16);
    central.writeUInt32LE(data.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(name.length, 28);
    central.writeUInt16LE(0, 30);
    central.writeUInt16LE(0, 32);
    central.writeUInt16LE(0, 34);
    central.writeUInt16LE(0, 36);
    central.writeUInt32LE(0, 38);
    central.writeUInt32LE(offset, 42);
    centralRecords.push(Buffer.concat([central, name]));

    offset += localRecord.length;
  }

  const localBytes = Buffer.concat(localRecords);
  const centralBytes = Buffer.concat(centralRecords);
  const eocd = Buffer.alloc(22);
  eocd.writeUInt32LE(0x06054b50, 0);
  eocd.writeUInt16LE(0, 4);
  eocd.writeUInt16LE(0, 6);
  eocd.writeUInt16LE(entries.length, 8);
  eocd.writeUInt16LE(entries.length, 10);
  eocd.writeUInt32LE(centralBytes.length, 12);
  eocd.writeUInt32LE(localBytes.length, 16);
  eocd.writeUInt16LE(0, 20);

  fs.writeFileSync(file, Buffer.concat([localBytes, centralBytes, eocd]));
}

function runVerifier() {
  return spawnSync(process.execPath, [verifier, root], { encoding: 'utf8' });
}

try {
  const zipName = 'Aetherwake-Chapter1-test-Windows.zip';
  const installerName = 'Aetherwake-Chapter1-test-Setup.exe';
  const zip = path.join(root, zipName);
  const installer = path.join(root, installerName);
  const evidencePath = path.join(root, 'CHAPTER1_RELEASE_EVIDENCE.json');
  const manifestPath = path.join(root, 'SHA256SUMS.txt');
  const sourceCommit = 'a'.repeat(40);

  function writeCandidateZip(commit) {
    writeStoredZip(zip, [
      {
        name: 'CHAPTER1_BUILD_PROVENANCE.json',
        data: JSON.stringify({
          schemaVersion: 1,
          kind: 'AETHERWAKE_CHAPTER1_BUILD_PROVENANCE',
          sourceCommit: commit,
          sourceBranch: 'test',
          builtAtUtc: '2026-09-24T20:00:00.000Z',
        }),
      },
      { name: 'Aetherwake.exe', data: 'synthetic-executable' },
    ]);
  }

  writeCandidateZip(sourceCommit);
  fs.writeFileSync(installer, 'installer-candidate');

  const evidence = {
    schemaVersion: 1,
    candidate: 'Aetherwake Chapter 1',
    sourceCommit,
    generatedAtUtc: '2026-09-24T20:00:00.000Z',
    chapter1Core: 'PASS',
    chapter1Visual: 'PASS',
    chapter1BrowserRoute: 'PASS',
    titleAudioReady: 'PASS',
    chapter1SoundtrackReady: 'PASS',
    desktopPackageContract: 'PASS',
    buildProvenance: 'PASS',
    desktopRuntimeReady: true,
    desktopFirstFrame: true,
    canvas: '960x640',
    portableZip: zipName,
    portableZipSha256: '',
    installer: installerName,
    installerEngine: 'IEXPRESS',
    installerSha256: '',
    installerInstall: 'PASS',
    installerRuntimeReady: true,
    installerProvenanceVerified: true,
    installerSaveCloseRelaunchContinue: 'PASS',
    installerPersistenceStorageType: 'nw-file',
    installerRestoredGameState: 'world',
    installerRestoredSlot: 'manual-6',
    installerRestoredTileX: 17,
    installerRestoredTileY: 16,
    installerRestoredQuestState: 'signal',
    packagedProvenanceSourceCommit: sourceCommit,
    packagedProvenanceVerified: true,
    windowsSaveCloseRelaunchContinue: 'PASS',
    persistenceStorageType: 'nw-file',
    persistenceSlot: 'manual-6',
    restoredGameState: 'world',
    restoredTileX: 17,
    restoredTileY: 16,
    restoredQuestState: 'signal',
    acceptance: 'TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING',
  };

  function writeEvidenceAndManifest() {
    evidence.portableZipSha256 = sha256(zip);
    evidence.installerSha256 = sha256(installer);
    fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
    fs.writeFileSync(
      manifestPath,
      evidence.portableZipSha256 + '  ' + zipName + '\n' +
      evidence.installerSha256 + '  ' + installerName + '\n'
    );
  }

  writeEvidenceAndManifest();
  const pass = runVerifier();
  assert.strictEqual(pass.status, 0, pass.stderr || pass.stdout);
  assert(pass.stdout.includes('CHAPTER1_RELEASE_EVIDENCE_VERIFY=PASS'));

  writeCandidateZip('b'.repeat(40));
  writeEvidenceAndManifest();
  const provenanceFail = runVerifier();
  assert.notStrictEqual(provenanceFail.status, 0, 'embedded provenance mismatch must fail verification');
  assert(provenanceFail.stderr.includes('portable ZIP embedded sourceCommit does not match release sourceCommit'));

  writeCandidateZip(sourceCommit);
  evidence.installerRestoredTileX = 99;
  writeEvidenceAndManifest();
  const coordinateFail = runVerifier();
  assert.notStrictEqual(coordinateFail.status, 0, 'installed coordinate mismatch must fail release verification');
  assert(coordinateFail.stderr.includes('installed persistence coordinates must restore tile 17,16'));

  evidence.installerRestoredTileX = 17;
  evidence.installerRestoredQuestState = 'contact';
  writeEvidenceAndManifest();
  const semanticFail = runVerifier();
  assert.notStrictEqual(semanticFail.status, 0, 'semantic mismatch must fail release verification');
  assert(semanticFail.stderr.includes('installerRestoredQuestState expected signal'));

  evidence.installerRestoredQuestState = 'signal';
  writeEvidenceAndManifest();
  fs.appendFileSync(manifestPath, '0'.repeat(64) + '  unexpected.bin\n');
  const manifestFail = runVerifier();
  assert.notStrictEqual(manifestFail.status, 0, 'unexpected manifest artifacts must fail verification');
  assert(manifestFail.stderr.includes('SHA256SUMS must contain exactly'));

  console.log('CHAPTER1_RELEASE_EVIDENCE_VERIFIER_CONTRACT=PASS');
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
