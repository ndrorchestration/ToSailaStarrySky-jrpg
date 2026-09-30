'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'scripts', 'prepare-field-art-admission.js'), 'utf8');

for (const required of [
  "['idle', 'walk', 'talk', 'focus', 'attack']",
  "crypto.createHash('sha256')",
  "git', ['rev-parse', 'HEAD']",
  "git', ['status', '--porcelain']",
  'working tree must be clean',
  'visual evidence manifest missing',
  'receipt.assetSha256 = stripHashes',
  'receipt.runtimeReview.exactHead = head',
  'receipt.runtimeReview.evidenceManifestSha256',
  'receipt.likenessReview.authorityStatus',
  'receipt.likenessReview.characterAuthorityStatus',
  'receipt.likenessReview.authorityDocumentSha256',
  'receipt.likenessReview.approvedReferenceSha256',
  'CREATOR_APPROVED_V1',
  'LOCKED_TO_APPROVED_ALIGNMENT_V1',
  'likeness authority document missing',
  "assets', 'characters', 'v1', 'admission'",
  "['ender', 'ionia'].includes(character)"
]) {
  assert(source.includes(required), 'admission preparer missing control: ' + required);
}

assert(source.includes('FIELD_ART_ADMISSION_PREP_FAIL'),
  'admission preparer must fail closed with an explicit error family');

console.log('Aetherwake field-art admission preparer contract: PASS');
