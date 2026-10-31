# Weather and surface material review v1

IMPLEMENTED SOURCE / NONCANONICAL STUDIES / NATIVE UNREAL NOT RUN.

Baseline: PR #634, `d4aa2ba2a75b73e3603c34a692fb11e56b033a83`, branch
`integration/unreal-first-wake-ship-art-reconcile-20261031`.
This additive candidate is on `feat/unreal-weather-material-review-v1`.
The creator's October 31 Unreal visual-development request supersedes the
historical Godot-only development target in AGENTS.md. Godot files remain unchanged.

## Deliverable

`Tools/build_weather_material_review.py` authors seven original procedural HLSL
materials, seven editable material instances, and a separate material comparison
map. No external texture/art license or paid dependency is needed.

| Study | Source behavior | Controls |
|---|---|---|
| Sand | Warm ripples, fine color variation, analytic tangent normals | Tiling |
| Snow surface | Cool drift shading, granular variation, soft normals | Tiling |
| Wet stone | Patchy darkening, lower roughness and flatter normals in wet areas | Intensity, Tiling |
| Rain | Animated streak card with edge fade and derivative antialiasing | Intensity, Speed, Tiling |
| Snowfall | Drifting flake card with edge fade and derivative antialiasing | Intensity, Speed, Tiling |
| Blowing sand | Two moving dust frequencies, restrained opacity | Intensity, Speed, Tiling |
| Spell ring | Two slowly animated concentric rings and segmented arcs | Intensity, Speed |

Three bays pair blowing sand with sand, snowfall with snow and rain with wet
stone. Each has a flat surface and curved object; one overview camera, sky,
sunlight and haze provide a reproducible review composition. These basic meshes
are material test objects, not finished environment art. Weather uses flat
shader cards, not Niagara particles, volumetrics or a weather simulation.

Speed clamps to 0–4 (0 freezes motion); Intensity clamps to 0–1 (0 hides cards);
Tiling clamps to 0.25–32. Material instances expose these controls without
requiring graph edits. Set Intensity to zero on all cards to disable effects.
Wet stone has its own independent wetness control; no global weather controller
or automatic accumulation is claimed. No camera shake or lightning is included.

## Build in an isolated Unreal 5.8 editor checkout

1. Enable Python Editor Script Plugin. Save all currently dirty maps and assets.
2. In the editor Output Log's Python mode run (substitute the checkout path):

```python
import runpy
review = runpy.run_path(r'C:/TSTSS/unreal/Tools/build_weather_material_review.py', run_name='tstss_weather_review')
review['build']()
```

3. Inspect `/Game/TSTSS/Review/WeatherMaterials_V1/WeatherReview` and the `MI_*`
   instances. Enable viewport Realtime for animation; pilot `TSTSS_REVIEW_Overview`.
4. Capture 1920×1080 overview plus surface closeups and 10-second animated clips
   at Speed 0 and 1, Intensity 0, 0.65 and 1. Record exact commit, engine version,
   hardware, exposure and resolution. Inspect UV seams, movement direction,
   shimmer, transparency sorting, repetition and frame time.

The generator refuses an existing destination directory, dirty maps/content,
missing meshes, failed material connections, shader compiler errors or missing
compiler results, and unsuccessful asset/map saves. UE5.8's recompile result is
checked; older editor versions that return None are intentionally unsupported.
A failed run may leave partially created assets for diagnosis. It never deletes
or overwrites them. Review/remove only the new folder manually before rerunning;
do not rerun repeatedly or erase other review work. It changes the current editor
world only after material generation succeeds, never project startup settings.

## Verification and admission

Offline command:

```sh
python -m unittest discover -s unreal/Tests -p 'test_weather_material_review.py' -v
python unreal/Tools/build_weather_material_review.py --validate
```

11 offline tests passed locally: destination protection, unsaved map/content
protection, missing mesh, valid preflight, failed graph connection, absent Editor,
manifest scope and compiler-result handling. These test Python control flow with
Editor-boundary substitutes; they DO NOT compile HLSL or execute Unreal APIs.
Native UE5.8 shader compilation, Editor map generation, animated rendering and
GPU performance remain NOT RUN. Hosted CI status must be checked separately.
No claim of cinematic quality or creator visual acceptance.

Next: native compile/render evidence, tune materials from actual captures, add
scene-depth intersections/roof occlusion and Niagara depth/parallax for accepted
weather, then integrate one reviewed effect in the First Wake scene. Current
cards lack physical precipitation, accumulation, world-space mapping, splashes,
wind volumes and indoor occlusion. Do not put them into a shipped scene yet.

The spell ring is an unassigned visual study, not a learned ability or Five
Lights combat grant. No changes to ship gates, party, save schema, story state,
main, releases or approved character appearances.

API reference: [Epic MaterialEditingLibrary](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/MaterialEditingLibrary).
