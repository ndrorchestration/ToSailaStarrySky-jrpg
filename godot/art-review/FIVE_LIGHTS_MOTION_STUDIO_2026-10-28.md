# Five Lights — Native Source-Custody Motion Studio (review only)

**Base:** playable Godot First Wake draft PR #555 exact code head 40e086d04c641ee98cd8bed69f8d2c1021cb0930.
**Status:** implementation candidate; native execution and creator art acceptance are independent gates.

Open godot/project.godot in Godot 4.7.2. Open res://scenes/five_lights_motion_studio.tscn and use F6 (Run Current Scene). Press Tab to select among Ionia, Ender, Aepex, Lyra and Reson; WASD/arrows travel using actual CharacterBody2D.move_and_slide, F selects a distinct authored static facing, R resets, M freezes atmospheric motion. Six frames are stepped from measured distance traveled, not timer-only movement. The five actors remain in a separate review scene and are not spawned during normal Chapter I gameplay.

Existing Ender/Ionia source textures remain untouched from #555. Lyra/Aepex/Reson each use the four independent six-phase source atlases, copied as identical Git blobs from unmerged PR #487 (lineage #421 > #435 > #439 > #446 > #458). The twelve imported sources are still UNAPPROVED. No mirroring, no new classes, no elemental spell unlock, no early Lyra recruitment, no spoilers and no save/party mutations. Atmospheric shader is a provisional review surface, not production art.

**Canon guard:** the uploaded presentation's element labels and several apparent character identities conflict with established Five Lights source lore (Ionia Earth, Ender Spirit, Aepex Air, Lyra Water with separate pink spirit motif, Reson Fire). Treat the graphic as an aspirational art/animation target, not authorization to overwrite canon, existing appearances or source atlases.

**Test:** godot/tests/five_lights_motion_studio_test.gd verifies five source-bound CharacterBody2D actors, all four independent facings, six atlas cells, real collision shapes, real translation, no horizontal sprite flip, and the unchanged normal F5 entry. A passing code test does NOT establish final artistic quality.

**Remaining gates:** exact-head native Godot import, 960×640 authentic frame captures, source frame silhouette/stride/boot-contact review, independent portrait/costume and lighting approval, frame-rate and reduced-motion visual QA, Windows/Defender security, creator acceptance, and separately authorized integration into playable First Wake. This draft is not a release candidate.


## P1 source-pose inspector (verified)
In the separate studio only: **P** toggles static pose inspection, **Q/E** choose the previous/next one of six source frame phases, and **F** changes among four independently authored facings. TAB switches the selected actor; R resets all actors. During pose inspection, the physics body must not translate, and exit restores normal native movement. These controls are not part of canonical First Wake.
The first official exact-head Godot 4.7.2 regression and GL capture at `751d5fd4e65cfca756086c4f75b68b73346d3091` **PASS**: [native run #40649632801](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40649632801). See the [P1 genuine capture evidence and quality gates](FIVE_LIGHTS_VISUAL_POLISH_P01_2026-10-28.md). This verifies keyboard-mode logic but **not** high-fidelity frame art or certified planted-foot animation.
