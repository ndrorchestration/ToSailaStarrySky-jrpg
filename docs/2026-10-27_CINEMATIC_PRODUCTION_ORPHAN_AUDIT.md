# To Sail the Starry Sky — October 27, 2026 cinematic production and orphan-work audit

**Status:** public-safe review/documentation candidate, not release/canon approval. **Baseline:** public `main` at `79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09`. Verified 2026-10-27 against GitHub branch/PR metadata and project Notion records; all head-specific checks must be re-read when branches advance. Do not merge this report as game mechanics or count it as a playable build.

## Authority
- **Current game title:** *To Sail the Starry Sky*; Aetherwake is a historical/in-world identifier; *First Wake* = Chapter I.
- **Forward implementation:** Godot 4.7.2 **GDScript** for gameplay. C# #375 is an isolated native geometry/LOD investigation. Existing JS/p5/NW.js main gameplay/documents are preserved as historical/migration references, not the platform for new features. Respect `AGENTS.md`.
- **Separate ships:** **Aureate Wake** = protagonists' compact dragonfly-inspired home ship. **The Dragonfly** = a separate larger Frigate-class vessel; older documents using the names interchangeably are **superseded**. Detailed hull, rigs, interiors, struts and equipment are not automatically canon.
- **Five story energies:** **Ender—Spirit; Lyra—Water** (distinct pink Spirit motif retained); **Ionia—Earth; Reson—Fire; Aepex—Air.** The innate plot-energy property survives any optional job, magic training, skill tree, or weapon choice. It is **not** an automatic combat/spell grant and is not identical to the Five Lights or legacy learned-domain mastery.
- Preserve existing authorial Ender visual identity, Resonance Staff, Aepex's lantern as *equipment*, and prior magic-domain contracts until explicitly reconciled. Protect private Moon Bridge source/reveal. No canon, runtime, public-spoiler or release gate is changed by this report.

## Priority: one excellent playable hero route before atlas expansion

