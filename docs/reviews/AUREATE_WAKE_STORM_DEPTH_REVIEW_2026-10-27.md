# Optional storm-night silhouette relief — native visual QA study

**2026-10-27 · DRAFT, NOT CANON, NOT APPROVED ART**

## Why this exists
Actual 960×640 Godot A/B footage from [native-verified draft #475](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/475) shows muted and depthless forest, distant hillside and cliff silhouettes in dark storm scenes. The earlier material fixes correctly narrowed the broad cyan shoreline shelf but intentionally did not address terrain value range. Existing pure `environment_mood.gd` yields at night+storm: very low directional key (0.35 × 0.57 = 0.1995), substantial ambient (0.75 × 0.89 = 0.6675), and dense fog (0.0042 + 0.007 = 0.0112). This is a *diagnostic hypothesis*, not proof of cause or final grading.

## Isolated candidate
- **Do not change** existing deterministic `environment_mood.gd`, the Five Lights, plot-affinity energies, physically meaningful moon phases, sky routes or canonical weather. The default `storm_depth_study_strength=0` retains the exact #475 rendering.
- A review-only setter in `visuals.gd` adjusts *render-time scalar intensities*, not the canonical/pure `current_mood` preset. At full NIGHT+STORM (`strength=1`), multiply existing directional key by 1.32, ambient energy by 0.86, and fog density by 0.74. Blend factor is 0 through golden daytime and eases continuously toward full storm-night, using existing `time_palette` and `weather_strength`, so interrupted crossfades avoid a binary midnight switch.
- No additional lights, shadows, draw calls, precipitation instances, collision volumes or player abilities. Original ship, terrain, ocean textures, foam, shelf grading, physics-backed **ground** touchdown, actual Chapter I splashdown branch (separate) and accessibility motion settings unchanged.

## Acceptance
- Real native Godot 4.7.2 `tests/test_storm_depth_review.gd` checks baseline-off exact light/fog/ambient, precise bounded full candidate factors, invalid-value fail-closed behavior, uninterrupted half-grade and fully restored golden grade, no ship/clock changes.
- New authentic 960×640 fixed-camera/clock, HUD-free `tests/capture_storm_depth_review.gd` creates *six* images: golden-off/golden-on, storm-off/storm-half/storm-on, and low-detail storm-on. Daylight must be pixel-neutral; both adjacent storm transitions must change sampled pixels. The automated pass is **NOT** visual artist signoff.
- Preserve exact source texture asset generation; full native texture tests, six actual ship hero frames, four foam frames, six shelf day/night/V frames, three atmospheric fade frames, five mood frames, all physics touchdown/contact, 96-frame high/low software GL profiles and repository smoke.
- Native CI must complete on the new exact head. No inherited parent CI verification. Inspect pictures for meaningful land silhouette depth *without* overbrightening, fog banding, washing out magical ribbons, stealing focus from Aureate Wake or misleading sky references.
- Actual globe terrain, Forward+ target Windows GPU, Chapter I 2.5D narrative integration, ship geodesic helm, full hull waterproofing, orbit/aurora secrets and user art approval remain open.

No automatic merge, production release, new canon, hidden moon clue leak or ship-system reveal.
