# First Wake → Godot Game Architecture: Prototype Integration Pipeline

**Status:** PROTOTYPE SOURCE / REQUIRES NATIVE CI; no merge, canon revision, save-schema promotion, release or UI art admission.
**Branch ancestry:** [draft #477](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/477) exact parent `658d225177bb22d9e64147207ce218d0117de6d0`, based on independently tested revised narrative #425/#426/#430/#447/#455/#464.
**Critical structural fact:** as inspected 2026-10-27, repository `main` still contains the **historical JS/p5 game**; Godot gameplay is on stacked draft branches. The Godot project's current `run/main_scene` is the older Lyra-first Chapter I native migration preview. New Ionia-first authorial chronology must **not** be silently overwritten by that old resolver, save v1 or worldmap study.

## What already transfers directly into the future native game

| Component already developed | First production consumer candidate | Integration gate |
| --- | --- | --- |
| Flyer, Ender job search, Ionia paid hiring (#430) | Native quest prompts, introductory playable dock, NPC interaction | Player/portrait/dialogue art approval; revised chronology in production scene |
| Three engineering inspections, preflight | Context prompts, evidence flags and engineering UI | Single event identity and save migration; do not turn checks into fake engine simulation |
| Ionia-first, Lyra-second chapter-state (#426) | Narrative party roster, character presence, dialogue triggers | Explicit split between **story presence**, **combat entitlement** and class/job trees |
| Short flight, drift, stable local splashdown (#447) | Cinematic Aureate Wake state, transition cues, camera/test shots | Replace 2D synthetic ocean with actual approved ship/planet physics; no teleport or invented hydrostatics |
| Reserve diagnosis, recovery 3/3 checklist (#455/#477) | Quest objectives, deck affordances and journal evidence | No sea route, message delivery or safe family meeting inferred |
| Family review and 2-of-3 clue investigation (#464) | Relationship scene, field clue interactions, theory board | Original Lyra/Talen geography and story/VO approval; no hidden power inference |
| Environmental ship light/rain shader work (#432, separate draft lineage) | Reusable presentation after ship/camera scene IDs align | Render pass/fidelity, GL real frame capture, frame pacing, reduced-motion |
| Globe/planet/auroral navigation (#364, separate draft lineage) | Later travel/exploration systems, not Chapter I landing proof | Shared coordinates, scene authority and progression lock; restricted late navigation stays private |

## First executable integration seam in this draft

`godot/scripts/first_wake_pipeline_projection.gd` is a **pure read-only adapter**. It accepts the *actual native* creator-directed opening contract and optional **same-source** flight, recovery and reunion scenes, then returns a versioned **prototype event/cue envelope**:

- **Story**: `story_phase` from job search through working theory, `story_party` with enforced Ender → Ionia → Lyra ordering, chapter/quest cue identifiers.
- **Ship/environment**: `ship_state` distinguishing docked, test flight, controlled descent and stably afloat; an abstract `visual_cue` for later ship, camera and weather consumers, not camera or worldmap authority.
- **Investigation/UX**: crew/engine/contact readiness observation list, working hypothesis and optional 2-of-3 clue state. Copy outputs so a UI consumer cannot mutate the authoritative runtime arrays.
- **Authority**: `prototype_only`; no navigation permission, production ocean proof, actual family reunion, production save write, combat grants or canon promotion. Invalid/mismatched stage, old Lyra-first FSM, foreign ship/quest sources, insufficient water or family evidence **fail closed**.

A new native SceneTree test exercises an actual Godot dock scene, Ionia first, preflight, physical `RigidBody2D` local ocean sensor, postflight reserve inspection, 3/3 recovery checks, synthetic family reunion (still separately flagged QA-only), Lyra second, and the two-observation fuel hypothesis. At each stage it checks **actual shared state → read-only cue contract**, rejects contradictions and verifies no privilege/canon leakage. The existing digest-verified Godot 4.7.2 CI now invokes this test. This is a **cross-system prototype contract**, not the real playable production entry scene.

## Recommended reversible admission sequence

1. **Now:** admit the *interface*, test and terminology to the forward Godot design after exact-head CI, leaving story scenes on draft branches. No source/party/save mutation in the historical default entrypoint.
2. **Next:** bind `visual_cue` to a producer-independent 960×640 CanvasLayer stage label and test real GL screenshots: dock → engineering → lift → ocean → deck. Use audited Aureate Wake model/GL shaders when the branch is reconciled; avoid treating synthetic polygons as accepted ship art.
3. **Then:** implement canonical event store / new save schema with migration fixtures distinct from legacy `aetherwake.first-wake.chapter1.v1`, with rollback/replay and no automatic combat actions. Never force revised narrative stages into the incompatible Lyra-first old save shape.
4. **Then:** introduce actual naval travel and reunion geography as a creator-reviewed scene/route; do not convert `ready_for_route_review` into actual `family_contact_safe` based merely on passing tests.
5. **Later:** align real planet/ship 3D flight and weather/camera branches, demonstrate altitude/ocean collision, timing, audio and accessibility under actual target hardware, then request gameplay/art release approval separately.

## Quality gates

- [ ] Exact-head official Godot 4.7.2 editor import and native test **PASS** including new pipeline adapter regression.
- [ ] Cross-scene prototype state resets/replays with no accidental saved-state or power changes.
- [ ] Real 960×640 GL capture of native cues in one coherent stage and UI/text acceptance.
- [ ] Actual cinematic ship/planet scene handshake verified without hidden geography or forbidden content.
- [ ] New author-approved canonical opening and persistence scheme replacing the older Lyra-first entry sequence.
- [ ] Security: Windows Defender custody gate, native hardware visual/performance test, uncoached player QA and creator approval remain independent.

**Do not merge the stacked narrative prototype into `main` or change its production entrypoint until the dependency and canon migrations are resolved.**
