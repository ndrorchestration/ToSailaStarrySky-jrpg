'use strict';

const assert = require('assert');
const crypto = require('crypto');
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

function arg(name, required = true) {
  const i = args.indexOf(name);
  if (i < 0) {
    if (required) throw new Error('Missing required argument: ' + name);
    return null;
  }
  assert(args[i + 1], 'Missing value for ' + name);
  return path.resolve(args[i + 1]);
}

function sha256(file) {
  const bytes = fs.readFileSync(file);
  return crypto.createHash('sha256').update(bytes).digest('hex');
}

function readJson(file, label) {
  assert(fs.existsSync(file), label + ' missing: ' + file);
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function runValidator(script, args) {
  const result = childProcess.spawnSync(
    process.execPath,
    [path.join(repo, 'scripts', script), ...args],
    { cwd: repo, encoding: 'utf8' }
  );
  if (result.status !== 0) {
    throw new Error(
      script + ' failed\n' +
      (result.stdout || '') +
      (result.stderr || '')
    );
  }
  return (result.stdout || '').trim();
}

const summaryPath = arg('--summary');
const accessibilityReviewPath = arg('--accessibility-review');
const matrixDir = arg('--matrix-dir');
const externalPlaytestPath = arg('--external-playtest');
const releaseEvidencePath = arg('--release-evidence');
const outputPath = arg('--output', false) ||
  path.join(path.dirname(summaryPath), 'M0_ACCEPTANCE.json');

const summary = readJson(summaryPath, 'M0 technical summary');
const visualManifestPath = path.join(matrixDir, 'manifest.json');
const visualManifest = readJson(visualManifestPath, 'Accessibility visual manifest');
const accessibilityReview = readJson(accessibilityReviewPath, 'Accessibility review');
const externalPlaytest = readJson(externalPlaytestPath, 'External playtest record');
const releaseEvidence = readJson(releaseEvidencePath, 'Release evidence');

assert.strictEqual(
  summary.overall,
  'PASS_WITH_MANUAL_ACCEPTANCE_PENDING',
  'Final M0 acceptance requires a complete technical M0 run'
);
assert(typeof summary.gitHead === 'string' && /^[0-9a-f]{40}$/.test(summary.gitHead),
  'Technical summary must bind exact Git HEAD');
assert(summary.evidenceBindings,
  'Technical summary is missing exact evidence bindings');

const commitSha = summary.gitHead;
const currentHead = childProcess.execFileSync(
  'git', ['rev-parse', 'HEAD'], { cwd: repo, encoding: 'utf8' }
).trim();
const trackedDiff = childProcess.spawnSync(
  'git', ['diff', '--quiet', 'HEAD', '--'], { cwd: repo }
);
const stagedDiff = childProcess.spawnSync(
  'git', ['diff', '--cached', '--quiet', '--'], { cwd: repo }
);
assert.strictEqual(currentHead, commitSha,
  'Final M0 acceptance must run from the exact candidate checkout');
assert.strictEqual(trackedDiff.status, 0,
  'Final M0 acceptance rejects tracked source changes after technical verification');
assert.strictEqual(stagedDiff.status, 0,
  'Final M0 acceptance rejects staged source changes after technical verification');

assert.strictEqual(visualManifest.gitHead, commitSha,
  'Visual manifest commit does not match technical M0 candidate');
assert.strictEqual(accessibilityReview.candidate.commitSha, commitSha,
  'Accessibility review commit does not match technical M0 candidate');
assert.strictEqual(releaseEvidence.source.gitHead, commitSha,
  'Release evidence commit does not match technical M0 candidate');
assert.strictEqual(externalPlaytest.candidate.commitSha, commitSha,
  'External playtest commit does not match technical M0 candidate');

const visualManifestSha256 = sha256(visualManifestPath);
const releaseEvidenceSha256 = sha256(releaseEvidencePath);

assert.strictEqual(
  summary.evidenceBindings.visualManifestSha256,
  visualManifestSha256,
  'Technical summary visual-manifest hash does not match reviewed evidence'
);
assert.strictEqual(
  summary.evidenceBindings.releaseEvidenceSha256,
  releaseEvidenceSha256,
  'Technical summary release-evidence hash does not match player candidate evidence'
);
assert.strictEqual(
  summary.evidenceBindings.releaseSourceCommit,
  commitSha,
  'Technical summary release source commit drifted'
);
assert.strictEqual(
  summary.evidenceBindings.installerSha256,
  releaseEvidence.artifacts.installer.sha256,
  'Technical summary installer hash does not match release evidence'
);
assert.strictEqual(
  summary.evidenceBindings.portableZipSha256,
  releaseEvidence.artifacts.portableZip.sha256,
  'Technical summary portable ZIP hash does not match release evidence'
);
assert(releaseEvidence.persistenceVerification,
  'Final M0 acceptance requires release persistence verification evidence');
assert.strictEqual(releaseEvidence.persistenceVerification.desktopSaveRestart, 'PASS',
  'Final M0 acceptance requires verified installed save/restart persistence');
assert.strictEqual(
  releaseEvidence.persistenceVerification.desktopSaveBackupOnlyRecovery,
  'PASS',
  'Final M0 acceptance requires verified backup-only crash-window recovery'
);

runValidator('validate-m0-accessibility-review.js', [
  '--record', accessibilityReviewPath,
  '--matrix-dir', matrixDir
]);
runValidator('validate-m0-external-playtest.js', [
  '--record', externalPlaytestPath,
  '--release-evidence', releaseEvidencePath
]);

assert.strictEqual(accessibilityReview.result, 'PASS',
  'Accessibility review is not PASS');
assert.strictEqual(externalPlaytest.result, 'PASS',
  'External playtest is not PASS');

const acceptance = {
  schemaVersion: 1,
  milestone: 'M0-reliable-first-wake-benchmark',
  status: 'PASS',
  acceptedAt: new Date().toISOString(),
  candidate: {
    commitSha,
    technicalSummarySha256: sha256(summaryPath),
    visualManifestSha256,
    accessibilityReviewSha256: sha256(accessibilityReviewPath),
    releaseEvidenceSha256,
    installer: {
      filename: releaseEvidence.artifacts.installer.filename,
      sha256: releaseEvidence.artifacts.installer.sha256,
      bytes: releaseEvidence.artifacts.installer.bytes
    },
    portableZip: {
      filename: releaseEvidence.artifacts.portableZip.filename,
      sha256: releaseEvidence.artifacts.portableZip.sha256,
      bytes: releaseEvidence.artifacts.portableZip.bytes
    },
    externalPlaytestSha256: sha256(externalPlaytestPath)
  },
  humanAcceptance: {
    accessibilityReviewer: accessibilityReview.reviewer.id,
    accessibilityReviewedAt: accessibilityReview.reviewer.reviewedAt,
    externalParticipant: externalPlaytest.participant.id,
    externalReviewer: externalPlaytest.reviewer,
    externalReviewedAt: externalPlaytest.reviewedAt
  }
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(acceptance, null, 2) + '\n', 'utf8');

console.log(JSON.stringify({
  status: 'PASS',
  milestone: acceptance.milestone,
  commitSha,
  output: outputPath,
  acceptanceSha256: sha256(outputPath)
}));
