'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'first-wake-visual-stage.js'), 'utf8');
const sandbox = { window: {}, globalThis: {} };
vm.runInNewContext(source, sandbox, { filename: 'first-wake-visual-stage.js' });

const api = sandbox.window.AetherFirstWakeVisual;
assert(api, 'First Wake visual stage missing');
assert.strictEqual(api.VERSION, '1.2.0');
for (const fn of ['draw','drawDock','drawInterior','drawChapter']) {
  assert.strictEqual(typeof api[fn], 'function', fn + ' missing');
}

assert(source.includes('AetherDragonflyVisual'),
  'opening dock must reuse shared Dragonfly authority');
assert(source.includes('AetherCharacterRenderer'),
  'opening must prefer the articulated character authority');
assert(source.includes('AetherEnvironmentVisualKit'),
  'v0.5 opening dock must reuse the shared environment-kit prop language');
assert(source.includes('AetherPixelSprites'),
  'opening must retain pixel sprites only as a compatibility fallback');
assert(source.includes('aetherwake-preview-world-pixelart-v2.png'),
  'v0.5 opening dock must bind the admitted painted-world authority');
assert(source.includes('drawPaintedDockBackdrop') && source.includes('openingWorldReady'),
  'v0.5 opening dock must retain painted-backdrop readiness and procedural fallback');
assert(source.includes('aetherwake-preview-interior-pixelart-v1.png'),
  'v0.9 opening interior must bind the authored cabin plate');
assert(source.includes('drawPaintedInteriorBackdrop') && source.includes('openingInteriorReady'),
  'v0.9 opening interior must preserve authored-cabin readiness with procedural fallback');
assert(source.includes('Presentation-only scene handoff') && source.includes('state.sceneTicks'),
  'opening visual stage must provide bounded scene-transition polish from presentation ticks');
assert(!source.includes('state.sceneTicks ='),
  'visual transition must not mutate opening scene timing state');
assert(source.includes('bandedSky(') && source.includes('cloudBands('),
  'opening dock must retain layered atmospheric fallback depth');
assert(source.includes('Only procedural fallback gets a full deck reconstruction') && source.includes('quad(inset0, y0'),
  'procedural dock fallback must retain perspective deck geometry while authored skyport art avoids overlay-board reconstruction');
assert(source.includes('function drawDockSkyportArchitecture') && source.includes('drawDockSkyportArchitecture(now, paintedBackdrop)'),
  'v0.8 opening dock must include authored midground skyport architecture');
assert(source.includes('function drawDockLivingDetails') && source.includes('drawDockLivingDetails(now, paintedBackdrop)'),
  'v0.8 opening dock must include solarpunk planters, flowers, and warm practical lighting');
assert(source.includes('Cloud drop below the deck'),
  'v0.3 dock must continuously communicate altitude');
assert(source.includes('cinematicRatio') && source.includes('const settle ='),
  'v0.4 opening must preserve authored cinematic settle timing');
assert(source.includes('scene.sequence >= 1'),
  'v0.4 Sequence 00 must remain a ship-and-sky establishing shot before sprite reveal');
assert(source.includes('1.38 + settle * 0.34') && source.includes(': 1.62'),
  'opening must preserve a restrained Dragonfly reveal scale that leaves authored skyport art dominant');
assert(source.includes('scale: cinematic ? 1.72 : 1.42'),
  'opening must keep Ender readable at a restrained JRPG scene scale against authored environments');
assert(source.includes('scale: cinematic ? 1.62 : 1.34'),
  'opening must keep Ionia proportionate to the authored dock and Dragonfly');
assert(source.includes("characters.draw('ender'") && source.includes("characters.draw('ionia'"),
  'opening must draw canonical Ender and Ionia through articulated character authority');
assert(source.includes("sprites.draw('ender'") && source.includes("sprites.draw('ionia'"),
  'opening must retain the old sprite path only as fallback');
assert(source.includes('function drawWakeExploration'),
  'v0.2 opening must expose the authored Wake exploration renderer');
assert(source.includes('authored.drawFieldCharacter') && source.includes('authoredDrawn'),
  'v1.1 opening interiors must prefer admitted authored field packs with fail-safe fallback');
assert(source.includes('drawProvisionalFieldCharacter'),
  'v1.2 opening must use reviewed pixel field sheets as the provisional fallback before procedural figures');
assert(source.includes("const enderPixel = drawProvisional('ender'") && source.includes("const lyraPixel = drawProvisional('lyra'") && source.includes("const ioniaPixel = drawProvisional('ionia'"),
  'interactive Wake exploration must preserve provisional pixel protagonist continuity before articulated fallback');
assert(source.includes('wakeMapPoint(x, y, paintedInterior)') && source.includes('(paintedInterior ? 326 : 156)'),
  'authored cabin exploration must floor-anchor logical grid positions instead of floating sprites across the windows');
assert(source.includes("id === 'lyra' ? 1.72") && source.includes("id === 'ionia' ? 1.76") && source.includes(': 1.82'),
  'authored cabin protagonist scale must stay subordinate to the environment');
