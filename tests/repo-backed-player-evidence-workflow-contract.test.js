const assert = require('assert');
const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '..', '.github', 'workflows', 'player-evidence.yml');
assert(fs.existsSync(workflowPath), 'player evidence workflow must exist');

const workflow = fs.readFileSync(workflowPath, 'utf8');

const requiredFragments = [
  ['name: Aetherwake player evidence', 'workflow must preserve the stable player evidence name'],
  ['branches:', 'workflow must be branch-scoped for the repo-backed fallback'],
  ['evidence/repo-backed-player-evidence-87550366', 'workflow must only auto-run repo-backed export on the temporary evidence branch'],
  ['paths-ignore:', 'workflow must avoid infinite loops after committing evidence files'],
  ['evidence/player-acceptance/**', 'workflow must ignore committed evidence-output paths'],
  ['contents: write', 'workflow must have write permission only for committing evidence back to the temporary branch'],
  ['TEMPORARY_BRANCH_EXPORT_ONLY: true', 'workflow must mark the run as temporary branch export only'],
  ['REPOSITORY_BACKED_EVIDENCE_EXPORT: true', 'workflow must mark the run as repository-backed evidence export'],
  ['npm run test:player-evidence-capture', 'workflow must verify the capture contract before capture'],
  ['node tests/repo-backed-player-evidence-workflow-contract.test.js', 'workflow must verify this branch-only export contract'],
  ['npx playwright install --with-deps chromium', 'workflow must install Chromium before browser capture'],
  ['npm run capture:player-evidence', 'workflow must run the player evidence capture command'],
  ['git add -f evidence/player-acceptance/', 'workflow must force-stage only the ignored player evidence output directory'],
  ['git commit -m "evidence: publish player review bundle for ${GITHUB_SHA}"', 'workflow must commit with a bounded evidence message'],
  ['git push origin HEAD:evidence/repo-backed-player-evidence-87550366', 'workflow must push only to the temporary evidence branch'],
  ['VISUAL_ACCEPTANCE=PENDING', 'workflow must preserve visual acceptance boundary'],
  ['HUMAN_PLAYER_ACCEPTANCE=PENDING', 'workflow must preserve human/player acceptance boundary'],
];

for (const [fragment, message] of requiredFragments) {
  assert(workflow.includes(fragment), message);
}

assert(!workflow.includes('actions/upload-artifact@'),
  'repo-backed fallback must not rely on Actions artifact storage on this temporary branch');
assert(!workflow.includes('retention-days:'),
  'repo-backed fallback must not imply artifact retention semantics on this temporary branch');

console.log('REPO_BACKED_PLAYER_EVIDENCE_WORKFLOW_CONTRACT=PASS');
