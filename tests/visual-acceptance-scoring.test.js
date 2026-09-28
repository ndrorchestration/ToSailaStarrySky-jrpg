"use strict";
const assert = require('assert');
const { scoreResults } = require('../scripts/score-visual-acceptance.js');

const scores = {
  cohesion:4.2, readability:4.3, appeal:4.0, identity:4.2,
  worldDepth:4.0, characterQuality:3.8, shipQuality:4.2, productionCredibility:4.1
};
const candidate = {
  commit:'a'.repeat(40),
  packageSha256:'b'.repeat(64),
  evidenceManifestSha256:'c'.repeat(64)
};
const passing = {
  schema:'AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS_V1',
  candidate,
  participants:Array.from({length:5},(_,i)=>({
    id:'P'+(i+1),
    independentOfImplementation:true,
    minutes:20,
    scores:{...scores},
    sameGamePass:true,
    dragonflyRecallPass:true,
    severity1Blocker:false
  }))
};

const result = scoreResults(passing);
assert(result.weightedAverage >= 4.0);
assert.strictEqual(result.sameGameRate, 1);
assert.strictEqual(result.dragonflyRecallRate, 1);

const missingScore = JSON.parse(JSON.stringify(passing));
missingScore.participants[0].scores.cohesion = null;
assert.throws(() => scoreResults(missingScore), /VISUAL_ACCEPTANCE_FAIL/);

const unboundCandidate = JSON.parse(JSON.stringify(passing));
unboundCandidate.candidate.packageSha256 = 'REPLACE';
assert.throws(() => scoreResults(unboundCandidate), /packageSha256/);

const nonIndependent = JSON.parse(JSON.stringify(passing));
nonIndependent.participants[0].independentOfImplementation = false;
assert.throws(() => scoreResults(nonIndependent), /independence not established/);

const duplicate = JSON.parse(JSON.stringify(passing));
duplicate.participants[1].id = duplicate.participants[0].id;
assert.throws(() => scoreResults(duplicate), /duplicate participant id/);

console.log('Aetherwake visual acceptance scorer: PASS');
