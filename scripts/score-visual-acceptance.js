"use strict";
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const contract = JSON.parse(fs.readFileSync(path.join(root, 'docs', 'visual-style-contract.json'), 'utf8'));

function scoreResults(results) {
  if (!results || results.schema !== 'AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS_V1') throw new Error('VISUAL_ACCEPTANCE_FAIL: schema mismatch');
  const candidate = results.candidate || {};
  if (typeof candidate.commit !== 'string' || !/^[0-9a-f]{40}$/i.test(candidate.commit)) {
    throw new Error('VISUAL_ACCEPTANCE_FAIL: candidate commit must be an exact 40-character SHA');
  }
  if (typeof candidate.packageSha256 !== 'string' || !/^[0-9a-f]{64}$/i.test(candidate.packageSha256)) {
    throw new Error('VISUAL_ACCEPTANCE_FAIL: candidate packageSha256 must be an exact SHA-256');
  }
  if (typeof candidate.evidenceManifestSha256 !== 'string' || !/^[0-9a-f]{64}$/i.test(candidate.evidenceManifestSha256)) {
    throw new Error('VISUAL_ACCEPTANCE_FAIL: candidate evidenceManifestSha256 must be an exact SHA-256');
  }
  if (typeof candidate.protocolSha256 !== 'string' || !/^[0-9a-f]{64}$/i.test(candidate.protocolSha256)) {
    throw new Error('VISUAL_ACCEPTANCE_FAIL: candidate protocolSha256 must be an exact SHA-256');
  }

  const participants = results.participants || [];
  if (participants.length < contract.acceptance.playtesters) throw new Error('VISUAL_ACCEPTANCE_FAIL: fewer than required participants');
  const categories = contract.acceptance.categories;
  const sums = Object.fromEntries(Object.keys(categories).map(key => [key, 0]));
  let sameGame = 0;
  let dragonfly = 0;
  const participantIds = new Set();
  for (const participant of participants) {
    if (!participant || typeof participant.id !== 'string' || !participant.id.trim()) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: participant id missing');
    }
    if (participantIds.has(participant.id)) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: duplicate participant id ' + participant.id);
    }
    participantIds.add(participant.id);
    if (participant.independentOfImplementation !== true) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: participant independence not established for ' + participant.id);
    }
    if (!Number.isFinite(participant.minutes) || participant.minutes < contract.acceptance.sessionMinutes) throw new Error('VISUAL_ACCEPTANCE_FAIL: ' + participant.id + ' session shorter than required');
    if (participant.severity1Blocker) throw new Error('VISUAL_ACCEPTANCE_FAIL: severity-1 blocker reported by ' + participant.id);
    for (const key of Object.keys(categories)) {
      const value = participant.scores && participant.scores[key];
      if (!Number.isFinite(value) || value < 1 || value > 5) throw new Error('VISUAL_ACCEPTANCE_FAIL: invalid/missing ' + key + ' for ' + participant.id);
      sums[key] += value;
    }
    const same = participant.sameGame || {};
    if (!Number.isInteger(same.aetherwakeCorrect) || same.aetherwakeCorrect < 0 || same.aetherwakeCorrect > 7) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: invalid same-game Aetherwake count for ' + participant.id);
    }
    if (!Number.isInteger(same.decoyCorrect) || same.decoyCorrect < 0 || same.decoyCorrect > 3) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: invalid same-game decoy count for ' + participant.id);
    }
    const sameGameRateForParticipant = same.aetherwakeCorrect / 7;
    if (sameGameRateForParticipant >= contract.acceptance.sameGameBlindTestMinimum) sameGame++;

    const recall = participant.dragonflyRecall || {};
    if (typeof recall.nameRecalled !== 'boolean' ||
        typeof recall.silhouetteDescriptionUnambiguous !== 'boolean' ||
        typeof recall.silhouetteChoiceCorrect !== 'boolean') {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: incomplete Dragonfly recall evidence for ' + participant.id);
    }
    if (recall.nameRecalled && recall.silhouetteDescriptionUnambiguous && recall.silhouetteChoiceCorrect) dragonfly++;

    if (participant.helpRequested === true &&
        (typeof participant.helpGiven !== 'string' || participant.helpGiven.trim().length === 0)) {
      throw new Error('VISUAL_ACCEPTANCE_FAIL: help requested but not documented for ' + participant.id);
    }
  }
  const averages = {};
  let weighted = 0;
  for (const [key, spec] of Object.entries(categories)) {
    averages[key] = sums[key] / participants.length;
    weighted += averages[key] * spec.weight;
    if (averages[key] < spec.minimum) throw new Error('VISUAL_ACCEPTANCE_FAIL: ' + key + ' average ' + averages[key].toFixed(2) + ' below ' + spec.minimum);
  }
  const sameRate = sameGame / participants.length;
  const dragonRate = dragonfly / participants.length;
  if (sameRate < contract.acceptance.sameGameBlindTestMinimum) throw new Error('VISUAL_ACCEPTANCE_FAIL: same-game rate below threshold');
  if (dragonRate < contract.acceptance.dragonflyRecallMinimum) throw new Error('VISUAL_ACCEPTANCE_FAIL: Dragonfly recall below threshold');
  if (weighted < contract.acceptance.weightedMinimum) throw new Error('VISUAL_ACCEPTANCE_FAIL: weighted average ' + weighted.toFixed(2) + ' below threshold');
  return { weightedAverage: weighted, categoryAverages: averages, sameGameRate: sameRate, dragonflyRecallRate: dragonRate, participantCount: participants.length };
}

if (require.main === module) {
  const input = process.argv[2] || path.join(root, 'visual-acceptance-results.json');
  if (!fs.existsSync(input)) throw new Error('VISUAL_ACCEPTANCE_FAIL: result file missing: ' + input);
  const result = scoreResults(JSON.parse(fs.readFileSync(input, 'utf8')));
  console.log('AETHERWAKE_VISUAL_ACCEPTANCE=PASS');
  console.log(JSON.stringify(result, null, 2));
}
module.exports = { scoreResults };
