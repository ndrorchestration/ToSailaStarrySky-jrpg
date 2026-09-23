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
const gitStatus = childProcess.execFileSync(
  'git', ['status', '--porcelain=v1'], { cwd: repo, encoding: 'utf8' }
).trim();
assert(gitHead, 'Release evidence requires Git HEAD provenance');
assert.strictEqual(gitStatus, '', 'Release evidence requires a clean working tree');

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

const evidence = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  source: {
    gitHead,
    workingTree: 'clean'
  },
  governedTitleAudio: {
    canonicalPath: title.canonicalPath,
    bytes: title.sourceVerification.bytes,
    sha256: title.sourceVerification.sha256,
    repositoryStatus: title.repositoryStatus,
    runtimeRegistration: title.runtimeRegistration
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
