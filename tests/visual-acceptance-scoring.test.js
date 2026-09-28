"use strict";
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { scoreResults, verifyProtocolBinding } = require('../scripts/score-visual-acceptance.js');

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

const allMarkedAetherwake = JSON.parse(JSON.stringify(passing));
allMarkedAetherwake.participants[0].sameGame.aetherwakeCorrect = 7;
allMarkedAetherwake.participants[0].sameGame.decoyCorrect = 0;
const allMarkedResult = scoreResults(allMarkedAetherwake);
assert.strictEqual(allMarkedResult.sameGameRate, 0.8,
  'a participant who labels every screenshot as Aetherwake must fail the blind same-game test');

const incompleteRecall = JSON.parse(JSON.stringify(passing));
incompleteRecall.participants[0].dragonflyRecall.silhouetteChoiceCorrect = null;
assert.throws(() => scoreResults(incompleteRecall), /incomplete Dragonfly recall evidence/);

const undocumentedHelp = JSON.parse(JSON.stringify(passing));
undocumentedHelp.participants[0].helpRequested = true;
undocumentedHelp.participants[0].helpGiven = '';
assert.throws(() => scoreResults(undocumentedHelp), /help requested but not documented/);

console.log('Aetherwake visual acceptance scorer: PASS');


const protocol = {
  schema:'AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_V1',
  candidate:{
    commit:candidate.commit,
    packageSha256:candidate.packageSha256,
    evidenceManifestSha256:candidate.evidenceManifestSha256
  },
  aetherwakeFrames:['a','b','c','d','e','f','g'],
  decoys:[
    {id:'D1',sha256:'1'.repeat(64)},
    {id:'D2',sha256:'2'.repeat(64)},
    {id:'D3',sha256:'3'.repeat(64)}
  ],
  participantPlan:{requiredCount:5,ids:['P1','P2','P3','P4','P5']},
  presentation:{
    orderSeed:'fixed-seed',
    order:['A:a','A:b','A:c','A:d','A:e','A:f','A:g','D:D1','D:D2','D:D3']
  },
  frozenBeforeFirstSession:true
};
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'aetherwake-g4-'));
const protocolPath = path.join(tempDir, 'protocol.json');
fs.writeFileSync(protocolPath, JSON.stringify(protocol));
const protocolHash = crypto.createHash('sha256').update(fs.readFileSync(protocolPath)).digest('hex');
const bound = JSON.parse(JSON.stringify(passing));
bound.candidate.protocolSha256 = protocolHash;
assert.strictEqual(verifyProtocolBinding(bound, protocolPath).schema, 'AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_V1');

const mismatched = JSON.parse(JSON.stringify(bound));
mismatched.candidate.protocolSha256 = 'e'.repeat(64);
assert.throws(() => verifyProtocolBinding(mismatched, protocolPath), /protocol SHA-256 mismatch/);


const omittedParticipant = JSON.parse(JSON.stringify(bound));
omittedParticipant.participants.pop();
assert.throws(() => verifyProtocolBinding(omittedParticipant, protocolPath), /frozen participant plan/);

const replacedParticipant = JSON.parse(JSON.stringify(bound));
replacedParticipant.participants[4].id = 'P6';
assert.throws(() => verifyProtocolBinding(replacedParticipant, protocolPath), /frozen participant plan/);


const invalidOrderProtocol = JSON.parse(JSON.stringify(protocol));
invalidOrderProtocol.presentation.order = invalidOrderProtocol.presentation.order.slice(0, 9);
const invalidOrderPath = path.join(tempDir, 'invalid-order.json');
fs.writeFileSync(invalidOrderPath, JSON.stringify(invalidOrderProtocol));
const invalidOrderHash = crypto.createHash('sha256').update(fs.readFileSync(invalidOrderPath)).digest('hex');
const invalidOrderResults = JSON.parse(JSON.stringify(passing));
invalidOrderResults.candidate.protocolSha256 = invalidOrderHash;
assert.throws(() => verifyProtocolBinding(invalidOrderResults, invalidOrderPath), /presentation order/);
