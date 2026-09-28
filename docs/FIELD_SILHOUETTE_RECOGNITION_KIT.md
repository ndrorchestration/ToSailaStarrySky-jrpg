# Aetherwake Field Silhouette Recognition Kit

Status: **HUMAN EVIDENCE PROCEDURE / NOT SELF-CLOSING**

Purpose: provide the independent human-recognition evidence required before a production field pack can be admitted. This procedure is for **production field strips**, not the current provisional bridge art.

## Freeze the candidate first

Before showing anything to a participant:

1. bind the test to one exact 40-character commit SHA;
2. run the pre-promotion mechanical completeness gate for the production strips;
3. render one neutral black silhouette from the same production idle frame/crop for each of Ender, Lyra, Ionia, Reson, and Aepex;
4. freeze those five silhouette images and their mapping before the first response is collected;
5. do not alter the candidate, silhouette crop, scale, or answer key between participants.

The participant must not have implemented the tested character art.

## Participant procedure

Use at least **5 independent participants**. Each participant sees all five silhouettes, one at a time, in a randomized order. For every silhouette, ask only:

**Which Aetherwake protagonist is this: Ender, Lyra, Ionia, Reson, or Aepex?**

Do not show portraits, names, costume descriptions, or other hints during the trial. Record exactly one answer per target. Do not coach or correct answers until all five trials are complete.

## Scoring

Create `field-silhouette-results.json` from `docs/field-silhouette-recognition-template.json`, then run:

`npm run score:field-silhouette-recognition`

The scorer is fail-closed. It requires:

- a full exact-head SHA;
- at least 5 participants;
- unique participant IDs;
- explicit independence from implementation;
- exactly one trial for each of the five protagonists per participant;
- **≥80% overall correct recognition**.

A **60% per-character anti-collapse floor** is also enforced so a single indistinguishable protagonist cannot be hidden by strong recognition of the other four.

## Admission handoff

A passing scorer result supplies the human portion of each character's field-art admission evidence. Copy the participant count and overall correct rate into the relevant `AETHERWAKE_FIELD_ART_ADMISSION_V1` receipt only after the scorer passes on the same candidate. The separate runtime evidence gates and post-promotion admission verifier must still pass.

Current provisional field art may be used to rehearse this procedure, but a rehearsal result is **not admissible production evidence**.
