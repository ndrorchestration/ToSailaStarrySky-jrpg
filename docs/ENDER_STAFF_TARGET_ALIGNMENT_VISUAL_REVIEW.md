# Ender staff combat — reachable training-target visual review

**Status:** New opt-in review layer / original geometric art, not approved. Stacked after #468 → #453 → #442 → #424 → #415. Chapter I playable scene and combat formulas remain unchanged.

## Evidence-based problem
The previous 21-frame storyboard shows distinct motion and grip, but the old fixed training disk at stage x=170 is visibly out of the swing path. A flash on an out-of-reach target suggests a collision that the engine has **not** verified. We must not misrepresent a purely visual beat as combat collision.

## Visual-only implementation
- `ender_staff_target_alignment_review.gd` adds a standalone authored wooden/brass training disk and grounded stand. **At a constant, known contact key p=0.695**, it samples the *actual keyed outward staff ferrule* from each of the four independent staff strike tracks. That position determines the review prop's stable visual anchor. It does not infer a target hit, physics raycast, enemy damage, item equip, or encounter state.
- During playback, the dynamic upper ferrule is compared to the stationary target anchor. The disk only performs a capped 4° tilt, 3.5-unit compression metadata and restrained optical rim indication when its visual distance is ≤18 units during p=0.62–0.77. It explicitly reports `collisionDetected=false`, `hitAuthorized=false`, `damage=0`, `sfxFired=false`, `combatCommandIssued=false`.
- Four independent facings place the disk **on the actual approach side** of the actor, rather than mirroring generic weapons. Target stands remain grounded at local y=112. This is an alignment *rehearsal*, not a dynamically simulated target impact.
- In the existing `weapon_directional_cinematic_review.tscn` preview, the original distant target/old optical marker are hidden only while **Combat keyframes** is selected. Both reappear unchanged when switching back to source walking-candidate or mannequin modes. The full-length wood/brass staff, its center wrap and two grip anchors are preserved.
- Motion reduction keeps phase labels but freezes authored physical body geometry and disables zoom, disk tilt, motion trails and bright flashes.

## Native tests and render evidence
- `ender_staff_target_alignment_review_test.gd`: exact Godot scene/actor authority; all four sides; contact-distance ≤0.001 at the intended key; no pre/recovery disk reaction; physical target bounds; no unauthorized actor/weapon/action promotion; reduced motion; explicit no-collision/no-damage; switchback restoration of legacy target.
- `capture_ender_staff_target_alignment.gd`: 4 × 3 native before/contact/recovery frames plus 1 reduced-motion reference — **13 genuine 960×640 Godot captures**. Hashes printed and 4×3 stage-only lossy contact sheet emitted into CI logs. Lossless frames remain runner-local unless separately moved under approved custody.

## Acceptance boundaries
Render-and-test green means the authoring fixture aligns with *its own deterministic pose key*, not that a real swing hits an enemy or a full combat system is operational. Independent review is required for target staging and visual quality. The current character is intentionally original, geometric and provisional; creator-approved portrait, sprite sources, five-energy story canon and Chapter I narrative are untouched. Windows Defender host-security gate, art signoff, save schema, formula execution and merge/release remain OPEN.

**Future gate:** add a real animation-event receiver and target collision contract, compare the VFX to actual collision diagnostics in a playable encounter, conserve HP/resources/turns, and visually refine layered character sprites; each step requires its own authorization and native regression proof.
