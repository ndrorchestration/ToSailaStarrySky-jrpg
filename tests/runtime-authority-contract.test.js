const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const read = rel => fs.readFileSync(path.join(root, rel), 'utf8');
const fail = message => { throw new Error(message); };

const authority = read('aetherwake.js');
if (!authority.startsWith('// PLAYABLE_RUNTIME_AUTHORITY')) {
  fail('aetherwake.js must begin with PLAYABLE_RUNTIME_AUTHORITY');
}

// The five historical/modular mirrors (modules/core.js, modules/combat.js,
// modules/world.js, modules/ui.js, modules/ui-adapter.js) were retired in
// favor of the integrated aetherwake.js runtime. They are no longer in the
// repository. Verify they are absent rather than reading them.
//
// Runtime authority is now solely: aetherwake.js (integrated) + the
// explicitly loaded supporting modules in index.html.
const retiredMirrors = [
  'modules/core.js',
  'modules/combat.js',
  'modules/world.js',
  'modules/ui.js',
  'modules/ui-adapter.js',
];

for (const mirror of retiredMirrors) {
  if (require('fs').existsSync(path.join(root, mirror))) {
    fail(mirror + ' still exists — should have been retired');
  }
}

function scriptSources(html) {
  return [...html.matchAll(/<script[^>]+src=["']([^"']+)["'][^>]*>/g)]
    .map(match => match[1]);
}

for (const entrypoint of ['index.html', 'index-embedded.html']) {
  const html = read(entrypoint);
  const scripts = scriptSources(html);

  if (!scripts.includes('aetherwake.js')) {
    fail(entrypoint + ' must load aetherwake.js');
  }

  for (const mirror of retiredMirrors) {
    if (scripts.includes(mirror)) {
      fail(entrypoint + ' must not load retired mirror ' + mirror);
    }
  }

  if (html.includes('window.world ?') || html.includes('window.combat ?')) {
    fail(entrypoint + ' debug overlay uses stale window.world/window.combat');
  }
  if (!html.includes('window._world ?') || !html.includes('window._combat ?')) {
    fail(entrypoint + ' debug overlay must use window._world/window._combat');
  }
}

const development = read('docs/DEVELOPMENT.md');
if (!development.includes('docs/RUNTIME_AUTHORITY.md')) {
  fail('docs/DEVELOPMENT.md must link the runtime authority contract');
}

const contract = read('docs/RUNTIME_AUTHORITY.md');
for (const marker of [
  'PLAYABLE_RUNTIME_AUTHORITY',
  'NON_RUNTIME_MIRROR',
  'window._world',
  'window._combat'
]) {
  if (!contract.includes(marker)) {
    fail('runtime authority document missing required marker: ' + marker);
  }
}

console.log('Aetherwake runtime authority contract: PASS');
