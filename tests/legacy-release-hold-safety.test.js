'use strict';
// Issue #293: source-only NW.js publication containment plus isolated preflight.
// Never run the archived installer/build script or install any historical binary.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

const root = path.resolve(__dirname, '..');
const workflow = fs.readFileSync(path.join(root, '.github/workflows/desktop-package.yml'), 'utf8').replace(/\r\n/g, '\n');
const local = fs.readFileSync(path.join(root, 'scripts/build-windows-release.ps1'), 'utf8').replace(/\r\n/g, '\n');
const activeWorkflow = workflow.split('\n').filter(line => !/^\s*#/.test(line)).join('\n');
const marker = 'AFTER_SECURITY_HOLD_MUST_NOT_EXECUTE_293';

function isolatedLocalGuard() {
  const preference = local.indexOf('$ErrorActionPreference = "Stop"');
  const boundary = local.indexOf('\n$repo = ', preference);
  assert.ok(preference >= 0 && boundary > preference, 'security guard must be before repository resolution');
  const prefix = local.slice(preference, boundary);
  const executable = prefix.split('\n').filter(line => !/^\s*#/.test(line)).join('\n');
  assert.match(executable, /^\$ErrorActionPreference = "Stop"\s*\nthrow "SECURITY_HOLD_293:/);
  const match = executable.match(/^throw "SECURITY_HOLD_293:[^"\n]*"$/m);
  assert.ok(match, 'unconditional throw required');
  return match[0];
}

test('retired workflow has no push/tag publisher, build action or write token', () => {
  assert.match(workflow, /# SECURITY HOLD/);
  assert.match(activeWorkflow, /^permissions:\s*\n\s*contents: read$/m);
  assert.doesNotMatch(activeWorkflow, /\bcontents:\s*write\b/);
  assert.doesNotMatch(activeWorkflow, /^\s*(?:push|tags):/m);
  assert.doesNotMatch(activeWorkflow, /softprops\/action-gh-release|gh\s+release\s+create|makensis|Start-Process|npm\s+run\s+package:windows/i);
  assert.doesNotMatch(activeWorkflow, /continue-on-error\s*:/);
  assert.match(activeWorkflow, /Refuse manual execution[\s\S]*?exit 1/);
});

test('archived local build is blocked before install, npm or NSIS', () => {
  const guard = isolatedLocalGuard();
  const guardAt = local.indexOf(guard);
  for (const command of ['npm ci', 'npm run package:windows', 'Start-Process -FilePath $installer', '& $makensis']) {
    assert.ok(local.indexOf(command) > guardAt, 'legacy action must occur after hold: ' + command);
  }
});

test('synthetic removal of hold or writable publication is detected', () => {
  const staticValid = text =>
    /^permissions:\s*\n\s*contents: read$/m.test(text) &&
    !/^\s*(?:push|tags):/m.test(text) &&
    !/\bcontents:\s*write\b/.test(text) &&
    !/softprops\/action-gh-release|gh\s+release\s+create/i.test(text);
  assert.equal(staticValid(activeWorkflow), true);
  assert.equal(staticValid(activeWorkflow.replace('contents: read', 'contents: write')), false);
  assert.equal(staticValid(activeWorkflow.replace('  workflow_dispatch:', '  push:\n  workflow_dispatch:')), false);
  assert.equal(staticValid(activeWorkflow + '\nuses: softprops/action-gh-release@v2'), false);
});

test('isolated Windows PowerShell throw rejects and does not execute a sentinel', {skip: process.platform !== 'win32'}, () => {
  const hold = isolatedLocalGuard();
  const testCommand = hold + "\nWrite-Output '" + marker + "'";
  const result = spawnSync('pwsh', ['-NoLogo','-NoProfile','-NonInteractive','-Command',testCommand], {
    encoding:'utf8', timeout:15000
  });
  assert.ifError(result.error);
  assert.notEqual(result.status, 0);
  assert.match(result.stdout + result.stderr, /SECURITY_HOLD_293/);
  assert.doesNotMatch(result.stdout + result.stderr, new RegExp(marker));
  // Negative control: replacing the throw in memory must permit a sentinel.
  const mutation = spawnSync('pwsh', ['-NoLogo','-NoProfile','-NonInteractive','-Command',
    hold.replace(/^throw /, 'Write-Output ') + "\nWrite-Output '" + marker + "'"], {
    encoding:'utf8', timeout:15000
  });
  assert.ifError(mutation.error);
  assert.equal(mutation.status, 0);
  assert.match(mutation.stdout, new RegExp(marker));
});
