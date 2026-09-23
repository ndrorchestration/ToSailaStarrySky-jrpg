'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const generator = fs.readFileSync(
  path.join(repo, 'scripts', 'prepare-m0-manual-acceptance.js'),
  'utf8'
);
const operator = fs.readFileSync(
  path.join(repo, 'scripts', 'run-m0-operator.ps1'),
  'utf8'
);
const packageJson = require('../package.json');

assert.strictEqual(
  packageJson.scripts['prepare:m0-manual-acceptance'],
  'node scripts/prepare-m0-manual-acceptance.js',
  'manual acceptance dashboard must have a stable command'
);
assert(generator.includes("PASS_WITH_MANUAL_ACCEPTANCE_PENDING"),
  'dashboard must require bounded technical M0 success');
assert(generator.includes("PENDING_HUMAN_REVIEW"),
  'dashboard must preserve pending accessibility review');
assert(generator.includes("uncoachedExternalPlayer"),
  'dashboard must preserve the external-player acceptance boundary');
assert(generator.includes("'NOT_RUN'"),
  'dashboard must require external playtest to remain NOT_RUN');
assert(generator.includes('summary.evidenceBindings.releaseEvidenceSha256'),
  'dashboard must bind release evidence identity');
assert(generator.includes('summary.evidenceBindings.installerSha256') &&
       generator.includes('summary.evidenceBindings.portableZipSha256'),
  'dashboard must expose exact player artifact hashes');
assert(generator.includes('This dashboard is an index over already-bound evidence.'),
  'dashboard must explicitly deny acceptance authority');
assert(!generator.includes("record.result = 'PASS'"),
  'dashboard must not mutate human evidence to PASS');

assert(operator.includes('npm run prepare:m0-manual-acceptance'),
  'operator lane must generate the manual acceptance dashboard after technical M0');
assert(operator.includes('MANUAL_ACCEPTANCE_DASHBOARD='),
  'operator lane must expose the dashboard path');

console.log('Aetherwake M0 manual acceptance dashboard contract: PASS');
