# First Wake — First Waterborne Diagnosis Review

**Status:** DRAFT / NATIVE TEST PENDING; no creator script/art, gameplay, or Windows release acceptance.

## Input authorities
- Creator's revised opening: [story PR #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425)
- Implemented playable flyer → Ionia hiring → engineering preflight: [draft PR #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430)
- Executed native local sea-contact / sustained flotation proof: [draft PR #447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447), exact native PASS on `665a2b6439023afc0f77234b94a1eb05b4b170ba` / [run 40596210927](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40596210927)

## Bounded follow-on gameplay
After the real bounded 2D `RigidBody2D`/water-sensor flotation test reaches `WATERBORNE`, E starts an Ender/Ionia **three-line observational diagnosis**. The player must advance each line before the existing revised `Opening.inspect_postflight_reserve(true)` contract may mark the specialized usable reserve depleted and transition to `POSTFLIGHT_DIAGNOSIS`.

This step purposely keeps the scene synthetic and does not assert that the on-screen ocean/ship has actual production physics, that the fuel composition or source is known, or that a recovery route has been mapped.

## QA acceptance checklist
- [ ] Exact native Godot 4.7.2 pilot passes expanded real-scene regression on this branch, including script import, preflight, buoyancy, all three dialogue lines, postflight stage and negative gates.
- [ ] A 960×640 actual native frame shows legible dialogue and no footer overlap or text clipping.
- [ ] The dialogue cannot be started before `WATERBORNE`; the diagnosis stage does not advance until all lines were acknowledged.
- [ ] The sequence remains Ender + Ionia; Lyra only joins later at a separate safe reunion.
- [ ] Save/restore remains unchanged; this opt-in review is neither the production chapter save schema nor a final quest transition.
- [ ] Engine failure observations remain distinct from hypotheses; fuel name, formula, origin and Denith's unfinished knowledge remain open.
- [ ] The safe location and method of meeting Lyra/Talen still require creator-reviewed geography and interaction design.

No merges, production release, gameplay ability grants, story-canon promotion, or workaround for Windows Defender gate #293 are authorized.
