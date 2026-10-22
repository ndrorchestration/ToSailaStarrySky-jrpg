const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const runtime = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');

const renderStart = runtime.indexOf('function render()');
const renderEnd = runtime.indexOf('// --- Ship Interior', renderStart);
const renderBlock = runtime.slice(renderStart, renderEnd);
const groundAt = renderBlock.indexOf('drawGroundLayer();');
const dockAt = renderBlock.indexOf('drawWakeDockComposition();');
const playerAt = renderBlock.indexOf('drawPlayer();');
assert(groundAt >= 0 && dockAt > groundAt && playerAt > dockAt,
  'Wake Dock composition must render above terrain and below actors');
assert(runtime.includes('function drawWakeDockComposition()'),
  'Wake Dock composition renderer is missing');
assert(runtime.includes('Worn traversal lanes connect the actual authored contact positions'),
  'Wake Dock lanes must remain presentation-only');
assert(runtime.includes('walkability and collision remain unchanged'),
  'Wake Dock composition must explicitly preserve gameplay collision');
assert(runtime.includes("text('WAKE DOCK'") &&
       runtime.includes("text('AUREATE WAKE // BERTH'"),
  'Wake Dock must expose place identity and berth context');

const grassStart = runtime.indexOf('function drawTileGrass');
const grassEnd = runtime.indexOf('function drawTileCrate', grassStart);
const grass = runtime.slice(grassStart, grassEnd);
assert(grass.includes('const hash = (tx * 17 + ty * 31 + tx * ty * 3) % 7'),
  'ground variation must be deterministic rather than random');
assert(!grass.includes('random('),
  'ground tile rendering must not use random state');

const playerStart = runtime.indexOf('function drawPlayer()');
const playerEnd = runtime.indexOf('// --- NPCs', playerStart);
const player = runtime.slice(playerStart, playerEnd);
assert(player.includes('scale(1.18)'),
  'Ender world sprite must preserve the readability-scale treatment');
assert(player.includes('fill(color(184, 137, 72))'),
  'Ender staff must retain visible brass ferrules');

const npcStart = runtime.indexOf('function drawNPC(npc)');
const npcEnd = runtime.indexOf('function drawNPCElder', npcStart);
const npc = runtime.slice(npcStart, npcEnd);
assert(npc.includes('scale(1.12)'),
  'world NPC sprite readability scale is missing');

const combatStart = runtime.indexOf('this.drawCombatScene = function');
const combatEnd = runtime.indexOf('if (typeof window !==', combatStart);
const combat = runtime.slice(combatStart, combatEnd);
assert(combat.includes('playerX = p.width * 0.38') &&
       combat.includes('playerY = p.height * 0.60'),
  'combat player staging must use deliberate scene coordinates');
assert(combat.includes('Raised berth platform creates a readable JRPG battle plane'),
  'combat stage platform is missing');
assert(combat.includes("p.text('WAKE DOCK // STORMFRONT EDGE'"),
  'combat stage must preserve Wake Dock location identity');
assert(combat.includes('const enemyScale = 1.28') &&
       combat.includes('p.scale(enemyScale)'),
  'enemy readability scale is missing');
assert(combat.includes('Grounded Ender combat silhouette') &&
       combat.includes('Staff with brass ferrules'),
  'Ender combat silhouette/staff treatment is missing');

assert(runtime.includes("const QUEST_STATES = {"),
  'quest state machine must remain present');
assert(runtime.includes("const MAP_SIZE       = 32;"),
  'canonical 32x32 world map contract must remain unchanged');

console.log('Aetherwake Chapter I world-depth presentation contract: PASS');
