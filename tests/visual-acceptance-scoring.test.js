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
  evidenceManifestSha256:'c'.repeat(64),
  protocolSha256:'d'.repeat(64)
};
const passing = {
  schema:'AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS_V1',
  candidate,
  participants:Array.from({length:5},(_,i)=>({
    id:'P'+(i+1),
    independentOfImplementation:true,
    minutes:20,
    scores:{...scores},
    sameGame:{aetherwakeCorrect:7,decoyCorrect:3},
    dragonflyRecall:{
      nameRecalled:true,
      silhouetteDescriptionUnambiguous:true,
      silhouetteChoiceCorrect:true
    },
    severity1Blocker:false,
    helpRequested:false,
    helpGiven:''
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

const unboundProtocol = JSON.parse(JSON.stringify(passing));
unboundProtocol.candidate.protocolSha256 = 'REPLACE';
assert.throws(() => scoreResults(unboundProtocol), /protocolSha256/);

const nonIndependent = JSON.parse(JSON.stringify(passing));
nonIndependent.participants[0].independentOfImplementation = false;
assert.throws(() => scoreResults(nonIndependent), /independence not established/);

const duplicate = JSON.parse(JSON.stringify(passing));
duplicate.participants[1].id = duplicate.participants[0].id;
assert.throws(() => scoreResults(duplicate), /duplicate participant id/);

const weakSameGame = JSON.parse(JSON.stringify(passing));
weakSameGame.participants[0].sameGame.aetherwakeCorrect = 5;
const weakResult = scoreResults(weakSameGame);
assert.strictEqual(weakResult.sameGameRate, 0.8);

const incompleteRecall = JSON.parse(JSON.stringify(passing));
incompleteRecall.participants[0].dragonflyRecall.silhouetteChoiceCorrect = null;
assert.throws(() => scoreResults(incompleteRecall), /incomplete Dragonfly recall evidence/);

const undocumentedHelp = JSON.parse(JSON.stringify(passing));
undocumentedHelp.participants[0].helpRequested = true;
undocumentedHelp.participants[0].helpGiven = '';
assert.throws(() => scoreResults(undocumentedHelp), /help requested but not documented/);

console.log('Aetherwake visual acceptance scorer: PASS');
