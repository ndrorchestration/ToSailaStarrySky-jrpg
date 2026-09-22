/* ============================================================
   Aetherwake — Commons Ledger Contract v0.1
   Read-only substrate for Ender's Mycelial / Commons access.

   SSOT boundary:
   - Mycelial / Commons is exceptional plot-bound Ender access.
   - This module may reveal relationships, dependencies, exchanges,
     obligations, and network structure already present in runtime data.
   - It MUST NOT invent hidden canon, mutate resources, or authorize the
     legacy random "gain scrap or aether" behavior as production semantics.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherCommonsLedger = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const OWNER = 'ender';
  const ACCESS_MODE = 'mycelial-commons';
  const MUTATION_POLICY = 'read-only';

  function freeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => freeze(value[key]));
    return value;
  }

  function cleanList(value) {
    if (!Array.isArray(value)) return [];
    return value
      .filter(item => item != null)
      .map(item => typeof item === 'string' ? item : JSON.stringify(item));
  }

  function createLedgerEntry(target) {
    if (!target || typeof target !== 'object') {
      throw new Error('COMMONS_LEDGER_TARGET_REQUIRED');
    }

    const entry = {
      owner: OWNER,
      accessMode: ACCESS_MODE,
      readOnly: true,
      targetId: target.id || target.type || null,
      targetName: target.name || null,
      targetType: target.type || null,
      observedAbility: target.ability || null,
      observedAbilityDescription: target.abilityDesc || null,
      observedWeakness: target.weakness || null,
      relationships: cleanList(target.relationships),
      dependencies: cleanList(target.dependencies),
      exchanges: cleanList(target.exchanges),
      obligations: cleanList(target.obligations),
      unknowns: [],
    };

    if (!entry.targetType) entry.unknowns.push('targetType');
    if (!entry.observedAbility) entry.unknowns.push('observedAbility');
    if (!entry.observedWeakness) entry.unknowns.push('observedWeakness');
    if (!entry.relationships.length) entry.unknowns.push('relationships');
    if (!entry.dependencies.length) entry.unknowns.push('dependencies');
    if (!entry.exchanges.length) entry.unknowns.push('exchanges');
    if (!entry.obligations.length) entry.unknowns.push('obligations');

    return freeze(entry);
  }

  function summarize(entry) {
    if (!entry || entry.accessMode !== ACCESS_MODE) {
      throw new Error('COMMONS_LEDGER_ENTRY_REQUIRED');
    }
    const facts = [];
    if (entry.targetType) facts.push('type=' + entry.targetType);
    if (entry.observedAbility) facts.push('ability=' + entry.observedAbility);
    if (entry.observedWeakness) facts.push('weakness=' + entry.observedWeakness);
    if (entry.relationships.length) facts.push('relationships=' + entry.relationships.length);
    if (entry.dependencies.length) facts.push('dependencies=' + entry.dependencies.length);
    if (entry.exchanges.length) facts.push('exchanges=' + entry.exchanges.length);
    if (entry.obligations.length) facts.push('obligations=' + entry.obligations.length);
    return facts.join('; ');
  }

  function validate() {
    if (OWNER !== 'ender') throw new Error('COMMONS_LEDGER_OWNER_DRIFT');
    if (MUTATION_POLICY !== 'read-only') throw new Error('COMMONS_LEDGER_MUTATION_POLICY_DRIFT');
    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    OWNER,
    ACCESS_MODE,
    MUTATION_POLICY,
    createLedgerEntry,
    summarize,
    validate,
  });
});
