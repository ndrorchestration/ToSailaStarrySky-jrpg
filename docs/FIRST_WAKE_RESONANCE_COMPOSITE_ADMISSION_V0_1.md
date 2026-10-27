# First Wake × Resonance — composite review admission v0.1

**Status:** native Godot 4.7.2 integration candidate **only**, draft/unmerged. This is **NOT** a live Chapter I combo, creator-approved Art unlock, save migration, final artwork, or release. The model intentionally returns `canExecute=false` on every path.

## Bound source and why this exists

This is the first **code-level composite** of two existing separately verified and independent draft stacks, without silently merging those PRs:

- **Source-base:** [Chapter I Ionia-first chronology/scene #450](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/450), exact source head `11995e859aa97eac0be5de7ba83ad5ee456a34ef`. Its `first_wake_revised_opening_contract.gd`, `first_wake_resonance_roster_gate.gd`, playable dock/engineering scene and original native First Wake permissions remain untouched.
- **Selectively reused unchanged content blobs** from [Resonance lab-grant #443](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/443) at `ae9fc46029722094f54102d90bee5dc96f24d791` (which contains the predecessor [#413](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/413)): the 19 documented Resonance catalog/normalizer/planner/grant/standalone-scene/test and support-document files. The *two existing conflicting CI workflow variants were not copied*. The composite branch adds only their test invocations and native-render capture to the #450 workflow lineage.

This is a **new additive review commit**, not a merge of #413/#443 into Chapter I main, and not an approval to merge those draft PRs. Source history, parent branch and creator canon remain separately reviewable.

## Creator-directed narrative vs reviewed model

- Story order: Ender receives Ionia's engineering employment offer; Ionia joins first; safe first flight/splashdown; Lyra and noncombat child Talen are introduced after recovery. Lyra does **not** belong to the active story roster during dock engineering, test flight, ocean contact or pre-reunion diagnosis. Approved immutable plot-energy mapping Spirit/Water/Earth/Fire/Air is not spell mastery, turn permission or Art entitlement.
- The older native Crossing implementation still has Ender+Lyra at start and Ionia-at-choice. This historical source **has not** been migrated or reauthorized; that live scene and save format remain intact.
- [Narrative source](https://app.notion.com/p/406f5bad238b81bcbacbeeb372e8fd77). The standalone preview can only prove employment, flyer, Ionia's arrival and engineering; it does **not** play the later flight/reunion.
- `Tidebound Promise` is a **proposed Art name and trial effect**. Creator has not approved a plot unlock moment, full turn economy, Arete/Echo currency, saved Art, or real combat skills for Lyra.

## Shared preflight with four **independent** locks

New `godot/scripts/first_wake_resonance_composite_preflight.gd` is **read-only** and accepts only exact `RefCounted` objects from the known revised-opening model and isolated Tidebound lab. It checks, in order:

1. Source identity / original native `first_wake_party_combat_authority.gd` validity (Lyra still has **no** authorized production formula turn).
2. The stage/roster/safe-reunion boundary from `first_wake_resonance_roster_gate.gd`. Ender+Lyra is rejected before their safe post-splashdown story reunion; even after reunion, the result is **presence only**.
3. A matching, `DESIGN_ONLY`, `canExecute=false` shared definition from `combat_ability_contract.gd`; plus `tidebound_promise_review.gd`'s **explicit temporary training-grant** admission (no automatic Light-derived unlock).
4. The pure `party_action_reservation.gd` plan: two available protagonists, one local review Focus each, with both actions atomically reserved in **a proposed deep copy only**; no live reservation commit.

The successful result contains `canPreview=true`, **`canExecute=false`**, **`canUnlockArt=false`**, an exact current review story stage and a copy of the two tentative reservation receipts. `try_execute` **always denies** `production_art_authority_not_implemented` and **never** calls the actual lab `activate()` method.

When used as a future **story-authority seam**, it must not be regarded as runtime combat authorization. It is not a cryptographic grant. The separate Tidebound F6 standalone lab remains playable with G (training unlock), 1 (ward), 2 (test strike), R (reset), etc., but is **not** attached to revised Chapter I and cannot be launched there.

## QA / exact branch evidence

- `godot/tests/first_wake_resonance_composite_preflight_test.gd` walks *the real previously-authored model object*: search → Ionia recruitment → checks → flight → observed failure → seaworthy ocean-contact evidence → postflight reserve → safe Lyra/Talen reunion. It deliberately issues an early lab grant and still requires every pre-Lyra check to reject. After Lyra joins, it proves absent training grant, forged old-Crossing story, corrupted roster/reunion, low Focus, and wrong battle phase fail; explicit training plus valid presence yields only nonmutating two-person reservation preview. The original formula/Art execution paths remain fail closed.
- The existing native 4.7.2 workflow additionally runs the 7 independent Resonance catalog/normalizer/reservation/grant/transaction/damage/scene checks plus the new composite contract test. It continues to run revised-opening and physical playable dock/engineering tests.
- Existing GL Compatibility capture adds three genuine 960×640 Tidebound laboratory frames: initial locked, shield and resolved. No artifacts are uploaded due the independent preexisting custody/quota gate. A rendered frame does not imply character-art approval.
- Verify exact **new PR HEAD** hosted import, contracts, actual Godot renderer and smoke independently before reporting PASS; no local Godot binary available in this session.
- Windows Defender security preflight and separate functional/install/player-release QA remain independent blockers, never waived by smoke or native script success.

## Remaining required gates

Creator approval of combo terminology, timing, relationship/progression requirements and participating class/job compatibility; migration of **mainline** Chapter I party-state/quest/save and true water event, confirmation of trial UI in production without Lyra pre-introduction, existing external battle action authority, typed economic costs and effects, multi-turn interruptions/saves, accepted character-specific cinematics and accessible input, actual player test, Windows custody and release authorization. None is implied by a successful preflight.
