'use strict';

const assert = require('assert');
const crypto = require('crypto');
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

function arg(name) {
  const index = args.indexOf(name);
  assert(index >= 0 && args[index + 1], 'Missing required argument: ' + name);
  return path.resolve(args[index + 1]);
}

const installer = arg('--installer');
const portableZip = arg('--zip');
const output = arg('--output');

for (const file of [installer, portableZip]) {
  assert(fs.existsSync(file), 'Release artifact missing: ' + file);
}

const gitHead = childProcess.execFileSync(
  'git', ['rev-parse', 'HEAD'], { cwd: repo, encoding: 'utf8' }
).trim();
const trackedDiff = childProcess.spawnSync(
  'git', ['diff', '--quiet', 'HEAD', '--'], { cwd: repo }
);
const stagedDiff = childProcess.spawnSync(
  'git', ['diff', '--cached', '--quiet', '--'], { cwd: repo }
);
assert(gitHead, 'Release evidence requires Git HEAD provenance');
assert.strictEqual(trackedDiff.status, 0,
  'Release evidence rejects tracked source changes created during the build');
assert.strictEqual(stagedDiff.status, 0,
  'Release evidence rejects staged source changes created during the build');

function sha256(file) {
  const hash = crypto.createHash('sha256');
  const bytes = fs.readFileSync(file);
  hash.update(bytes);
  return { bytes: bytes.length, sha256: hash.digest('hex') };
}

const audioManifest = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'audio-assets.json'), 'utf8'
));
const title = audioManifest.titleTheme;
assert(title && title.repositoryStatus === 'admitted' && title.runtimeRegistration === true,
  'Release evidence requires admitted governed title audio');

assert.strictEqual(
  process.env.AETHERWAKE_RELEASE_DESKTOP_SAVE_RESTART,
  'PASS',
  'Release evidence requires packaged save restart verification'
);
assert.strictEqual(
  process.env.AETHERWAKE_RELEASE_DESKTOP_SAVE_BACKUP_ONLY_RECOVERY,
  'PASS',
  'Release evidence requires packaged backup-only save recovery verification'
);

const evidence = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  source: {
    gitHead,
    trackedSource: 'unchanged-from-head'
  },
  governedTitleAudio: {
    canonicalPath: title.canonicalPath,
    bytes: title.sourceVerification.bytes,
    sha256: title.sourceVerification.sha256,
    repositoryStatus: title.repositoryStatus,
    runtimeRegistration: title.runtimeRegistration
  },
  persistenceVerification: {
    desktopSaveRestart: process.env.AETHERWAKE_RELEASE_DESKTOP_SAVE_RESTART,
    desktopSaveBackupOnlyRecovery:
      process.env.AETHERWAKE_RELEASE_DESKTOP_SAVE_BACKUP_ONLY_RECOVERY
  },
  artifacts: {
    installer: {
      filename: path.basename(installer),
      ...sha256(installer)
    },
    portableZip: {
      filename: path.basename(portableZip),
      ...sha256(portableZip)
    }
  }
};

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, JSON.stringify(evidence, null, 2) + '\n', 'utf8');
console.log(JSON.stringify({ status: 'PASS', output, gitHead }));
