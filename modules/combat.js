// HISTORICAL MIRROR — NOT RUNTIME AUTHORITY.
// The live combat executor is integrated in ../aetherwake.js and production
// player actions are migrating to explicit JRPG formula/contract resolution.
// This file preserves earlier 2D6/PbtA behavior for provenance only and must
// not be used as evidence of current gameplay semantics.

// AetherCombat — Turn-based 2D6 PbtA combat module for Aetherwake JRPG.
// Exposes window.AetherCombat as a constructor: new AetherCombat(p, C)
// Also compatible with direct call: AetherCombat(p, C) returns the namespace.

function AetherCombat(p, C) {
  'use strict';
  const self = this;
  const state = {
    player: {
      name: 'Ender',
      age: 22,
      class: 'Rift Scholar',
      vit: 13, maxVit: 13,
      echoes: { current: 3, max: 3 }, maxEchoes: 3,
      wits: 2, presence: 1, spirit: 1, might: -1,
      grace: 0,
      scrap: 7,
      aether: { current: 4, max: 6 },
      heat: { current: 1, max: 3 },
      charge: 2.0,
      staffCharges: 2, maxStaffCharges: 2,
      level: 1, xp: 0, xpToNext: 50,
      unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
      equipment: { staff: null, backpack: null },
    },
    enemy: null,
    turn: 0,
    log: [],
    encounterOver: false,
    initiative: 0,
  };

  const actions = [
    { id: 'staffStrike',  label: 'Resonator Staff — EMP strike',
      stat: 'might', cost: 0, type: 'attack',
      desc: '1d6+2 EMP, 10ft melee / 60ft beam, 1 charge' },
    { id: 'uncoverTruth', label: 'Uncover Truth — read the weave',
      stat: 'wits', cost: 1, type: 'ability',
      desc: '2D6+Wits. Reveal enemy weakness. +1 next roll.' },
    { id: 'sharedDream',  label: 'Shared Dream — lend your vision',
      stat: 'spirit', cost: 1, type: 'ability',
      desc: '2D6+Spirit. Ally +1 next action OR heal 1-2 Vit' },
    { id: 'mycelialLedger', label: 'Mycelial Ledger — account the commons',
      stat: 'presence', cost: 0, type: 'ability',
      desc: '2D6+Presence. Gain scrap or aether' },
    { id: 'hold',         label: 'Hold position — conserve',
      stat: null, cost: 0, type: 'hold',
      desc: 'Regain 1 staff charge in sunlight' },
    { id: 'windWard',     label: 'Wind Ward — ground yourself',
      stat: 'grace', cost: 1, type: 'defense',
      desc: '2D6+Grace. Resist wind shear. Restore 1 Vit if 10+' },
    { id: 'aetherSeal',   label: 'Aether Seal — close the leak',
      stat: 'wits', cost: 1, type: 'defense',
      desc: '2D6+Wits. Drain aether pool. Gain scrap on 10+' },
    { id: 'rest',         label: 'Rest — lower your heat',
      stat: null, cost: 0, type: 'rest',
      desc: 'Reduce current heat by 1. Recover 1 Vit on 10+' },
  ];

  const enemies = {
    skyPredator: {
      name: 'Sky-Predator',
      goal: 'Kill or drive off the predator feeding on the island\'s aether.',
      hp: 12, maxHp: 12, might: 1, presence: 0, grace: 0, wits: 0,
      weakness: 'Its brass wing-joints shudder in EMP.',
      status: 'roosting',
      type: 'skyPredator',
      ability: 'diveBomb',
      abilityDesc: 'Dive Bomb — 2 damage, ignores dodge',
      color: 'rust',
      bodyShape: 'predator',
    },
    corporateSalvager: {
      name: 'Dock Authority Enforcer',
      goal: 'Force the Wake to clear berth before the stormfront arrives.',
      hp: 10, maxHp: 10, might: 0, presence: 2, grace: 1, wits: 1,
      weakness: 'Procedure pressure overreaches — clear evidence can hold the berth.',
      status: 'negotiating',
      type: 'corporateSalvager',
      ability: 'contractClause',
      abilityDesc: 'Hold Order — you lose 1 scrap to emergency repairs',
      color: 'soil',
      bodyShape: 'humanoid',
    },
    windShear: {
      name: 'Wind Shear Elemental',
      goal: 'Tear the island apart — wind strips grace from all who stand here.',
      hp: 14, maxHp: 14, might: 2, presence: 0, grace: 0, wits: 1,
      weakness: 'Uncover Truth reveals the wind pattern — exposing it to EMP.',
      status: 'howling',
      type: 'windShear',
      ability: 'galeForce',
      abilityDesc: 'Gale Force — 2 damage, knocks you back',
      color: 'scioto',
      bodyShape: 'elemental',
    },
    aetherLeak: {
      name: 'Aether Leak Wraith',
      goal: 'Pool the aether, distort the local weave — and feed.',
      hp: 8, maxHp: 8, might: 0, presence: 1, grace: 2, wits: 1,
      weakness: 'Shared Dream seals the leak — starve the wraith of aether.',
      status: 'draining',
      type: 'aetherLeak',
      ability: 'drain',
      abilityDesc: 'Drain — removes 1 aether from you',
      color: 'teal',
      bodyShape: 'wraith',
    },
  };

  // ── Helpers ──
  function roll2d6() {
    return floor(random(1, 7)) + floor(random(1, 7));
  }

  function roll2d6Plus(stat) {
    const dice = roll2d6();
    const total = dice + stat;
    let outcome;
    if (total >= 10) outcome = 'success';
    else if (total >= 7) outcome = 'partial';
    else outcome = 'failure';
    return { dice, stat, total, outcome };
  }

  function log(msg) {
    state.log.push(msg);
    if (state.log.length > 20) state.log.shift();
  }

  // ── Public API ──
  this.init = function(options) {
    options = options || {};
    if (options.seed !== undefined) {
      if (randomSeed) randomSeed(options.seed);
    } else {
      const seed = floor(random(99999));
      if (randomSeed) randomSeed(seed);
    }
    state.player.vit = options.vit ?? 13;
    state.player.scrap = options.scrap ?? 7;
    state.player.aether = options.aether ? { current: options.aether.current, max: options.aether.max } : { current: options.aether ?? 4, max: options.aetherMax ?? 6 };
    state.player.heat = options.heat ? { current: options.heat.current, max: options.heat.max } : { current: options.heat ?? 1, max: options.heatMax ?? 3 };
    state.player.echoes = options.echoes ? { current: options.echoes.current, max: options.echoes.max } : { current: options.echoes ?? 3, max: options.echoesMax ?? 3 };
    state.player.staffCharges = options.charges ?? (options.staffCharges ?? 2);
    state.maxStaffCharges = options.staffMax ?? 2;
    const progression = (typeof window !== 'undefined' && window.AetherProgressionDefs) ? window.AetherProgressionDefs : null;
    const requestedLevel = options.level ?? 1;
    state.player.level = progression && typeof progression.normalizeLevel === 'function' ? progression.normalizeLevel(requestedLevel) : requestedLevel;
    state.player.xp = options.xp ?? 0;
    state.player.xpToNext = options.xpToNext ?? (progression && typeof progression.getXPToNext === 'function' ? progression.getXPToNext(state.player.level) : 50);
    state.player.unlockedAbilities = options.unlockedAbilities || ['uncoverTruth', 'sharedDream', 'mycelialLedger'];
    state.player.equipment = options.equipment || { staff: null, backpack: null };
    state.turn = 0;
    state.log = [];
    state.enemy = null;
    state.encounterOver = false;
    log('Combat initialized. The weave awaits.');
  };

  this.getAether = function() { return state.player.aether; };
  this.getCharges = function() { return { current: state.player.staffCharges, max: state.maxStaffCharges }; };
  this.getEchoes = function() { return state.player.echoes; };
  this.getScrap = function() { return state.player.scrap; };

  this.getLevel = function() { return state.player.level; };
  this.getXP = function() { return { current: state.player.xp, toNext: state.player.xpToNext }; };

  this.levelUp = function() {
    const p = state.player;
    const progression = (typeof window !== 'undefined' && window.AetherProgressionDefs) ? window.AetherProgressionDefs : null;
    const hardCap = progression && progression.LEVEL_LIMITS ? progression.LEVEL_LIMITS.HARD_CAP : 175;

    if (p.level >= hardCap) {
      p.level = hardCap;
      p.xp = 0;
      p.xpToNext = 0;
      return false;
    }
    if (p.xp < p.xpToNext) return false;

    p.xp -= p.xpToNext;
    p.level++;

    p.xpToNext = progression && typeof progression.getXPToNext === 'function'
      ? progression.getXPToNext(p.level)
      : Math.floor(50 * Math.pow(1.5, p.level - 1));

    p.echoes.max = Math.min(6, p.echoes.max + 1);

    const unlocks = progression && typeof progression.getUnlocksForLevel === 'function'
      ? progression.getUnlocksForLevel(p.level)
      : [];

    if (unlocks.length > 0) {
      unlocks.forEach(entry => {
        if (!p.unlockedAbilities.includes(entry.abilityId)) {
          p.unlockedAbilities.push(entry.abilityId);
          log(entry.log);
        }
      });
    } else {
      // Compatibility fallback if progression definitions are unavailable.
      if (p.level === 3 && !p.unlockedAbilities.includes('windWard')) {
        p.unlockedAbilities.push('windWard');
        log('── LEVEL 3: Wind Ward unlocked! ──');
      }
      if (p.level === 4 && !p.unlockedAbilities.includes('aetherSeal')) {
        p.unlockedAbilities.push('aetherSeal');
        log('── LEVEL 4: Aether Seal unlocked! ──');
      }
      if (p.level === 5 && !p.unlockedAbilities.includes('rest')) {
        p.unlockedAbilities.push('rest');
        log('── LEVEL 5: Rest unlocked! ──');
      }
    }

    const milestone = progression && typeof progression.getMilestone === 'function'
      ? progression.getMilestone(p.level)
      : null;
    if (milestone) {
      log('── MILESTONE: ' + milestone.label + ' ──');
    }

    log('── LEVEL UP! You are now level ' + p.level + '. Choose a stat to increase. ──');

    if (p.level >= hardCap) {
      p.xp = 0;
      p.xpToNext = 0;
    }

    return true;
  };

  this.awardXP = function(amount) {
    const p = state.player;
    if (!Number.isFinite(amount) || amount <= 0) return 0;

    const progression = (typeof window !== 'undefined' && window.AetherProgressionDefs) ? window.AetherProgressionDefs : null;
    const hardCap = progression && progression.LEVEL_LIMITS ? progression.LEVEL_LIMITS.HARD_CAP : 175;
    if (p.level >= hardCap) {
      p.level = hardCap;
      p.xp = 0;
      p.xpToNext = 0;
      return 0;
    }

    p.xp += Math.floor(amount);
    log('+' + Math.floor(amount) + ' XP');

    let gained = 0;
    let guard = 0;
    while (p.level < hardCap && p.xpToNext > 0 && p.xp >= p.xpToNext) {
      if (!this.levelUp()) break;
      gained++;
      guard++;
      if (guard > hardCap) {
        throw new Error('PROGRESSION_LEVEL_LOOP_GUARD');
      }
    }

    return gained;
  };

  this.beginEncounter = function(enemyId) {
    const template = enemies[enemyId];
    if (!template) {
      log('Unknown enemy: ' + enemyId);
      return;
    }
    const activeLevels = (typeof window !== 'undefined' && Array.isArray(window.ACTIVE_PARTY))
      ? window.ACTIVE_PARTY
          .filter(member => member && Number.isFinite(member.level) && member.level >= 1)
          .map(member => member.level)
      : [];
    const partyLevels = activeLevels.length ? activeLevels : [state.player.level];
    const scaling = (typeof window !== 'undefined' && window.AetherEncounterScaling &&
      typeof window.AetherEncounterScaling.scaleEnemy === 'function')
      ? window.AetherEncounterScaling
      : null;
    const scaledTemplate = scaling
      ? scaling.scaleEnemy(template, {
          partyLevels,
          partySize: partyLevels.length,
          playerLevel: state.player.level,
        })
      : template;

    state.enemy = {
      name: scaledTemplate.name,
      goal: scaledTemplate.goal,
      hp: scaledTemplate.hp,
      maxHp: scaledTemplate.maxHp,
      might: scaledTemplate.might,
      presence: scaledTemplate.presence,
      grace: scaledTemplate.grace,
      wits: scaledTemplate.wits,
      weakness: scaledTemplate.weakness,
      status: scaledTemplate.status,
      scaling: scaledTemplate.scaling || null,
    };
    state.turn = 0;
    state.encounterOver = false;
    state.initiative = state.player.wits + (state.player.grace || 0);
    log('Encounter: ' + state.enemy.name + ' — ' + state.enemy.goal);
    log(state.enemy.name + ' weakness: ' + state.enemy.weakness);
  };

  this.resolveTurn = function(actionId, resources) {
    if (!state.enemy || state.enemy.hp <= 0) {
      log('No active enemy.');
      return;
    }
    const action = actions.find(a => a.id === actionId);
    if (!action) {
      log('Unknown action: ' + actionId);
      return;
    }

    state.turn++;

    // Resource cost
    if (action.cost > 0) {
      if (state.player.echoes.current <= 0 && state.player.aether.current <= 0) {
        log('No echoes or aether to spend — the action falters.');
        return;
      }
      if (state.player.echoes.current > 0) {
        state.player.echoes.current--;
        log('Echo spent.');
      } else if (state.player.aether.current > 0) {
        state.player.aether.current--;
        log('Aether spent.');
      }
    }

    // Heat generation: most actions add heat
    if (action.type !== 'hold' && action.type !== 'rest') {
      state.player.heat.current = Math.min(state.player.heat.max, state.player.heat.current + 1);
    }

    // Roll
    const statBonus = action.stat ? state.player[action.stat] || 0 : 0;
    const r = roll2d6Plus(statBonus);
    let actionText = '';
    let enemyDmg = 0;
    let playerDmg = 0;
    let heal = 0;
    let resourceGain = '';
    let nextRollBonus = 0;

    if (r.outcome === 'success') {
      if (action.type === 'attack') {
        if (state.player.staffCharges <= 0) {
          actionText = 'Staff Strike — no charges left. The weapon falls silent. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else {
          enemyDmg = floor(random(1, 7)) + 2; // 1d6+2
          state.enemy.hp -= enemyDmg;
          state.player.staffCharges = Math.max(0, state.player.staffCharges - 1);
          actionText = action.label + ' — ' + enemyDmg + ' EMP damage. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
        }
      } else if (action.type === 'ability') {
        // Visual: ability flash for all abilities
        state._abilityFlashTurn = millis();
        if (action.id === 'uncoverTruth') {
          nextRollBonus = 1;
          actionText = 'Uncover Truth — the weave reveals its pattern. +1 to next roll. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else if (action.id === 'sharedDream') {
          heal = floor(random(1, 3));
          state.player.vit = Math.min(state.player.maxVit, state.player.vit + heal);
          actionText = 'Shared Dream — ' + heal + ' Vit restored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else if (action.id === 'mycelialLedger') {
          const gain = floor(random(1, 3));
          if (floor(random(2)) === 0) {
            state.player.aether.current = Math.min(state.player.aether.max, state.player.aether.current + gain);
            actionText = 'Mycelial Ledger — +' + gain + ' Aether stored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          } else {
            state.player.scrap += gain;
            actionText = 'Mycelial Ledger — +' + gain + ' Scrap recorded. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          }
        }
      } else if (action.type === 'hold') {
        if (state.player.staffCharges < state.player.maxStaffCharges) {
          state.player.staffCharges++;
          actionText = 'Hold — Resonator recharges in light. +1 charge. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else {
          actionText = 'Hold — the weave passes through you. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        }
      } else if (action.type === 'defense') {
        if (action.id === 'windWard') {
          if (r.outcome === 'success') {
            heal = 1;
            state.player.vit = Math.min(state.player.maxVit, state.player.vit + heal);
            actionText = 'Wind Ward — you brace against the gale. 1 Vit restored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          } else {
            playerDmg = 1;
            actionText = 'Wind Ward — the wind knocks you. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          }
        } else if (action.id === 'aetherSeal') {
          if (r.outcome === 'success') {
            const gain = floor(random(1, 3));
            state.player.scrap += gain;
            actionText = 'Aether Seal — the leak closes. +' + gain + ' Scrap. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          } else {
            playerDmg = 1;
            actionText = 'Aether Seal — the aether burns you. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
          }
        }
      } else if (action.type === 'rest') {
        if (r.outcome === 'success') {
          state.player.heat.current = Math.max(0, state.player.heat.current - 2);
          heal = floor(random(1, 3));
          state.player.vit = Math.min(state.player.maxVit, state.player.vit + heal);
          actionText = 'Rest — heat eases, ' + heal + ' Vit restored. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else {
          playerDmg = 1;
          actionText = 'Rest — you cannot find peace. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        }
      }
    } else if (r.outcome === 'partial') {
      if (action.type === 'attack') {
        enemyDmg = Math.max(0, floor(random(1, 7)) + 2 - 1);
        state.enemy.hp -= enemyDmg;
        state.player.staffCharges = Math.max(0, state.player.staffCharges - 1);
        playerDmg = 1;
        actionText = action.label + ' — ' + enemyDmg + ' damage, but the enemy counters. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
      } else if (action.type === 'ability') {
        if (action.id === 'uncoverTruth') {
          actionText = 'Uncover Truth — a glimpse, but it slips. No bonus. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else if (action.id === 'sharedDream') {
          heal = 1;
          state.player.vit = Math.min(state.player.maxVit, state.player.vit + heal);
          actionText = 'Shared Dream — faint echo, ' + heal + ' Vit. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else if (action.id === 'mycelialLedger') {
          state.player.scrap += 1;
          actionText = 'Mycelial Ledger — +1 Scrap. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        }
      } else if (action.type === 'hold') {
        if (state.player.staffCharges < state.player.maxStaffCharges) {
          state.player.staffCharges++;
        }
        playerDmg = 1;
        actionText = 'Hold — but the enemy finds you. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
      } else if (action.type === 'defense') {
        playerDmg = 1;
        if (action.id === 'windWard') {
          actionText = 'Wind Ward — the wind pushes through. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        } else {
          actionText = 'Aether Seal — the leak persists. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        }
      } else if (action.type === 'rest') {
        actionText = 'Rest — tension keeps you awake. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
      }
    } else {
      // Failure
      if (action.type === 'attack') {
        playerDmg = Math.floor(random(1, 4)) + 1;
        actionText = action.label + ' — misfires. ' + playerDmg + ' Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total + ' (' + r.outcome + ')';
      } else if (action.type === 'ability') {
        actionText = action.label + ' — the weave resists. Nothing gained. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
        playerDmg = 1;
      } else if (action.type === 'hold') {
        playerDmg = 1;
        actionText = 'Hold — the enemy finds you. ' + playerDmg + ' Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
      } else if (action.type === 'defense') {
        playerDmg = floor(random(1, 4)) + 1;
        actionText = action.label + ' — overwhelmed. ' + playerDmg + ' Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
      } else if (action.type === 'rest') {
        playerDmg = 1;
        actionText = 'Rest — exhaustion hits hard. 1 Vit lost. Roll: ' + r.dice + '+' + r.stat + '=' + r.total;
      }
    }

    // Apply
    state.player.vit = Math.max(0, state.player.vit - playerDmg);
    // Combat animation triggers
    if (enemyDmg > 0) {
      state._flashTurn = millis();
      state._totalDamageDealt = (state._totalDamageDealt || 0) + enemyDmg;
      // Damage number
      state._lastDamageNum = {
        value: enemyDmg,
        crit: (action && action.type === 'attack' && r.outcome === 'success'),
        time: millis(),
      };
      // Critical hit flash (10+ on attack)
      if (action && action.type === 'attack' && r.outcome === 'success') {
        state._critFlashTurn = millis();
      }
    }
    if (playerDmg > 0) {
      state._playerHitTurn = millis();
    } else if (action && action.type === 'attack' && r.outcome === 'success') {
      // Successful attack = dodge animation on enemy side
      state._dodgeTurn = millis();
    }
    // ── Visual + audio feedback (triggered from core.js helpers) ──
    if (typeof triggerCombatHitFeedback === 'function') {
      triggerCombatHitFeedback(enemyDmg, playerDmg, r.total, action && action.type === 'attack');
    }
    if (typeof triggerAbilityFeedback === 'function' && action && action.type === 'ability') {
      triggerAbilityFeedback(r.outcome === 'success');
    }
    if (enemyDmg > 0) log(state.enemy.name + ' takes ' + enemyDmg + ' EMP. HP: ' + state.enemy.hp + '/' + state.enemy.maxHp);
    if (playerDmg > 0) log('You take ' + playerDmg + ' damage. Vit: ' + state.player.vit + '/' + state.player.maxVit);
    if (heal > 0) log('Healed ' + heal + ' Vit.');
    if (text) log('[Turn ' + state.turn + '] ' + text);

    // Enemy turn — use special abilities by type
    if (state.enemy.hp > 0) {
      const eHit = floor(random(1, 4)) >= 3 ? 1 : 0;
      const eType = state.enemy.type || 'generic';
      if (eHit) {
        let enemyText = '';
        if (eType === 'skyPredator') {
          // Dive Bomb: 2 damage, ignores dodge
          const dmg = 2;
          state.player.vit = Math.max(0, state.player.vit - dmg);
          enemyText = state.enemy.name + ' dive-bombs — ' + dmg + ' damage (ignores dodge)!';
        } else if (eType === 'corporateSalvager') {
          // Hold Order: lose 1 scrap to emergency repairs
          if (state.player.scrap > 0) {
            state.player.scrap -= 1;
            enemyText = state.enemy.name + ' enforces a hold order — 1 scrap spent on emergency compliance!';
          } else {
            // Fallback to strike
            state.player.vit = Math.max(0, state.player.vit - 1);
            enemyText = state.enemy.name + ' strikes — 1 Vit lost.';
          }
        } else if (eType === 'windShear') {
          // Gale Force: 2 damage, knockback feel
          const dmg = 2;
          state.player.vit = Math.max(0, state.player.vit - dmg);
          enemyText = state.enemy.name + ' unleashes gale force — ' + dmg + ' damage, wind knocks you back!';
          state._windKnockTurn = millis();
        } else if (eType === 'aetherLeak') {
          // Drain: remove 1 aether
          if (state.player.aether.current > 0) {
            state.player.aether.current = Math.max(0, state.player.aether.current - 1);
            enemyText = state.enemy.name + ' drains your aether — 1 aether lost!';
          } else {
            state.player.vit = Math.max(0, state.player.vit - 1);
            enemyText = state.enemy.name + ' strikes desperately — 1 Vit lost.';
          }
        } else {
          // Generic strike
          state.player.vit = Math.max(0, state.player.vit - 1);
          enemyText = state.enemy.name + ' strikes — 1 Vit lost.';
        }
        log('[Enemy] ' + enemyText);
        if (eType === 'skyPredator' || eType === 'windShear') {
          state._flashTurn = millis();
        }
      } else {
        // Enemy holds — but some enemies have conditional pressure
        if (eType === 'corporateSalvager' && floor(random(1, 4)) >= 3) {
          log('[Enemy] ' + state.enemy.name + ' exerts dock pressure — the berth feels smaller.');
          state._pressureTurn = millis();
        } else {
          log('[Enemy] ' + state.enemy.name + ' holds.');
        }
      }
    }

    // --- Enemy Special Attacks ---
    // After enemy turn, handle ability usage
    // Enemy abilities are stored in enemy.abilities array
    // Each ability is triggered randomly during enemy turn
    const enemyAbilities = enemy.abilities || [];
    if (state.enemy && enemyAbilities.length > 0 && !state.encounterOver) {
      // Roll for enemy ability usage (30% chance per turn)
      const abilityRoll = floor(random(1, 11));
      if (abilityRoll <= 3) {
        // Use random enemy ability
        const abilityIdx = floor(random(0, enemyAbilities.length));
        const abilityId = enemyAbilities[abilityIdx];
        const enemyAbility = ENEMY_ABILITIES[abilityId];
        if (enemyAbility) {
          const result = enemyAbility.execute(state);
          if (result) {
            log('[Enemy Ability] ' + enemyAbility.name + ' — ' + result);
            // Trigger visual feedback
            if (abilityId === 'diveBomb' || abilityId === 'galeForce') {
              state._enemyAbilityFlash = millis();
            } else if (abilityId === 'contractClause') {
              state._enemyAbilityFlash = millis();
            }
          }
        }
      }
    }

    // Check end
    if (state.enemy.hp <= 0) {
      state.encounterOver = true;
      // Track if last attack was a critical (10+) killing blow
      if (action && action.type === 'attack' && r.outcome === 'success' && enemyDmg > 0) {
        state._lastTurnCrit = true;
      } else {
        state._lastTurnCrit = false;
      }
      // Base reward — scales with fight performance
      let scrapReward = 1 + floor(random(1, 3));
      let echoReward = 1;
      // Bonus for critical success on final turn (last successful attack that ended it)
      if (state._lastTurnCrit) {
        scrapReward += 2;
        echoReward = 2;
        log('── Critical finish! Bonus rewards awarded. ──');
      }
      // Bonus for surviving near-death
      if (state.player.vit <= 3 && state.player.vit > 0) {
        scrapReward += 1;
        log('── You fought through the brink — resilience reward. ──');
      }
      state.player.scrap += scrapReward;
      log('── ' + state.enemy.name + ' defeated. +' + scrapReward + ' Scrap. ──');
      state.player.echoes.current = Math.min(state.player.echoes.max, state.player.echoes.current + echoReward);
      log('+' + echoReward + ' Echo' + (echoReward > 1 ? 's' : '') + '. The weave settles.');
      // XP reward based on enemy difficulty
      let xpReward = 0;
      const eName = state.enemy.name;
      if (eName === 'Sky-Predator') xpReward = 15;
      else if (eName === 'Dock Authority Enforcer') xpReward = 12;
      else if (eName === 'Wind Shear') xpReward = 20;
      else if (eName === 'Aether Leak') xpReward = 18;
      else xpReward = 10;
      if (r.outcome === 'success' && action.type === 'attack') xpReward += 5;
      state.player.xp += xpReward;
      log('+' + xpReward + ' XP');
      state._defeatTurn = millis();
      // Victory stats
      state._victoryStats = {
        turns: state.turn,
        damageDealt: state._totalDamageDealt || 0,
        scrapEarned: scrapReward,
        echoEarned: echoReward,
      };
    }

    if (state.player.vit <= 0) {
      state.player.vit = 1;
      log('Your vitality fails. The dream fades — for now.');
    }
  };

  this.ability = function(name, target) {
    const action = actions.find(a => a.id === name.toLowerCase().replace(/\s+/g, ''));
    if (action) this.resolveTurn(action.id, null);
  };

  this.roll2d6 = roll2d6;
  this.roll2d6Plus = roll2d6Plus;

  this.getState = function() {
    return {
      turn: state.turn,
      player: JSON.parse(JSON.stringify(state.player)),
      enemy: state.enemy ? JSON.parse(JSON.stringify(state.enemy)) : null,
      log: state.log.slice(),
      encounterOver: state.encounterOver,
      actions: actions,
      initiative: state.initiative,
    };
  };

  this.handleInput = function(p, keys, pressed) {
    // Combat input handled by core; this is a no-op hook
    return;
  };

  // ── Rendering (called from core.js drawCombatScene wiring) ──
  this.drawCombatScene = function(playerX, playerY, aetherMax, staffMax, sceneOptions) {
    const now = millis();
    const dodgeBob = state._dodgeTurn && state._dodgeTurn > now - 200
      ? Math.sin((now - state._dodgeTurn) * 0.02) * 4
      : 0;
    
    // ── Visual stage authority ──
    const visualStage = window.AetherCombatVisual;
    const stage = visualStage && typeof visualStage.stage === 'function'
      ? visualStage.stage(p.width, p.height)
      : {
          playerX: Math.round(p.width * 0.34),
          playerY: Math.round(p.height * 0.58),
          enemyX: Math.round(p.width * 0.72),
          enemyY: Math.round(p.height * 0.50),
          horizonY: Math.round(p.height * 0.47),
        };

    const combatPlayerX = stage.playerX;
    const combatPlayerY = stage.playerY;

    if (visualStage && typeof visualStage.drawBackdrop === 'function') {
      visualStage.drawBackdrop({
        width: p.width,
        height: p.height,
        now,
        enemy: state.enemy,
        turn: state.turn,
        domain: sceneOptions && sceneOptions.domain ? sceneOptions.domain : 'ground',
        weatherId: sceneOptions && sceneOptions.weatherId ? sceneOptions.weatherId : 'clear',
        altitude: sceneOptions ? sceneOptions.altitude : null,
        encounterPressure: sceneOptions && Number.isFinite(sceneOptions.encounterPressure)
          ? sceneOptions.encounterPressure : 0,
      });
    } else {
      noStroke();
      fill(C.navy[0], C.navy[1], C.navy[2]);
      rect(0, 0, p.width, p.height);
      fill(C.soil[0], C.soil[1], C.soil[2]);
      rect(0, p.height * 0.55, p.width, p.height * 0.45);
    }

    // ── JRPG encounter title rail ──
    if (state.enemy && state.turn <= 1) {
      const bannerT = Math.max(0.72, Math.min(1, (state.turn + 1) / 2));
      const railW = Math.min(456, Math.round(p.width * 0.48));
      const railX = Math.round((p.width - railW) / 2);
      p.noStroke();
      p.fill(5, 10, 20, 145 * bannerT);
      p.rect(railX, 21, railW, 58, 8);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 34 * bannerT);
      p.rect(railX + 8, 50, railW - 16, 1);
      p.fill(C.rust[0], C.rust[1], C.rust[2], 165 * bannerT);
      p.rect(railX + 14, 29, 44, 3);
      p.fill(C.teal[0], C.teal[1], C.teal[2], 165 * bannerT);
      p.rect(railX + railW - 58, 29, 44, 3);

      p.textAlign(p.CENTER, p.TOP);
      p.textFont('Segoe UI Semibold');
      p.textSize(9);
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 185 * bannerT);
      p.text('ENCOUNTER', p.width/2, 28);
      p.textFont('Trebuchet MS');
      p.textSize(18);
      p.fill(C.parchment[0], C.parchment[1], C.parchment[2], 235 * bannerT);
      p.text(state.enemy.name.toUpperCase(), p.width/2, 46);
    }

    // ── Enemy ──
    if (state.enemy) {
      const ex = stage.enemyX;
      const ey = stage.enemyY;
      const eType = state.enemy.type || 'generic';
      const eVisual = state.enemy.bodyShape || ({
        windShear: 'elemental',
        aetherLeak: 'wraith',
        corporateSalvager: 'humanoid',
      }[eType] || eType);
      const eColor = state.enemy.color || 'soil';

      // Map color name to C array
      const colorMap = {
        rust: C.rust,
        soil: C.soil,
        scioto: C.scioto,
        teal: C.teal,
        biolum: C.biolum,
        rose: C.rose,
      };
      const eBodyColor = colorMap[eColor] || C.soil;
      const hpRatio = state.enemy.hp / state.enemy.maxHp;

      // Shared visual-stage enemy treatment. Mechanical state remains local.
      if (visualStage && typeof visualStage.drawEnemy === 'function') {
        visualStage.drawEnemy({
          x: ex,
          y: ey,
          now,
          enemy: state.enemy,
          turn: state.turn,
        });
      } else {
        p.fill(eBodyColor[0], eBodyColor[1], eBodyColor[2], 220);
        p.noStroke();
        p.rect(ex - 14, ey - 18, 28, 36);
      }

      // Enemy identity and HP are already carried by the compact command window.
      // Keep the battlefield sprite clean rather than attaching HUD labels/bars to it.

      // ── Enemy attack flash — bigger, brighter ──
      if (state._flashTurn && state._flashTurn > now - 300) {
        const age = now - state._flashTurn;
        const flashAlpha = map(age, 0, 300, 180, 0);
        const flashScale = map(age, 0, 300, 1, 2.5);
        p.fill(C.teal[0], C.teal[1], C.teal[2], flashAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 80 * flashScale, 60 * flashScale);
        // Secondary ring
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], flashAlpha * 0.4);
        p.ellipse(ex, ey, 100 * flashScale, 75 * flashScale);
      }

      // ── Critical hit flash — huge red burst ──
      if (state._critFlashTurn && state._critFlashTurn > now - 500) {
        const age = now - state._critFlashTurn;
        const critAlpha = map(age, 0, 500, 220, 0);
        const critScale = map(age, 0, 500, 1, 3.5);
        p.fill(C.rust[0], C.rust[1], C.rust[2], critAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 90 * critScale, 70 * critScale);
        p.fill(C.teal[0], C.teal[1], C.teal[2], critAlpha * 0.5);
        p.ellipse(ex, ey, 120 * critScale, 90 * critScale);
        // "CRITICAL" text
        if (age < 300) {
          p.textFont('Press Start 2P');
          p.textSize(14);
          p.textAlign(p.CENTER, p.CENTER);
          p.fill(C.teal[0], C.teal[1], C.teal[2], map(age, 0, 300, 255, 0));
          p.text('CRIT', ex, ey - 50 - (1 - age / 300) * 20);
        }
      }

      // ── Damage number floating up ──
      if (state._lastDamageNum && state._lastDamageNum.time && state._lastDamageNum.time > now - 1200) {
        const dAge = now - state._lastDamageNum.time;
        const dAlpha = map(dAge, 0, 1200, 255, 0);
        const dY = ey - 40 - map(dAge, 0, 1200, 0, 40);
        p.textFont('Press Start 2P');
        p.textSize(14);
        p.textAlign(p.CENTER, p.CENTER);
        const dCol = state._lastDamageNum.crit ? C.rust : C.teal;
        p.fill(dCol[0], dCol[1], dCol[2], dAlpha);
        p.text('-' + state._lastDamageNum.value, ex, dY);
      }

      // ── Enemy near-death shimmer ──
      if (hpRatio < 0.3 && hpRatio > 0) {
        const shimmer = Math.sin(now * 0.025) * 0.5 + 0.5;
        p.fill(C.rust[0], C.rust[1], C.rust[2], 40 * shimmer);
        p.noStroke();
        p.ellipse(ex, ey, 55, 42);
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 30 * (1 - shimmer));
        p.ellipse(ex, ey, 40, 30);
      }

      // ── Enemy defeat / victory flash ──
      if (state.enemy.hp <= 0 && state._defeatTurn && state._defeatTurn > now - 800) {
        const dfAge = now - state._defeatTurn;
        const dfAlpha = map(dfAge, 0, 800, 200, 0);
        p.fill(C.teal[0], C.teal[1], C.teal[2], dfAlpha);
        p.noStroke();
        p.ellipse(ex, ey, 120, 90);
        p.fill(C.scioto[0], C.scioto[1], C.scioto[2], dfAlpha * 0.4);
        p.ellipse(ex, ey, 160, 120);
        // Debris particles
        for (let d = 0; d < 6; d++) {
          const da = (dfAge * 0.01 + d * 1.05) % (Math.PI * 2);
          const dd = map(dfAge, 0, 800, 5, 30) * (1 - Math.abs(Math.cos(da)) * 0.6);
          p.fill(C.teal[0], C.teal[1], C.teal[2], dfAlpha * 0.6);
          p.noStroke();
          p.ellipse(ex + Math.cos(da) * dd, ey + Math.sin(da) * dd * 0.6, 4, 4);
        }
      }
    }

    // ── Player hit flash — red impact at player position ──
    if (state._playerHitTurn && state._playerHitTurn > now - 400) {
      const hitAge = now - state._playerHitTurn;
      const hitAlpha = map(hitAge, 0, 400, 140, 0);
      const hitScale = map(hitAge, 0, 400, 1, 3);
      p.fill(C.rust[0], C.rust[1], C.rust[2], hitAlpha);
      p.noStroke();
      p.ellipse(combatPlayerX, combatPlayerY + dodgeBob, 40 * hitScale, 40 * hitScale);
      p.fill(C.teal[0], C.teal[1], C.teal[2], hitAlpha * 0.3);
      p.ellipse(combatPlayerX, combatPlayerY + dodgeBob, 50 * hitScale, 50 * hitScale);
    }

    // ── Player ability flash — pixel starburst, not a smooth debug bubble ──
    if (state._abilityFlashTurn && state._abilityFlashTurn > now - 300) {
      const aAge = now - state._abilityFlashTurn;
      const aAlpha = map(aAge, 0, 300, 190, 0);
      const aReach = Math.round(map(aAge, 0, 300, 18, 42));
      const ax = combatPlayerX;
      const ay = combatPlayerY + dodgeBob - 16;
      p.noStroke();
      p.fill(C.teal[0], C.teal[1], C.teal[2], aAlpha);
      p.rect(ax - 2, ay - aReach, 4, 10);
      p.rect(ax - 2, ay + aReach - 10, 4, 10);
      p.rect(ax - aReach, ay - 2, 10, 4);
      p.rect(ax + aReach - 10, ay - 2, 10, 4);
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], aAlpha * 0.78);
      p.rect(ax - Math.round(aReach * 0.68), ay - Math.round(aReach * 0.68), 7, 3);
      p.rect(ax + Math.round(aReach * 0.68) - 7, ay - Math.round(aReach * 0.68), 7, 3);
      p.rect(ax - Math.round(aReach * 0.68), ay + Math.round(aReach * 0.68), 7, 3);
      p.rect(ax + Math.round(aReach * 0.68) - 7, ay + Math.round(aReach * 0.68), 7, 3);
    }

    // ── Wind knockback visual — screen shake effect ──
    if (state._windKnockTurn && state._windKnockTurn > now - 400) {
      const wAge = now - state._windKnockTurn;
      const wIntensity = map(wAge, 0, 400, 6, 0);
      const wPhase = wAge * 0.02;
      // Draw wind streaks across screen
      p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], map(wAge, 0, 400, 80, 0));
      p.strokeWeight(2);
      p.noFill();
      for (let ws = 0; ws < 5; ws++) {
        const wsX = (ws * 100 + wAge * 0.1 * (ws + 1)) % p.width;
        const wsY = p.height * 0.4 + Math.sin(wPhase + ws * 1.3) * 30;
        p.line(wsX, wsY, wsX + wIntensity * 2, wsY - wIntensity);
      }
      p.noStroke();
    }

    // ── Resonator staff cue — attached to Ender, never floating as a separate HUD prop ──
    if (state.player.staffCharges > 0) {
      const fx = combatPlayerX - 18;
      const fy = combatPlayerY + dodgeBob - 2;
      const chargeGlow = Math.sin(now * 0.004) * 0.3 + 0.7;

      p.stroke(C.scioto[0], C.scioto[1], C.scioto[2], 185);
      p.strokeWeight(3);
      p.line(fx, fy, fx + 8, fy - 42);
      p.noStroke();

      // Pixel charge crown at the staff tip.
      const tipX = fx + 8;
      const tipY = fy - 42;
      p.fill(C.teal[0], C.teal[1], C.teal[2], 155 * chargeGlow);
      p.rect(tipX - 3, tipY - 3, 6, 6);
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], 120 * chargeGlow);
      p.rect(tipX - 1, tipY - 10, 2, 5);
      p.rect(tipX - 1, tipY + 5, 2, 5);
      p.rect(tipX - 10, tipY - 1, 5, 2);
      p.rect(tipX + 5, tipY - 1, 5, 2);

    } else {
      // Empty staff remains physically attached to Ender; resource state is carried by the command window.
      const fx = combatPlayerX - 18;
      const fy = combatPlayerY + dodgeBob - 2;
      p.stroke(C.soil[0], C.soil[1], C.soil[2], 125);
      p.strokeWeight(3);
      p.line(fx, fy, fx + 8, fy - 42);
      p.noStroke();
    }

    // ── Staff aether motes — local to Ender rather than a detached HUD effect ──
    if (state.player.staffCharges > 0) {
      for (let i = 0; i < 5; i++) {
        const pi = (now * 0.02 + i * 7) % 5;
        const fx = combatPlayerX - 10 + Math.sin(now * 0.015 + i * 2.1) * 8;
        const fy = combatPlayerY + dodgeBob - 44 - pi * 7;
        const particleAlpha = Math.max(0, 70 - pi * 12 - Math.sin(now * 0.025 + i) * 15);
        if (particleAlpha > 0) {
          p.fill(C.teal[0], C.teal[1], C.teal[2], particleAlpha);
          p.noStroke();
          const mote = Math.max(2, Math.round(5 - pi * 0.7));
          p.rect(Math.round(fx), Math.round(fy), mote, mote);
        }
      }
    }

    // ── Ambient aether motes ──
    for (let i = 0; i < 8; i++) {
      const ai = (i * 47 + 13) % p.width;
      const aj = (i * 73 + 29) % (p.height * 0.45);
      const aPhase = (now * 0.0005 + i * 1.7) % (Math.PI * 2);
      const aDriftX = Math.sin(aPhase) * 20;
      const aDriftY = Math.cos(aPhase * 0.7 + i) * 12;
      const aAlpha = 8 + Math.sin(now * 0.003 + i * 2.3) * 5;
      p.fill(C.scioto[0], C.scioto[1], C.scioto[2], aAlpha);
      p.noStroke();
      p.ellipse(ai + aDriftX, aj + aDriftY, 3 + Math.sin(aPhase) * 1.5, 2 + Math.cos(aPhase * 0.5) * 1);
    }

    // ── Player character ──
    const px = combatPlayerX, py = combatPlayerY;
    if (visualStage && typeof visualStage.drawPlayer === 'function') {
      visualStage.drawPlayer({
        x: px,
        y: py,
        now,
        dodgeBob,
        player: state.player,
      });
    } else {
      p.fill(C.teal[0], C.teal[1], C.teal[2], 190);
      p.noStroke();
      p.rect(px - 10, py - 20 + dodgeBob, 20, 20);
    }

    // Player identity and HP live in the command window; keep the field sprite unobstructed.

    if (visualStage && typeof visualStage.drawTurnRail === 'function' && state.turn > 1) {
      visualStage.drawTurnRail({
        width: p.width,
        height: p.height,
        turn: state.turn,
        enemy: state.enemy,
        domain: sceneOptions && sceneOptions.domain ? sceneOptions.domain : 'ground',
        weatherId: sceneOptions && sceneOptions.weatherId ? sceneOptions.weatherId : 'clear',
        altitude: sceneOptions ? sceneOptions.altitude : null,
        encounterPressure: sceneOptions && Number.isFinite(sceneOptions.encounterPressure)
          ? sceneOptions.encounterPressure : 0,
      });
    }
  };
};

if (typeof window !== 'undefined') {
  window.AetherCombat = AetherCombat;
}
