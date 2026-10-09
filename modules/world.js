/* ============================================================
   aetherwake-jrpg/modules/world.js
   World / Map / Quest module for the Aetherwake JRPG.
   p5-compatible. No DOM creation inside draw().
   ============================================================ */

'use strict';

// ---------------------------------------------------------------------------
// Export surface — every name the rest of the app can reach
// ---------------------------------------------------------------------------
const World = {
  init, update, render,
  movePlayer, interact, toggleLayer,
  plantField, boardShip,
  openLedger, openShop,
  getQuestState, advanceQuest
};

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const MAP_SIZE       = 32;
const TILE_TYPES = {
  GROUND_SOLID  : 1,
  GROUND_GRASS  : 2,
  GROUND_CRATE  : 3,
  GROUND_FLOAT  : 4,   // floating island chunk
  GROUND_WATER  : 5,
  GROUND_LORE   : 6,   // lore tile — reveals story text when walked
  SKY_EMPTY     : 0,
  SKY_CLOUD     : 1,
  SKY_ASTRO     : 2    // distant celestial drift
};

const DAY_CYCLE_SEC       = 120;
const SOLAR_MAX_KWH       = 2.0;
const SOLAR_RATE_W        = 400;
const SOLAR_PEAK_FACTOR   = 1.0;

const QUEST_STATES = {
  SIGNAL   : 'signal',
  CROSSING : 'crossing',
  CONTACT  : 'contact',
  CHOICE   : 'choice',
  WAKE     : 'wake',
  DONE     : 'done'
};

// ---------------------------------------------------------------------------
// Globals (module-scoped; referenced by the rest of the app via World.*)
// ---------------------------------------------------------------------------
let groundLayer = [];
let skyLayer    = [];
let player = {};
let dayTime = 0;
let covenantField = null;
let isSkyLayerVisible = false;
let quest = {};
let npcs = [];
let ledger = { entries: [], title: 'Mycelial Ledger' };
let shop = null;
let gameOver = false;
let wakeVariants = [];
let currentInteractionKey = null;
let activeDialogue = null;

// p5 hooks — called by core.js setup()/draw()/update()
// ---------------------------------------------------------------------------

/**
 * init() — called once from core.js setup(). Builds map, NPCs, default state.
 */
function init() {
  buildMap();
  initNPCs();
  initPlayer();
  World.npcs = npcs;
  World.quest = quest;
  initQuest();
  initShop();
  initLedgerPlaceholder();
  covenantField = { x: 0, y: 0, planted: false, life: 0 };
  dayTime = 0;
  isSkyLayerVisible = false;
  gameOver = false;
}

// ---------------------------------------------------------------------------
// Map construction
// ---------------------------------------------------------------------------

function buildMap() {
  groundLayer = [];
  skyLayer    = [];
  for (let y = 0; y < MAP_SIZE; y++) {
    groundLayer[y] = new Array(MAP_SIZE);
    skyLayer[y]    = new Array(MAP_SIZE);
  }

  // Fill ground with grass by default
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      groundLayer[y][x] = TILE_TYPES.GROUND_GRASS;
    }
  }

  // Solid border
  for (let i = 0; i < MAP_SIZE; i++) {
    groundLayer[0][i]       = TILE_TYPES.GROUND_SOLID;
    groundLayer[MAP_SIZE-1][i] = TILE_TYPES.GROUND_SOLID;
    groundLayer[i][0]       = TILE_TYPES.GROUND_SOLID;
    groundLayer[i][MAP_SIZE-1] = TILE_TYPES.GROUND_SOLID;
  }

  // Columbus wreck debris zones
  const debrisSpots = [
    [5,5],[6,7],[7,4],[8,8],
    [14,4],[13,6],[15,7],
    [22,10],[23,11],[21,12],
    [4,22],[5,24],[3,23],
    [18,20],[19,22],[20,19],
    [27,27],[28,26],[26,28]
  ];
  for (const [x, y] of debrisSpots) {
    if (inBounds(x, y)) groundLayer[y][x] = TILE_TYPES.GROUND_CRATE;
  }

  // Lore tiles — walk over them to reveal story fragments
  const loreSpots = [
    { x: 3, y: 6, text: 'A child\'s drawing, preserved on a scrap of hull plating. The Dragonfly spreads four bright wings over three little ships while storm marks gather at the page edge.' },
    { x: 11, y: 5, text: 'The Aureate Wake\'s manifest, water-stained but legible: "Storm posture: local shielding unreliable. Maintain reserve power until dock authority clears the berth."' },
    { x: 19, y: 7, text: 'Ionia\'s watch log, tucked behind a cracked gauge: "Day 47. Standard systems answer the helm. The wider responses remain intermittent. Lyra says the ship listens."' },
    { x: 24, y: 14, text: 'A dock weather slate, cracked but still glowing: "Colony shield cycling irregularly. Adjacent berths vulnerable to lateral shear at stormfall."' },
    { x: 16, y: 20, text: 'Lyra\'s drawing of the Wakeheart: a brass insect made of winglight. She wrote beneath it: "If it opens wide enough, maybe it can hold more than us."' },
    { x: 9, y: 24, text: 'A salvager\'s note, pinned to a bulkhead with a rusted nail: "A vessel is not only its engine. Sometimes the missing part is the people brave enough to ask what it can do."' },
    { x: 28, y: 19, text: 'The Wakeheart diagnostic repeats one quiet line: "Helm, reach, and stranger-current detected. Patterns unresolved. Awaiting stable chord."' }
  ];
  for (const l of loreSpots) {
    if (inBounds(l.x, l.y)) {
      groundLayer[l.y][l.x] = TILE_TYPES.GROUND_LORE;
      groundLayer[l.y][l.x]._loreText = l.text;
    }
  }

  // 14 falling-upward islands
  const islands = [
    [4, 4], [7, 3], [12, 5], [18, 4],
    [25, 6], [3, 9], [10, 8], [16, 10],
    [23, 9], [29, 7], [5, 15], [13, 14],
    [20, 16], [27, 15]
  ];
  for (const [x, y] of islands) {
    if (inBounds(x, y)) {
      skyLayer[y][x]    = TILE_TYPES.SKY_CLOUD;
      groundLayer[y][x] = TILE_TYPES.GROUND_FLOAT;
    }
  }
}

function inBounds(x, y) {
  return x >= 0 && x < MAP_SIZE && y >= 0 && y < MAP_SIZE;
}

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------

function initPlayer() {
  player = {
    x: 16,
    y: 16,
    px: 16 * 16,
    py: 16 * 16,
    tileX: 16,
    tileY: 16,
    vit: 13,
    maxVit: 13,
    echoes: 3,
    echoesMax: 3,
    scrap: 7,
    gold: 60,
    aether: 4,
    aetherMax: 6,
    heat: 1,
    heatMax: 3,
    solarCharge: 1.0,
    staffCharges: 2,
    wits: 2,
    presence: 1,
    spirit: 1,
    might: -1,
    grace: 0,
    level: 1,
    xp: 0,
    xpToNext: 50,
    unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
    equipment: { staff: null, backpack: null },
    class: 'ender'
  };
  World.player = player;
}

// ---------------------------------------------------------------------------
// NPCs
// ---------------------------------------------------------------------------

