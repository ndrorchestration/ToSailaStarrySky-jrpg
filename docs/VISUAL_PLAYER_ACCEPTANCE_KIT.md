# Aetherwake Chapter 1 — Visual Player Acceptance Kit

Status: **G4 HUMAN EVIDENCE PROCEDURE**

This procedure is intentionally separate from developer review. A participant should use the exact candidate build without being coached on what the visuals are supposed to communicate.

## Participants
- Exactly **5 preregistered participant slots** (`P1`–`P5`) for the scored package, each filled by a person who did not implement the current visual tranche.
- Session: **at least 20 elapsed minutes** each, derived from recorded start/end timestamps rather than a manually entered duration.
- Use the same exact-head packaged candidate for every participant.
- Do not explain character names, the Dragonfly, controls, or intended art direction before the session beyond normal launch instructions.

## Evidence bundle
Bind the session to one immutable candidate before testing:
- exact 40-character candidate commit SHA;
- packaged-candidate SHA-256;
- exact visual-evidence `manifest.json` SHA-256;
- SHA-256 of the frozen blind-test protocol.

Record for each participant:
1. a unique participant ID;
2. explicit confirmation that the participant did **not** implement the tested visual tranche;
3. raw session start and end timestamps; the scorer derives elapsed minutes and enforces the minimum;
4. whether help was requested and exactly what help was given;
5. eight 1–5 visual scores;
6. raw same-game counts: how many of the 7 Aetherwake frames were correctly grouped and how many of the 3 decoys were correctly rejected;
7. raw Dragonfly recall observations: name recalled, silhouette description unambiguous, silhouette choice correct;
8. free-response confusion/unfinished notes.

The scorer fails closed if candidate/protocol hashes are placeholders, participant IDs are duplicated, participant independence is not explicitly established, raw same-game counts are invalid, Dragonfly recall fields are incomplete, or requested help is not documented.

## 20-minute session prompts
Ask only after play unless the participant is blocked:
- What did you look at first on the title screen?
- Who appears to be the protagonist?
- What is the airship called?
- What do you think you are supposed to do next?
- Which part looked most finished?
- Which part looked most unfinished?
- In combat, where did you look first?
- Did any UI cover something you wanted to see?
- Did any scene look like it belonged to a different game?

## Blind same-game test
Before the first participant session, choose and record a fixed seven-frame subset from the exact-head evidence bundle. Use the same subset for every participant; do not change it after seeing responses. The subset should span the title/opening, authored environment, dialogue, combat, Dragonfly/flight, and character identity rather than selecting seven near-duplicates.

Show those seven exact-head frames in randomized order alongside three unrelated decoy JRPG/fantasy screenshots that are legally usable for internal testing. Ask which screenshots belong to the same game.

Pass rule is derived from the complete ten-image classification: the participant must correctly group at least **6 of 7** Aetherwake frames **and** achieve at least **80% total accuracy across all 10 images**, including decoy rejection. This prevents an all-positive “everything is Aetherwake” response from passing. Final package rule: at least **80% of participants** pass.

## Dragonfly recognition / recall
After the play session, remove the game from view and ask:
- What was the ship called?
- Describe its silhouette in one sentence.
- Choose the Dragonfly from a small silhouette set if available.

Pass rule is derived from three raw observations: the participant recalls the Dragonfly name, gives an unambiguous silhouette description, and correctly chooses its silhouette. All three must be true for that participant to pass. Final package rule: **≥80%** participant pass rate.

## Weighted visual score
Use 1–5 integer or half-point scores:

| Category | Weight | Floor |
|---|---:|---:|
| Cohesion | 20% | 4.0 |
| Readability | 20% | 4.0 |
| Appeal | 15% | 3.5 |
| Identity | 15% | 4.0 |
| World depth | 10% | 3.5 |
| Character quality | 10% | 3.5 |
| Ship quality | 5% | 4.0 |
| Production credibility | 5% | 4.0 |

Final visual acceptance requires:
- weighted group average **≥4.0**;
- every category group average at or above its floor;
- same-game participant pass rate **≥80%**;
- Dragonfly participant pass rate **≥80%**;
- no unresolved severity-1 visual/readability blocker;
- technical visual performance verifier remains PASS on the exact candidate.

## Result file
After the frozen protocol exists, generate `visual-acceptance-results.json` with:

`npm run prepare:visual-acceptance-results`

This copies the exact candidate commit, package SHA-256, evidence-manifest SHA-256, and actual frozen-protocol SHA-256 directly from `visual-acceptance-protocol.json`; do not manually transcribe those bindings. Then fill only the participant observation fields. Set `independentOfImplementation: true` only when that fact is established for the participant. Then run:

`npm run score:visual-acceptance`

The scorer is fail-closed: incomplete participant/category data does not produce a PASS.

## G4 authority boundary
Automated visual tests, screenshots, and developer scoring can prepare G4 but cannot close it. G4 closes only from the exact candidate's human evidence plus the technical gates.


## Frozen blind-test protocol
Before participant P1 begins, create the protocol artifact from `docs/visual-acceptance-protocol-template.json`.

The preregistered Aetherwake set is fixed to these seven exact evidence frames:
- `00-title-screen.png`
- `00a-opening-world-reveal.png`
- `01-first-wake-dock-walk.png`
- `00b-first-wake-ionia-arrival.png`
- `03-dialogue-ionia.png`
- `04-combat-sky-predator.png`
- `05-dragonfly-flight.png`

Add exactly three legally usable decoy image files and choose a fixed order seed. Then run:

`npm run prepare:visual-acceptance-protocol -- --package <candidate-package> --seed <fixed-seed> --decoy <d1> --decoy <d2> --decoy <d3>`

The preparer requires a clean exact-head worktree, hashes the packaged candidate, evidence manifest, all seven Aetherwake frames, and all three decoys, and writes `visual-acceptance-protocol.json`. Its SHA-256 goes into `candidate.protocolSha256` in the result file.

`npm run score:visual-acceptance` now hashes the real protocol artifact and cross-checks its commit/package/evidence bindings before scoring participants. Changing the frame set, decoys, candidate, or protocol bytes after testing begins invalidates the binding.


## Participant-slot preregistration
The frozen protocol includes exactly five pseudonymous scored slots: `P1` through `P5`. The scored result must contain that exact set.

Do not silently omit a failed or inconvenient completed session and do not replace a participant after seeing their scores. If a session becomes genuinely unusable for a procedural reason (for example, corrupted recording, wrong candidate launched, or participant turns out not to be independent), document the exclusion and create an explicit protocol amendment before collecting the replacement session. The original attempted session record should remain available for audit.


## Frozen presentation order
The fixed protocol seed is not merely recorded. Protocol preparation deterministically derives and stores the exact ten-image order using IDs for all seven Aetherwake frames and all three decoys. Every scored participant must receive that same frozen artifact order. The G4 scorer rejects a protocol whose stored order does not contain exactly those ten unique artifacts.
