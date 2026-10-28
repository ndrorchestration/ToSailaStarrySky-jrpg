# Aureate Wake — Shared Geometry Feasibility Audit, Stage B1 (2026-10-28)

**Status: NONCANON PHYSICAL SCALE STUDY / SOURCE-EXACT GODOT ART / PRODUCTION ADMISSION BLOCKED**

## Cross-branch provenance

Built as an isolated public-safe stacked draft on [native Chapter I 3D wing proof #523](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/523), head `0bc89c83c0fc82c7286fa806cbf2f84d795fbd73`. The real Chapter I engineering scene still starts with Ender taking Ionia's flyer/job, the gangway and engineering station, and shows **no** 3D geometry without explicit test opt-in.

Four independent existing artist studies are brought together **byte-identically**, except for their relocated Godot project path:

| Source | Reference PR/head | Original blob |
|---|---|---|
| Four articulated wings + external hull | [#490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490), `7abee4f14971868f52626d032d238c7140e0c457` | `b21327071e2120fd75113d6051af17dd2c45dbfd` |
| Normally accessible open-air foredeck | [#452](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/452), `eaae30938ce313aa8d92a53e5f43213e29fc0b2b` | `638b2e1d2761cd27870ec38a470f6e3f47c027cc` |
| Geodesic glass helm study | [#482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482), `8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9` | `88bb7540df89ab552f5ef415ab5c0b1da8945086` |
| Associated original glass shader | #482 same head | `b6c7e8d4144acc14074581b08b61c61b7f5a047a` |
| Lived-in cabin cutaway layout | [#431](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/431), `4071f4941af96c010c74656399271b42f358f2f0` | `036ada9a33ddb6ce8a56886156c4f22992d319fd` |

**Critical constraint:** These branches were authored in independent local art units, not a signed-off shared 1m Godot grid. The source-provenance table does **not** declare them mutually compatible.

## Physical contradictions found before authoring more assets

Using the independent boarding PR #461 **hypothetical** scale, 1 art unit = 2.5 metres:

| Provisional comparison | Derived result | Admission |
|---|---:|---|
| Dome diameter `2 × 0.76 × 2.5` | **3.80 m** | vs separate entry/cabin threshold width 2.35 m: **1.45 m overhang** |
| Maximum *summit* standing height above deck `(0.40 + 0.76 − 0.43) × 2.5` | **1.825 m** | 2.05 m review goal: **0.225 m shortfall**; local slopes even lower |
| Foredeck/bridge plan connection `abs((-0.50 − 0.76) − (-1.23)) × 2.5` | **0.075 m gap** | proximity does not make a door opening or safe passage |
| Original outer hull's maximum loft beam `(±0.68) × 2.5` | **3.40 m** | vs separate live-in cabin cutaway beam **3.80 m**: **0.40 m interior wider than exterior** |
| Original exterior loft bounding length `(2.28 − (-2.38)) × 2.5` | **11.65 m** | compared with 10.40 m cutaway: *not* proof of fit in tapered hull |

These figures expose a mismatch **in the provisional mapping**, not a definitive canonical length, vessel category, real pressure limit or engineering certificate. Do not force the cutaway inside the existing mesh by shrinking human safety volumes. No pressure, marine or submersible capabilities are modeled here.

## Test-only composite and clearance methodology

- Existing [#523](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/523) authentic source four-wing rig is the parent coordinate frame. On **explicit QA opt-in only**, attach copied foredeck at its authored original ship origin and copied dome at source study ship-Z = −0.50 art units. Both remain in **art units**; they are **never** falsely rescaled to fit.
- The conservative `ship_cross_study_clearance_contract.gd` samples five actual Godot wing pose frames (0, 25, 50, 75, 100% of the existing 15-degree ordinary review motion). Every original membrane and rib batch is compared to the deck, railing, weather hood, dome panes, frame and collar by transformed **axis-aligned mesh bounding boxes**.
- It reports bounding-box overlap-pair counts and minimum gaps in **art units**. AABB overlap is **not** proof of triangle collision; an absence of overlap would still not certify continuous swept volume, crew body or weather safety. All results are **fail-closed** with `BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME`.
- All four visual hinge yaw states are restored after the diagnostic, even when inspected during a half-completed pose transition. No rendering cue can mutate ship position, Chapter I actor, story order, save data or Resonance.
- A real Chapter I native test checks those invariants and the original numeric mismatch; true fixed-camera 960×640 Godot images show no-preview, plain wing rig, assembled **provisional** deck/dome, and gentle swept-wing composite. These do not establish walkable interiors.

## Production authority and next decisions

1. Agree a single creator-approved outer ship hull frame **in metres** with documented external max beam/length/height and usable deck height. Treat original local proportions as editable *art*, not binding hull dimensions.
2. Redesign **together**, not independently, the habitable cabin/engineering/circulation envelope, transparent geodesic navigation dome, correctly open normal bow foredeck, hatch, guardrails, original three masts, four wing roots and normal six landing struts. Preserve the Aureate Wake's small, lived-in home identity.
3. Define representative adult/smaller body occupancy volumes, safe exits and moving-wing no-occupancy zones; test continuous swept triangles/convex proxies and physics (not just AABBs). Give fail-closed access restrictions when unsafe.
4. Re-run actual Godot Chapter I 3D scene, fixed and moving cameras, genuine gameplay/scene tests, reduced-motion and interruption, input/save parity, target Windows GPU security/performance and creator/player visual QA.
5. No merge, release, new engine ability, new ship mode, unlock, alternate route, secret lore or physical-safety certification from this provisional cross-study.

**Hard stop:** physical integration = **BLOCKED**. The correct output of a working gate is to report the mismatched sources and refuse admission.