[P0 #387](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/387) owns the integration: First Wake embark → actual Aureate Wake ascent/flight → coast + ocean → forest + highland → physics-confirmed safe touchdown → convincing ground encounter → return to flight, with coordinate/save continuity. Global bathymetry is an accepted **planning requirement**, not an implemented underwater world. Separate visual art, physics, native graphical, target hardware performance, accessibility, save, Windows install and uncoached player-acceptance evidence.

Current study evidence:
- [#402](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/402): stacked sky/camera + terrain; exact-head Godot 4.7.2 [run 40557758401](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40557758401) succeeded with actual software GL shots, not art acceptance.
- [#404](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/404): mixed canopy; native/CI verified there. [#405](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/405), [#406](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/406), and [#407](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/407) are **sibling** foliage/understory studies; do not assume all coexist or have passed combined performance tests.
- [#408](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/408): four-wing Aureate Wake visual study at `f047569a20a9c73192803a62d7cdc5df93f12d9f`; exact-head Godot [run 40569578703](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40569578703) and smoke run 40569578358 succeeded; native ship close-up capture step succeeded. Still a noncanonical candidate, not final art.
- [#409](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/409): five-character lineup with Ender/Ionia candidate strips and other **three blockouts**; early exact-head native pilot/render/smoke green. No actor-asset promotion.
- [#410](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/410): original provisional Wind Shear visual; initial smoke/render green, pilot/Windows pending at inspection. No final enemy approval.
- [#411](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/411): five-energy sigils + reusable magic VFX gallery. First observed exact-head CI was still running. No claim that animation/performance/render acceptance passed.
- [#380](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/380)–[#383](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/383): bounded native manual flight and real physics ray-admission evidence, **not** globe-scale full-hull collision or complete Chapter I. [#367](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/367) provides a separate globe/chart study. Private Celestial Arc source is not public integration authority.

## Work found outside the reviewed PR chain

| Branch / artifact | Readback | Decision / next reversible step |
| --- | --- | --- |
| `feat/native-battle-equipment-visual-slice-20261027` | `537ddcbba8e2a380aff198433059551af59c37ed`; contains `godot/scripts/battle_equipment_loadout.gd`, `battle_equipment_visual.gd`, dedicated tests and `godot/BATTLE_EQUIPMENT_REVIEW.md`; no PR matched during audit | Inspect exact-head native battle preview and equip→sprite/mesh source-of-truth binding, plus old save compatibility. Create isolated draft review PR if valid |
| `feat/godot-weapon-trees-visual-preview-20261027` | `ca5e5ed5e5b72a256f793aee757a2b5172791a97`; contains `weapon_skill_catalog.gd` and `weapon_silhouette_review.gd`; no PR matched | Review weapon/job preconditions and concrete visual/move catalog independently of learned magic; test before staging PR |
| `feat/godot-party-resonance-planner-20261027` | HEAD = `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670` (the same SHA as #347 base), no new resonance files or matching PR | **No unique work at this checkpoint.** Design combination-state/eligibility/interrupt/reaction rules; do not call this implemented |
| `review/godot-five-protagonist-lineup-20261027`; `art/godot-wind-shear-visual-study-20261027`; `feat/godot-magic-vfx-showcase-20261027` | PRs #409–#411, **not** the coast-to-highland PR parent chain | Review as separate native Chapter I art surfaces, then integrate only via an explicit UI/VFX/scene ABI |
| `feat/visual-v*`, `art/current-main*`, `pilot/godot-*`, `review/godot-ender*`, `release/godot-first-wake*` | Large historic branch family, partially superseded / potentially reusable | Inventory exact SHAs, compare adopted art provenance, tests and player evidence; salvage only smallest licensed/approved component. **Do not bulk merge** |
| Private `ToSailtheStarrySky-Dev` | Private default `main` contains README only. Private [PR #3](https://github.com/ndrorchestration/ToSailtheStarrySky-Dev/pull/3) reports local verified fail-closed Git-bundle handoff; remote full source import still absent | Owner-authorized private import only; no copying or mentioning secret mechanics in public artifacts |

## Stale documentation corrections for review

1. `docs/DEVELOPMENT.md`: historical heading “Aetherwake Development Guide” and browser runtime-first description are stale **as forward engine instructions**. Preserve historical JS and packaging receipts but read the current Godot gate first.
2. `docs/WORLD_SHIP_VISUAL_DIRECTION.md`: older combined “Dragonfly / Aureate Wake” identity directly conflicts with creator's separate vessels; detailed 3 masts/6 struts/volume/interior details are *concept hypotheses*, not automatically final Aureate Wake facts.
3. `docs/MAGIC_SYSTEM.md`: earlier Ender **Aether/Resonance/Correspondence/Lumen** domain-affinity matrix has a different semantic level from the now-approved Spirit/Water/Earth/Fire/Air **plot energy** matrix. Other four old *learned magic-domain* affinities remain open where appropriate; none of the five receives default spell permission.
4. `docs/NOTION_SOURCE_INDEX.md`: the historical Dragonfly/home pointer needs a current ship-split warning and reference to the latest Notion authority.
5. Notion visual/magic/character historical pages sometimes preserve “Aetherwake is current title”; those are **2026-10-09 historical** records superseded by the October 23 title decision, not grounds for mass deletion.

## Cinematic asset production gates (recommended order)

1. Establish repeatable **same-camera/time** native Godot hero images (coast, ship, forest, highland, landing, battle) in Compatibility and high-fidelity Forward+; keep original SVG/PNG/mesh source and copyright/provenance.
2. Reconcile the three independent foliage proposals into one bounded instancing/material/LOD candidate, profiled on real target hardware rather than accepting a green CI as GPU evidence.
3. Author cohesive surface material response (sky, water, terrain, foliage, structures) with reduced-motion/quality alternatives and object-scale legibility.
4. Reconcile the correct Aureate Wake ship silhouette, windows/interior scale, rig, deployment and flight camera **without** using the distinct Dragonfly frigate as a replacement.
5. Integrate approved actor art, enemy readbacks, equipped-weapon visuals, magic VFX and combination-resonance HUD via reusable visual event contracts, not fabricated mechanics.
6. Verify actual native playthrough, secure map & save, full scene navigation, accessibility, Windows installed runtime and creator/player visual acceptance before declaring cinematic/Chapter I completion.

## Evidence and authority routing

- [Notion consolidated log — October 27](https://app.notion.com/p/406f5bad238b81649ecaea05f451c2d6)
- [Notion orphan/stale audit — October 27](https://app.notion.com/p/406f5bad238b81f4b4b2caa1b7416a82)
- [P0 playable world issue #387](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/387)
- Existing [canon and reveal policy](CANON_AND_REVEAL_POLICY.md), [current agent handoff](AGENT_HANDOFF_INDEX.md), [visual authority](VISUAL_BIBLE.md)

Labels: **CREATOR CANON / ESTABLISHED SPEC / IMPLEMENTED AT EXACT SHA / STUDY / PROPOSAL / OPEN / RESTRICTED / SUPERSEDED**. Real gameplay acceptance must never be inferred from proposal existence or a single rendered frame.