assert(source.includes('sceneTicks < 36'),
  'v1.1 non-cinematic scene titles must clear quickly instead of becoming permanent HUD chrome');
assert(source.includes('(!scene.interactive || Boolean(scene.speaker))') && source.includes("} else if (!scene.interactive && scene.id !== 'arrival_horizon') {"),
  'interactive exploration must not keep narration copy floating over the authored field when no character is speaking');
assert(source.includes('Exploration feedback is a subtitle-like cue') && source.includes('const messageW = Math.min(520'),
  'interactive exploration feedback must remain compact rather than becoming a wide dialogue panel');
assert(source.includes('const displayMessage = fitHudText(explorationMessage, messageW - 24)') && source.includes('text(displayMessage, width / 2, 559)'),
  'exploration feedback must remain bounded and explicitly centered');
assert(source.includes('authored.drawPortrait') && source.includes('portraitDrawn'),
  'v1.1 opening narration must use admitted speaker portrait art when available');
assert(source.includes('function drawHorizonEstablishing') && source.includes("scene.id === 'arrival_horizon'"),
  'v1.2 opening must begin with a HUD-light establishing shot rather than the dock gameplay composition');
assert(source.includes('if (!paintedBackdrop) {') && source.includes('broad translucent quads read like a prototype board laid'),
  'painted dock must suppress full-deck overlay reconstruction and preserve the authored plate');
assert(source.includes('paintedBackdrop ? 52 : 165') && source.includes('A narrow reclaimed-timber lane anchors traversal'),
  'painted dock traversal must remain lane-led and subordinate to the authored environment');
assert(source.includes('physical dock') && source.includes('triangle(277, 365, 291, 362, 286, 375)'),
  'closed-route cue must read as a physical barricade rather than a floating board');
assert(source.includes("sceneTicks >= 90 && sceneTicks < 160") && source.includes("sceneTicks >= 142"),
  'v1.2 opening must stage location and narration after a sustained world reveal rather than immediately');
assert(source.includes("['Dawn gathers beneath', 'a sea of clouds.']") && source.includes("['A small patched vessel hangs', 'against a very large sky.']"),
  'arrival-horizon narration must use centered bounded cinematic line breaks rather than overflow the vista');
assert(!source.includes("FIRST WAKE // ' + String(scene.sequence)"),
  'player-facing scene transition must not expose sequence metadata');
assert(source.includes('Math.min(286, width - 420)') && source.includes("promptText = '← / →   WALK'"),
  'opening location labels and interaction prompts must remain compact and JRPG-like');
assert(!source.includes('A / D or Left / Right  —  Walk to the Dragonfly') && !source.includes('Enter / Space  —  Continue'),
  'opening must not regress to verbose tutorial-style prompts');
assert(source.includes("text('SETTLING IN', 40, 91)") && source.includes("text('TALK WITH TALEN', 40, 91)") && source.includes('upper-left quest chip'),
  'opening task progress must use compact upper-left JRPG quest chips plus pips');
assert(source.includes("if (!paintedInterior) {") && source.includes("drawWakeRoomLabel('BERTH'"),
  'authored Wake interior must suppress map-like room labels while procedural fallback may retain them');
assert(source.includes('const objectiveW = 320') && source.includes("text('E   INSPECT', width / 2, 585)"),
  'interactive Wake HUD must keep compact JRPG objective/inspect cues');
const hudStart = source.indexOf('const objectiveW = 320');
const hudEnd = source.indexOf('textAlign(LEFT, TOP);', hudStart);
assert(hudStart > -1 && hudEnd > hudStart, 'exploration HUD segment missing');
const hud = source.slice(hudStart, hudEnd);
assert(hud.includes('function fitHudText(value, maxWidth)') &&
  hud.includes('textWidth(raw) <= maxWidth') &&
  hud.includes('textWidth(raw.slice(0, mid).trimEnd() + suffix) <= maxWidth') &&
  hud.includes('objectiveW - 24') &&
  hud.includes('messageW - 24'),
  'visible objective and feedback copy must fit the measured canvas text bounds');
assert(hud.includes('fill(5, 8, 13, 190)') &&
  hud.includes('rect(width / 2 - objectiveW / 2, 42, objectiveW, 36, 7)') &&
  hud.includes('textSize(12)') &&
  hud.includes('fill(235, 250, 240, 248)'),
  'objective chip must remain legible over busy bright or dark scenery');
assert(hud.includes('fill(5, 8, 13, 184)') &&
  hud.includes('fill(245, 237, 216, 246)'),
  'feedback panel must preserve readable foreground/background contrast');
assert(hud.includes("if (scene.id === 'core_walk' || nearby)") &&
  hud.includes('rect(width / 2 - 88, 579, 176, 25, 6)') &&
  hud.includes('textSize(11)') &&
  hud.includes('color(123,150,153,140)'),
  'actionable inspect and clue cues must remain backed and readable');
assert(!hud.includes("'CLUES ' + e.clues.length"),
  'clue cue must not expose a debug counter');
