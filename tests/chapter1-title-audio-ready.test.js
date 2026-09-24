'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');

const repo = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(path.join(repo, 'docs', 'audio-assets.json'), 'utf8'));
const title = manifest.titleTheme;
const titleMusic = fs.readFileSync(path.join(repo, 'modules', 'title-music.js'), 'utf8');

assert.strictEqual(title.canonicalPath, 'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3');
assert.strictEqual(title.sourceVerification.bytes, 4233081);
assert.strictEqual(title.sourceVerification.sha256,
  '7ac5fe9c2ee0bc8d0cbfa36441dbb7783dbe2ef0cc5e2ee665086a527a7bc350');
assert.strictEqual(title.repositoryStatus, 'admitted',
  'Chapter 1 candidate requires canonical title theme admitted to the repository');
assert.strictEqual(title.runtimeRegistration, true,
  'Chapter 1 candidate requires title theme runtime registration');
assert.strictEqual(title.sourceRecovery.repositoryTransfer, 'completed',
  'Chapter 1 candidate requires completed binary handoff');

const assetPath = path.join(repo, title.canonicalPath);
assert(fs.existsSync(assetPath), 'canonical Chapter 1 title MP3 is missing');
const bytes = fs.readFileSync(assetPath);
assert.strictEqual(bytes.length, title.sourceVerification.bytes);
assert.strictEqual(crypto.createHash('sha256').update(bytes).digest('hex'),
  title.sourceVerification.sha256);
childProcess.execFileSync('git', ['ls-files', '--error-unmatch', '--', title.canonicalPath],
  { cwd: repo, stdio: 'ignore' });
assert(titleMusic.includes("const THEME_PATH = 'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3';"),
  'title runtime path must match governed canonical asset path');

console.log('Aetherwake Chapter 1 title-audio readiness: PASS');
