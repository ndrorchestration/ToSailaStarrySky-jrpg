'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

function arg(name, fallback) {
  const i = args.indexOf(name);
  if (i < 0) return fallback;
  assert(args[i + 1], 'Missing value for ' + name);
  return path.resolve(args[i + 1]);
}

const summaryPath = arg(
  '--summary',
  path.join(repo, 'artifacts', 'm0-local-verification', 'summary.json')
);
const outputPath = arg(
  '--output',
  path.join(repo, 'artifacts', 'm0-manual-acceptance', 'index.html')
);

assert(fs.existsSync(summaryPath), 'M0 local summary missing');
const summaryBytes = fs.readFileSync(summaryPath);
const summary = JSON.parse(summaryBytes.toString('utf8'));
const summarySha256 = crypto.createHash('sha256').update(summaryBytes).digest('hex');

assert.strictEqual(
  summary.overall,
  'PASS_WITH_MANUAL_ACCEPTANCE_PENDING',
  'Manual-acceptance dashboard requires a technically successful bounded M0 run'
);
assert(summary.gitHead && /^[0-9a-f]{40}$/.test(summary.gitHead),
  'M0 summary must bind exact Git HEAD');
assert(summary.visualMatrix &&
       summary.visualMatrix.status === 'CAPTURED_HUMAN_REVIEW_REQUIRED',
  'Accessibility packet is not ready for human review');
assert(summary.externalPlaytest &&
       summary.externalPlaytest.status === 'PREPARED_NOT_RUN',
  'External playtest packet is not prepared');
assert(summary.manualAcceptance &&
       summary.manualAcceptance.accessibilityVisualReview === 'PENDING_HUMAN_REVIEW',
  'Accessibility acceptance state drifted');
assert.strictEqual(
  summary.manualAcceptance.uncoachedExternalPlayer,
  'NOT_RUN',
  'External-player acceptance state drifted'
);

const requiredPaths = [
  summary.visualMatrix.reviewHtml,
  summary.visualMatrix.reviewRecord,
  summary.externalPlaytest.observerGuide,
  summary.externalPlaytest.record,
  summary.evidenceBindings.releaseEvidencePath
];

for (const item of requiredPaths) {
  assert(typeof item === 'string' && item.length > 0,
    'Manual-acceptance packet path missing');
  assert(fs.existsSync(item), 'Manual-acceptance artifact missing: ' + item);
}

const releaseEvidenceBytes = fs.readFileSync(summary.evidenceBindings.releaseEvidencePath);
const releaseEvidenceSha256 =
  crypto.createHash('sha256').update(releaseEvidenceBytes).digest('hex');
assert.strictEqual(
  releaseEvidenceSha256,
  summary.evidenceBindings.releaseEvidenceSha256,
  'Release evidence bytes do not match M0 summary binding'
);

function rel(target) {
  return path.relative(path.dirname(outputPath), target).replace(/\\/g, '/');
}
function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Aetherwake M0 Manual Acceptance — ${esc(summary.gitHead.slice(0,12))}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:system-ui,sans-serif;max-width:1000px;margin:32px auto;padding:0 20px;line-height:1.5}
.card{border:1px solid #999;padding:18px;margin:18px 0;border-radius:8px}
.warn{border:2px solid #a66;padding:12px;background:#fff8f5}
code{word-break:break-all}
a{font-weight:600}
</style>
</head>
<body>
<h1>Aetherwake M0 Manual Acceptance</h1>
<div class="warn"><strong>Technical verification is complete, but M0 is not accepted yet.</strong> Both human gates below remain blocking.</div>

<h2>Candidate identity</h2>
<ul>
<li>Commit: <code>${esc(summary.gitHead)}</code></li>
<li>M0 summary SHA-256: <code>${esc(summarySha256)}</code></li>
<li>Visual manifest SHA-256: <code>${esc(summary.evidenceBindings.visualManifestSha256)}</code></li>
<li>Release evidence SHA-256: <code>${esc(summary.evidenceBindings.releaseEvidenceSha256)}</code></li>
<li>Installer SHA-256: <code>${esc(summary.evidenceBindings.installerSha256)}</code></li>
<li>Portable ZIP SHA-256: <code>${esc(summary.evidenceBindings.portableZipSha256)}</code></li>
</ul>

<div class="card">
<h2>1. Accessibility visual review — PENDING HUMAN REVIEW</h2>
<p>Review all ${esc(summary.visualMatrix.captureCount)} candidate-bound captures. Do not mark PASS until every capture is inspected and the completed record validates.</p>
<p><a href="${esc(rel(summary.visualMatrix.reviewHtml))}">Open accessibility review contact sheet</a></p>
<p>Record: <code>${esc(rel(summary.visualMatrix.reviewRecord))}</code></p>
<p>Validation command: <code>npm run validate:accessibility-review -- --record "&lt;completed-review.json&gt;" --matrix-dir "artifacts/accessibility-visual-matrix"</code></p>
</div>

<div class="card">
<h2>2. Uncoached external-player playtest — NOT RUN</h2>
<p>Use the exact candidate named above. Do not coach the participant beyond how to launch the supplied standalone build.</p>
<p><a href="${esc(rel(summary.externalPlaytest.observerGuide))}">Open external-playtest observer guide</a></p>
<p>Record: <code>${esc(rel(summary.externalPlaytest.record))}</code></p>
<p>Validation command: <code>npm run validate:external-playtest -- --record "&lt;completed-playtest.json&gt;" --release-evidence "${esc(rel(summary.evidenceBindings.releaseEvidencePath))}"</code></p>
</div>

<h2>Acceptance boundary</h2>
<p>This dashboard is an index over already-bound evidence. It does not modify either human record, cannot set either result to PASS, and is not final M0 authorization.</p>
</body>
</html>`;

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, html, 'utf8');

console.log(JSON.stringify({
  status: 'PASS',
  commitSha: summary.gitHead,
  summarySha256,
  output: outputPath,
  accessibility: 'PENDING_HUMAN_REVIEW',
  externalPlaytest: 'NOT_RUN'
}));
