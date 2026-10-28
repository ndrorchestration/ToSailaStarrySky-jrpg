# Daylight and storm-night coastal shelf review — integrated Aureate Wake flight lab

**2026-10-27 · noncanonical Godot 4.7.2 Compatibility study · DRAFT / NOT ART APPROVED**

## Motivation and verified parent
Native screenshots from [draft #466](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/466), exact commit `330e536c3b881d70a52a4a6f6abeb56fbd70f26f`, confirm softer broken foam but still show an overly broad turquoise nearshore water shelf and bright glare. Parent [Godot CI 40599834906](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40599834906) and [smoke 40599834877](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40599834877) PASSED, including 670 terrain/flight, 89 mood, 60 blend, 47 microtexture, 45 touchdown and 30 contact checks, 6 ship/weather hero images, real four-frame foam proof 3,468 pixels changed and exact low-quality delta zero.

Separate [#456](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/456), exact `6268400df43623b6673394abc9f368003798c981`, developed a depth-bounded, deterministic muted-shelf color that had its **own** successful native Godot and smoke execution. Its residual turquoise shelf and lack of final art approval were explicitly noted. Its success is **not** evidence of combined correctness.

## Source-preserving integration
- Copy only #456's depth-limited color composition and `shelf_transition_strength` onto #466's *existing* procedural ocean, not the whole shader or branch. Preserve actual PNG `water_ripple_detail`, `texture_detail_strength`, storm `sun_visibility`, sun specular, signed-depth foam breakup, terrain coverage, authoritative seabed from the shared height sampler, and plane geometry.
- `shelf_transition_strength=0.0` restores exact #466 high-quality shelf color; `1.0` selects muted, narrower shallows; the added calculation is gated to near-shore `shelf_zone` and `cover`. **V** low-quality ignores strength and renders the same former output for either value.
- Existing ground-physics touchdown and contact recovery are not equivalent to actual seawater splashdown. No actual hull waterproofing, world tides, moonlight physics, canonical climate, engine fuel revelation, moon route or new weather gameplay.
- New fixed-camera/HUD-free/ship-hidden native GL `tests/capture_shelf_lighting_integrated.gd` takes six true 960×640 frames: golden clear reference/candidate, storm-night reference/candidate, and both low-quality storm-night frames. Daily/night sampled pixel deltas must each remain between 100 and 65,000; fallback must be pixel-identical with `low_delta=0`. Assert static ship and camera, no queued environment fade, unchanged terrain chunk count.
- Retain all already native-verified original PNG byte checks, 6 original texture A/B frames, 4 foam A/B frames, 6 ship frames, 3 half-fade and 5 mood frames, contact/touchdown and 96-frame high/low software GL movement profiles.

## Evidence gate / approval limitations
The new combined head requires **its own** complete native Godot and smoke workflow. The pictures must be read for shoreline tonality, storm readability and loss of coastal detail before selecting the art treatment. Pixel difference proves rendered response, not an aesthetic improvement, realistic water, GPU performance, a playable planetary route, Chapter I chapter-complete content or creator acceptance.

Related local studies [#467](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/467) for shared coastline distance and [#471](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/471) for the Aureate Wake's geodesic glass helm are **separate drafts**; do not silently import, supersede or merge. The small Aureate Wake is not the larger Dragonfly Frigate.

No auto-merge, release, public spoiler disclosure, actual private Moon Bridge trigger or canon change.
