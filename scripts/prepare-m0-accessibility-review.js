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

const matrixDir = arg(
  '--matrix-dir',
  path.join(repo, 'artifacts', 'accessibility-visual-matrix')
);
const recordOut = arg(
  '--record-out',
  path.join(matrixDir, 'human-review.json')
);
const htmlOut = arg(
  '--html-out',
  path.join(matrixDir, 'review-index.html')
);

const manifestPath = path.join(matrixDir, 'manifest.json');
assert(fs.existsSync(manifestPath), 'Accessibility visual manifest missing');

const manifestBytes = fs.readFileSync(manifestPath);
const manifest = JSON.parse(manifestBytes.toString('utf8'));
const manifestSha256 = crypto.createHash('sha256').update(manifestBytes).digest('hex');

assert.strictEqual(manifest.schemaVersion, 2,
  'Accessibility visual manifest must use provenance schema v2');
assert(typeof manifest.gitHead === 'string' && /^[0-9a-f]{40}$/.test(manifest.gitHead),
  'Accessibility visual manifest must bind exact Git HEAD');
assert.strictEqual(manifest.captureCount, 54,
  'Accessibility visual manifest must contain exactly 54 captures');
assert(Array.isArray(manifest.captures) && manifest.captures.length === 54,
  'Accessibility visual manifest capture list must contain 54 records');

for (const capture of manifest.captures) {
  const file = path.join(matrixDir, capture.file);
  assert(fs.existsSync(file), 'Visual capture missing: ' + capture.file);
  const bytes = fs.readFileSync(file);
  assert.strictEqual(bytes.length, capture.bytes,
    'Visual capture byte count drifted: ' + capture.file);
  assert.strictEqual(
    crypto.createHash('sha256').update(bytes).digest('hex'),
    capture.sha256,
    'Visual capture hash drifted: ' + capture.file
  );
}

const template = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'm0-accessibility-visual-review.template.json'),
  'utf8'
));

const record = JSON.parse(JSON.stringify(template));
record.candidate.commitSha = manifest.gitHead;
record.candidate.visualManifestPath = path.relative(
  repo,
  manifestPath
).replace(/\\/g, '/');
record.candidate.visualManifestSha256 = manifestSha256;
record.candidate.captureCount = manifest.captureCount;
record.result = 'NOT_RUN';

fs.mkdirSync(path.dirname(recordOut), { recursive: true });
fs.writeFileSync(recordOut, JSON.stringify(record, null, 2) + '\n', 'utf8');

const groups = [
  ['Text scale', manifest.captures.filter(x => /^scale-/.test(x.file))],
  ['High contrast', manifest.captures.filter(x => /^contrast-high/.test(x.file))],
  ['Subtitles', manifest.captures.filter(x => /^subtitle__/.test(x.file))]
];

function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const sections = groups.map(([label, captures]) => {
  const cards = captures.map(capture => `
<figure>
  <img loading="lazy" src="${esc(capture.file)}" alt="${esc(capture.file)}">
  <figcaption>
    <strong>${esc(capture.file)}</strong><br>
    ${capture.bytes} bytes<br>
    <code>${esc(capture.sha256)}</code>
  </figcaption>
</figure>`).join('\n');
  return `<section><h2>${esc(label)} (${captures.length})</h2><div class="grid">${cards}</div></section>`;
}).join('\n');

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Aetherwake M0 Accessibility Review — ${esc(manifest.gitHead)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:system-ui,sans-serif;margin:24px;line-height:1.4;background:#111;color:#eee}
code{word-break:break-all;font-size:11px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}
figure{margin:0;padding:12px;border:1px solid #666;background:#1a1a1a}
img{width:100%;height:auto;display:block;border:1px solid #444}
figcaption{margin-top:8px}
.notice{padding:12px;border:2px solid #d0a000;background:#2a2300}
</style>
</head>
<body>
<h1>Aetherwake M0 Accessibility Review</h1>
<div class="notice">
<strong>Human review required.</strong> This packet does not pre-approve any criterion.
Complete <code>${esc(path.basename(recordOut))}</code> only after reviewing all 54 captures.
</div>
<p><strong>Commit:</strong> <code>${esc(manifest.gitHead)}</code><br>
<strong>Manifest SHA-256:</strong> <code>${esc(manifestSha256)}</code><br>
<strong>Captures:</strong> ${manifest.captureCount}</p>
${sections}
</body>
</html>
`;

fs.writeFileSync(htmlOut, html, 'utf8');

console.log(JSON.stringify({
  status: 'PASS',
  commitSha: manifest.gitHead,
  manifestSha256,
  captureCount: manifest.captureCount,
  reviewRecord: recordOut,
  reviewHtml: htmlOut,
  result: record.result
}));
