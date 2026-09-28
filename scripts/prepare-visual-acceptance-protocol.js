'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const templatePath = path.join(root, 'docs', 'visual-acceptance-protocol-template.json');
const evidenceDir = path.join(root, 'visual-evidence');
const evidenceManifestPath = path.join(evidenceDir, 'manifest.json');

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function exactHead() {
  const result = cp.spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: unable to resolve Git head');
  const head = result.stdout.trim();
  if (!/^[0-9a-f]{40}$/i.test(head)) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: invalid exact Git head');
  return head;
}

function cleanWorktree() {
  const result = cp.spawnSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: git status failed');
  if (result.stdout.trim()) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: working tree must be clean');
}

function parseArgs(argv) {
  const args = { package: null, seed: null, decoys: [] };
  for (let i = 0; i < argv.length; i++) {
    const value = argv[i];
    if (value === '--package') args.package = argv[++i];
    else if (value === '--seed') args.seed = argv[++i];
    else if (value === '--decoy') args.decoys.push(argv[++i]);
    else throw new Error('VISUAL_PROTOCOL_PREP_FAIL: unknown argument ' + value);
  }
  return args;
}

function prepare(options) {
  cleanWorktree();
  const head = exactHead();

  if (!options.package) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: --package is required');
  if (!options.seed || !String(options.seed).trim()) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: --seed is required');
  if (!Array.isArray(options.decoys) || options.decoys.length !== 3) {
    throw new Error('VISUAL_PROTOCOL_PREP_FAIL: exactly three --decoy files are required');
  }

  const packagePath = path.resolve(options.package);
  if (!fs.existsSync(packagePath)) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: package file missing');
  if (!fs.existsSync(evidenceManifestPath)) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: evidence manifest missing');

  const protocol = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
  if (!Array.isArray(protocol.aetherwakeFrames) || protocol.aetherwakeFrames.length !== 7) {
    throw new Error('VISUAL_PROTOCOL_PREP_FAIL: protocol must contain exactly seven frozen Aetherwake frames');
  }

  protocol.candidate.commit = head;
  protocol.candidate.packageSha256 = sha256File(packagePath);
  protocol.candidate.evidenceManifestSha256 = sha256File(evidenceManifestPath);

  protocol.aetherwakeFrameSha256 = {};
  for (const filename of protocol.aetherwakeFrames) {
    const framePath = path.join(evidenceDir, filename);
    if (!fs.existsSync(framePath)) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: missing frozen Aetherwake frame ' + filename);
    protocol.aetherwakeFrameSha256[filename] = sha256File(framePath);
  }

  protocol.decoys = options.decoys.map((file, index) => {
    const absolute = path.resolve(file);
    if (!fs.existsSync(absolute)) throw new Error('VISUAL_PROTOCOL_PREP_FAIL: decoy file missing: ' + file);
    return {
      id: 'D' + (index + 1),
      source: path.basename(absolute),
      sha256: sha256File(absolute)
    };
  });

  protocol.presentation.orderSeed = String(options.seed);
  protocol.frozenBeforeFirstSession = true;

  const output = path.join(root, 'visual-acceptance-protocol.json');
  fs.writeFileSync(output, JSON.stringify(protocol, null, 2) + '\n');
  const protocolSha256 = sha256File(output);

  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL=PREPARED');
  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_SHA256=' + protocolSha256);
  console.log('AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_PATH=' + path.relative(root, output).replace(/\\/g, '/'));
  return { output, protocolSha256 };
}

if (require.main === module) {
  try {
    prepare(parseArgs(process.argv.slice(2)));
  } catch (error) {
    console.error(String(error && error.message ? error.message : error));
    process.exit(1);
  }
}

module.exports = { parseArgs, prepare, sha256File };
