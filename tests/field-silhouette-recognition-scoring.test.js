"use strict";
const assert = require("assert");
const { score, IDS } = require("../scripts/score-field-silhouette-recognition.js");

function participant(index) {
  return {
    id: "P" + index,
    independentOfImplementation: true,
    trials: IDS.map(id => ({ targetId: id, answerId: id }))
  };
}

const passing = {
  schema: "AETHERWAKE_FIELD_SILHOUETTE_RECOGNITION_V1",
  exactHead: "a".repeat(40),
  participants: [1,2,3,4,5].map(participant)
};
const result = score(passing);
assert.strictEqual(result.participantCount, 5);
assert.strictEqual(result.trialCount, 25);
assert.strictEqual(result.correctRate, 1);

const tooFew = JSON.parse(JSON.stringify(passing));
tooFew.participants.pop();
assert.throws(() => score(tooFew), /fewer than 5 participants/);

const nonIndependent = JSON.parse(JSON.stringify(passing));
nonIndependent.participants[0].independentOfImplementation = false;
assert.throws(() => score(nonIndependent), /independence not established/);

const duplicate = JSON.parse(JSON.stringify(passing));
duplicate.participants[1].id = duplicate.participants[0].id;
assert.throws(() => score(duplicate), /duplicate participant id/);

const badHead = JSON.parse(JSON.stringify(passing));
badHead.exactHead = "REPLACE";
assert.throws(() => score(badHead), /40-character commit SHA/);

const collapsed = JSON.parse(JSON.stringify(passing));
for (let i = 0; i < 3; i++) {
  collapsed.participants[i].trials.find(t => t.targetId === "aepex").answerId = "reson";
}
assert.throws(() => score(collapsed), /aepex recognition below 60%/);

const lowOverall = JSON.parse(JSON.stringify(passing));
for (const p of lowOverall.participants) {
  p.trials[0].answerId = "lyra";
  p.trials[1].answerId = "ender";
}
assert.throws(() => score(lowOverall), /overall recognition below 80%/);

console.log("Aetherwake field silhouette recognition scorer: PASS");
