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

const zip = path.join(root, evidence.portableZip || '');
const installer = path.join(root, evidence.installer || '');
if (!fs.existsSync(zip)) fail('portable ZIP missing: ' + zip);
if (!fs.existsSync(installer)) fail('installer missing: ' + installer);

const zipHash = sha256(zip);
const installerHash = sha256(installer);
if (zipHash !== evidence.portableZipSha256) fail('portable ZIP SHA-256 mismatch');
if (installerHash !== evidence.installerSha256) fail('installer SHA-256 mismatch');

const manifest = fs.readFileSync(manifestPath, 'utf8').trim().split(/\r?\n/);
const expectedLines = new Map(manifest.map(line => {
  const m = line.match(/^([0-9a-f]{64})\s{2}(.+)$/);
  if (!m) fail('invalid SHA256SUMS line: ' + line);
  return [m[2], m[1]];
}));
if (expectedLines.get(path.basename(zip)) !== zipHash) fail('SHA256SUMS does not match portable ZIP');
if (expectedLines.get(path.basename(installer)) !== installerHash) fail('SHA256SUMS does not match installer');

console.log('CHAPTER1_RELEASE_EVIDENCE_VERIFY=PASS');
console.log('SOURCE_COMMIT=' + evidence.sourceCommit);
console.log('PORTABLE_ZIP_SHA256=' + zipHash);
console.log('INSTALLER_SHA256=' + installerHash);
