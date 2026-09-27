'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'ui-visual-system.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'ui-visual-system.js' });
const api = sandbox.window.AetherUIVisualSystem;
assert(api, 'shared UI visual system missing');
assert.strictEqual(api.VERSION, '0.6.0');
assert.strictEqual(api.TOKENS.gridPx, 8);
assert.strictEqual(api.TOKENS.safeMarginPx, 24);
assert(api.TOKENS.panelOpacity >= 0.78 && api.TOKENS.panelOpacity <= 0.90);
assert(api.TOKENS.minBodyContrast >= 4.5);
assert(api.TOKENS.maxPrimaryPanels <= 2);
const noLog = api.layoutCombat(960, 640, false);
assert.strictEqual(noLog.logPanel, null, 'empty combat log must not reserve a primary panel');
assert(noLog.statusPanel.x >= api.TOKENS.safeMarginPx, 'combat status panel violates safe margin');
assert(noLog.statusPanel.w <= 184, 'combat status panel must remain narrow enough to preserve arena art');
assert(noLog.statusPanel.h <= 400, 'combat status panel must not reserve unused lower-screen space');
const dialogue = api.layoutDialogue(960, 640);
assert.strictEqual(dialogue.x, 70, 'dialogue panel must remain centered inside 24px safe area');
assert.strictEqual(dialogue.y, 464, 'dialogue panel must respect bottom safe margin');
assert.strictEqual(dialogue.w, 820);
assert.strictEqual(dialogue.h, 152);
const flight = api.layoutFlight(960, 640);
assert.strictEqual(flight.routeRibbon.x, 24);
assert.strictEqual(flight.routeRibbon.y, 24);
assert(flight.routeRibbon.w <= 456 && flight.routeRibbon.h === 56,
  'flight route ribbon exceeds compact shared HUD budget');
assert(flight.controlsHint && flight.controlsHint.w <= 232 && flight.controlsHint.h === 24,
  'flight controls hint must remain a compact readable chip');
assert(flight.artReserve.h >= 450, 'flight HUD must preserve a large central art reserve');
assert.strictEqual(flight.nearestSignal.x + flight.nearestSignal.w, 936,
  'nearest-signal card must respect right safe margin');
assert.strictEqual(flight.nearestSignal.y + flight.nearestSignal.h, 616,
  'nearest-signal card must respect bottom safe margin');
assert(flight.nearestSignal.w <= 216 && flight.nearestSignal.h === 44,
  'nearest-signal card must remain compact');
const title = api.layoutTitle(960, 640);
assert(title.panel.x >= api.TOKENS.safeMarginPx && title.panel.y >= api.TOKENS.safeMarginPx,
  'title panel must respect shared safe area');
assert(title.panel.w <= 448 && title.panel.h === 216,
  'title panel must stay compact enough to preserve hero art');
assert(title.artReserve.w >= 400, 'title layout must preserve a substantial hero-art reserve');
const withLog = api.layoutCombat(960, 640, true);
assert(withLog.logPanel && withLog.logPanel.w <= 184 && withLog.logPanel.h <= 184,
  'combat log must remain compact');
assert(withLog.centerReserve.w >= 480, 'combat UI must preserve a large central encounter reserve');
const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
assert(html.includes('modules/ui-visual-system.js'), 'UI visual system missing from runtime');
assert(html.indexOf('modules/ui-visual-system.js') < html.indexOf('aetherwake.js'),
  'UI system must load before runtime');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(runtime.includes('AetherUIVisualSystem'), 'runtime must bind shared UI visual system');
assert(runtime.includes('hasCombatLog'), 'runtime must collapse an empty combat log');
console.log('Aetherwake shared UI visual system: PASS');
