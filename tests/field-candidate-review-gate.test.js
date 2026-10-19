const assert = require('assert');
const fs = require('fs');

const art = fs.readFileSync('modules/authored-character-art.js','utf8');
const world = fs.readFileSync('modules/preview-world-presentation.js','utf8');
const evidence = fs.readFileSync('scripts/capture-player-evidence.js','utf8');

assert(art.includes('candidateFieldArt=1'),
  'candidate field art must remain behind an explicit review flag');
assert(world.includes('authored.candidateReviewEnabled()'),
  'world presentation must consult the candidate review gate');
assert(world.includes('authored.drawCandidateFieldCharacter'),
  'review mode must render candidate field sheets before provisional fallback');
assert(world.includes('!provisionalDrawn && protagonist'),
  'candidate review failure must retain the provisional fallback');
assert(evidence.includes('index-embedded.html?candidateFieldArt=1'),
  'human-review evidence must explicitly opt into candidate field art');
assert(evidence.includes("fieldArtReviewMode: 'CANDIDATE_REVIEW_NOT_ADMITTED'"),
  'evidence manifest must disclose candidate-art authority ceiling');
assert(!art.includes('return true; // candidate review default'),
  'candidate review must not be silently enabled by default');

console.log('Aetherwake candidate field-art review gate: PASS');
