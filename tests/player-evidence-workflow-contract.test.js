const assert = require('assert');
const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '..', '.github', 'workflows', 'player-evidence.yml');
assert(fs.existsSync(workflowPath), 'manual player evidence workflow must exist');

const workflow = fs.readFileSync(workflowPath, 'utf8');

assert(workflow.includes('name: Aetherwake player evidence'),
  'workflow must have a stable player evidence name');
assert(workflow.includes('workflow_dispatch:'),
  'workflow must be manually dispatchable');
assert(workflow.includes('npm run test:player-evidence-capture'),
  'workflow must run the capture contract before capture');
assert(workflow.includes('npx playwright install --with-deps chromium'),
  'workflow must install Chromium before browser capture');
assert(workflow.includes('npm run capture:player-evidence'),
  'workflow must run the player evidence capture command');
assert(workflow.includes('actions/upload-artifact@'),
  'workflow must attempt to publish a retrievable artifact');
assert(workflow.includes('evidence/player-acceptance/'),
  'workflow must upload the generated player-acceptance evidence directory');
assert(workflow.includes('if-no-files-found: error'),
  'workflow must fail closed when capture output is missing');
assert(workflow.includes('retention-days:'),
  'workflow must set an explicit artifact retention period');

console.log('Aetherwake player evidence workflow contract: PASS');
