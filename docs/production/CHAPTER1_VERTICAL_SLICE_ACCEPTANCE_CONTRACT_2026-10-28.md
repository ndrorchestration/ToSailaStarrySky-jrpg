# To Sail the Starry Sky — Chapter I vertical-slice contract
**Date:** 2026-10-28 · **Status:** proposed production acceptance contract, not new canon or art approval
**Basis:** creator-supplied 100-point JRPG development and quality checklist (§§1–20 and 81–90 in particular).
**Owner approval needed:** release/content scope, numerical balance exceptions, final visual approval.

## Player promise
**Join Captain Ionia aboard the Aureate Wake, help diagnose a harmonic levitation engine, survive its first flight in a year, and discover that the ship and its fuel hold mysteries worth exploring.** The player should experience wonder through navigable environments, character decisions and credible cinematic presentation—not only concept images.

## Content cap for the first production-quality acceptance slice
- **One connected playable Chapter I route:** Ender's job-search flyer → Ionia hiring → three engineering checks → short physical first flight → controlled ocean splashdown → reserve diagnosis → safe local berth. The local berth remains explicitly non-geographic until an authorized map/story route exists.
- **Characters:** Ender and Ionia are the only recruited playable/story-party participants before the postflight family meeting. Lyra and her son Talen can appear only in the separately authorized later family sequence; no automatic recruitment or child combat participant. The other Five Lights remain established canon but need not be introduced during this slice.
- **Gameplay:** a real discover/inspect/repair/flight/diagnose/recover loop, with an understandable decision and consequence. Combat is **not** certified by the current native formula metadata; include a small independently gated encounter only when fully authorized, playable, and balanced. Do not turn harmonic ship engineering into automatic combat magic.
- **Visuals:** one consistent Godot 3D ship environment (geodesic bridge, open foredeck, cabin/engineering, sky/ocean), faithful actor representations from creator-approved references, restrained cinematic transitions, consistent material/lighting and accessible 2D UI. No visual proxy may authorize physical contact, damage, unlocks, saves or story events.
- **Production infrastructure:** normal project launch, readable dialogue/UI, remappable movement/interaction policy where supported, motion-safe alternatives, save/cold reload at approved checkpoints, failure/retry paths and reproducible QA evidence.

## Riskiest assumptions
1. The strongest authored 2D story/physics code and optional 3D ship review can become **one continuous, correctly authorized experience** without breaking input, scene state or saves.
2. Cinematic visual fidelity can be achieved at sustainable asset-production cost and target PC performance.
3. RPG combat and later Resonance provide interesting, legible decisions without conflicting with Ionia-first chronology or unapproved skill unlocks.

## Definition of done — evidence required
- **Comprehension:** unfamiliar players can explain who Ender is, why Ionia needs help, the immediate engine objective and the consequence of splashdown without developer coaching.
- **Actual play:** record an uncut normal-launch run through the agreed slice, with genuine 3D world navigation, interaction feedback, physics proof and one meaningful decision; never substitute developer teleports for the acceptance run.
- **System correctness:** inspect numerical/stat/EXP/equipment/ability source of truth; fail closed for unsupported actions. Test resolved combat events driving animations, audio, VFX and UI—not the reverse. A separate encounter gate is required before combat qualifies as production-ready.
- **Visual review:** capture native source-engine shots in 3D at player-controlled viewpoints and cinematics; inspect silhouettes, faithful five-character identity where shown, texture/material detail, glass, water horizon, lighting, legibility and reduced-motion parity. Compare against creator references; renderer success alone is not artistic acceptance.
- **Persistence and recovery:** validate legitimate party order, stage boundaries, old-save versioning, crash-safe writing, cold reload, retry and softlock prevention. A true save round trip must preserve the right gameplay state, not an invented stage.
- **Measurement:** maintain timestamps for one finished/revised scene, character, encounter and cinematic; track player confusion, encounter duration, unused actions, defects and target-hardware FPS/frame time. None of these measurements is yet claimed.
- **Acceptance authority:** document distinct narrative, systems/balance, art, accessibility, technical and release approvals. Merge/release and installer security custody remain owner-controlled.

## Scope-cut / redesign rule
If this slice cannot pass the above evidence gates within the available capacity, **defer** global planet travel, Moon Bridge traversal, ship's secret configurations, extra biomes, full five-person combat, optional crafting/economy/romance and elaborate parallel cinematics. Preserve their canon/design documentation but do not let them block a complete Chapter I experience.

## Existing evidence and blockers
- **Verified structural checks:** draft PR #582 cohesion workflow, native First Wake and render tests, and repository smoke passed on head `fd53065133ae33abca2ee16c9d75ab7fece4d743`.
- **Unresolved:** outdated Crossing Ender+Lyra chronology versus revised Ender→Ionia→Lyra progression; level-one 25-budget exceptions (Ender 31, Ionia 26); verified full 3D scene consolidation; source-custodied character art and target GPU cinematic acceptance; playable combat/Resonance balance and unlock rules.
- **Release:** no approved single Windows installer; Defender real-time-on validation is still an independent fail-closed gate.

**Promotion rule:** Pass structural, player-experience, visual, balance, save and release gates independently; do not claim a complete cinematic 3D JRPG based solely on prototype functionality.
