'use strict';

const assert = require('assert');
const crypto = require('crypto');
const childProcess = require('child_process');
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

const releaseEvidencePath = arg(
  '--release-evidence',
  path.join(repo, 'local-release', 'RELEASE_EVIDENCE.json')
);
const outputDir = arg(
  '--output-dir',
  path.join(repo, 'artifacts', 'm0-external-playtest')
);

assert(fs.existsSync(releaseEvidencePath),
  'Release evidence missing: ' + releaseEvidencePath);

const releaseBytes = fs.readFileSync(releaseEvidencePath);
const release = JSON.parse(releaseBytes.toString('utf8'));
const releaseEvidenceSha256 =
  crypto.createHash('sha256').update(releaseBytes).digest('hex');

assert.strictEqual(release.schemaVersion, 1,
  'Unsupported release evidence schema');
assert(release.source && /^[0-9a-f]{40}$/.test(release.source.gitHead),
  'Release evidence must bind exact Git HEAD');
assert(release.artifacts && release.artifacts.installer,
  'Release evidence installer identity missing');
assert(typeof release.artifacts.installer.filename === 'string' &&
       release.artifacts.installer.filename.length > 0,
  'Release evidence installer filename missing');
assert(typeof release.artifacts.installer.sha256 === 'string' &&
       /^[0-9a-f]{64}$/.test(release.artifacts.installer.sha256),
  'Release evidence installer SHA-256 missing');
assert(release.governedTitleAudio &&
       release.governedTitleAudio.repositoryStatus === 'admitted' &&
       release.governedTitleAudio.runtimeRegistration === true,
  'External playtest packet requires admitted governed title audio');

const currentHead = childProcess.execFileSync(
  'git', ['rev-parse', 'HEAD'], { cwd: repo, encoding: 'utf8' }
).trim();
assert.strictEqual(
  currentHead,
  release.source.gitHead,
  'Release evidence source commit does not match current checkout HEAD'
);

const template = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'm0-external-playtest-record.template.json'),
  'utf8'
));
const record = JSON.parse(JSON.stringify(template));

record.candidate.commitSha = release.source.gitHead;
record.candidate.buildId =
  'm0-' + release.source.gitHead.slice(0, 12) + '-' +
  release.artifacts.installer.sha256.slice(0, 12);
record.candidate.installerSha256 = release.artifacts.installer.sha256;
record.candidate.installerFilename = release.artifacts.installer.filename;
record.candidate.releaseEvidencePath =
  path.relative(repo, releaseEvidencePath).replace(/\\/g, '/');
record.candidate.releaseEvidenceSha256 = releaseEvidenceSha256;
record.candidate.playerVerifiedStandalone = false;
record.result = 'NOT_RUN';

fs.mkdirSync(outputDir, { recursive: true });

const recordPath = path.join(outputDir, 'external-playtest.json');
fs.writeFileSync(recordPath, JSON.stringify(record, null, 2) + '\n', 'utf8');

function esc(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const htmlPath = path.join(outputDir, 'observer-guide.html');
const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Aetherwake M0 External Playtest — ${esc(record.candidate.buildId)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:system-ui,sans-serif;max-width:960px;margin:32px auto;padding:0 20px;line-height:1.5}
code{word-break:break-all}.warn{border:2px solid #a66;padding:12px;background:#fff8f5}
li{margin:.45rem 0}
</style>
</head>
<body>
<h1>Aetherwake M0 Uncoached External Playtest</h1>
<div class="warn"><strong>Do not coach the participant.</strong> Explain only how to launch the supplied standalone build. Do not explain objectives, controls, combat strategy, quest order, save/load behavior, or expected story beats.</div>
<h2>Exact candidate</h2>
<ul>
<li>Build: <code>${esc(record.candidate.buildId)}</code></li>
<li>Commit: <code>${esc(record.candidate.commitSha)}</code></li>
<li>Installer: <code>${esc(record.candidate.installerFilename)}</code></li>
<li>Installer SHA-256: <code>${esc(record.candidate.installerSha256)}</code></li>
<li>Release evidence SHA-256: <code>${esc(record.candidate.releaseEvidenceSha256)}</code></li>
</ul>
<h2>Observe without intervention</h2>
<ol>
<li>Install and launch the standalone Windows candidate.</li>
<li>Begin through New Game or Continue as appropriate.</li>
<li>Observe whether the next objective is understood without help.</li>
<li>Observe First Wake exploration/contact progression.</li>
<li>Ask only after actions what the participant believed a combat choice would do; do not suggest choices.</li>
<li>Have the participant create a manual save.</li>
<li>Close the game process.</li>
<li>Relaunch and restore the save.</li>
<li>Observe at least one non-happy-path state and recovery using player-facing affordances.</li>
<li>Observe completion of the bounded Choice → WAKE experience.</li>
<li>Record Dragonfly/open-sky traversal if present in the candidate.</li>
</ol>
<h2>Evidence rules</h2>
<p>Record hesitation, stated reasoning, confusion, defects, and any intervention. Any live coaching/intervention invalidates an uncoached PASS. The generated JSON begins <code>NOT_RUN</code> and does not pre-approve any observation.</p>
<p>Complete <code>external-playtest.json</code>, then validate it with the repository command documented in <code>docs/M0_EXTERNAL_PLAYTEST.md</code>.</p>
</body>
</html>`;
fs.writeFileSync(htmlPath, html, 'utf8');

console.log(JSON.stringify({
  status: 'PASS',
  commitSha: record.candidate.commitSha,
  buildId: record.candidate.buildId,
  installerSha256: record.candidate.installerSha256,
  releaseEvidenceSha256,
  record: recordPath,
  observerGuide: htmlPath,
  result: record.result
}));
