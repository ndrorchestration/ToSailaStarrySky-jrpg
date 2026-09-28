"use strict";
const fs = require("fs");
const path = require("path");

const IDS = Object.freeze(["ender","lyra","ionia","reson","aepex"]);
const SCHEMA = "AETHERWAKE_FIELD_SILHOUETTE_RECOGNITION_V1";

function score(results) {
  if (!results || results.schema !== SCHEMA) throw new Error("FIELD_SILHOUETTE_FAIL: schema mismatch");
  if (typeof results.exactHead !== "string" || !/^[0-9a-f]{40}$/i.test(results.exactHead)) {
    throw new Error("FIELD_SILHOUETTE_FAIL: exactHead must be a 40-character commit SHA");
  }
  const participants = results.participants || [];
  if (participants.length < 5) throw new Error("FIELD_SILHOUETTE_FAIL: fewer than 5 participants");

  const seen = new Set();
  const correctById = Object.fromEntries(IDS.map(id => [id, 0]));
  const totalById = Object.fromEntries(IDS.map(id => [id, 0]));
  let correct = 0;
  let total = 0;

  for (const participant of participants) {
    if (!participant || typeof participant.id !== "string" || !participant.id.trim()) {
      throw new Error("FIELD_SILHOUETTE_FAIL: participant id missing");
    }
    if (seen.has(participant.id)) throw new Error("FIELD_SILHOUETTE_FAIL: duplicate participant id " + participant.id);
    seen.add(participant.id);
    if (participant.independentOfImplementation !== true) {
      throw new Error("FIELD_SILHOUETTE_FAIL: independence not established for " + participant.id);
    }
    const trials = participant.trials || [];
    if (trials.length !== IDS.length) {
      throw new Error("FIELD_SILHOUETTE_FAIL: " + participant.id + " must complete exactly 5 trials");
    }
    const targets = new Set();
    for (const trial of trials) {
      if (!IDS.includes(trial.targetId)) throw new Error("FIELD_SILHOUETTE_FAIL: unknown targetId");
      if (!IDS.includes(trial.answerId)) throw new Error("FIELD_SILHOUETTE_FAIL: unknown answerId");
      if (targets.has(trial.targetId)) throw new Error("FIELD_SILHOUETTE_FAIL: repeated target for " + participant.id);
      targets.add(trial.targetId);
      total++;
      totalById[trial.targetId]++;
      if (trial.answerId === trial.targetId) {
        correct++;
        correctById[trial.targetId]++;
      }
    }
    if (targets.size !== IDS.length) throw new Error("FIELD_SILHOUETTE_FAIL: incomplete target roster");
  }

  const overallRate = correct / total;
  const perCharacter = Object.fromEntries(IDS.map(id => [id, correctById[id] / totalById[id]]));
  if (overallRate < 0.80) throw new Error("FIELD_SILHOUETTE_FAIL: overall recognition below 80%");
  for (const id of IDS) {
    if (perCharacter[id] < 0.60) {
      throw new Error("FIELD_SILHOUETTE_FAIL: " + id + " recognition below 60% anti-collapse floor");
    }
  }
  return { participantCount: participants.length, trialCount: total, correct, correctRate: overallRate, perCharacter };
}

if (require.main === module) {
  const file = process.argv[2] || path.resolve(__dirname, "..", "field-silhouette-results.json");
  if (!fs.existsSync(file)) throw new Error("FIELD_SILHOUETTE_FAIL: result file missing: " + file);
  const result = score(JSON.parse(fs.readFileSync(file, "utf8")));
  console.log("AETHERWAKE_FIELD_SILHOUETTE_RECOGNITION=PASS");
  console.log(JSON.stringify(result, null, 2));
}

module.exports = { IDS, SCHEMA, score };
