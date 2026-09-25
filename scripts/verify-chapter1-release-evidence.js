'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');

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

function inspectZip(file, extractNames = new Set()) {
  const fd = fs.openSync(file, 'r');
  try {
    const size = fs.fstatSync(fd).size;
    const tailLength = Math.min(size, 22 + 0xffff);
    const tail = Buffer.alloc(tailLength);
    fs.readSync(fd, tail, 0, tail.length, size - tailLength);

    let eocd = -1;
    for (let i = tail.length - 22; i >= 0; i--) {
      if (tail.readUInt32LE(i) === 0x06054b50) {
        eocd = i;
        break;
      }
    }
    if (eocd < 0) throw new Error('ZIP end-of-central-directory record missing');

    const entryCount = tail.readUInt16LE(eocd + 10);
    const centralSize = tail.readUInt32LE(eocd + 12);
    const centralOffset = tail.readUInt32LE(eocd + 16);
    if (centralOffset === 0xffffffff || centralSize === 0xffffffff) {
      throw new Error('ZIP64 portable candidates are not supported by this verifier');
    }
    if (centralOffset + centralSize > size) throw new Error('ZIP central directory exceeds file size');

    const central = Buffer.alloc(centralSize);
    fs.readSync(fd, central, 0, central.length, centralOffset);

    const names = new Set();
    const extracted = new Map();
    let pos = 0;
    let parsed = 0;
    while (pos < central.length) {
      if (pos + 46 > central.length || central.readUInt32LE(pos) !== 0x02014b50) {
        throw new Error('invalid ZIP central-directory entry');
      }
      const method = central.readUInt16LE(pos + 10);
      const compressedSize = central.readUInt32LE(pos + 20);
      const uncompressedSize = central.readUInt32LE(pos + 24);
      const nameLength = central.readUInt16LE(pos + 28);
      const extraLength = central.readUInt16LE(pos + 30);
      const commentLength = central.readUInt16LE(pos + 32);
      const localOffset = central.readUInt32LE(pos + 42);
      if (compressedSize === 0xffffffff || uncompressedSize === 0xffffffff || localOffset === 0xffffffff) {
        throw new Error('ZIP64 entry is not supported by this verifier');
      }

      const nameStart = pos + 46;
      const nameEnd = nameStart + nameLength;
      if (nameEnd > central.length) throw new Error('ZIP filename exceeds central directory');
      const name = central.subarray(nameStart, nameEnd).toString('utf8').replace(/\\/g, '/');
      names.add(name);

      if (extractNames.has(name)) {
        const local = Buffer.alloc(30);
        fs.readSync(fd, local, 0, local.length, localOffset);
        if (local.readUInt32LE(0) !== 0x04034b50) throw new Error('invalid ZIP local header for ' + name);
        const localNameLength = local.readUInt16LE(26);
        const localExtraLength = local.readUInt16LE(28);
        const dataOffset = localOffset + 30 + localNameLength + localExtraLength;
        const compressed = Buffer.alloc(compressedSize);
        fs.readSync(fd, compressed, 0, compressed.length, dataOffset);

        let data;
        if (method === 0) data = compressed;
        else if (method === 8) data = zlib.inflateRawSync(compressed);
        else throw new Error('unsupported ZIP compression method ' + method + ' for ' + name);

        if (data.length !== uncompressedSize) {
          throw new Error('ZIP uncompressed size mismatch for ' + name);
        }
        extracted.set(name, data);
      }

      pos += 46 + nameLength + extraLength + commentLength;
      parsed += 1;
    }
    if (parsed !== entryCount) throw new Error('ZIP entry-count mismatch');
    return { names, extracted };
  } finally {
    fs.closeSync(fd);
  }
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
  ['restoredGameState', 'world'],
  ['installerRestoredGameState', 'world'],
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
if (evidence.installerRestoredTileX !== 17 || evidence.installerRestoredTileY !== 16) {
  fail('installed persistence coordinates must restore tile 17,16');
}
if (!Number.isFinite(Date.parse(evidence.generatedAtUtc || ''))) {
  fail('generatedAtUtc must be a valid timestamp');
}
for (const [key, value] of [
  ['portableZipSha256', evidence.portableZipSha256],
  ['installerSha256', evidence.installerSha256],
  ['packagedTreeSha256', evidence.packagedTreeSha256],
]) {
  if (!/^[0-9a-f]{64}$/.test(value || '')) fail(key + ' must be a lowercase SHA-256');
}
if (!/^[0-9a-f]{40}$/.test(evidence.releaseToolCommit || '')) {
  fail('releaseToolCommit must be a full Git SHA');
}
if (evidence.releaseOnlyDeltaVerified !== true) {
  fail('releaseOnlyDeltaVerified must be true');
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

let zipInspection;
try {
  zipInspection = inspectZip(zip, new Set(['CHAPTER1_BUILD_PROVENANCE.json']));
} catch (err) {
  fail('portable ZIP structure invalid: ' + err.message);
}
if (!zipInspection.names.has('Aetherwake.exe')) {
  fail('portable ZIP must contain root Aetherwake.exe');
}
if (!zipInspection.extracted.has('CHAPTER1_BUILD_PROVENANCE.json')) {
  fail('portable ZIP must contain root CHAPTER1_BUILD_PROVENANCE.json');
}
let packagedProvenance;
try {
  packagedProvenance = JSON.parse(
    zipInspection.extracted.get('CHAPTER1_BUILD_PROVENANCE.json').toString('utf8').replace(/^\uFEFF/, '')
  );
} catch (err) {
  fail('portable ZIP build provenance is not valid JSON');
}
if (packagedProvenance.kind !== 'AETHERWAKE_CHAPTER1_BUILD_PROVENANCE') {
  fail('portable ZIP build provenance kind mismatch');
}
if (packagedProvenance.sourceCommit !== evidence.sourceCommit) {
  fail('portable ZIP embedded sourceCommit does not match release sourceCommit');
}

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
console.log('PACKAGE_TREE_SHA256=' + evidence.packagedTreeSha256);
console.log('INSTALLER_SHA256=' + installerHash);
