'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
function arg(name) {
  const i = args.indexOf(name);
  assert(i >= 0 && args[i + 1], 'Missing required argument: ' + name);
  return path.resolve(args[i + 1]);
}

const recordPath = arg('--record');
const releaseEvidencePath = arg('--release-evidence');

assert(fs.existsSync(recordPath), 'External playtest record missing');
assert(fs.existsSync(releaseEvidencePath), 'Release evidence missing');

const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
const releaseBytes = fs.readFileSync(releaseEvidencePath);
const release = JSON.parse(releaseBytes.toString('utf8'));
const releaseEvidenceSha256 =
  crypto.createHash('sha256').update(releaseBytes).digest('hex');

assert.strictEqual(record.version, 1, 'Unsupported external playtest record version');
assert.strictEqual(record.milestone, 'M0-reliable-first-wake-benchmark');

assert(record.candidate, 'Candidate binding missing');
assert.strictEqual(record.candidate.commitSha, release.source.gitHead,
  'Playtest commit does not match release source commit');
assert.strictEqual(record.candidate.releaseEvidenceSha256, releaseEvidenceSha256,
  'Playtest release-evidence hash does not match exact evidence bytes');
assert.strictEqual(record.candidate.installerFilename, release.artifacts.installer.filename,
  'Playtest installer filename does not match release evidence');
assert.strictEqual(record.candidate.installerSha256, release.artifacts.installer.sha256,
  'Playtest installer hash does not match release evidence');
assert.strictEqual(record.candidate.platform, 'Windows',
  'M0 external playtest must use the governed Windows candidate');
assert.strictEqual(record.candidate.playerVerifiedStandalone, true,
  'External playtest PASS requires player-verified standalone execution');

assert(record.participant && typeof record.participant.id === 'string' &&
       record.participant.id.trim(),
  'Participant stable label is required');
assert.strictEqual(record.participant.priorAetherwakeExposure, 'none',
  'PASS requires an uncoached participant with no prior Aetherwake exposure');
assert.strictEqual(record.participant.priorInstructionsBeyondLaunch, 'none',
  'PASS requires no pre-session gameplay coaching');

assert.strictEqual(record.constraints.liveCreatorCoachingAllowed, false);
assert.strictEqual(record.constraints.repositoryKnowledgeRequired, false);
assert.strictEqual(record.constraints.browserDependencyAllowed, false);

const requiredTrue = [
  'installedAndLaunched',
  'understoodNextObjectiveWithoutHelp',
  'combatChoicesIntelligible',
  'saveCreated',
  'processClosedAndRelaunched',
  'saveRestoredCorrectly',
  'nonHappyPathAttempted',
  'nonHappyPathRecovered',
  'firstWakeCompleted'
];
for (const key of requiredTrue) {
  assert.strictEqual(record.observations[key], true,
    'External playtest PASS requires observation=true: ' + key);
}

assert(typeof record.observations.objectiveUnderstandingEvidence === 'string' &&
       record.observations.objectiveUnderstandingEvidence.trim(),
  'Objective comprehension requires recorded evidence');
assert(Array.isArray(record.observations.combatDecisionReasoning) &&
       record.observations.combatDecisionReasoning.length > 0,
  'Combat intelligibility requires recorded reasoning');
assert(typeof record.observations.recoveryReasoning === 'string' &&
       record.observations.recoveryReasoning.trim(),
  'Non-happy-path recovery requires recorded reasoning');

assert(Array.isArray(record.interventions));
assert.strictEqual(record.interventions.length, 0,
  'External playtest PASS cannot include live intervention');
assert(Array.isArray(record.defects),
  'Defects must be an array');
assert(!record.defects.some(item =>
  item && (item.blocking === true || item.severity === 'blocking')),
  'External playtest PASS cannot retain blocking defects');

assert(Number.isFinite(record.completionMinutes) && record.completionMinutes > 0,
  'Completion time must be recorded');
assert(typeof record.reviewer === 'string' && record.reviewer.trim(),
  'Reviewer/observer identity is required');
assert(record.reviewedAt, 'Review timestamp is required');
assert.strictEqual(record.result, 'PASS',
  'External playtest evidence is not PASS');

console.log(JSON.stringify({
  status: 'PASS',
  commitSha: record.candidate.commitSha,
  installerSha256: record.candidate.installerSha256,
  releaseEvidenceSha256,
  participant: record.participant.id,
  reviewer: record.reviewer,
  reviewedAt: record.reviewedAt
}));
