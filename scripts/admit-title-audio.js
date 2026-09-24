'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const MANIFEST_PATH = path.join(REPO, 'docs', 'audio-assets.json');

function loadManifest() {
  return JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
}

function verifySourceFile(sourcePath, title) {
  if (!fs.existsSync(sourcePath)) {
    throw new Error('TITLE_AUDIO_SOURCE_MISSING:' + sourcePath);
  }
  const bytes = fs.readFileSync(sourcePath);
  if (bytes.length !== title.sourceVerification.bytes) {
    throw new Error('TITLE_AUDIO_SIZE_MISMATCH:' + bytes.length + ':' + title.sourceVerification.bytes);
  }
  const sha256 = crypto.createHash('sha256').update(bytes).digest('hex');
  if (sha256 !== title.sourceVerification.sha256) {
    throw new Error('TITLE_AUDIO_SHA256_MISMATCH:' + sha256 + ':' + title.sourceVerification.sha256);
  }
  return { bytes, sha256 };
}

function admitTitleAudio(sourcePath, options) {
  const opts = options || {};
  const manifest = loadManifest();
  const title = manifest.titleTheme;
  const canonicalPath = path.join(REPO, title.canonicalPath);
  const verification = verifySourceFile(sourcePath, title);

  if (opts.checkOnly === true) {
    return {
      ok: true, checkOnly: true, sourcePath, canonicalPath,
      sha256: verification.sha256, bytes: verification.bytes.length
    };
  }

  fs.mkdirSync(path.dirname(canonicalPath), { recursive: true });
  if (path.resolve(sourcePath) !== path.resolve(canonicalPath)) {
    fs.copyFileSync(sourcePath, canonicalPath);
  }
  verifySourceFile(canonicalPath, title);

  title.repositoryStatus = 'admitted';
  title.runtimeRegistration = true;
  title.admission = {
    admittedAt: new Date().toISOString(),
    verifiedSha256: verification.sha256,
    verifiedBytes: verification.bytes.length,
    method: 'scripts/admit-title-audio.js'
  };
  title.sourceRecovery.repositoryTransfer = 'completed';
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n', 'utf8');

  return {
    ok: true, checkOnly: false, sourcePath, canonicalPath,
    sha256: verification.sha256, bytes: verification.bytes.length,
    repositoryStatus: title.repositoryStatus,
    runtimeRegistration: title.runtimeRegistration
  };
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const checkOnly = args.includes('--check-only');
  const sourceFlag = args.indexOf('--source');
  const source = sourceFlag >= 0 ? args[sourceFlag + 1] : null;
  if (!source) {
    throw new Error('TITLE_AUDIO_SOURCE_REQUIRED: use --source "/path/to/Aetherwake - Skyward Arpeggio Main Title.mp3"');
  }
  return { source, checkOnly };
}

if (require.main === module) {
  try {
    const args = parseArgs(process.argv);
    const result = admitTitleAudio(path.resolve(args.source), { checkOnly: args.checkOnly });
    console.log('Aetherwake Chapter 1 title-audio admission: PASS');
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Aetherwake Chapter 1 title-audio admission: FAIL');
    console.error(error.stack || error.message || String(error));
    process.exit(1);
  }
}

module.exports = { verifySourceFile, admitTitleAudio, parseArgs };
