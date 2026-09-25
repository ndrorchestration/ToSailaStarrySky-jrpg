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

function runVerifier() {
  return spawnSync(process.execPath, [verifier, root], { encoding: 'utf8' });
}

try {
  const zipName = 'Aetherwake-Chapter1-test-Windows.zip';
  const installerName = 'Aetherwake-Chapter1-test-Setup.exe';
  const zip = path.join(root, zipName);
  const installer = path.join(root, installerName);
  fs.writeFileSync(zip, 'portable-candidate');
  fs.writeFileSync(installer, 'installer-candidate');
  const zipHash = sha256(zip);
  const installerHash = sha256(installer);

  const evidence = {
    schemaVersion: 1,
    candidate: 'Aetherwake Chapter 1',
    sourceCommit: 'a'.repeat(40),
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
    portableZipSha256: zipHash,
    installer: installerName,
    installerEngine: 'IEXPRESS',
    installerSha256: installerHash,
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
    packagedProvenanceSourceCommit: 'a'.repeat(40),
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

  const evidencePath = path.join(root, 'CHAPTER1_RELEASE_EVIDENCE.json');
  const manifestPath = path.join(root, 'SHA256SUMS.txt');
  fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
  fs.writeFileSync(manifestPath, zipHash + '  ' + zipName + '\n' + installerHash + '  ' + installerName + '\n');

  const pass = runVerifier();
  assert.strictEqual(pass.status, 0, pass.stderr || pass.stdout);
  assert(pass.stdout.includes('CHAPTER1_RELEASE_EVIDENCE_VERIFY=PASS'));

  evidence.installerRestoredTileX = 99;
  fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
  const coordinateFail = runVerifier();
  assert.notStrictEqual(coordinateFail.status, 0, 'installed coordinate mismatch must fail release verification');
  assert(coordinateFail.stderr.includes('installed persistence coordinates must restore tile 17,16'));

  evidence.installerRestoredTileX = 17;
  evidence.installerRestoredQuestState = 'contact';
  fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
  const semanticFail = runVerifier();
  assert.notStrictEqual(semanticFail.status, 0, 'semantic mismatch must fail release verification');
  assert(semanticFail.stderr.includes('installerRestoredQuestState expected signal'));

  evidence.installerRestoredQuestState = 'signal';
  fs.writeFileSync(evidencePath, JSON.stringify(evidence, null, 2) + '\n');
  fs.appendFileSync(manifestPath, '0'.repeat(64) + '  unexpected.bin\n');
  const manifestFail = runVerifier();
  assert.notStrictEqual(manifestFail.status, 0, 'unexpected manifest artifacts must fail verification');
  assert(manifestFail.stderr.includes('SHA256SUMS must contain exactly'));

  console.log('CHAPTER1_RELEASE_EVIDENCE_VERIFIER_CONTRACT=PASS');
} finally {
  fs.rmSync(root, { recursive: true, force: true });
}
