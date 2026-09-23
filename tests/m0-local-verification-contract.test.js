'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const script = fs.readFileSync(
  path.join(repo, 'scripts', 'verify-m0-local.ps1'),
  'utf8'
);
const doc = fs.readFileSync(
  path.join(repo, 'docs', 'M0_LOCAL_VERIFICATION.md'),
  'utf8'
);
const visualReviewProtocolPath = path.join(repo, 'docs', 'M0_ACCESSIBILITY_VISUAL_REVIEW.md');
const visualReviewTemplatePath = path.join(repo, 'docs', 'm0-accessibility-visual-review.template.json');
assert(fs.existsSync(visualReviewProtocolPath),
  'candidate-bound accessibility visual-review protocol is missing');
assert(fs.existsSync(visualReviewTemplatePath),
  'candidate-bound accessibility visual-review template is missing');
const visualReviewTemplate = JSON.parse(fs.readFileSync(visualReviewTemplatePath, 'utf8'));
assert.strictEqual(visualReviewTemplate.candidate.captureCount, 54,
  'visual-review template must bind the current 54-frame matrix');
assert.strictEqual(visualReviewTemplate.result, 'NOT_RUN',
  'visual-review template must fail closed until a human review occurs');
assert.strictEqual(visualReviewTemplate.coverage.allManifestCapturesReviewed, false,
  'visual-review template must not pre-approve matrix coverage');

for (const gate of [
  'test:save-system',
  'test:save-runtime',
  'test:save-payload',
  'test:save-interrupted-write',
  'test:persistence-coverage',
  'test:first-wake-benchmark',
  'test:input-runtime',
  'test:input-accessibility',
  'test:accessibility-rendering',
  'test:audio-assets',
  'test:title-audio-admission',
  'test:title-audio-runtime',
  'test:m0-title-audio-ready',
  'test:world-authority',
  'test:production-method',
  'test:smoke',
  'test:first-wake-benchmark-live',
  'test:controller-parity-live',
  'test:accessibility-visual-matrix'
]) {
  assert(script.includes(gate), 'M0 local verifier missing gate: ' + gate);
}

assert(script.includes('captureCount -ne 54'),
  'M0 local verifier must require the 54-frame matrix');
assert(script.includes("reviewStatus -ne 'HUMAN_REVIEW_REQUIRED'"),
  'M0 local verifier must preserve human visual review');
assert(script.includes("Invoke-Gate 'prepare:accessibility-review' 'npm run prepare:accessibility-review'"),
  'M0 local verifier must generate a deterministic accessibility review packet');
assert(script.includes('ACCESSIBILITY_REVIEW_HTML=') && script.includes('ACCESSIBILITY_REVIEW_RECORD='),
  'M0 local verifier must expose generated review packet paths');
assert(script.includes('build-windows-release.ps1'),
  'M0 local verifier must invoke exact Windows package verification by default');
assert(script.includes('summary.json'),
  'M0 local verifier must emit a machine-readable summary');
assert(script.includes('requires a clean working tree'),
  'M0 local verifier must fail closed on uncommitted working-tree changes');
assert(script.includes('INCOMPLETE_REQUIRED_PREREQUISITE_SKIPPED'),
  'M0 local verifier must not pass when install/browser prerequisites are skipped');
assert(script.includes('developmentSkips'),
  'M0 summary must record development skip provenance');
assert(script.includes('requires readable Git HEAD provenance'),
  'M0 local verifier must fail closed when exact Git HEAD provenance is unavailable');
assert(doc.includes('clean working tree'),
  'documentation must require a clean working tree for exact-head claims');
assert(doc.includes('not the same as final M0 acceptance'),
  'documentation must not overclaim local script success');
assert(script.includes('PASS_WITH_MANUAL_ACCEPTANCE_PENDING'),
  'local verifier must not report final M0 acceptance');
assert(script.includes('INCOMPLETE_REQUIRED_GATE_SKIPPED'),
  'skipping the Windows package gate must produce an incomplete non-passing result');
assert(script.includes("status = 'SKIPPED_DEVELOPMENT_ONLY'"),
  'development-only Windows-package skips must be explicit in the summary');
assert(script.includes("uncoachedExternalPlayer = 'NOT_RUN'"),
  'local verifier summary must expose the uncoached-player gate as not run');
assert(script.includes("accessibilityVisualReview = 'PENDING_HUMAN_REVIEW'"),
  'local verifier summary must expose pending visual review');
assert(script.includes("accessibilityReviewProtocol = 'docs/M0_ACCESSIBILITY_VISUAL_REVIEW.md'"),
  'local verifier summary must route visual acceptance to its human-review protocol');
assert(script.includes("accessibilityEvidenceTemplate = 'docs/m0-accessibility-visual-review.template.json'"),
  'local verifier summary must expose the candidate-bound visual-review evidence template');
assert(doc.includes('M0_ACCESSIBILITY_VISUAL_REVIEW.md'),
  'local M0 documentation must route visual acceptance to its protocol');
assert(doc.includes('M0_EXTERNAL_PLAYTEST.md'),
  'documentation must route manual player-comprehension evidence to its protocol');
assert(doc.includes('uncoached external-player completion pass'),
  'documentation must preserve the external-player acceptance dependency');
assert(doc.includes('test:m0-title-audio-ready'),
  'documentation must name the strict M0 title-audio readiness gate');
assert(doc.includes('fail closed unless it is admitted and Git-tracked'),
  'documentation must distinguish development fallback from M0 readiness');
assert(doc.includes('admit:title-audio'),
  'documentation must route title audio through governed admission');

console.log('Aetherwake M0 local verification orchestrator: PASS');
