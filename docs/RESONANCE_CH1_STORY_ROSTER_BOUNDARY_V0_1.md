# First Wake → Resonance story-roster gate (read-only review v0.1)

**STATUS: NONAUTHORITATIVE GODOT ADAPTER / DRAFT.** No live combination ability, no story save schema, no changed party runtime, no spell, class, job, or damage permission.

## Authority and provenance

- Creator-directed [opening reboard](https://app.notion.com/p/406f5bad238b81bcbacbeeb372e8fd77): Ender seeks work, Ionia joins first after employment, test flight/engine failure and controlled ocean splashdown, Lyra joins with family after safety/postflight diagnosis. Exact reunion geography and ultimate fuel mechanism are open.
- [Revised-opening story contract #426](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/426) and playable opening [draft #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430) are **separate unmerged review artifacts**. The standalone new adapter *reuses* the existing `first_wake_revised_opening_contract.gd` instead of inventing another chronology state machine.
- [Resonance lab #413](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/413) and its explicit training-grant gate [#443](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/443) are **parallel branches**. They already enforce separate metadata, resource and review-scope admission. This PR does **not** import/reimplement them; future integration needs an independently reviewed composite branch.
- The incumbent `first_wake_chapter1_state.gd` and `first_wake_party_combat_authority.gd` on PR #347 are historical adaptation state: the old Crossing party Ender+Lyra / Ionia-at-choice is *in conflict with the new creator story*. Do not overwrite it without live scene/quest/save tests.

## Pure gate behavior

`godot/scripts/first_wake_resonance_roster_gate.gd` takes the **real revised-opening GDScript model object**, not arbitrary caller-supplied JSON or a lookalike old save. A query validates two/three distinct known protagonists; checks stage-bound full party roster and safe-family-reunion evidence; and confirms every proposed Art participant is actually present at that stage. It NEVER mutates story, issues story/grant tokens, reserves actions, unlocks techniques or executes abilities.

- Initial search: Ender only; Ender+Lyra pair **blocked**.
- After Ionia's job, throughout engineering, preflight and flight: Ender+Ionia presence can be reported, but **no Art permission**; Ender+Lyra **blocked**.
- Recorded phase/containment/fuel failure and seaworthy ocean splashdown: Ender+Lyra **still blocked**.
- Postflight fuel inventory: Lyra **still blocked** until safe family introduction.
- After the model records safe Lyra/Talen reunion: Ender+Lyra **roster-eligible only** (and Ender+Ionia+Lyra present), with `canUnlockArt=false` and `canExecute=false`. Roster presence ≠ spell or combo authorization.
- Old-crossing/fabricated states, mismatched ordered party, missing reunion evidence, child party insertion, unknown Aepex/Reson early, duplicates, invalid participant sizes: fail closed.

**Critically, passing the post-reunion roster gate does not decide Tidebound Promise's actual story unlock.** That would require creator-approved timing and art, an authorized progression source, combat-turn scheduling and the separate #443 admission/turn contract. It does not imply the group learns a combo as soon as Lyra joins.

## Player-visible Chapter I review proof

The existing **playable flyer/interview/engineering preview** from PR #430 now calls this new read-only gate when refreshing the party HUD. The on-screen accessibility text states **RESONANCE: LOCKED — Lyra has not joined; no combined abilities available.** It remains present after Ionia accepts Ender for the job and at the preflight handoff. This is informational only; no Resonance menu, combat command, synchronized ability or Lyra actor is instantiated. The revised-opening preview stops before flight, so it cannot demonstrate a post-splashdown live player action.

The pre-existing `first_wake_job_preview_test.gd` is extended to check the actual Godot scene label and unchanged refusal state at job search, after Ionia recruitment, and at preflight. This is actual scene-level UI evidence after Godot CI passes—not evidence that mainline Chapter I now follows the new order.

## Tests and evidence requirements

- `godot/tests/first_wake_resonance_roster_gate_test.gd`: walk the actual revised opening model through Ionia hiring → checked flight → observed failure → recorded splashdown → reserve inspection → safe Lyra/Talen reunion → 2-of-3 working fuel theory; assert no Ender+Lyra roster before reunion, full denial/side-effect-free validation before every stage and nonauthorizing eligibility after.
- Preserve the existing opening scene test and all earlier legacy First Wake tests; update the pinned Godot 4.7.2 native workflow to execute this one additional SceneTree test.
- Native exact SHA, real editor import and contract pass must be confirmed from GitHub Actions before reporting verified. A unit PASS does not prove ocean physics, actual game-screen UI, merged chronology, playable combined Arts, canonical romance/family arcs, or Windows acceptance.
- No cross-branch merge, no change to protected main, no release, no unreleased plot content.

## Future composite integration gate (not yet implemented)

After explicit approval of the new Chapter I adaptation and when assembling the new game branch, require (a) revised scene and save chronology, (b) story roster eligibility from this gate, (c) creator-approved story Art unlock, (d) existing external party combat action authority, (e) typed joint resource reservation, (f) targeting/effect resolver, (g) QA under multiple battles. **No one of (a)–(e) implies the others.**
