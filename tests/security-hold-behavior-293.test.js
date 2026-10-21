'use strict';
// #293: EXECUTE PRE-FLIGHT ONLY. Never execute installer or workflow itself.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const workflow = fs.readFileSync(path.join(root,'.github/workflows/desktop-package.yml'),'utf8').replace(/\r\n/g,'\n');
const local = fs.readFileSync(path.join(root,'scripts/build-windows-release.ps1'),'utf8').replace(/\r\n/g,'\n');
const MARKER = 'AFTER_HOLD_MUST_NOT_EXECUTE_293';
function workflowGuard(){
  const step = workflow.match(/^      - name: Fail closed while generated NSIS uninstaller security hold is unresolved\n        shell: pwsh\n        run: \|\n((?: {10}[^\n]*\n)+)/m);
  assert.ok(step,'guard shell run must be extractable');
  assert.equal(step.index, workflow.indexOf('      - name: '),'guard must be first step');
  const command = step[1].trimEnd().split('\n').map(line=>line.slice(10)).join('\n');
  assert.match(command,/^throw "SECURITY_HOLD_293:/);
  return command;
}
function localGuard(){
  const start=local.indexOf('$ErrorActionPreference = "Stop"');
  const end=local.indexOf('\n$repo = ',start);
  assert.ok(start>=0 && end>start,'local guard must precede build');
  const snippet=local.slice(start,end).trim();
  assert.match(snippet,/^\$ErrorActionPreference = "Stop"\n# [^\n]*\nthrow "SECURITY_HOLD_293:/);
  return snippet;
}
function probe(guard){
  const p=spawnSync('pwsh',['-NoLogo','-NoProfile','-NonInteractive','-Command',
    guard+"\nWrite-Output '"+MARKER+"'\n"],{
    encoding:'utf8',timeout:10000,env:{PATH:process.env.PATH||'',HOME:process.env.HOME||'/tmp'}
  });
  assert.ifError(p.error);
  return p;
}
test('workflow deny is unconditional and permission and publish gates are closed',()=>{
  assert.match(workflow,/^permissions:\n  contents: read$/m);
  assert.doesNotMatch(workflow,/(?:^|\n)\s*contents:\s*write\s*(?:\n|$)/);
  assert.doesNotMatch(workflow,/continue-on-error\s*:/);
  assert.match(workflow,/- name: Publish verified Windows release\n\s+# [^\n]*\n\s+if: \$\{\{ false \}\}/);
  assert.equal((workflow.match(/- name: Publish verified Windows release/g)||[]).length,1);
  workflowGuard();
  localGuard();
});
test('workflow preflight throws before next shell statement',()=>{
  const x=probe(workflowGuard());
  assert.notEqual(x.status,0);
  assert.doesNotMatch(x.stdout+x.stderr,new RegExp(MARKER));
  assert.match(x.stdout+x.stderr,/SECURITY_HOLD_293/);
});
test('local installer preflight throws before next shell statement',()=>{
  const x=probe(localGuard());
  assert.notEqual(x.status,0);
  assert.doesNotMatch(x.stdout+x.stderr,new RegExp(MARKER));
  assert.match(x.stdout+x.stderr,/SECURITY_HOLD_293/);
});
test('mutation oracle: removing workflow throw permits sentinel',()=>{
  const g=workflowGuard().replace(/^throw /,'Write-Output ');
  const x=probe(g);
  assert.equal(x.status,0);
  assert.match(x.stdout,new RegExp(MARKER));
});
test('synthetic permission, publish, and continue-on-error mutations reject',()=>{
  const valid=s=>/^permissions:\n  contents: read$/m.test(s) &&
    /- name: Publish verified Windows release\n\s+# [^\n]*\n\s+if: \$\{\{ false \}\}/.test(s) &&
    !/continue-on-error\s*:/.test(s);
  assert.equal(valid(workflow),true);
  assert.equal(valid(workflow.replace('contents: read','contents: write')),false);
  assert.equal(valid(workflow.replace('if: $'+'{{ false }}','if: $'+'{{ true }}')),false);
  assert.equal(valid(workflow.replace('      - name: Check out source',
    '      - name: Check out source\n        continue-on-error: true')),false);
});
test('local guard precedes npm and NSIS installer process',()=>{
  const index=local.indexOf('throw "SECURITY_HOLD_293:');
  assert.ok(index>=0 && index<local.indexOf('npm ci'));
  assert.ok(index<local.indexOf('Start-Process -FilePath $installer'));
});
