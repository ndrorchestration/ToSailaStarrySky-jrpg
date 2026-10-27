# Resonance review grant admission — v0.3 candidate

**Authority:** isolated Godot 4.7.2 study only. Stacked on native Resonance PR #413, which itself is stacked on native Chapter I authority PR #347. All proposed Art names and balancing remain unapproved. Neither narrative Light identity nor spell-school affinity grants a production combination move.

## Why another gate

Prior Tidebound Promise review automatically passed an `[ART_ID]` unlock list to the preview catalog. That was safe inside the review fixture, but it did not demonstrate the **missing vs explicitly granted** experience or make a future story unlock seam visible. The new small, reversible gate refuses an Art unless the player explicitly enables training access in the *isolated* lab.

This is **not** a cryptographic ticket, production authorization or canonical relationship progression. No connector, saved grant, unlocked spell, story item or class skill has been created. The grant is in-memory, purely local to the lab and cleared at reset.

## Contract and UX

- `godot/scripts/resonance_review_grant_policy.gd` validates a structured grant bound to a known Art, its specific ordered participants, `isolated-resonance-review` scope, `explicit-training-control` origin and version. It denies missing/duplicate, corrupt, differently scoped, forged `canExecute`, mismatched membership, unknown Art or non-review states. Its `check_production()` **always rejects** because creator-authorized story/progression rules remain open.
- `godot/scripts/tidebound_promise_review.gd`: `grant_training_access("tidebound_promise")` can be called once before the turn begins, and makes a defensive in-memory copy of the lab grant. `admission()` checks that grant **before** the existing normalized shared AbilityDefinition and pure two-party resource reservation. `reset()` removes the grant. A blocked cast cannot advance a turn, spend Focus or create a ward.
- `godot/scripts/resonance_dual_review.gd`: review scene now begins **LOCKED**. Press **G** (or click **Grant training Art**) before **1** to execute the proposed combined ward. All other controls remain: 2 enemy strike, B no-ward comparison, R reset, M motion option. The label explicitly explains why a combo is unavailable.
- `godot/tests/resonance_review_grant_policy_test.gd`: rejects implicit Light-based unlock, forged fields/participants/scope, duplicate grants, non-review context, unknown Art and production-shaped access.
- Existing native Tidebound, 24-case damage sweep, live scene and GL-render capture tests deliberately issue a lab grant before testing the effect, preserving their expected model and proving that no automatic access is required.

## Canon/story chronology dependency

The newer Chapter I storyboard introduces Ionia first and Lyra **after the splashdown**; the older native Crossing party test still exposes Ender + Lyra. **Do not** attach Tidebound or any Resonance skill to the pre-Lyra production party. This review gate intentionally has **no chapter number, trust score, save entitlement, or relationship threshold**: such values would fabricate canonical unlock timing. Production advancement needs an approved story entitlement source, authority-owned grant contract, explicit chapter/roster checks, resource taxonomy, and persistence/migration plan first.

## Native evidence

Use the pinned official Godot 4.7.2 workflow, with `godot/tests/resonance_review_grant_policy_test.gd` added to the existing headless job. The unchanged standalone scene and GL capture workflow exercise the locked-to-granted-to-ward flow. Run results and exact SHA must be recorded separately when completed.

The code and test additions make **no changes to production combat permissions, save schemas, main scene, chronology, prohibited actions, release gating, protected branches, or private lore**. Merge/release authorization remains separate.
