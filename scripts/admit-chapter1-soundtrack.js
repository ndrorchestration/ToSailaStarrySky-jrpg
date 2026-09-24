'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const manifestPath = path.join(REPO, 'docs', 'audio-assets.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

function hashFile(filePath) {
  const bytes = fs.readFileSync(filePath);
  return { bytes, sha256: crypto.createHash('sha256').update(bytes).digest('hex') };
}

function admitOne(track, sourcePath, checkOnly) {
  if (!fs.existsSync(sourcePath)) throw new Error('SOUNDTRACK_SOURCE_MISSING:' + sourcePath);
  const v = hashFile(sourcePath);
  if (v.bytes.length !== track.sourceVerification.bytes) {
    throw new Error('SOUNDTRACK_SIZE_MISMATCH:' + track.id);
  }
  if (v.sha256 !== track.sourceVerification.sha256) {
    throw new Error('SOUNDTRACK_SHA256_MISMATCH:' + track.id);
  }
  const dest = path.join(REPO, track.canonicalPath);
  if (!checkOnly) {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    if (path.resolve(sourcePath) !== path.resolve(dest)) fs.copyFileSync(sourcePath, dest);
    const copied = hashFile(dest);
    if (copied.sha256 !== track.sourceVerification.sha256) throw new Error('SOUNDTRACK_COPY_VERIFY_FAILED:' + track.id);
    track.repositoryStatus = 'admitted';
    track.runtimeRegistration = true;
  }
  return { id:track.id, sourcePath, canonicalPath:dest, bytes:v.bytes.length, sha256:v.sha256 };
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const checkOnly = args.includes('--check-only');
  const map = {};
  for (let i=0;i<args.length;i++) {
    if (args[i].startsWith('--') && args[i] !== '--check-only') map[args[i].slice(2)] = args[i+1];
  }
  return { checkOnly, map };
}

if (require.main === module) {
  try {
    const {checkOnly,map} = parseArgs(process.argv);
    const aliases = {
      'first-wake-cinematic':'amonigio',
      'nocturnal-resolve':'nocturnal',
      'solar-punk-airship':'solar'
    };
    const results=[];
    for (const track of manifest.chapter1Tracks || []) {
      const source = map[aliases[track.id]];
      if (!source) throw new Error('SOUNDTRACK_SOURCE_REQUIRED:' + aliases[track.id]);
      results.push(admitOne(track, path.resolve(source), checkOnly));
    }
    if (!checkOnly) {
      fs.writeFileSync(manifestPath, JSON.stringify(manifest,null,2)+'\n','utf8');
    }
    console.log('Aetherwake Chapter 1 soundtrack admission: PASS');
    console.log(JSON.stringify({checkOnly,results},null,2));
  } catch (error) {
    console.error('Aetherwake Chapter 1 soundtrack admission: FAIL');
    console.error(error.stack || error.message || String(error));
    process.exit(1);
  }
}
