'use strict';
const { spawnSync } = require('child_process');
const path = require('path');

const root = path.resolve(__dirname, '..');
const env = {
  ...process.env,
  AETHERWAKE_CANDIDATE_FIELD_REVIEW: '1',
  AETHERWAKE_VISUAL_EVIDENCE_DIR: path.join(root, 'visual-evidence-candidate-field'),
};
const result = spawnSync(process.execPath, [path.join(root, 'tests', 'capture-visual-evidence.js')], {
  cwd: root,
  env,
  stdio: 'inherit',
});
if (result.error) throw result.error;
process.exit(result.status === null ? 1 : result.status);
