'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'assets', 'characters', 'v1', 'manifest.json');
const templatePath = path.join(root, 'docs', 'field-art-admission-template.json');
const evidenceManifestPath = path.join(root, 'visual-evidence', 'manifest.json');
const ACTIONS = ['idle', 'walk', 'talk', 'focus', 'attack'];

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function exactHead() {
  const result = cp.spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: unable to resolve Git head');
  const head = result.stdout.trim();
  if (!/^[0-9a-f]{40}$/i.test(head)) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: invalid exact Git head');
  return head;
}

function cleanWorktree() {
  const result = cp.spawnSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: git status failed');
  if (result.stdout.trim()) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: working tree must be clean');
}

function loadJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function prepare(character) {
  const manifest = loadJson(manifestPath);
  const record = manifest.characters && manifest.characters[character];
  if (!record) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: unknown character ' + character);

  cleanWorktree();
  const head = exactHead();

  const stripHashes = {};
  for (const action of ACTIONS) {
    const spec = record.fieldStrips && record.fieldStrips[action];
    if (!spec || !spec.path) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: missing strip contract ' + action);
    const file = path.join(root, spec.path);
    if (!fs.existsSync(file)) throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: missing strip ' + spec.path);
    stripHashes[action] = sha256File(file);
  }

  if (!fs.existsSync(evidenceManifestPath)) {
    throw new Error('FIELD_ART_ADMISSION_PREP_FAIL: visual evidence manifest missing');
  }

  const receipt = loadJson(templatePath);
  receipt.characterId = character;
  receipt.assetSha256 = stripHashes;
  receipt.runtimeReview.exactHead = head;
  receipt.runtimeReview.evidenceManifestSha256 = sha256File(evidenceManifestPath);

  const outputDir = path.join(root, 'assets', 'characters', 'v1', 'admission');
  fs.mkdirSync(outputDir, { recursive: true });
  const output = path.join(outputDir, character + '.json');
  fs.writeFileSync(output, JSON.stringify(receipt, null, 2) + '\n');

  console.log('AETHERWAKE_FIELD_ART_ADMISSION_PREPARED=' + character);
  console.log('AETHERWAKE_FIELD_ART_EXACT_HEAD=' + head);
  console.log('AETHERWAKE_FIELD_ART_RECEIPT=' + path.relative(root, output).replace(/\\/g, '/'));
  console.log(JSON.stringify({ character, assetSha256: stripHashes, evidenceManifestSha256: receipt.runtimeReview.evidenceManifestSha256 }, null, 2));
  return output;
}

if (require.main === module) {
  const character = process.argv[2];
  if (!['ender', 'ionia'].includes(character)) {
    console.error('Usage: node scripts/prepare-field-art-admission.js <ender|ionia>');
    process.exit(2);
  }
  try {
    prepare(character);
  } catch (error) {
    console.error(String(error && error.message ? error.message : error));
    process.exit(1);
  }
}

module.exports = { prepare, sha256File };
