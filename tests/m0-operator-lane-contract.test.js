'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const script = fs.readFileSync(
  path.join(repo, 'scripts', 'run-m0-operator.ps1'),
  'utf8'
);

assert(script.includes('requires readable Git HEAD provenance'),
  'operator lane must require exact Git provenance');
assert(script.includes('requires a named branch; detached HEAD is not allowed'),
  'operator lane must reject detached HEAD');
assert(script.includes('requires a clean working tree'),
  'operator lane must start from a clean checkout');
assert(script.includes('admit-title-audio.ps1') && script.includes('-Commit'),
  'operator lane must use governed committed title-audio admission');
assert(script.includes('verify-m0-local.ps1'),
  'operator lane must run the full local M0 verifier');
assert(script.includes("PASS_WITH_MANUAL_ACCEPTANCE_PENDING"),
  'operator lane must not claim final M0 acceptance');
assert(script.includes("accessibilityVisualReview -ne 'PENDING_HUMAN_REVIEW'"),
  'operator lane must preserve pending accessibility review');
assert(script.includes("uncoachedExternalPlayer -ne 'NOT_RUN'"),
  'operator lane must preserve external-player NOT_RUN state');
assert(script.includes("externalPlaytest.status -ne 'PREPARED_NOT_RUN'"),
  'operator lane must require a prepared-but-not-run playtest packet');
assert(script.includes('M0_OPERATOR_LANE=TECHNICAL_PASS_MANUAL_ACCEPTANCE_PENDING'),
  'operator lane must emit a bounded success marker');
assert(script.includes('ACCESSIBILITY_REVIEW_HTML=') &&
       script.includes('EXTERNAL_PLAYTEST_GUIDE='),
  'operator lane must expose the two human-review packet entry points');

console.log('Aetherwake M0 operator lane contract: PASS');
