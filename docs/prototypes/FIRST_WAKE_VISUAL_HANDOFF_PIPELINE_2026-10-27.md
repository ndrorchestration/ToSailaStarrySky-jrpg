# First Wake × Aureate Wake cinematography — native presentation-only prototype seam

**Date:** 2026-10-27. **Authority:** PUBLIC-SAFE REVIEW CONTRACT; no scene composition/render execution, production art, canon promotion, released playable chapter, or installer. **Actual code/test branch is stacked on draft [#447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447)**, which contains Ender+Ionia job/preflight, an opt-in native 2D RigidBody2D/Area2D water-contact proof, and local settled flotation. No JS gameplay was added; the frozen JS `main` remains a historical reference.

## Source layers and readiness

| Source | Transferrable now | Not transferable by implication |
| --- | --- | --- |
| [#486 native review](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486), exact `36a13d6063235ed2114bb25d2a2cc61d1d4c9f22`, [Godot CI 40609537235](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609537235) | Provenanced camera IDs (bow, planform, stern); original ship/shore/sky visual study controls; reduced-motion, low-detail and opt-in dark-storm review concepts | Imported GL textures, 3D scene running inside Chapter I, accepted art, real ocean buoyancy in a planet, per-hardware frametime or canon storm/weather events |
| [#475 coast study](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/475), exact `0b547b4d893002c5ab462b772720e77009805515` | Reversible texture, surf/shelf, day/night and A/B evidence methodology | Production biome material atlas; sea-surface physics; finished coastline |
| [#447 Chapter I water review](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447), exact base `665a2b6439023afc0f77234b94a1eb05b4b170ba` | **Actual** authoritatively gated Ender→Ionia→preflight→short lift→engine warning→safe sea descent→Area2D contact→local buoyancy settlement | Chapter-complete story, final live-native opening, save migration, global planetary ocean, an approved flight cinematic |

## Thin seam implementation

`godot/scripts/first_wake_cinematic_handoff.gd` produces a *read-only visual-intent descriptor* from the actual `first_wake_flight_water_review.gd` native `review_snapshot()`. `godot/prototypes/first_wake_visual_handoff.v1.json` freezes source SHA, renderer version, provenanced available shot names and explicit non-authority. Default environment is golden-clear. Optional storm depth is **review-only OFF by default**, because the creator did not canonize a storm during the initial brief test flight. There is no hidden Moon Bridge information.

| Chapter I authentic physics/story state | Proposed future flight-lab camera | Progression guard |
| --- | --- | --- |
| Ionia-first accepted preflight | bow-quarter | No launch before actual engineering checks |
| Ascent after player launch | wing-planform | Visual effect cannot assert contact or new skills |
| Phase drift + containment / fuel warning | stern-quarter | No definitive fuel explanation |
| Controlled descent | bow-quarter | Still not waterborne |
| Real physics water contact plus settled float | stern-quarter | Only actual native contact, stable buoyancy and story FSM may advance to waterborne |

The handoff reports `executes_visuals=false`, `blocks_progression=false`, `changes_saves=false`, `modifies_story_state=false`, `production_ocean_verified=false`; it *does not import a 3D renderer, call shots, display captured stills or save new fields*. This is intentional. Presenting this test as a playable 2.5D ship cinematic would be false.

## Automated admission test

`godot/tests/first_wake_cinematic_handoff_test.gd` instantiates the actual native Godot 2D flight scene with legitimate preflight, exercises the live 2D body and water Area2D, tests a descriptor at real preflight/ascent/warning/descent/physical-waterborne states, rejects forged contact, early Lyra, invented fuel formula, story-step mismatch and production-ocean claims, verifies shot/visual-source SHA, and verifies review controls leave the real original FSM untouched.

The opt-in `.github/workflows/godot-first-wake-pilot.yml` adds the exact 4.7.2 headless test while preserving chapter/test/Windows security gates. This is a **pipeline authority/integration contract**, not a native visual-image acceptance test. Its actual CI completion status belongs to **its own new PR exact-head run**, not parent evidence.

## Next vertical-slice handoff

1. Creatively review a short **Chapter I First Lift → phase drift → ocean splashdown** 5–15s shot sequence and exact Ender/Ionia placement; no premature Lyra/Talen, no implied storm by default.
2. Add a visual-only `SubViewport`/scene-review adapter or provenance-verified original movie/stills behind the existing chapter interaction, then instrument a *real in-engine* render and fallback. Maintain current physics controller as the only contact truth.
3. Test matching ship silhouette, geodesic bridge, nearby coastline, rain/magic constraints, visibility and reduced-motion; compare same cameras against actual native software-GL frames.
4. Run target hardware performance, input remapping/accessibility, real rendered Chapter I playback, fail-closed story and save parity. Keep Windows Defender security preflight intact.
5. Creator approval and separate merge/release authorization.

**Not in scope:** redesign of the Five Lights, hidden celestial lanes, unapproved ship dimensions, final atmospheric canon, or full production globe conversion.