function initNPCs() {
  npcs = [
    // 1 - Captain Ionia
    {
      id: 'elder_farmer',
      name: 'Captain Ionia',
      title: 'Captain of the Aureate Wake',
      x: 7,
      y: 7,
      tileX: 7,
      tileY: 7,
      dialogue: {
        intro: [
          '"The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found."',
          '"Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter."',
          '"Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits."',
          '"I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing."',
          '"If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do."'
        ],
        class_ender: [
          '"Your hands are on the rigging. You are not a navigator or a captain, and that may be why the ship is listening differently. You fix from inside the problem."',
          '"The frequencies settle when you cross the deck. Not enough for a doctrine. Enough for me to notice."',
          '"Do not mistake this for destiny. Ships do not need worship. They need crews who can hear one another under pressure."'
        ],
        class_farmer: [
          '"Navigation teaches the same lesson every watch: the sky tells the truth if you know how to read it. You notice wrongness before most people can name it. I can work with that."',
          '"Captain Denith taught me to trust instruments, weather, and people in that order only when the first two agree. Today, none of them agree cleanly."'
        ],
        generic_follow: [
          '"Check the dock reports, then the shield console. Meaning can wait until the shielding holds."'
        ],
        deep: [
          '"You have heard Lyra, the Wakeheart, and Verrick. None of them are wrong. That is what makes command unpleasant."',
          '"A captain can order a ship to leave. A crew decides whether leaving is the only kind of survival left."',
          '"If the Wake answers, it will not be because one person is special. It will be because, for one dangerous moment, we finally become legible to one another."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 2 - The Wakeheart
    {
      id: 'engine_spirit',
      name: 'Wakeheart',
      title: 'Harmonic Console of the Aureate Wake',
      x: 22,
      y: 10,
      tileX: 22,
      tileY: 10,
      dialogue: {
        intro: [
          '"Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing."',
          '"Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds."',
          '"Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising."',
          '"Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended."',
          '"Request: captain confirmation, reach stabilization, stranger-current consent."'
        ],
        class_ender: [
          '"Ender-pattern produces nonstandard agreement across helm, reach, and hull. Diagnostic category unavailable."',
          '"Your adjustments do not add power. They reduce disagreement."',
          '"If command is given, shield geometry can widen beyond the Wake\'s own silhouette. Survival probability improves for adjacent berths."'
        ],
        class_witch: [
          '"Listening pattern recognized. Harmonic access improves when observation is gentle."',
          '"The Wake does not require force. It requires accord."'
        ],
        generic_follow: [
          '"Awaiting stable chord."'
        ],
        deep: [
          '"Earlier crews produced flight. Current pattern suggests shelter."',
          '"Future capability cannot be extrapolated from present crew state. Additional voices may alter combat response, environmental envelope, and lane access."',
          '"Auroral-lane topology remains inaccessible. Requirement unknown. Crew-state insufficient."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 3 - Lyra
    {
      id: 'child_prophet',
      name: 'Lyra',
      title: 'Frequency-Sensitive Dreamer of the Aureate Wake',
      x: 8,
      y: 20,
      tileX: 8,
      tileY: 20,
      dialogue: {
        intro: [
          '"The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for."',
          '"I can hear the shield lattice when it tries to open. It gets lonely halfway through."',
          '"When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer."',
          '"The storm has teeth on the front edge. The little ships beside us are going to feel it first."',
          '"If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind."'
        ],
        class_ender: [
          '"You hear it too, just lower than I do. Like something green under a floorboard."',
          '"Ionia is the helm. I am the reach. You are... I do not know yet. The place where the answer says yes, maybe."',
          '"Do not tell the ship what it is. Ask what it can hold."'
        ],
        class_witch: [
          '"The frequencies get shy when people stare at them. Listen sideways."',
          '"The Wake hums better when nobody is trying to win an argument with it."'
        ],
        generic_follow: [
          '"The storm is closer. The ship knows. I think it wants us to notice the same thing at the same time."'
        ],
        deep: [
          '"I heard the wide shield before I saw the alert. It sounded like opening both hands."',
          '"If we leave now, we live smaller. If we stay, we might learn what the Wake thinks shelter means."',
          '"I am scared. That does not make the listening wrong."'
        ]
      },
      flags: { met: false, questMarker: true }
    },

    // 4 - Verrick
    {
      id: 'corporate_salvager',
      name: 'Verrick',
      title: 'Harbor Shield Officer',
      x: 26,
      y: 24,
      tileX: 26,
      tileY: 24,
      dialogue: {
        intro: [
          '"Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math."',
          '"Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible."',
          '"The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do."',
          '"I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it."',
          '"So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open."'
        ],
        class_corporate: [
          '"You understand systems, so here is the system: authority hates uncertainty, weather exploits delay, and captains hate being told both at once."',
          '"If you can give me a stable projection number, I can keep the dock from ordering you out."',
          '"A clean evacuation is a victory. A heroic mess is still a mess."'
        ],
        class_ender: [
          '"You are the new variable? Good. Variables are annoying, but sometimes they are where the answer is hiding."',
          '"If your ledger can track shield draw, track it now. I need proof before the dock board panics."',
          '"Do not sell me poetry, Ender. Give me a number I can defend and a reason not to clear this berth."'
        ],
        generic_follow: [
          '"My hold order stands until the stormfront crosses the outer pylons. After that, math gets rude."'
        ],
        deep: [
          '"I have watched captains gamble with other people\'s hulls and call it vision. I have also watched cautious people preserve a rule while a person died beside it."',
          '"If the Wake can shield the neighboring berths, I will sign the exception myself."',
          '"Just understand the cost. Push every shield face forward and your sides go soft. One bad cross-gust and the heroic answer becomes an expensive wreck."',
          '"Choose something you can live with after the sky clears."'
        ]
      },
      flags: { met: false, questMarker: true, classLock: 'corporate' }
    }
  ];
}

// ---------------------------------------------------------------------------
// Quest FSM — 'The Island That Falls Upward'
// ---------------------------------------------------------------------------

function initQuest() {
  quest = {
    state: QUEST_STATES.SIGNAL,
    act: 'signal',
    hooksCompleted: 0,
    hazardsCompleted: 0,
    npcsMet: [],
    choiceMade: null,
    choiceVariant: null,
    hullIntegrity: 100,
    morale: 50,
    heatLevel: 1,
    engineIntegration: 0,
    wakeEpilogue: null,
    discoveries: [],      // lore tiles discovered so far
  journal: [
    { state: 'signal', text: 'Ender boards the Aureate Wake as Wake Dock prepares for stormfall. The ship flies, but its deeper shield responses need the right crew to become clear.' },
    { state: 'crossing', text: 'Three dockside hazards stand between the crew and shield readiness. Each one tests whether the Wake can protect more than itself.' },
    { state: 'contact', text: 'Ender hears Ionia, Lyra, the Wakeheart, and Verrick. Each voice names a different cost of waiting, leaving, or reaching wider.' },
    { state: 'choice', text: 'The storm is turning. The crew must choose whether to leave early, hold dock, or project the Wake\'s shield across the neighboring berths.' }
  ],          // auto-populated journal entries
  journalToggle: false, // whether player has opened journal view
    signalHooks: [
      { id: 'harmonic_buoy', label: 'Wakeheart Diagnostic', done: false },
      { id: 'sky_lane_warning', label: 'Dock Shield Warning', done: false },
      { id: 'below_frequency', label: 'Lyra\'s Frequency Sketch', done: false }
    ],
    crossingHazards: [
      { id: 'sky_predator', label: 'Loose Cargo Sweep', done: false, stat: 'grace' },
      { id: 'wind_shear', label: 'Wind Shear', done: false, stat: 'grace' },
      { id: 'corporate_intercept', label: 'Dock Authority Hold', done: false, stat: 'wits' }
    ],
    contactNPCs: [
      { id: 'elder_farmer', label: 'Ionia' },
      { id: 'engine_spirit', label: 'Wakeheart' },
      { id: 'child_prophet', label: 'Lyra' },
      { id: 'corporate_salvager', label: 'Verrick' }
    ],
    choicePaths: [
      {
        id: 'path_a',
        label: 'Leave early / Beat the storm',
        description: 'Launch before the front arrives. Save the Wake by refusing the wider risk.',
        outcomes: {
          '10+': 'The Wake clears the dock ahead of the storm. Ionia keeps everyone alive, but the berths behind you vanish into weather static. Lyra watches the empty horizon and says the ship wanted to try.',
          '7-9':  'The Wake launches late and takes shear along the port wing. You survive, but the flight is rough and the dock calls after you until the signal breaks.'
        }
      },
      {
        id: 'path_b',
        label: 'Hold dock / Stabilize the colony shield',
        description: 'Stay moored and route power into the local shield grid.',
        outcomes: {
          '10+': 'The colony shield steadies long enough for the neighboring crews to brace. The Wake remains safe, though the deeper alert on the console fades unanswered.',
          '7-9':  'The local shield catches, but only in pulses. The Wake holds her berth while smaller craft take damage at the edge of the umbrella.'
        }
      },
      {
        id: 'path_c',
        label: 'Project shield / Cover the berths',
        description: 'Let the Wake front-load her shield into a wide stormward umbrella.',
        outcomes: {
          '10+': 'The Wake turns her shield like a bright wing into the storm. For one impossible minute, three vessels survive under one shelter. Ionia, Lyra, and Ender feel the ship answer as if a hidden circuit finally closed.',
          '7-9':  'The umbrella holds, but the Wake pays for it. Side shielding thins, alarms bloom, and everyone aboard learns that miracles still need engineering.'
        }
      }
    ],
    epilogues: [
      { id: 'epiline_5', name: 'The Weather-Bruised',
        trigger: () => quest.hullIntegrity < 40 || quest.morale < 20,
        text: 'The Wake survives stormfall damaged and shaken. The crew has proof that the ship can answer them, but also proof that courage without balance has a cost.' },
      { id: 'epiline_1', name: 'The Clear Departure',
        trigger: () => quest.hullIntegrity >= 60 && quest.morale >= 45 && (quest.engineIntegration < 50 || quest.choicePath === 'path_a'),
        text: 'The Wake beats the storm into open sky. You are alive, the ship is steady, and the unanswered shield alert follows you like a question waiting for better weather.' },
      { id: 'epiline_2', name: 'The Shield-Bound',
        trigger: () => quest.hullIntegrity >= 50 && quest.engineIntegration >= 70,
        text: 'The Wake\'s shield lattice remembers the three of you. After stormfall, the console keeps offering patterns no captain has seen since Denith.' },
      { id: 'epiline_3', name: 'Verrick\'s Weather Ledger',
        trigger: () => quest.morale >= 40 && quest.hullIntegrity >= 40 && quest.choicePath === 'path_b',
        text: 'Verrick files the exception with no jokes in the margins. The colony shield held because the Wake stayed, and official records become a little less certain about what counts as impossible.' },
      { id: 'epiline_4', name: 'Lyra\'s Wide Wing',
        trigger: () => quest.choicePath === 'path_c' && quest.morale >= 60,
        text: 'Lyra draws the storm afterward: one bright wing, three small ships, and a crew shaped like a chord. She does not know what it means yet. She only knows it happened.' },
      { id: 'epiline_6', name: 'The First Chord',
        trigger: () => quest.choicePath === 'path_c' && quest.engineIntegration >= 60 && quest.hullIntegrity >= 50,
        text: 'The umbrella vector becomes the first real secret the Wake gives back. Not a prophecy. Not a chosen one. A crew, briefly aligned, and a ship that can do more when it is understood.' }
    ]
  };
  World.quest = quest;
}

// ---------------------------------------------------------------------------
// Quest FSM API
// ---------------------------------------------------------------------------

function getQuestState() {
  return {
    state: quest.state,
    act: quest.act,
    hooksCompleted: quest.hooksCompleted,
    hazardsCompleted: quest.hazardsCompleted,
    npcsMet: quest.npcsMet.slice(),
    choiceMade: quest.choiceMade,
    choiceVariant: quest.choiceVariant,
    hullIntegrity: quest.hullIntegrity,
    morale: quest.morale,
    heatLevel: quest.heatLevel,
    engineIntegration: quest.engineIntegration,
    signalHooks: quest.signalHooks.map(h => ({ ...h })),
    crossingHazards: quest.crossingHazards.map(h => ({ ...h })),
    contactNPCs: quest.contactNPCs.map(n => ({ ...n })),
    choicePaths: quest.choicePaths.map(p => ({ ...p })),
    epilogues: quest.epilogues.map(e => ({ id: e.id, name: e.name }))
  };
}

/**
 * advanceQuest() — re-derives the next state from current progress.
 */
function advanceQuest() {
  if (gameOver) return;

  switch (quest.state) {
    case QUEST_STATES.SIGNAL:
      advanceSignal();
      break;
    case QUEST_STATES.CROSSING:
      advanceCrossing();
      break;
    case QUEST_STATES.CONTACT:
      advanceContact();
      break;
    case QUEST_STATES.CHOICE:
      advanceChoice();
      break;
    case QUEST_STATES.WAKE:
      advanceWake();
      break;
    case QUEST_STATES.DONE:
      break;
  }
}

function advanceSignal() {
  if (quest.hooksCompleted >= 3) {
    quest.state = QUEST_STATES.CROSSING;
    quest.act = 'crossing';
    appendJournalEntry('crossing', 'The stormfront turns toward Wake Dock. Three hazards now stand between the crew and a usable shield posture.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.hooksCompleted >= 1) {
    appendJournalEntry('signal', 'You found the first useful reading. The Wake is not explaining itself, but it is answering.');
  }
}

function advanceCrossing() {
  if (quest.hazardsCompleted >= 3) {
    quest.state = QUEST_STATES.CONTACT;
    quest.act = 'contact';
    appendJournalEntry('contact', 'The dockside hazards are behind you. Four voices now frame the same question: leave, hold, or shelter wider.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.hazardsCompleted >= 1) {
    appendJournalEntry('crossing', 'One hazard is under control. The storm is closer, and the shield math is getting less theoretical.');
  }
}

function advanceContact() {
  if (quest.npcsMet.length >= 4) {
    quest.state = QUEST_STATES.CHOICE;
    quest.act = 'choice';
    appendJournalEntry('choice', 'All four voices heard. The ship holds steady while the storm asks for a decision.');
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  } else if (quest.npcsMet.length >= 1) {
    const met = quest.npcsMet.length;
    appendJournalEntry('contact', met + ' soul' + (met > 1 ? 's' : '') + ' spoken to. The core hums a little louder each time.');
  }
}

function advanceChoice() {
  if (quest.choiceMade) {
    quest.state = QUEST_STATES.WAKE;
    quest.act = 'wake';
    resolveEpilogue();
    if (typeof triggerQuestAdvance === 'function') triggerQuestAdvance();
  }
}

function advanceWake() {
  if (!quest.wakeEpilogue) {
    resolveEpilogue();
  }
  if (quest.wakeEpilogue) {
    quest.state = QUEST_STATES.DONE;
    quest.act = 'done';
    gameOver = true;
    appendJournalEntry('done', 'The ending found you. Epilogue: ' + quest.wakeEpilogue.name + '. The ledger closes on its own.');
  }
}

function appendJournalEntry(state, text) {
  quest.journal.push({ state, text });
}

function resolveEpilogue() {
  for (const ep of quest.epilogues) {
    if (ep.trigger()) {
      quest.wakeEpilogue = ep;
      return;
    }
  }
  quest.wakeEpilogue = quest.epilogues[0];
}

// ---------------------------------------------------------------------------
// Interaction
// ---------------------------------------------------------------------------

/**
 * movePlayer(dx, dy) — dx,dy in tile units (-1,0,1).
 */
function movePlayer(dx, dy) {
  if (gameOver) return;
  const nx = player.tileX + dx;
  const ny = player.tileY + dy;
  if (!inBounds(nx, ny)) return;
  if (groundLayer[ny][nx] === TILE_TYPES.GROUND_SOLID) return;
  player.tileX = nx;
  player.tileY = ny;
  player.px = player.tileX * 16;
  player.py = player.tileY * 16;
  checkHazardProximity(nx, ny);
  checkLoreTile(nx, ny);
}

function checkLoreTile(tx, ty) {
  const t = groundLayer[ty] && groundLayer[ty][tx];
  if (t === TILE_TYPES.GROUND_LORE) {
    // Check if already discovered
    if (!quest.discoveries.some(d => d.x === tx && d.y === ty)) {
      const tile = groundLayer[ty][tx];
      const loreText = tile._loreText || 'Something hums beneath your feet.';
      quest.discoveries.push({ x: tx, y: ty, text: loreText });
      addLedgerEntry('discovery', 'You found something: ' + loreText);
      // Add a journal entry referencing the discovery
      quest.journal.push({
        state: quest.state,
        text: 'Discovery at (' + tx + ', ' + ty + '): ' + loreText
      });
    }
  }
}

function checkHazardProximity(tx, ty) {
  if (tx >= 28 && ty >= 4 && ty <= 8 && !quest.crossingHazards[0].done) {
    if (Math.random() < 0.15) {
      completeHazard(0);
    }
  }
  if (tx >= 10 && tx <= 20 && ty >= 8 && ty <= 14 && !quest.crossingHazards[1].done) {
    if (Math.random() < 0.1) {
      completeHazard(1);
    }
  }
  if (ty <= 5 && tx >= 15 && tx <= 25 && !quest.crossingHazards[2].done) {
    if (Math.random() < 0.08) {
      completeHazard(2);
    }
  }
}

function completeHazard(index) {
  quest.crossingHazards[index].done = true;
  quest.hazardsCompleted++;
  advanceQuest();
}

function toggleLayer() {
  isSkyLayerVisible = !isSkyLayerVisible;
  // Re-draw prompt
  if (isSkyLayerVisible) {
    addLedgerEntry('toggle', 'Sky layer revealed — the 14 floating deck-islands hang above.');
  } else {
    addLedgerEntry('toggle', 'Sky layer hidden — only the ground remains.');
  }
}

/**
 * interact() — dispatches on the key passed from core.js.
 */
function interact() {
  if (gameOver) return;
  const key = window.interactionKey;
  if (!key) return;

  switch (key) {
    case 'e': doTalk();          break;
    case 'q': plantField();      break;
    case 'f': boardShip();       break;
    case 'tab': toggleLayer();   break;
    case 'l': openLedger();      break;
    case 'm': openShop();        break;
  }
}

/**
 * doTalk() — find nearest NPC within 2 tiles, show dialogue.
 */
function doTalk() {
  const nearest = findNearestNPC(2);
  if (!nearest) return;

  if (!nearest.flags.met) {
    nearest.flags.met = true;
    if (!quest.npcsMet.includes(nearest.id)) {
      quest.npcsMet.push(nearest.id);
    }
    if (quest.state === QUEST_STATES.CONTACT || quest.state === QUEST_STATES.CHOICE) {
      advanceQuest();
    }
  }

  if (quest.state === QUEST_STATES.SIGNAL) {
    checkSignalHook(nearest);
  }

  openDialogue(nearest);
}

function checkSignalHook(npc) {
  if (npc.id === 'engine_spirit') {
    completeSignalHook('harmonic_buoy');
  }
  if (npc.id === 'corporate_salvager') {
    completeSignalHook('sky_lane_warning');
  }
  if (npc.id === 'child_prophet') {
    completeSignalHook('below_frequency');
  }
}

function completeSignalHook(hookId) {
  const hook = quest.signalHooks.find(h => h.id === hookId);
  if (hook && !hook.done) {
    hook.done = true;
    quest.hooksCompleted++;
    advanceQuest();
  }
}

function findNearestNPC(range) {
  let best = null;
  let bestDist = Infinity;
  for (const npc of npcs) {
    const d = Math.abs(npc.tileX - player.tileX) + Math.abs(npc.tileY - player.tileY);
    if (d <= range && d < bestDist) {
      bestDist = d;
      best = npc;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Dialogue state
// ---------------------------------------------------------------------------

function openDialogue(npc) {
  const classKey = getClassLockKey(npc);
  let lines = [];

  if (!npc.flags.met) {
    lines = npc.dialogue.intro.slice();
  } else {
    const classLines = npc.dialogue['class_' + classKey];
    if (classLines) {
      lines = classLines.slice();
    } else if (npc.dialogue.generic_follow) {
      lines = npc.dialogue.generic_follow.slice();
    } else {
      lines = npc.dialogue.intro.slice();
    }
  }

  // Build a stable batch identifier from the NPC's actual dialogue structure.
  // batch keys: 'intro' | 'class_ender' | 'class_corporate' | 'generic_follow'
  // Matches the on-disk audio layout: tts/{npc_id}/{batch}/{NN}.mp3
  let batch = 'intro';
  if (npc.flags.met) {
    const classKey = getClassLockKey(npc);
    const classLines = npc.dialogue['class_' + classKey];
    if (classLines && classLines.length > 0) {
      batch = 'class_' + classKey;
    } else {
      batch = 'generic_follow';
    }
    if (!npc.dialogue[batch] || npc.dialogue[batch].length === 0) {
      batch = 'intro';  // fallback: play intro audio on repeat if follow-up batch is empty
    }
  }

  window.UI.dialogueOpen = true;
  window.UI.dialogueNPC = npc;
  window.UI.dialogueText = lines[0] || '...';
  window.UI.dialogueLines = lines;
  window.UI.dialogueLineIndex = 0;
  // TTS audio state
  window.UI.dialogueAudioNPC = npc.id;
  window.UI.dialogueAudioBatch = batch;
  window.UI.dialogueAudioPlayed = false;

  // ── Dialogue type-in effect ──
  if (typeof startDialogueTypeIn === 'function') {
    startDialogueTypeIn(lines[0] || '...');
  }

  // ── NPC name reveal animation trigger ──
  if (typeof triggerScreenFlash === 'function') {
    triggerScreenFlash(42, 255, 181, 200, 60);
  }

  activeDialogue = {
    npc: npc,
    lines: lines,
    lineIndex: 0,
    closed: false
  };

  playDialogueAudioLine();
}

function getClassLockKey(npc) {
  if (npc.flags.classLock) {
    return npc.flags.classLock;
  }
  return (player.class && player.class.toLowerCase()) || 'ender';
}

function closeDialogue() {
  if (activeDialogue) {
    activeDialogue.closed = true;
    activeDialogue = null;
    stopDialogueAudio();
  }
}

function nextDialogueLine() {
  if (!activeDialogue) return null;
  if (activeDialogue.lineIndex < activeDialogue.lines.length - 1) {
    activeDialogue.lineIndex++;
    window.UI.dialogueLineIndex = activeDialogue.lineIndex;
    window.UI.dialogueText = activeDialogue.lines[activeDialogue.lineIndex];
    // Advance TTS to the next line's audio clip
    window.UI.dialogueAudioPlayed = false;
    playDialogueAudioLine();
    return activeDialogue.lines[activeDialogue.lineIndex];
  }
  const last = activeDialogue.lines[activeDialogue.lineIndex];
  stopDialogueAudio();
  closeDialogue();
  return last;
}

function getCurrentDialogueLine() {
  if (!activeDialogue) return null;
  return activeDialogue.lines[activeDialogue.lineIndex];
}

// ---------------------------------------------------------------------------
// Dialogue audio (TTS voice clips)
// Files on disk: tts/{npc_id}/{batch}/{line_number:02d}.mp3
// Example: tts/elder_farmer/intro/01.mp3
// Played when dialogue opens / advances; triggered from openDialogue + nextDialogueLine.
// ---------------------------------------------------------------------------

let _dialogueAudioEl = null;

function playDialogueAudioLine() {
  const npcId  = window.UI.dialogueAudioNPC;
  const batch  = window.UI.dialogueAudioBatch;
  const idx    = window.UI.dialogueLineIndex;
  if (!npcId || !batch || idx == null || idx < 0) return;
  const lineNum = String(idx + 1).padStart(2, '0');
  const src = 'tts/' + npcId + '/' + batch + '/' + lineNum + '.mp3';
  try {
    if (!_dialogueAudioEl) {
      _dialogueAudioEl = new Audio();
      _dialogueAudioEl.volume = 0.92;
    }
    _dialogueAudioEl.src = src;
    _dialogueAudioEl.play().catch(function(err) {
      console.warn('[TTS] play failed for ' + src + ': ' + err.message);
    });
  } catch (e) {
    console.warn('[TTS] audio error for ' + src + ': ' + e.message);
  }
}

function stopDialogueAudio() {
  if (_dialogueAudioEl) {
    try { _dialogueAudioEl.pause(); } catch (e) { /* ignore */ }
    _dialogueAudioEl = null;
  }
}

// ---------------------------------------------------------------------------
// Covenant Field — Q press
// ---------------------------------------------------------------------------

function plantField() {
  if (gameOver) return;
  if (covenantField.planted) {
    covenantField.planted = false;
    covenantField.life = 0;
    return;
  }
  covenantField.x = player.tileX;
  covenantField.y = player.tileY;
  covenantField.planted = true;
  covenantField.life = 12;
  if (player.aether > 0) {
    player.aether--;
  } else {
    covenantField.planted = false;
    return;
  }
  // Visual feedback — ring expansion
  if (typeof emitRing === 'function') {
    emitRing(covenantField.x * 16 + 8, covenantField.y * 16 + 8, 12, 30, 50, [42, 255, 181]);
  }
  if (typeof triggerScreenFlash === 'function') {
    triggerScreenFlash(42, 255, 181, 300, 80);
  }
}

function updateCovenantField(dt) {
  if (!covenantField.planted) return;
  covenantField.life -= dt;
  if (covenantField.life <= 0) {
    covenantField.planted = false;
  }
}

// ---------------------------------------------------------------------------
// Board ship — F press
// ---------------------------------------------------------------------------

function boardShip() {
  if (gameOver) return;
  const shipTileX = 23;
  const shipTileY = 10;
  const dist = Math.abs(player.tileX - shipTileX) + Math.abs(player.tileY - shipTileY);
  if (dist <= 2) {
    player.shipBoarded = true;
    player.shipTileX = 0;
    player.shipTileY = 0;
    const spirit = npcs.find(n => n.id === 'engine_spirit');
    if (spirit && !spirit.flags.met) {
      spirit.flags.met = true;
      if (!quest.npcsMet.includes(spirit.id)) {
        quest.npcsMet.push(spirit.id);
      }
      checkSignalHook(spirit);
    }
    advanceQuest();
  }
}

// ---------------------------------------------------------------------------
// Ledger — L press
// ---------------------------------------------------------------------------

function initLedgerPlaceholder() {
  ledger.entries = [
    { type: 'start', text: 'The ledger opens in your hands. It remembers everything you\'ve forgotten.' },
    { type: 'note', text: 'Day cycle: 120s. Solar charge peaks at midday.' }
  ];
}

function openLedger() {
  ledger.open = true;
}

function closeLedger() {
  ledger.open = false;
}

function addLedgerEntry(type, text) {
  ledger.entries.push({ type, text, time: dayTime });
}

// ---------------------------------------------------------------------------
// Shop — M press (Repair Cafe)
// ---------------------------------------------------------------------------

function initShop() {
  shop = {
    name: 'Repair Cafe',
    owner: 'Maeve of the Tinker\'s Hand',
    x: 14,
    y: 22,
    open: false,
    items: [
      { name: 'Solar Resonator Recharge', cost: 12, kind: 'gold', effect: 'aether', desc: 'Restore 1 aether charge.' },
      { name: 'Staff Crystal Polish',     cost: 8,  kind: 'gold', effect: 'staffCharges', desc: 'Restore 1 staff charge.' },
      { name: 'Mycelial Thread Sheaf',   cost: 18, kind: 'gold', effect: 'echoesMax', desc: '+1 echo capacity (permanent).' },
      { name: 'Nav-Line Compass',         cost: 24, kind: 'gold', effect: 'navLineCompass', desc: 'Survival advantage on sky crossings.' },
      { name: 'Hull Patch Kit',           cost: 10, kind: 'gold', effect: 'hullIntegrity', desc: '+10 hull integrity.' },
      { name: 'Heat Sink Fitting',        cost: 16, kind: 'gold', effect: 'heatMax', desc: '+1 heat capacity.' }
    ]
  };
}
function openShop() {
  const dist = Math.abs(player.tileX - shop.x) + Math.abs(player.tileY - shop.y);
  if (dist > 3) {
    return;
  }
  shop.open = true;
}

function closeShop() {
  shop.open = false;
}

function purchaseItem(itemIndex) {
  if (!shop || !shop.items[itemIndex]) return false;
  const item = shop.items[itemIndex];
  if (item.kind !== 'gold' || player.gold < item.cost) return false;

  const maxStaffCharges = player.maxStaffCharges || 2;
  if (item.effect === 'aether' && player.aether >= player.aetherMax) return false;
  if (item.effect === 'staffCharges' && player.staffCharges >= maxStaffCharges) return false;
  if (item.effect === 'navLineCompass' && player.navLineCompass === true) return false;

  player.gold -= item.cost;
  switch (item.effect) {
    case 'aether':
      player.aether = Math.min(player.aetherMax, player.aether + 1);
      break;
    case 'staffCharges':
      player.staffCharges = Math.min(maxStaffCharges, player.staffCharges + 1);
      break;
    case 'echoesMax':
      player.echoesMax += 1;
      player.echoes = Math.min(player.echoesMax, player.echoes + 1);
      break;
    case 'navLineCompass':
      player.navLineCompass = true;
      break;
    case 'hullIntegrity':
      quest.hullIntegrity = Math.min(100, quest.hullIntegrity + 10);
      break;
    case 'heatMax':
      player.heatMax += 1;
      break;
    default:
      player.gold += item.cost;
      return false;
  }
  addLedgerEntry('purchase', 'Bought ' + item.name + ' from Repair Cafe.');
  return true;
}

// ---------------------------------------------------------------------------
// Day-night cycle & solar charge
// ---------------------------------------------------------------------------

function updateDayNight(dt) {
  dayTime = (dayTime + dt / DAY_CYCLE_SEC) % 1.0;
  const solarFactor = Math.sin(dayTime * Math.PI);
  const chargeRate = (SOLAR_RATE_W / 1000) * solarFactor * (dt / 60);
  player.solarCharge = Math.min(SOLAR_MAX_KWH, player.solarCharge + chargeRate);
  if (solarFactor > 0.3 && player.staffCharges < 2) {
    // staffChargeRegen tick
  }
}

function getSolarFactor() {
  return Math.sin(dayTime * Math.PI);
}

function isDay() {
  return dayTime > 0.15 && dayTime < 0.85;
}

function isNight() {
  return !isDay();
}

// ---------------------------------------------------------------------------
// World update
// ---------------------------------------------------------------------------

function update(dt) {
  if (gameOver) return;
  const cdt = Math.min(dt, 0.05);
  updateDayNight(cdt);
  updateCovenantField(cdt);

  const lerpSpeed = 8 * cdt;
  player.px += (player.tileX * 16 - player.px) * Math.min(1, lerpSpeed);
  player.py += (player.tileY * 16 - player.py) * Math.min(1, lerpSpeed);

  if (getSolarFactor() > 0.25 && player.staffCharges < 2) {
    // regen tick
  }

  if (player.shipBoarded) {
    // ship interior movement
  }
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function render() {
  drawGroundLayer();
  if (isSkyLayerVisible) {
    drawSkyLayer();
  }
  drawCovenantField();
  drawWorldAmbient();
  drawPlayer();
  drawNPCs();
  drawQuestOverlay();
  drawSolarMeter();
}

// --- Ground Layer -----------------------------------------------------------

function drawGroundLayer() {
  const tileSize = 16;
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      const t = groundLayer[y][x];
      const px = x * tileSize;
      const py = y * tileSize;
      switch (t) {
        case TILE_TYPES.GROUND_SOLID:
          drawTileSolid(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_GRASS:
          drawTileGrass(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_CRATE:
          drawTileCrate(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_FLOAT:
          drawTileFloat(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_WATER:
          drawTileWater(px, py, tileSize);
          break;
        case TILE_TYPES.GROUND_LORE:
          drawTileLore(px, py, tileSize);
          break;
        default:
          drawTileGrass(px, py, tileSize);
      }
    }
  }
}

function drawTileSolid(px, py, s) {
  const rust = color(120, 60, 30);
  const dark = color(60, 30, 15);
  fill(rust);
  noStroke();
  rect(px, py, s, s);
  fill(dark);
  rect(px + 3, py + 3, 2, 2);
  rect(px + s - 5, py + 3, 2, 2);
  rect(px + 3, py + s - 5, 2, 2);
  rect(px + s - 5, py + s - 5, 2, 2);
}

function drawTileGrass(px, py, s) {
  const tan = color(180, 160, 120);
  fill(tan);
  noStroke();
  rect(px, py, s, s);
  stroke(color(80, 120, 60));
  strokeWeight(1);
  const seed = (px * 7 + py * 13) % 5;
  if (seed === 0) {
    line(px + 4, py + s, px + 4, py + s - 4);
    line(px + 8, py + s, px + 8, py + s - 3);
  } else if (seed === 1) {
    line(px + 6, py + s, px + 6, py + s - 5);
  } else if (seed === 2) {
    line(px + 2, py + s, px + 2, py + s - 3);
    line(px + 10, py + s, px + 10, py + s - 4);
  }
  noStroke();
}

function drawTileCrate(px, py, s) {
  const wood = color(140, 100, 60);
  const darkWood = color(90, 60, 30);
  fill(wood);
  noStroke();
  rect(px, py, s, s);
  stroke(darkWood);
  strokeWeight(1);
  line(px, py + s/2, px + s, py + s/2);
  line(px + s/2, py, px + s/2, py + s);
  noStroke();
  fill(darkWood);
  rect(px + 2, py + 2, 2, 2);
  rect(px + s - 4, py + 2, 2, 2);
  rect(px + 2, py + s - 4, 2, 2);
  rect(px + s - 4, py + s - 4, 2, 2);
  noStroke();
}

function drawTileFloat(px, py, s) {
  const earth = color(110, 90, 60);
  fill(earth);
  noStroke();
  rect(px, py, s, s);
  noFill();
  stroke(color(42, 255, 181, 40));
  strokeWeight(1);
  rect(px, py, s, s);
  noStroke();
  fill(color(100, 140, 70));
  rect(px + 3, py, s - 6, 3);
}

function drawTileWater(px, py, s) {
  const blue = color(60, 120, 160, 120);
  fill(blue);
  noStroke();
  rect(px, py, s, s);
  noFill();
  stroke(color(100, 180, 220, 100));
  strokeWeight(1);
  ellipse(px + s/2, py + s/2, s * 0.4, s * 0.2);
  noStroke();
}

function drawTileLore(px, py, s) {
  const tile = groundLayer[py / s] && groundLayer[py / s][px / s];
  const loreText = tile && tile._loreText ? tile._loreText : '';
  const discovered = quest.discoveries.some(d => d.x === px / s && d.y === py / s);

  // Base: dark crate with subtle cyan outline
  fill(color(60, 50, 40));
  noStroke();
  rect(px, py, s, s);
  stroke(color(42, 255, 181, discovered ? 100 : 30));
  strokeWeight(1);
  noFill();
  rect(px + 2, py + 2, s - 4, s - 4);
  noStroke();

  // Discovered: show a faint icon/mark
  if (discovered) {
    fill(color(42, 255, 181, 120));
    noStroke();
    ellipse(px + s/2, py + s/2, 4, 4);
  } else {
    // Undiscovered: question mark glyph
    fill(color(180, 160, 140, 120));
    noStroke();
    textAlign(CENTER, CENTER);
    textSize(8);
    textFont('VT323');
    text('?', px + s/2, py + s/2);
  }
}

// --- Sky Layer --------------------------------------------------------------

function drawSkyLayer() {
  const tileSize = 16;
  for (let y = 0; y < MAP_SIZE; y++) {
    for (let x = 0; x < MAP_SIZE; x++) {
      const t = skyLayer[y] && skyLayer[y][x];
      if (!t || t === TILE_TYPES.SKY_EMPTY) continue;
      const px = x * tileSize;
      const py = y * tileSize;
      if (t === TILE_TYPES.SKY_CLOUD) {
        drawSkyCloud(px, py, tileSize);
      } else if (t === TILE_TYPES.SKY_ASTRO) {
        drawSkyAstro(px, py, tileSize);
      }
    }
  }
  drawFallingIslands();
}

function drawSkyCloud(px, py, s) {
  const cloudCol = color(120, 160, 180, 80);
  fill(cloudCol);
  noStroke();
  ellipse(px + s/2, py + s/2, s * 1.2, s * 0.7);
  noStroke();
}

function drawSkyAstro(px, py, s) {
  const astro = color(200, 220, 255, 100);
  noFill();
  stroke(astro);
  strokeWeight(1);
  ellipse(px + s/2, py + s/2, s * 0.6, s * 0.6);
  noStroke();
}

function drawFallingIslands() {
  const islands = [
    [4,4],[7,3],[12,5],[18,4],
    [25,6],[3,9],[10,8],[16,10],
    [23,9],[29,7],[5,15],[13,14],
    [20,16],[27,15]
  ];
  const fallOffset = (dayTime * 8) % 4;
  for (const [ix, iy] of islands) {
    const cx = ix * 16 + 8;
    const cy = iy * 16 + 8 - fallOffset;
    noFill();
    stroke(color(42, 255, 181, 60));
    strokeWeight(2);
    ellipse(cx, cy, 22, 14);
    noStroke();
    fill(color(60, 70, 50, 180));
    noStroke();
    ellipse(cx, cy, 18, 10);
    fill(color(80, 120, 60));
    ellipse(cx, cy - 4, 14, 4);
    noStroke();
    noFill();
    stroke(color(42, 255, 181, 100));
    strokeWeight(1);
    ellipse(cx, cy, 18, 10);
    noStroke();
  }
  noStroke();
}

// --- World Ambient Atmosphere ------------------------------------------------

function drawWorldAmbient() {
  const now = millis();

  // ── Floating aether motes (ambient atmosphere — teal-blue motes drifting) ──
  for (let i = 0; i < 12; i++) {
    const seed = i * 137.5;
    const bx = (seed + player.px * 0.2) % width;
    const by = ((i * 97.3 + 20) % (height * 0.5)) + Math.sin(now * 0.0005 + i * 2.3) * 40;
    const driftX = Math.sin(now * 0.0008 + i * 1.7) * 25;
    const driftY = Math.cos(now * 0.0006 + i * 1.3) * 18;
    const moteAlpha = 8 + Math.sin(now * 0.002 + i * 3.1) * 5;
    const moteSize = 2 + Math.sin(now * 0.003 + i * 2.7) * 0.8;

    noStroke();
    fill(color(124, 200, 232, moteAlpha));
    ellipse(bx + driftX, by + driftY, moteSize, moteSize);

    // Soft teal core
    fill(color(42, 255, 181, moteAlpha * 0.4));
    ellipse(bx + driftX, by + driftY, moteSize * 1.8, moteSize * 1.8);
  }

  // ── Ground mist wisps (bottom of screen — low teal fog) ──
  for (let i = 0; i < 4; i++) {
    const mistX = (i * 220 + (now * 0.02 + i * 50) % width) % width;
    const mistY = height - 40 - i * 12 + Math.sin(now * 0.001 + i * 2) * 8;
    fill(color(42, 255, 181, 6));
    noStroke();
    ellipse(mistX, mistY, 180, 16);
    fill(color(124, 200, 232, 4));
    ellipse(mistX + 30, mistY - 5, 140, 12);
  }

  // ── Aether drift particles (slow rise from below) ──
  for (let i = 0; i < 6; i++) {
    const riseBase = ((i * 193 + 47) % width);
    const riseY = (height - 20 - (now * 0.002 + i * 30) % (height * 0.7));
    const riseAlpha = map(riseY, height - 20, 50, 0, 20);
    if (riseAlpha > 0) {
      noStroke();
      fill(color(42, 255, 181, riseAlpha));
      ellipse(riseBase, riseY, 3 + Math.sin(now * 0.004 + i) * 1.5, 2 + Math.cos(now * 0.003 + i * 2) * 1);
    }
  }

  // ── Quest-state atmospheric tint ──
  const tint = {
    signal:   { r: 42, g: 255, b: 181 },
    crossing: { r: 255, g: 160, b: 60 },
    contact:  { r: 100, g: 200, b: 255 },
    choice:   { r: 255, g: 200, b: 80 },
    wake:     { r: 200, g: 180, b: 255 },
    done:     { r: 255, g: 255, b: 200 }
  }[quest.state] || { r: 42, g: 255, b: 181 };

  const alphaBase = { signal: 6, crossing: 10, contact: 8, choice: 14, wake: 18, done: 20 }[quest.state] || 6;
  noStroke();
  fill(tint.r, tint.g, tint.b, alphaBase);
  rect(0, 0, width, height);

  // ── Floating accent motes (quest-state colored, intensifies in choice/wake) ──
  const accentCount = (quest.state === 'choice' || quest.state === 'wake') ? 16 : 8;
  const accentSpeed = (quest.state === 'choice' || quest.state === 'wake') ? 0.004 : 0.0025;
  for (let i = 0; i < accentCount; i++) {
    const seed = i * 73.1;
    const ax = (seed + player.px * 0.15) % width;
    const ay = ((i * 131.7 + 30) % height);
    const driftY = Math.sin(now * accentSpeed + i * 3.7) * 30;
    const a = 5 + Math.sin(now * 0.003 + i * 2.1) * 4;
    fill(color(tint.r, tint.g, tint.b, a));
    ellipse(ax, ay + driftY, 1.5, 1.5);
  }
}

// --- Covenant Field ----------------------------------------------------------

function drawCovenantField() {
  if (!covenantField.planted) return;
  const cx = covenantField.x * 16 + 8;
  const cy = covenantField.y * 16 + 8;
  const radius = 20 + Math.sin(covenantField.life * 3) * 4;

  noFill();
  stroke(color(42, 255, 181, 80));
  strokeWeight(2);
  ellipse(cx, cy, radius * 2, radius * 2);
  stroke(color(42, 255, 181, 160));
  strokeWeight(1);
  ellipse(cx, cy, radius * 1.2, radius * 1.2);
  noStroke();
  fill(color(42, 255, 181, 40));
  ellipse(cx, cy, radius * 0.6, radius * 0.6);
  noFill();
  stroke(color(42, 255, 181, 120));
  strokeWeight(1);
  for (let i = 0; i < 4; i++) {
    const angle = (i / 4) * Math.PI * 2 + covenantField.life * 0.5;
    const inner = radius * 0.3;
    const outer = radius * 0.8;
    line(
      cx + Math.cos(angle) * inner,
      cy + Math.sin(angle) * inner,
      cx + Math.cos(angle) * outer,
      cy + Math.sin(angle) * outer
    );
  }
  noStroke();
}

// --- Player -----------------------------------------------------------------

function drawPlayer() {
  const px = player.px;
  const py = player.py;

  noStroke();
  fill(color(0, 0, 0, 80));
  ellipse(px + 8, py + 14, 14, 5);

  fill(color(40, 45, 60));
  noStroke();
  rect(px + 5, py + 9, 4, 5);
  rect(px + 9, py + 9, 4, 5);

  fill(color(30, 50, 40));
  rect(px + 4, py + 4, 10, 6);
  fill(color(42, 255, 181, 120));
  rect(px + 2, py + 5, 3, 4);
  rect(px + 13, py + 5, 3, 4);
  noStroke();
  fill(color(42, 255, 181, 60));
  ellipse(px + 3.5, py + 7, 3, 2);
  ellipse(px + 14.5, py + 7, 3, 2);

  fill(color(220, 200, 170));
  rect(px + 5, py + 1, 8, 4);
  fill(color(42, 255, 181, 180));
  rect(px + 5, py + 2, 3, 2);
  rect(px + 10, py + 2, 3, 2);
  noFill();
  stroke(color(60, 60, 60));
  strokeWeight(1);
  line(px + 5, py + 2, px + 5, py);
  line(px + 13, py + 2, px + 13, py);
  noStroke();

  noFill();
  stroke(color(42, 255, 181, 120));
  strokeWeight(1);
  line(px + 13, py + 2, px + 15, py + 3);
  line(px + 15, py + 3, px + 16, py + 2);
  noStroke();

  const staffX = px + 14;
  const staffY = py + 1;
  fill(color(80, 80, 90));
  noStroke();
  rect(staffX, staffY, 2, 12);
  fill(color(42, 255, 181, 200));
  rect(staffX - 1, staffY - 1, 4, 3);
  noStroke();
  fill(color(42, 255, 181, 80));
  ellipse(staffX + 1, staffY, 4, 3);
  noStroke();

  fill(color(232, 220, 198));
  noStroke();
  textAlign(CENTER, TOP);
  textSize(8);
  textFont('VT323');
  text('Ender', px + 8, py - 6);
  textSize(9);
  textFont('VT323');
}

// --- NPCs -------------------------------------------------------------------

function drawNPCs() {
  for (const npc of npcs) {
    drawNPC(npc);
  }
}

function drawNPC(npc) {
  const px = npc.tileX * 16 + 8;
  const py = npc.tileY * 16 + 8;

  if (npc.flags.questMarker && quest.state !== QUEST_STATES.DONE) {
    const pulse = Math.sin(frameCount * 0.05) * 0.3 + 0.7;
    noFill();
    stroke(color(42, 255, 181, 80 * pulse));
    strokeWeight(1);
    ellipse(px, py - 10, 8, 4);
    noStroke();
  }

  noStroke();
  fill(color(0, 0, 0, 60));
  ellipse(px + 4, py + 8, 10, 4);

  switch (npc.id) {
    case 'elder_farmer':
      drawNPCElder(px, py);
      break;
    case 'engine_spirit':
      drawNPCSpirit(px, py);
      break;
    case 'child_prophet':
      drawNPCChild(px, py);
      break;
    case 'corporate_salvager':
      drawNPCSavager(px, py);
      break;
    default:
      drawNPCDefault(px, py, npc.name);
  }

  noStroke();
  fill(color(232, 220, 198, 200));
  textAlign(CENTER, TOP);
  textSize(7);
  textFont('VT323');
  text(npc.name, px, py - 12);
  textSize(9);
  textFont('VT323');
}

function drawNPCElder(px, py) {
  fill(color(80, 60, 40));
  noStroke();
  rect(px - 4, py - 4, 16, 4);
  rect(px - 2, py - 8, 12, 5);
  fill(color(130, 110, 80));
  rect(px - 3, py - 1, 14, 8);
  fill(color(110, 90, 60));
  rect(px - 2, py + 5, 5, 6);
  rect(px + 3, py + 5, 5, 6);
  fill(color(200, 180, 150));
  rect(px - 2, py - 3, 12, 4);
  fill(color(40, 30, 20));
  rect(px + 1, py - 2, 2, 1);
  rect(px + 7, py - 2, 2, 1);
  fill(color(100, 70, 40));
  noStroke();
  rect(px + 10, py - 6, 2, 14);
}

function drawNPCSpirit(px, py) {
  fill(color(120, 200, 220, 140));
  noStroke();
  ellipse(px, py, 14, 16);
  noStroke();
  fill(color(42, 255, 181, 180));
  ellipse(px, py - 2, 6, 6);
  noFill();
  stroke(color(42, 255, 181, 120));
  strokeWeight(1);
  for (let i = 0; i < 4; i++) {
    const a = (i / 4) * Math.PI * 2 + frameCount * 0.02;
    line(px, py, px + Math.cos(a) * 12, py + Math.sin(a) * 12);
  }
  noStroke();
  fill(color(200, 230, 240, 150));
  rect(px - 3, py - 2, 10, 4);
  fill(color(40, 60, 80, 150));
  rect(px - 1, py - 1, 2, 1);
  rect(px + 4, py - 1, 2, 1);
}

function drawNPCChild(px, py) {
  fill(color(180, 60, 80));
  noStroke();
  rect(px - 4, py - 4, 16, 4);
  fill(color(60, 60, 100));
  rect(px - 3, py - 7, 12, 4);
  fill(color(200, 180, 160));
  rect(px - 2, py - 5, 12, 4);
  fill(color(42, 255, 181, 200));
  rect(px, py - 4, 3, 2);
  rect(px + 6, py - 4, 3, 2);
  fill(color(100, 80, 120));
  rect(px - 3, py, 12, 7);
  fill(color(60, 50, 80));
  rect(px - 2, py + 6, 4, 4);
  rect(px + 2, py + 6, 4, 4);
  noFill();
  stroke(color(42, 255, 181, 40));
  strokeWeight(1);
  ellipse(px, py - 2, 20, 16);
  noStroke();
}

function drawNPCSavager(px, py) {
  fill(color(100, 100, 105));
  noStroke();
  rect(px - 4, py - 3, 16, 10);
  fill(color(80, 80, 85));
  rect(px - 3, py - 3, 14, 3);
  fill(color(180, 170, 160));
  rect(px - 3, py - 8, 12, 6);
  fill(color(30, 30, 35));
  rect(px, py - 7, 2, 1);
  rect(px + 6, py - 7, 2, 1);
  fill(color(42, 255, 181, 160));
  rect(px + 8, py - 4, 4, 3);
  fill(color(10, 10, 10));
  rect(px + 9, py - 3, 2, 1);
  fill(color(60, 60, 65));
  rect(px - 3, py + 6, 5, 5);
  rect(px + 2, py + 6, 5, 5);
  fill(color(100, 100, 105));
  rect(px + 11, py, 3, 7);
}

function drawNPCDefault(px, py, name) {
  fill(color(160, 140, 110));
  noStroke();
  rect(px - 3, py - 2, 12, 9);
  fill(color(200, 180, 150));
  rect(px - 2, py - 6, 10, 5);
  fill(color(40, 30, 20));
  rect(px + 1, py - 5, 2, 1);
  rect(px + 6, py - 5, 2, 1);
}

// --- Quest Overlay -----------------------------------------------------------

function drawQuestOverlay() {
  if (gameOver && quest.wakeEpilogue) {
    drawEpilogueScreen();
    return;
  }

  const stateColors = {
    signal:   color(42, 255, 181, 120),
    crossing: color(255, 160, 60, 140),
    contact:  color(100, 200, 255, 140),
    choice:   color(255, 200, 80, 160),
    wake:     color(200, 180, 255, 160),
    done:     color(255, 255, 200, 180)
  };

  const col = stateColors[quest.state] || color(232, 220, 198, 150);
  const stateLabel = {
    signal: 'SIGNAL',
    crossing: 'CROSSING',
    contact: 'CONTACT',
    choice: 'CHOICE',
    wake: 'WAKE',
    done: 'DONE'
  }[quest.state] || '—';

  noStroke();
  fill(color(26, 16, 46, 200));
  rect(620, 8, 170, 22, 4);
  fill(col);
  noStroke();
  rect(620, 8, 4, 22);
  fill(col);
  textAlign(LEFT, TOP);
  textSize(11);
  textFont('Press Start 2P');
  text(stateLabel, 630, 11);
  textSize(10);
  textFont('VT323');

  fill(color(232, 220, 198, 150));
  textAlign(LEFT, TOP);
  textSize(8);
  let progressText = '';
  if (quest.state === 'signal') {
    progressText = quest.hooksCompleted + '/3 hooks';
  } else if (quest.state === 'crossing') {
    progressText = quest.hazardsCompleted + '/3 hazards';
  } else if (quest.state === 'contact') {
    progressText = quest.npcsMet.length + '/4 NPCs';
  } else if (quest.state === 'choice') {
    progressText = quest.choiceMade ? quest.choiceMade + ' — ' + quest.choiceVariant : 'Awaiting choice';
  } else if (quest.state === 'wake') {
    progressText = 'Epilogue resolving…';
  } else if (quest.state === 'done') {
    progressText = quest.wakeEpilogue ? quest.wakeEpilogue.name : '—';
  }
  text(progressText, 630, 23);
  textSize(10);
  textFont('sans-serif');
}

function drawEpilogueScreen() {
  noStroke();
  fill(color(26, 16, 46, 230));
  rect(0, 0, width, height);

  fill(color(42, 255, 181, 220));
  textAlign(CENTER, CENTER);
  textSize(18);
  textFont('Press Start 2P');
  const ep = quest.wakeEpilogue;
  if (ep) {
    text(ep.name.toUpperCase(), width/2, height/2 - 40);
    fill(color(232, 220, 198, 200));
    textSize(14);
    textFont('VT323');
    textAlign(CENTER, CENTER);
    text(ep.text, width/2, height/2 + 20, width - 80, 100);
    fill(color(42, 255, 181, 120));
    textSize(10);
    textFont('Press Start 2P');
    text('[ R ] to begin again', width/2, height/2 + 80);
  }
  textSize(10);
  textFont('sans-serif');
}

// --- Solar Meter ------------------------------------------------------------

function drawSolarMeter() {
  const mx = 12;
  const my = 540;
  const mw = 120;
  const mh = 10;

  noStroke();
  fill(color(26, 16, 46, 200));
  rect(mx, my, mw, mh, 3);

  const fillW = (player.solarCharge / SOLAR_MAX_KWH) * (mw - 4);
  noStroke();
  fill(color(42, 255, 181, 180));
  rect(mx + 2, my + 2, fillW, mh - 4, 2);

  if (player.solarCharge > 1.5) {
    noStroke();
    fill(color(42, 255, 181, 40));
    rect(mx + 2, my + 2, fillW, mh - 4, 2);
  }

  fill(color(232, 220, 198, 160));
  noStroke();
  textAlign(LEFT, BOTTOM);
  textSize(8);
  textFont('VT323');
  text('SOLAR ' + player.solarCharge.toFixed(2) + 'kWh', mx, my - 2);
  textSize(10);
  textFont('sans-serif');

  // ── Fire bar (staff charges) ──
  const fx = 12, fy = 556, fw = 120, fh = 10;
  noStroke();
  fill(color(26, 16, 46, 200));
  rect(fx, fy, fw, fh, 3);
  const chargeFill = (player.staffCharges / 2) * (fw - 4);
  if (chargeFill > 0) {
    noStroke();
    fill(color(42, 255, 181, 180));
    rect(fx + 2, fy + 2, chargeFill, fh - 4, 2);
    if (player.staffCharges > 1) {
      noStroke();
      fill(color(42, 255, 181, 40));
      rect(fx + 2, fy + 2, chargeFill, fh - 4, 2);
    }
  }
  noStroke();
  fill(color(232, 220, 198, 160));
  textAlign(LEFT, BOTTOM);
  textSize(8);
  textFont('VT323');
  text('⚡ FIRE ' + player.staffCharges + '/2', fx, fy - 2);
  textSize(10);
  textFont('sans-serif');
}

// --- Interaction Hints -------------------------------------------------------

function drawInteractionHints() {
  const key = window.interactionKey;
  if (!key) return;

  const px = player.px + 8;
  const py = player.py - 16;

  const labels = {
    e:    'E — Talk',
    q:    'Q — Covenant Field',
    f:    'F — Board Ship',
    tab:  'Tab — Toggle Sky',
    l:    'L — Ledger',
    m:    'M — Repair Cafe'
  };

  const label = labels[key] || key.toUpperCase();
  const pulse = Math.sin(frameCount * 0.08) * 0.2 + 0.8;

  noStroke();
  fill(color(26, 16, 46, 180));
  rect(px - 30, py - 6, 60, 12, 3);

  fill(color(42, 255, 181, 200 * pulse));
  textAlign(CENTER, TOP);
  textSize(8);
  textFont('VT323');
  text(label, px, py - 4);
  textSize(10);
  textFont('sans-serif');
}

// ---------------------------------------------------------------------------
// Exported surface
// ---------------------------------------------------------------------------
const AetherWorld = function(p, C) {
  return World;
};

if (typeof window !== 'undefined') {
  window.AetherWorld = AetherWorld;
}
