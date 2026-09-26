# Visual Baseline ? 068792a

Status: **G0 AUDIT RECORD / PROVISIONAL HUMAN SCORECARD**
Source: `068792a49c38b0d3ba236de5fafa84c9e295c45a`
Evidence: `visual-evidence/manifest.json`, captured 2026-09-26 at 1440?960 over the 960?640 logical canvas.

The scores below are an internal expert-panel baseline used to prioritize work. They are **not player-acceptance evidence** and do not satisfy a visual gate by themselves.

## Current inventory
- 7 canonical evidence frames: title, First Wake dock walk, Dragonfly dusk dock, Ionia dialogue, Sky-Predator combat, Dragonfly flight, crosswind sky combat.
- 8 preview visual assets in `assets/preview` totaling ~1.99 MB.
- Full `assets/` tree: 26,994,314 bytes.
- Staged `.desktop-runtime`: 29,846,982 bytes.
- Runtime module files: 44.
- Shared visual authorities currently include character, Dragonfly, First Wake, projected world, combat, flight and title modules.
- Character reference authority also exists in Google Drive and Notion; runtime rendering is not yet fully faithful to that canon set.

## Evidence hashes
| Frame | SHA-256 |
|---|---|
| 00 title | `69ea029b43acbc74c1d02cb0484d3d0d8f748863c5f3f2ce343370d8470cd36e` |
| 01 dock walk | `536a7ce4d0cd0e0f081c218be9f587154689f6f1464646c1dd53c1c40b4547c0` |
| 02 dusk dock | `b75f6e0f20ba91a67076d8ff96e588946a5ee3a7419a19137352b5bd2f96d380` |
| 03 Ionia dialogue | `3065ca64b6e88965942deecee1460f275350375058113380cc45abc3b8becb8a` |
| 04 combat | `766143d7db5905a4b1f78528bd61eef1f0e15a90d1894845b8581fa693b06ec7` |
| 05 flight | `e0b73e0cf2007d2c6c7257ebe0b7abead71ee61d95272fb7ec2e879f14380d05` |
| 06 sky combat | `b0dec588fb7399ec54736f1edfbad1e37c3595c9abfb56e6c5c69c133ed6b66c` |

## Provisional screen scorecard (1?5)
| Screen | Cohesion | Readability | Appeal | Identity | World depth | Character | Ship | Credibility |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 4.2 | 3.6 | 4.6 | 4.2 | 4.8 | 3.0* | 3.5 | 4.1 |
| First Wake dock | 3.2 | 3.9 | 3.0 | 3.4 | 3.5 | 2.7 | 2.9 | 3.0 |
| Dusk dock | 3.1 | 3.8 | 3.0 | 3.4 | 3.6 | 2.7 | 2.9 | 3.0 |
| Dialogue | 3.2 | 3.9 | 3.1 | 3.4 | 3.5 | 2.8 | 2.8* | 3.1 |
| Combat | 3.6 | 3.8 | 4.0 | 3.7 | 4.5 | 2.8 | 3.0* | 3.7 |
| Flight | 3.8 | 3.5 | 4.2 | 3.9 | 4.6 | 2.5* | 3.0 | 3.8 |
| Sky combat | 3.5 | 3.6 | 3.9 | 3.7 | 4.5 | 2.8 | 3.0* | 3.6 |

`*` indicates a category only weakly represented in that frame; it should not be used alone for final category acceptance.

## Top 20 visual problems by player impact / correction cost
| Rank | Problem | Impact | Cost | Owner |
|---:|---|---|---|---|
| 1 | Runtime character bodies still read as articulated/mannequin placeholders | Very high | Medium | Character |
| 2 | Runtime character likeness drifts from current Drive/Notion canon | Very high | Medium | Character |
| 3 | Dragonfly procedural silhouette does not match painted-world fidelity | Very high | High | Vehicle |
| 4 | Dock/opening environments remain much flatter than painted title/combat assets | High | High | Environment |
| 5 | UI visual language competes with finished backgrounds | High | Medium | UI |
| 6 | Combat panels consume too much horizontal field and weaken enemy staging | High | Medium | UI/Combat |
| 7 | Flight UI + ship still feel layered over a backdrop rather than integrated | High | Medium | Flight/UI |
| 8 | Title text panel contrast/hierarchy is inconsistent over bright art | High | Low | UI/Title |
| 9 | Dialogue portrait/body styles are not yet a coherent single likeness system | High | Medium | Character/UI |
| 10 | Scale relationships vary significantly between opening/world/combat | High | Low | Integrator |
| 11 | Painted background assets and procedural props use different detail densities | Medium-high | High | Environment |
| 12 | Repeated simple crate/rock/grass primitives signal prototype status | Medium-high | Medium | Environment |
| 13 | Dusk benchmark lighting does not yet create strong warm/cool focal hierarchy | Medium-high | Medium | Lighting |
| 14 | Character contact shadows/occlusion are inconsistent | Medium | Low | Technical Art |
| 15 | Flight depth/motion is improved but lacks authored near/mid/far traffic variety | Medium | Medium | Environment/Flight |
| 16 | Enemy visual language is stronger than player visual language in combat | Medium | Medium | Character/Combat |
| 17 | Typography family varies by surface and can feel tool-like | Medium | Low | UI |
| 18 | Transient notifications still need systematic reserved-area rules | Medium | Low | UI |
| 19 | No exact performance frame-time baseline exists for the seven evidence states | High risk | Medium | Technical Art |
| 20 | No blind same-game / silhouette / Dragonfly recall study exists yet | High risk | Medium | QA |

## Performance baseline
Measured now:
- staged desktop runtime: **29.85 MB**;
- assets tree: **26.99 MB**;
- evidence viewport/canvas: **1440?960 / 960?640**.

Not yet measured and therefore explicitly **OPEN** at G0:
- per-scene p50/p95 frame time;
- process/GPU memory attributable to the runtime;
- scene transition/load latency;
- active particle peaks.

Canvas2D/p5 does not expose a stable engine-level ?draw call? count comparable to a WebGL renderer, so the strike program uses frame-time and memory/load budgets as the authoritative performance gates rather than inventing a misleading draw-call metric.

## G0 disposition
`G0_BASELINE_AUDITED = PROVISIONAL_PASS_WITH_OPEN_PERFORMANCE_MEASUREMENT`

The inventory, screenshot baseline, issue ranking and size baseline exist. G1 may proceed. G0 becomes fully closed when the performance capture harness records representative frame/load data for title, world, combat and flight.