assert(source.includes("t.kind !== 'system'") && source.includes('if (!hasSceneNotice)') && source.includes('const messageX = width / 2 - messageW / 2'),
  'interactive Wake HUD must suppress duplicate scene notices and keep narrative copy aligned inside its panel');
assert(!source.includes('WASD / ARROWS MOVE   E INSPECT') && !source.includes("'CLUES ' + e.clues.length + ' / 3  //  2 REQUIRED'"),
  'interactive Wake HUD must not expose tutorial/debug control strings or numeric clue counters');
assert(!source.includes("'SETTLING IN  ·  ' + step + ' / '") && !source.includes("'TALK WITH TALEN  ·  ' + talenStep + ' / '"),
  'opening task progress must not expose dashboard-style numeric counters');
assert(source.includes('function drawWrongSongSetPiece') && source.includes('drawWrongSongSetPiece(now'),
  'v1.0 opening must stage the Wrong Song as a bounded visual set piece');
assert(source.includes("['ionia'"),
  'opening must use canonical Ionia sprite');
assert(source.includes("['lyra'"),
  'opening must use canonical Lyra sprite');
assert(source.includes('ellipse(') && source.includes('smooth()'),
  'opening visual stage must support smooth atmospheric/cinematic geometry');
assert(!source.includes('function drawShip(') && source.includes('AetherDragonflyVisual'),
  'opening must keep the Dragonfly under the shared ship authority while allowing environmental polygon geometry');

const dockSpriteCalls = [];
const behaviorSandbox = {
  window: {
    AetherPreviewWorldPresentation: { drawScenicBackdrop() {} },
    AetherDragonflyVisual: { draw() {} },
    AetherPixelSprites: {
      validate: () => true,
      drawShadow() {},
      draw(id, x, y, options) { dockSpriteCalls.push({ id, x, frame: options.frame }); },
      drawPreview(id, x, y, options) { dockSpriteCalls.push({ id, x, frame: options.frame }); },
    },
  },
  globalThis: {},
  width: 960,
  height: 640,
  noStroke() {}, fill() {}, rect() {}, ellipse() {}, quad() {}, triangle() {}, beginShape() {}, vertex() {}, endShape() {}, smooth() {}, stroke() {}, strokeWeight() {}, line() {}, CLOSE: 'close',
};
vm.runInNewContext(source, behaviorSandbox, { filename: 'first-wake-visual-stage-behavior.js' });
const dockVisual = behaviorSandbox.window.AetherFirstWakeVisual;
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 1, max: 8 } }, 1000);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 1, max: 8 } }, 1500);
assert(dockSpriteCalls.some(sprite => sprite.id === 'ender'),
  'dock renderer must draw Ender');
assert(dockSpriteCalls.some(sprite => sprite.id === 'ionia'),
  'dock renderer must draw Ionia');
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 2, max: 8 } }, 1600);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 2, max: 8 } }, 1730);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 3, max: 8 } }, 1760);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 4, max: 8 } }, 1860);
dockVisual.drawDock({ id: 'dock_walk', sequence: 2 }, { dockWalk: { x: 4, max: 8 } }, 2380);
assert.notStrictEqual(dockSpriteCalls[0].x, dockSpriteCalls[4].x,
  'Ender should advance along the dock when the walk state advances');
const enderCalls = dockSpriteCalls.filter(sprite => sprite.id === 'ender');
assert(enderCalls.length >= 4, 'dock walk must keep rendering Ender across progression');
assert(new Set(enderCalls.map(sprite => sprite.x)).size > 1,
  'Ender dock position must advance with authored walk progression');


const html = fs.readFileSync(path.join(root, 'index-embedded.html'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
assert(html.indexOf('modules/first-wake-visual-stage.js') >= 0,
  'First Wake visual stage script missing');
assert(html.indexOf('modules/first-wake-visual-stage.js') < html.indexOf('aetherwake.js'),
  'First Wake visual authority must load before runtime');
const openingStart = runtime.indexOf('function drawFirstWakeOpening() {');
const openingEnd = runtime.indexOf('\nfunction ensureAirNavigationState()', openingStart);
assert(openingStart >= 0 && openingEnd > openingStart, 'First Wake opening renderer missing');
const openingFunction = runtime.slice(openingStart, openingEnd);
assert(openingFunction.includes('const visual = window.AetherFirstWakeVisual;'),
  'opening renderer must acquire the shared First Wake visual authority');
assert(openingFunction.includes("typeof visual.draw === 'function'"),
  'opening renderer must verify the shared draw method');
assert(openingFunction.includes('visual.draw(scene, state, { now: millis(), width, height });'),
  'opening runtime does not delegate to shared visual stage');

console.log('Aetherwake First Wake visual stage contract: PASS');

assert(source.includes('const narrativePanelH = Math.min(112, 40 + visibleLines.length * 21)') && source.includes('String(scene.speaker || \'\').toUpperCase()'),
  'opening narration must use the expanded JRPG dialogue panel with admitted speaker-name treatment');
