'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function sha256(file) {
  const h = crypto.createHash('sha256');
  const fd = fs.openSync(file, 'r');
  const buf = Buffer.allocUnsafe(1024 * 1024);
  try {
    let n;
    while ((n = fs.readSync(fd, buf, 0, buf.length, null)) > 0) h.update(buf.subarray(0, n));
  } finally {
    fs.closeSync(fd);
  }
  return h.digest('hex');
}

function fail(message) {
  console.error('CHAPTER1_RELEASE_EVIDENCE_VERIFY=FAIL');
  console.error(message);
  process.exit(1);
}

const root = path.resolve(process.argv[2] || path.join(__dirname, '..', 'chapter1-release'));
const evidencePath = path.join(root, 'CHAPTER1_RELEASE_EVIDENCE.json');
const manifestPath = path.join(root, 'SHA256SUMS.txt');

if (!fs.existsSync(evidencePath)) fail('release evidence missing: ' + evidencePath);
if (!fs.existsSync(manifestPath)) fail('SHA256SUMS missing: ' + manifestPath);

const evidence = JSON.parse(fs.readFileSync(evidencePath, 'utf8').replace(/^\uFEFF/, ''));
const requiredPass = [
  ['chapter1Core', 'PASS'],
  ['chapter1Visual', 'PASS'],
  ['chapter1BrowserRoute', 'PASS'],
  ['titleAudioReady', 'PASS'],
  ['chapter1SoundtrackReady', 'PASS'],
  ['desktopPackageContract', 'PASS'],
  ['buildProvenance', 'PASS'],
  ['installerInstall', 'PASS'],
  ['installerSaveCloseRelaunchContinue', 'PASS'],
  ['windowsSaveCloseRelaunchContinue', 'PASS'],
];
for (const [key, expected] of requiredPass) {
  if (evidence[key] !== expected) fail(key + ' expected ' + expected + ', got ' + evidence[key]);
}
for (const key of [
  'desktopRuntimeReady','desktopFirstFrame','installerRuntimeReady',
  'installerProvenanceVerified','packagedProvenanceVerified'
]) {
  if (evidence[key] !== true) fail(key + ' must be true');
}

if (!/^[0-9a-f]{40}$/.test(evidence.sourceCommit || '')) fail('sourceCommit is not a full Git SHA');
if (evidence.packagedProvenanceSourceCommit !== evidence.sourceCommit) {
  fail('packaged provenance commit does not match release sourceCommit');
}
if (evidence.acceptance !== 'TECHNICAL_CANDIDATE_PLAYER_ACCEPTANCE_PENDING') {
  fail('release evidence must preserve player-acceptance boundary');
}

if (evidence.candidate !== 'Aetherwake Chapter 1') fail('candidate identity mismatch');
if (evidence.canvas !== '960x640') fail('canvas evidence must be 960x640');
if (!['NSIS', 'IEXPRESS'].includes(evidence.installerEngine)) {
  fail('installerEngine must be NSIS or IEXPRESS');
}
for (const [key, expected] of [
  ['persistenceStorageType', 'nw-file'],
  ['installerPersistenceStorageType', 'nw-file'],
  ['persistenceSlot', 'manual-6'],
  ['installerRestoredSlot', 'manual-6'],
  ['restoredQuestState', 'signal'],
  ['installerRestoredQuestState', 'signal'],
]) {
  if (evidence[key] !== expected) fail(key + ' expected ' + expected + ', got ' + evidence[key]);
}
if (evidence.restoredTileX !== 17 || evidence.restoredTileY !== 16) {
  fail('portable persistence coordinates must restore tile 17,16');
}
if (!Number.isFinite(Date.parse(evidence.generatedAtUtc || ''))) {
  fail('generatedAtUtc must be a valid timestamp');
}
for (const [key, value] of [
  ['portableZipSha256', evidence.portableZipSha256],
  ['installerSha256', evidence.installerSha256],
]) {
  if (!/^[0-9a-f]{64}$/.test(value || '')) fail(key + ' must be a lowercase SHA-256');
}
for (const [key, value] of [
  ['portableZip', evidence.portableZip],
  ['installer', evidence.installer],
]) {
  if (!value || path.basename(value) !== value) fail(key + ' must be a basename, not a path');
}

const zip = path.join(root, evidence.portableZip || '');
const installer = path.join(root, evidence.installer || '');
if (!fs.existsSync(zip)) fail('portable ZIP missing: ' + zip);
if (!fs.existsSync(installer)) fail('installer missing: ' + installer);

const zipHash = sha256(zip);
const installerHash = sha256(installer);
if (zipHash !== evidence.portableZipSha256) fail('portable ZIP SHA-256 mismatch');
if (installerHash !== evidence.installerSha256) fail('installer SHA-256 mismatch');

const manifest = fs.readFileSync(manifestPath, 'utf8').trim().split(/\r?\n/);
if (manifest.length !== 2) fail('SHA256SUMS must contain exactly the portable ZIP and installer');
const expectedLines = new Map(manifest.map(line => {
  const m = line.match(/^([0-9a-f]{64})\s{2}(.+)$/);
  if (!m) fail('invalid SHA256SUMS line: ' + line);
  if (path.basename(m[2]) !== m[2]) fail('SHA256SUMS entries must be basenames');
  return [m[2], m[1]];
}));
if (expectedLines.size !== 2) fail('SHA256SUMS must contain two unique filenames');
if (expectedLines.get(path.basename(zip)) !== zipHash) fail('SHA256SUMS does not match portable ZIP');
if (expectedLines.get(path.basename(installer)) !== installerHash) fail('SHA256SUMS does not match installer');
for (const name of expectedLines.keys()) {
  if (name !== path.basename(zip) && name !== path.basename(installer)) {
    fail('SHA256SUMS contains unexpected artifact: ' + name);
  }
}

console.log('CHAPTER1_RELEASE_EVIDENCE_VERIFY=PASS');
console.log('SOURCE_COMMIT=' + evidence.sourceCommit);
console.log('PORTABLE_ZIP_SHA256=' + zipHash);
console.log('INSTALLER_SHA256=' + installerHash);
