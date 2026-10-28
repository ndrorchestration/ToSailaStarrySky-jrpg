# Chapter I 3D / RPG systems cohesion review — 2026-10-28

**Authority:** diagnostic only. No canon, skill unlock, save schema, character design or combat rebalance approved.

## Source inspection (exact parent of this audit)

- Native gameplay and visuals: optional 3D foredeck, ocean and sky are render-only, not combat, movement or story authority. Active 3D branch `visual/ch1-3d-ocean-motion-accessibility-20261028`; source visual quality is still a draft study, not an approved cinematic build.
- Stats: `godot/scripts/jrpg_stat_model.gd` defines levels **1–175**, five primary stats (might, grace, wits, spirit, presence), a **60** soft cap and **75** hard cap; derived HP, physical/aether/technical attack, support potency, defense, accuracy, evasion, initiative, break, resolve and critical rate. Level-one "baseline budget" constant is **25**, while listed level-one totals are Ender **31**, Ionia **26**, Lyra **25**, Reson **25**, Aepex **25**. This *may* be an intended per-actor exception: **do not silently normalize** until a designer decides whether the budget is normative.
- Formula: `first_wake_combat_formula.gd` has only **staffStrike, uncoverTruth, hold, rest** formula metadata; dedicated staff charge costs, bounded damage variance and critical chance; `combat_ability_contract.gd` reports `canExecute=false` and requires separate turn authority. Shared Dream and Wind Ward are blocked; proposed dual/triple resonance is design-only.
- **Narrative authority conflict:** `first_wake_party_combat_authority.gd` documents older Crossing Ender+Lyra active party, Ionia joining later; contemporary `first_wake_revised_opening_contract.gd` and `first_wake_resonance_roster_gate.gd` instead enforce **Ender → Ionia preflight → Lyra postflight family reunion**, and no Lyra before true reunion. These are **different story contracts**. Do not expose old Crossing combat roster/UI in the revised Chapter I until owner-approved migration is documented. The new diagnostic test explicitly preserves the known legacy constant to catch silent edits, rather than declaring that legacy chronology correct.
- **Leveling/skill balance remains unverified:** stat progression formulas alone are not an EXP curve, encounter TTK, status resistance, skill tree unlock, enemy budget, economy or multi-party battle test. No cinematic visual should imply such systems are unlocked merely by character affiliation or action animation.

## Integration/QA gates

1. **Narrative/gameplay domain lead:** sign off on one actual Chapter I party chronology and explicitly quarantine historical Crossing models before UI/3D avatar/action displays use them.
2. **Combat and economy lead:** validate 25-budget exceptions; derive full five-actor stat ranges, enemy and action numerical fixtures, equipment/resource costs, damage TTK, status/crit cap stress tests, resource recovery, EXP and late-game progression. No balance certificate from a basic stat-formula test.
3. **Magic/resonance authority lead:** distinguish story harmonic energy and ship engineering from combat spell unlocks; guard actual learned skill, roster, resource and turn state. Proposed Resonance effects need independent playable and authorization tests.
4. **3D/VFX and accessibility lead:** bind animations and VFX to immutable resolved combat events, not speculative “magic” descriptors. Draw FX only after authority returns a valid action result; damage numbers use authoritative computed values. Reduced motion, legible contrast, camera occlusion and 60fps/VRAM budgets must be proven on real target hardware.
5. **QA and production:** test normal F5 first flight, contact, Ionia-first recruitment, postflight/reunion gates, save/cold reload, 3D walkthrough and rendering with consistent character identity. Native scene captures and owner comparison required. No branch merge, Windows release or security bypass.

**Automation:** `godot/tests/first_wake_cross_system_cohesion_test.gd` checks bounded Five Lights stats at levels 1/50/175, positive HP, formula metadata fail-closed, blocked magic, opening party and forbidden early Lyra. It does **not** measure game fun or certify balance. Its pass is a structural audit only.
