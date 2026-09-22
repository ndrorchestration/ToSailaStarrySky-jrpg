/* ============================================================
   Aetherwake JRPG — Production Stat Model v0.1
   Research-informed numeric substrate for formula combat.

   IMPORTANT:
   - No player-facing dice.
   - No PbtA success/partial/failure bands.
   - This module does not mutate combat state.
   - All RNG enters as an injected [0,1) value for deterministic tests.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherJRPGStatModel = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const LEVEL_MIN = 1;
  const LEVEL_CAP = 175;
  const PRIMARY_MIN = 1;
  const PRIMARY_SOFT_CAP = 60;
  const PRIMARY_HARD_CAP = 75;

  const PRIMARY_STATS = Object.freeze([
    'might', 'grace', 'wits', 'spirit', 'presence',
  ]);

  const LEVEL_ONE_BASELINE_BUDGET = 25;

  const PROFILES = deepFreeze({
    ender: {
      role: 'analyst-controller',
      level1: { might:3, grace:4, wits:8, spirit:12, presence:4 },
      capstone: { might:22, grace:30, wits:60, spirit:42, presence:36 },
    },
    lyra: {
      role: 'perceptive-support',
      level1: { might:2, grace:6, wits:5, spirit:9, presence:3 },
      capstone: { might:18, grace:42, wits:36, spirit:66, presence:30 },
    },
    ionia: {
      role: 'captain-support',
      level1: { might:5, grace:5, wits:4, spirit:3, presence:9 },
      capstone: { might:40, grace:36, wits:30, spirit:24, presence:60 },
    },
    reson: {
      role: 'durable-weapon-specialist',
      level1: { might:9, grace:4, wits:3, spirit:4, presence:5 },
      capstone: { might:68, grace:34, wits:24, spirit:34, presence:40 },
    },
    aepex: {
      role: 'technical-specialist',
      level1: { might:4, grace:5, wits:9, spirit:3, presence:4 },
      capstone: { might:32, grace:40, wits:64, spirit:28, presence:36 },
    },
  });

  const POLICY = deepFreeze({
    damageVarianceMin: 0.95,
    damageVarianceMax: 1.05,
    criticalMultiplier: 1.5,
    defaultCritRate: 0.05,
    critRateMin: 0,
    critRateMax: 0.5,
    defaultAccuracy: 0.95,
    hitChanceMin: 0.6,
    hitChanceMax: 0.995,
    statusChanceMin: 0.05,
    statusChanceMax: 0.95,
    defenseConstant: 100,
    defenseWeight: 1.5,
    minDamage: 1,
  });

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function normalizeLevel(level) {
    const n = Number.isFinite(Number(level)) ? Math.floor(Number(level)) : LEVEL_MIN;
    return clamp(n, LEVEL_MIN, LEVEL_CAP);
  }

  function normalizePrimary(value) {
    const n = Number.isFinite(Number(value)) ? Number(value) : PRIMARY_MIN;
    return clamp(n, PRIMARY_MIN, PRIMARY_HARD_CAP);
  }

  function sumPrimaries(stats) {
    return PRIMARY_STATS.reduce((sum, key) => sum + Number(stats[key] || 0), 0);
  }

  // Slightly back-loaded curve: early identity is stable, late mastery still has headroom.
  function growthProgress(level) {
    const l = normalizeLevel(level);
    const t = (l - LEVEL_MIN) / (LEVEL_CAP - LEVEL_MIN);
    return Math.pow(t, 1.08);
  }

  function getProfile(characterId) {
    return PROFILES[characterId] || null;
  }

  function getPrimaryStats(characterId, level) {
    const profile = getProfile(characterId);
    if (!profile) throw new Error('UNKNOWN_CHARACTER_PROFILE:' + characterId);
    const p = growthProgress(level);
    const result = {};
    PRIMARY_STATS.forEach(stat => {
      const start = profile.level1[stat];
      const end = profile.capstone[stat];
      result[stat] = normalizePrimary(Math.round(start + (end - start) * p));
    });
    return result;
  }

  function derive(stats, level, equipment) {
    const s = {};
    PRIMARY_STATS.forEach(key => { s[key] = normalizePrimary(stats[key]); });
    const l = normalizeLevel(level);
    const eq = equipment || {};
    const armor = Number(eq.armorDefense || 0);
    const ward = Number(eq.aetherDefense || 0);
    const accuracy = Number(eq.accuracy || 0);
    const evasion = Number(eq.evasion || 0);
    const weaponAttack = Number(eq.weaponAttack || 0);
    const techPower = Number(eq.techPower || 0);
    const supportPower = Number(eq.supportPower || 0);

    return Object.freeze({
      maxHp: Math.round(45 + l * 4.5 + s.might * 7 + s.spirit * 2.5),
      physicalAttack: Math.round(s.might * 2.0 + s.grace * 0.35 + weaponAttack),
      aetherAttack: Math.round(s.spirit * 1.8 + s.wits * 0.65),
      technicalPower: Math.round(s.wits * 2.0 + s.grace * 0.25 + techPower),
      supportPotency: Math.round(s.presence * 1.65 + s.spirit * 0.65 + supportPower),
      physicalDefense: Math.round(s.might * 1.25 + s.grace * 0.25 + armor),
      aetherDefense: Math.round(s.spirit * 1.25 + s.presence * 0.35 + ward),
      accuracy: Math.round(70 + s.wits * 0.85 + s.grace * 0.35 + accuracy),
      evasion: Math.round(s.grace * 0.8 + s.wits * 0.2 + evasion),
      initiative: Math.round(s.grace * 1.5 + s.wits * 0.5),
      breakPower: Math.round(s.might * 1.45 + s.wits * 0.2),
      resolve: Math.round(s.spirit * 0.9 + s.presence * 0.9),
      critRate: clamp(
        POLICY.defaultCritRate + (s.grace + s.wits) * 0.0008,
        POLICY.critRateMin,
        POLICY.critRateMax
      ),
    });
  }

  function defenseMultiplier(defense) {
    const d = Math.max(0, Number(defense || 0));
    return POLICY.defenseConstant /
      (POLICY.defenseConstant + d * POLICY.defenseWeight);
  }

  function varianceMultiplier(rng) {
    const r = clamp(Number.isFinite(Number(rng)) ? Number(rng) : 0.5, 0, 0.999999);
    return POLICY.damageVarianceMin +
      (POLICY.damageVarianceMax - POLICY.damageVarianceMin) * r;
  }

  function resolveDamage(input) {
    if (!input || !input.attacker) throw new Error('DAMAGE_ATTACKER_REQUIRED');
    const statValue = normalizePrimary(input.attacker[input.scalingStat]);
    const power = Math.max(0, Number(input.power || 0));
    const scaling = Math.max(0, Number(input.scaling || 1));
    const equipmentPower = Math.max(0, Number(input.equipmentPower || 0));
    const defense = Math.max(0, Number(input.defense || 0));
    const elementMultiplier = Math.max(0, Number(input.elementMultiplier || 1));
    const situationalMultiplier = Math.max(0, Number(input.situationalMultiplier || 1));
    const variance = input.allowVariance === false ? 1 : varianceMultiplier(input.varianceRng);
    const critRate = clamp(
      Number.isFinite(Number(input.critRate)) ? Number(input.critRate) : POLICY.defaultCritRate,
      POLICY.critRateMin,
      POLICY.critRateMax
    );
    const critRng = clamp(Number.isFinite(Number(input.critRng)) ? Number(input.critRng) : 0.999999, 0, 0.999999);
    const critical = input.canCrit !== false && critRng < critRate;
    const critMultiplier = critical ? POLICY.criticalMultiplier : 1;

    const preDefense = (power + statValue * scaling + equipmentPower) *
      variance * critMultiplier * elementMultiplier * situationalMultiplier;
    const damage = Math.max(POLICY.minDamage,
      Math.round(preDefense * defenseMultiplier(defense)));

    return Object.freeze({
      damage,
      critical,
      statValue,
      variance,
      defenseMultiplier: defenseMultiplier(defense),
      preDefense,
    });
  }

  function resolveHealing(input) {
    if (!input || !input.actor) throw new Error('HEAL_ACTOR_REQUIRED');
    const statValue = normalizePrimary(input.actor[input.scalingStat]);
    const power = Math.max(0, Number(input.power || 0));
    const scaling = Math.max(0, Number(input.scaling || 1));
    const supportBonus = Math.max(0, Number(input.supportBonus || 0));
    const situationalMultiplier = Math.max(0, Number(input.situationalMultiplier || 1));
    return Math.max(0, Math.round(
      (power + statValue * scaling + supportBonus) * situationalMultiplier
    ));
  }

  function resolveHitChance(input) {
    const base = Number.isFinite(Number(input && input.baseAccuracy))
      ? Number(input.baseAccuracy) : POLICY.defaultAccuracy;
    const attackerAccuracy = Number(input && input.attackerAccuracy || 0);
    const defenderEvasion = Number(input && input.defenderEvasion || 0);
    // One point of accuracy/evasion differential = 0.5 percentage point.
    return clamp(base + (attackerAccuracy - defenderEvasion) * 0.005,
      POLICY.hitChanceMin, POLICY.hitChanceMax);
  }

  function resolveStatusChance(input) {
    const base = Number.isFinite(Number(input && input.baseChance))
      ? Number(input.baseChance) : 0.5;
    const potency = Number(input && input.potency || 0);
    const resolve = Number(input && input.resolve || 0);
    return clamp(base + (potency - resolve) * 0.005,
      POLICY.statusChanceMin, POLICY.statusChanceMax);
  }

  function resolveBreakDamage(input) {
    const attack = Math.max(0, Number(input && input.breakPower || 0));
    const resistance = Math.max(0, Number(input && input.breakResistance || 0));
    const power = Math.max(0, Number(input && input.power || 1));
    return Math.max(0, Math.round((attack * power) - resistance * 0.5));
  }

  function validate() {
    Object.entries(PROFILES).forEach(([id, profile]) => {
      if (sumPrimaries(profile.level1) < LEVEL_ONE_BASELINE_BUDGET) {
        throw new Error('LEVEL_ONE_BUDGET_BELOW_BASELINE:' + id);
      }
      PRIMARY_STATS.forEach(stat => {
        if (profile.level1[stat] < PRIMARY_MIN) {
          throw new Error('LEVEL_ONE_PRIMARY_BELOW_MIN:' + id + ':' + stat);
        }
        if (profile.capstone[stat] > PRIMARY_HARD_CAP) {
          throw new Error('CAPSTONE_PRIMARY_ABOVE_HARD_CAP:' + id + ':' + stat);
        }
        if (profile.capstone[stat] < profile.level1[stat]) {
          throw new Error('PRIMARY_GROWTH_REVERSED:' + id + ':' + stat);
        }
      });
    });
    if (POLICY.damageVarianceMin < 0.9 || POLICY.damageVarianceMax > 1.1) {
      throw new Error('DAMAGE_VARIANCE_TOO_WIDE');
    }
    if (POLICY.criticalMultiplier > 2) {
      throw new Error('CRITICAL_MULTIPLIER_TOO_HIGH');
    }
    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    LEVEL_MIN,
    LEVEL_CAP,
    PRIMARY_MIN,
    PRIMARY_SOFT_CAP,
    PRIMARY_HARD_CAP,
    PRIMARY_STATS,
    LEVEL_ONE_BASELINE_BUDGET,
    PROFILES,
    POLICY,
    normalizeLevel,
    normalizePrimary,
    growthProgress,
    getProfile,
    getPrimaryStats,
    derive,
    defenseMultiplier,
    varianceMultiplier,
    resolveDamage,
    resolveHealing,
    resolveHitChance,
    resolveStatusChance,
    resolveBreakDamage,
    validate,
  });
});
