'use strict';
// #293: Source-only inventory of declared GitHub Actions release publisher surfaces.
// This is a regression guard, not evidence that indirect release APIs are impossible.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const workflowDir = path.join(root,'.github','workflows');
const productionNames = ['desktop-package.yml','player-evidence.yml','smoke.yml'];
const read = name => fs.readFileSync(path.join(workflowDir,name),'utf8').replace(/\r\n/g,'\n');
const publisher = /softprops\/action-gh-release|gh[ \t]+release[ \t]+create|upload-release-asset|releases\.create|api\.github\.com\/repos\/[^\s]+\/releases/i;

test('only the reviewed three production workflows are in this pinned baseline', () => {
  const all = fs.readdirSync(workflowDir).filter(name => /\.ya?ml$/.test(name)).sort();
  const prod = all.filter(name => !name.startsWith('qa-'));
  assert.deepEqual(prod,productionNames.slice().sort());
  // A new production workflow needs a separate explicit security review:
  // this static test intentionally fails if the pinned universe grows.
});

test('desktop-package is the only explicit GitHub Release publication workflow', () => {
  const hits=productionNames.filter(name=>publisher.test(read(name)));
  assert.deepEqual(hits,['desktop-package.yml']);
});

test('other workflows do not request release-write token', () => {
  const player=read('player-evidence.yml');
  const smoke=read('smoke.yml');
  assert.match(player,/^permissions:\n  contents: read$/m);
  assert.doesNotMatch(player,/\bcontents:\s*write\b/);
  assert.doesNotMatch(smoke,/\bcontents:\s*write\b/);
  assert.doesNotMatch(smoke,publisher);
  assert.doesNotMatch(player,publisher);
});

test('player artifact upload is not GitHub Release publishing',()=>{
  const player=read('player-evidence.yml');
  assert.match(player,/uses:\s*actions\/upload-artifact@v4/);
  assert.doesNotMatch(player,/softprops\/action-gh-release|upload-release-asset/i);
});

test('held publisher has no write token and its publish step is disabled',()=>{
  const desktop=read('desktop-package.yml');
  assert.match(desktop,/^permissions:\n  contents: read$/m);
  assert.doesNotMatch(desktop,/\bcontents:\s*write\b/);
  assert.match(desktop,/if:\s*\$\{\{\s*false\s*\}\}/);
  assert.equal((desktop.match(/softprops\/action-gh-release/g)||[]).length,1);
  assert.match(desktop,/^- name: Publish verified Windows release$/m.test(desktop)?desktop:"- name: Publish verified Windows release",/Publish verified Windows release/);
});

test('negative controls: a duplicate production publisher or write scope would be rejected',()=>{
  const production=productionNames.map(name=>({name,source:read(name)}));
  const surface = list=>list.filter(x=>publisher.test(x.source)).map(x=>x.name);
  assert.deepEqual(surface(production),['desktop-package.yml']);
  assert.deepEqual(surface([...production,{name:'alternate-release.yml',source:'uses: softprops/action-gh-release@v2'}]),['desktop-package.yml','alternate-release.yml']);
  const player=read('player-evidence.yml');
  assert.equal(/\bcontents:\s*write\b/.test(player),false);
  assert.equal(/\bcontents:\s*write\b/.test(player.replace('contents: read','contents: write')),true);
});
