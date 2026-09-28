'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const protocolPath = path.join(root, 'visual-acceptance-protocol.json');
const templatePath = path.join(root, 'docs', 'visual-acceptance-template.json');
const outputPath = path.join(root, 'visual-acceptance-results.json');

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function requireSha(value, length, label) {
  const pattern = length === 40 ? /^[0-9a-f]{40}$/i : /^[0-9a-f]{64}$/i;
  if (typeof value !== 'string' || !pattern.test(value)) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: invalid ' + label);
  }
  return value.toLowerCase();
}

function prepare() {
  if (!fs.existsSync(protocolPath)) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: frozen protocol file missing');
  }
  if (!fs.existsSync(templatePath)) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: results template missing');
  }

  const protocol = JSON.parse(fs.readFileSync(protocolPath, 'utf8'));
  if (protocol.schema !== 'AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_V1') {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: protocol schema mismatch');
  }
  if (protocol.frozenBeforeFirstSession !== true) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: protocol is not frozen');
  }
  if (!Array.isArray(protocol.aetherwakeFrames) || protocol.aetherwakeFrames.length !== 7) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: protocol must contain seven Aetherwake frames');
  }
  if (!Array.isArray(protocol.decoys) || protocol.decoys.length !== 3) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: protocol must contain three decoys');
  }
  const participantPlan = protocol.participantPlan || {};
  if (participantPlan.requiredCount !== 5 ||
      !Array.isArray(participantPlan.ids) ||
      participantPlan.ids.join(',') !== 'P1,P2,P3,P4,P5') {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: participant plan must be frozen to P1-P5');
  }

  const candidate = protocol.candidate || {};
  const commit = requireSha(candidate.commit, 40, 'protocol commit');
  const packageSha256 = requireSha(candidate.packageSha256, 64, 'package SHA-256');
  const evidenceManifestSha256 = requireSha(candidate.evidenceManifestSha256, 64, 'evidence manifest SHA-256');
  const protocolSha256 = sha256File(protocolPath);

  const results = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
  if (results.schema !== 'AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS_V1') {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: results template schema mismatch');
  }
  results.candidate = {
    commit,
    packageSha256,
    evidenceManifestSha256,
    protocolSha256
  };
  const resultIds = results.participants.map(p => p.id);
  if (resultIds.join(',') !== participantPlan.ids.join(',')) {
    throw new Error('VISUAL_RESULTS_PREP_FAIL: results template does not match frozen participant plan');
  }

  fs.writeFileSync(outputPath, JSON.stringify(results, null, 2) + '\n');

  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS=PREPARED');
  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS_PATH=visual-acceptance-results.json');
  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_SHA256=' + protocolSha256);
  return results;
}

if (require.main === module) {
  try {
    prepare();
  } catch (error) {
    console.error(String(error && error.message ? error.message : error));
    process.exit(1);
  }
}

module.exports = { prepare, sha256File };
