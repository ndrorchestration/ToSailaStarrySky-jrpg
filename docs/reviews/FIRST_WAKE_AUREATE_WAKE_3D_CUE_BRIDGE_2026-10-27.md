# First Wake → Aureate Wake 3D cinematic cue bridge — 2026-10-27

**Status:** Independent native Godot 4.7.2 study; FIRST HEAD CI / GL EVIDENCE PENDING at creation. Draft/unmerged, noncanonical art; no main/production entrypoint edits or release.

## Exact source ancestry (do not silently pretend one Godot project)

The forward Chapter I story-to-UI producer, [draft PR #491](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491), exact `641a1ba07535ff6f2383fa6ca46a5d4a1d7818fb`, lives in the **2D Godot chapter pilot** `godot/scripts/first_wake_pipeline_projection.gd`. It passed [Godot #40612310838](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40612310838). It returns immutable-like copy-safe read-only `tstss.review.first_wake_pipeline.v1` records with story phase, Ionia-first/Lyra-second party, quest/visual cue, ship state and explicit production-denial flags. It never writes saves or grants powers.

The existing original four-wing **Aureate Wake** art/weather and real GL flight renderer is a **separate project and ancestry**, `godot/flight_slice/`, [draft PR #432](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/432) at exact `b65c9ca1114c2df35193df9e0c598b8705b305d8`. It has its own independent main scene, shader weather crossfade, cinematic rig, collision/flight study and screenshot workflow. These cannot simply be merged by copying the 2D scenes or redirecting `godot/project.godot`.

**This new visual-consumer PR stacks on #432 (not #491)**, and uses exactly #491's versioned envelope shape via an independent curated input fixture. The producer and consumer **have not yet been executed in one loaded Godot project or one CI job**. A producer-to-consumer artifact handshake and source-level migration remain required for production.

## What this prototype genuinely integrates

1. `godot/flight_slice/first_wake_visual_cue_consumer.gd` validates the exact schema, stage-specific story/visual/quest cue, party order, ship phase, recovery evidence, two-of-three hypothesis, QA-only reunion provenance, and every production authority denial. Rejects legacy Lyra-first, fabricated sailing/ocean and invented combat power.
2. The real flight slice's `main.gd` exposes an **opt-in** `preview_first_wake_visual_cue(packet, duration)` and `clear_first_wake_visual_cue()`. A valid packet alters **only** the camera goal, existing Godot `visuals.queue_environment_look()` light/weather/blend parameters and a conspicuous **concept-only** cue label. The native 3D Aureate Wake with lofted hull, four cambered wings, and existing terrain remains intact. Invalid packet has no effects.
3. The main renderer preserves all automatic flight, pilot input, touchdown collider, ship motion transform, planet/weather authority and existing scene selection. Manual piloting or land-contact review **blocks** starting the cinematic cue.
4. `tests/test_first_wake_visual_cues.gd`: executable Godot assertions for valid stage mapping, real 3D camera/mood, four wing rigs and ship unchanged; rejects fabricated authorizations, early Lyra, insufficient theory, bad source IDs, manual-mode changes and saves. No script claims real ship ocean contact.
5. `tests/capture_first_wake_visual_cues.gd`: **four actual 960×640 Compatibility/OpenGL frames** of the same ship at fixed location, clock and camera: first lift, controlled descent, ocean-afloat look, shipboard recovery look. Three pairwise RGB difference tests sample actual scene pixels and exclude the top/footer text so changed words alone cannot pass. This only proves the weather/lighting look changes on the original ship; not believable rain/mood, artistry or astronomical weather.

## Status and missing gates

- [ ] Native test and real GL capture executed **at this exact head**; no inherited #432 CI claims.
- [ ] Review the actual generated frames and verify framing, HUD readability, underwater/skyline errors and artistic quality, rather than relying on RGB differences alone.
- [ ] Shared verified producer/consumer artifact exchange without fake fixtures, and a single agreed Godot root/scene architecture. Producer version drift must fail closed.
- [ ] Time-of-day/weather and water contact remain **presentation-only**; the first test flight's actual atmosphere and sea route have **not** been canonically set. The blue-hour/rain/mist are alternative cinematography moods, not plot facts.
- [ ] Art-level acceptance for 3D ship (including geodesic helm design in separate [PR #471](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/471)), actual Chapter I portraits/subtitles/character animation and bridge-interior continuity.
- [ ] Target-platform performance/reduced motion, durable forward save migration, creator-reviewed family reunion geography, real sea/planet dynamics, Windows Defender custody and explicit release consent.

## Next safe admission

If the exact-head GL tests pass, mark this as **3D CONSUMER PROTOTYPE VERIFIED**, then use a CI-generated JSON receipt from actual #491 producer stages to replace the curated shape fixtures in a single isolated integration harness. Follow with genuine 960×640 frame human review and migration planning; **do not** merge the two parallel drafts into `main` or assume their Godot project roots are already compatible.
