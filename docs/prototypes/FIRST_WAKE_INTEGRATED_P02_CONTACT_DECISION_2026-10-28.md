# First Wake — Integrated P-02 Recovery Decisions (Review-Only)

**Status:** draft, unmerged, no canon or production-authority changes. **Source:** stacks directly on the native real-player P-01 draft [#526](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/526) at `90b74ad25eade6c2207e8bb14f25540325f4ba7f`; original ship and physical contact source inherited from #525.

## Target and authoritative boundary

The creator-directed First Wake order Ender → Ionia → physical first-flight splashdown → Lyra after safe meeting is preserved. [Revised opening](https://app.notion.com/p/406f5bad238b81bcbacbeeb372e8fd77) explicitly leaves the exact recovery **geography**, route and communication option open. This PR **does not pick a port**, teleport family, say a message was delivered, or resolve the fuel formula.

The actual current player route in the P-01 scene already moves from flyer to hiring, engineering, real RigidBody2D/Area2D flotation, postflight reserve diagnosis and a three-station onboard recovery checklist. P-02 adds a concrete, interactable **contact and route desk** as a dependent child of the exact checklist scene.

1. **F** from `ready_for_route_review` after *all* crew/engine/contact checklist lines and native physical water evidence creates `first_wake_contact_decision_review.tscn`. The previous recovery UI hides, physical hull/story object continues as one authority. Early/duplicate entry is denied.
2. **1 — Sea:** sailing is plausible for the seaworthy Wake, but a real safe coastline/distance and current conditions are **not verified**.
3. **2 — Signal:** a status message is drafted, but neither a working connection, recipient nor successful delivery is **established**.
4. **3 — Tow:** external help could be possible, but **no assistance, rendezvous or tow approach** is arranged.
5. After reading both lines of each option, **E** concludes an evidence-limited **ROUTE HOLD**. Inputs cannot silently transition beyond that point.

This is an actual Godot UI / branching observation stage, not a simple generated text proposal. It presents honest choices without inventing a world destination. The author can later supply real navigable geography, contact method, family meeting site and any route-specific quest costs; that source contract can then be extended without discarding the player-facing screen.

## Native testing and proof

- `first_wake_integrated_p01_test.gd` remains the **unchanged default P-01 gate**; a new `--p02` flag extends the *same real scene and native physical scenario* through route desk origin, source identity, no premature/duplicate access, all three fully read observations, and no claimed rescue or party join.
- With `--p02 --capture`, save five actual same-run native Godot 960×640 GL screenshots including settled physical water contact, witnessed reserve, readiness completion, option desk before observations, and terminal route hold.
- `.github/workflows/godot-first-wake-pilot.yml` gates native P-01, native P-02, real rendered P-01 and rendered P-02 independently with fail-on-script-error receipts and pixel delta. Prior native original 3D inset and chapter tests remain intact.
- **No claim of production approval** from passing tests: screenshots must be reviewed for legibility, controls are not independently playtested by a new player, Windows Defender preflight remains separate.

## Next vertical-slice critical path

1. Authorize *specific* local safe geography and communication method in a canonical story map. Bind this to a real world-space route/contact implementation; no fabricated proof flags.
2. Integrate an actual family arrival/reunion with Lyra and Talen **only after** that route/meeting is verifiably safe, preserving Lyra agency and Talen non-party status.
3. Connect the existing independent working theory and physically collected materials / Denith melody bench without accepting the old QA reunion fixture.
4. Consolidate New Game default path, checkpoint v2 story and equipment persistence, audio/dialogue, native battle, visual art and uncoached player acceptance. Secret ship forms, Moon Bridge and full globe exploration are outside P-02.

**Canon / evidence invariant:** Ionia Earth, Ender Spirit, Lyra Water remain story Lights separate from authorized combat abilities. No launch, sea rescue, magical solution or hidden moon traversal is inferred.
