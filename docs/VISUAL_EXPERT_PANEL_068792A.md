# Expert Panel Review ? Visual Frontier 068792a

Status: **ROLE-SEPARATED DESIGN REVIEW / INPUT TO G1?G4**
Evidence reviewed: seven exact-head visual frames from `visual-evidence/manifest.json`, Visual Bible, benchmark scene, Character Art Direction contract, Character Art Library authority, current runtime modules and measured performance telemetry.

This is a structured multi-perspective review. It does not replace human player acceptance.

## Art Director / Integrator
**Current read:** the painted world/battle assets establish a credible quality ceiling, but the runtime character/Dragonfly/UI systems still belong to a lower-detail visual dialect. The strongest path is not ?more detail everywhere?; it is reducing the number of competing rendering languages.

**Highest-value actions:**
1. Make one canonical character likeness pipeline span field, portrait, combat and cinematic use.
2. Make one canonical Dragonfly design span title/dock/flight/combat.
3. Move UI from surface-specific boxes to one tokenized instrument/cartography system.

**Merge gate:** no specialist lane may introduce a new palette, scale or silhouette authority without an explicit contract change.

## Character Design + Animation
**Current read:** motion architecture exists, but figures still read as procedural mannequins against painted environments. Canon drift is visible: current renderer approximations do not fully encode the strongest Drive/Notion likeness authority.

**Required next artifact:** five-character canonical model pack with turnaround + portrait + gameplay animation manifest.

**Critical corrections:**
- Ender: strengthen copper/auburn buzz cut, forehead goggles, freckles, lean scholar silhouette.
- Lyra: long red-hair silhouette must be unmistakable at field and portrait scale.
- Ionia: curly blond shoulder-length hair and young-capable-captain posture must replace generic brown-haired treatment.
- Reson: backwards red cap, light mustache, broad/tall silhouette.
- Aepex: dirty-blond undercut, eyebrow notch, tattoos, lanky-muscular silhouette.

**Do not merge until:** five silhouettes can be identified without labels; portrait/body/sprite depictions agree.

## Environment / World Presentation
**Current read:** title, combat and new flight backdrops have strong vertical-scale appeal; dock/world layers remain more procedural and expose repetition. Current environments are strongest when the painted assets dominate and weakest when simple crates/rocks/ellipses become the primary texture vocabulary.

**Required next artifact:** Chapter 1 environment kit and depth manifest.

**Priority:** benchmark dock first. It is the correct calibration scene because it includes character, Dragonfly, local props, depth, lighting and world-scale context in one frame.

**Do not propagate until:** dock, dialogue, combat and flight all clear the same cohesion threshold.

## Dragonfly / Vehicle Design
**Current read:** the shared renderer solved authority fragmentation but not final art quality. The craft is recognizable by position/context more than by an iconic authored silhouette. Painted title art currently contains a stronger airship visual language than the runtime craft.

**Required next artifact:** orthographic blueprint + silhouette/state sheet + runtime-authority implementation.

**Priority:** establish body/wing/helm/core proportions before adding more effects. Effects cannot rescue a weak base silhouette.

**Do not merge until:** blind Dragonfly recognition reaches 9/10 and title/dock/flight/combat no longer disagree on body language.

## UI / HUD / UX
**Current read:** functionality is clear, but combat and flight overlays feel like developer/control surfaces placed over finished illustration. The issue is not only opacity; panel geometry, typography, density and reserved areas differ by state.

**Required next artifact:** tokenized UI kit: 8pt grid, type scale, 9-slice frames, safe areas and per-state component layouts.

**Priority:** combat first because it currently carries the most visual obstruction and the strongest readability demands.

**Do not merge until:** HP/status scan is <2 seconds in test and critical enemy tell space remains visible.

## Cinematic / Narrative Presentation
**Current read:** First Wake has authored sequencing and stronger pacing than earlier prototypes, but its visual handoff from painted title into procedural dock still exposes the quality discontinuity immediately.

**Required next artifact:** New Game ? world shot/timing sheet with exact framing rules and handoff states.

**Priority:** solve continuity at the title ? opening ? playable dock transition before adding more cinematic shots.

**Do not merge until:** a first-time viewer can name the protagonist, identify the Dragonfly, and understand the next interaction without explanation.

## Technical Art / Performance
**Current read:** title and flight have healthy p95 timing near 60fps. Benchmark dock and combat sit on the 30fps hard floor. This is acceptable as a baseline, not as final headroom.

**Measured evidence:** title p95 16.7ms; dock 33.4ms; combat 33.3ms with 49.9ms isolated spike; flight 16.8ms.

**Required next artifact:** state-specific render-cost report plus before/after p95 evidence for dock and combat optimizations.

**Priority:** identify redundant procedural passes and UI/background overdraw before reducing visual quality.

**Do not merge G4:** if any representative scene exceeds 33.4ms p95 or 50ms isolated-frame hard limit on the operator benchmark machine.

## Player Acceptance / QA
**Current read:** the package has strong ?world promise? but insufficient evidence that unaffiliated players perceive one coherent game. Internal screenshots alone cannot validate identity or polish.

**Required next artifact:** five-player 20-minute acceptance set + blind same-game screenshot test + silhouette/Dragonfly recall test.

**Questions:**
- Which screenshots look like they belong to another game?
- What is the ship called after 20 minutes?
- What visual element looked most unfinished?
- What did you look at first in combat?
- Where did UI obscure something you wanted to see?

**Do not close G4 until:** weighted score ?4.0, same-game test ?80%, Dragonfly recall ?80%, and no category misses its floor.

## Consensus priority order
1. **Lock style/scale/UI contracts (G1).**
2. **Character identity package.**
3. **Dragonfly identity package.**
4. **Benchmark dock/world-depth kit.**
5. **Combat-first UI system, then dialogue/flight/title propagation.**
6. **Opening continuity and scene transitions.**
7. **Performance recovery for dock/combat.**
8. **Blind human acceptance and final exact-head packaging.**

## Integrator disposition
`REVISE / CONTINUE` ? the direction is coherent enough to invest in, but current evidence does not support final visual acceptance. The next authoritative production work should be character + Dragonfly identity, not additional unrelated environments or systems.
