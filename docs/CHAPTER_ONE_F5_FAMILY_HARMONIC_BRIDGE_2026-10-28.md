# Chapter One — normal F5 family and harmonic review bridge

**2026-10-28 · New native playable integration candidate, draft and unmerged.** This is an implementation experiment, not a final chapter, approved player-facing safe voyage or release. In response to [CH1-01 / CH1-03 / CH1-06 / CH1-11 / CH1-14](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/docs/chapter-one-hq-polish-gate-20261028/docs/CHAPTER_ONE_HIGH_QUALITY_POLISH_CHECKLIST_2026-10-28.md). **These checklist requirements remain OPEN** until all acceptance criteria, especially physical transition, extended save and human review, are met.

## Scope and true source identity

The branch starts at [normal F5 game entry #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547), exact parent `eae84a63d370d64bc5a11b049df4abb958301394`. It preserves its source-authoritative hiring, three engineering inspections, actual `RigidBody2D`/water `Area2D` contact and sustained float, shipboard Ender control, depleted-reserve dialogue and strict **`tstss.first-wake.first-flight.v1`** checkpoint with legacy schema isolation. No changes to the original `godot/project.godot` startup, source 3D ship, physics, engine warning, global party or combat.

It ports **unaltered original story/review dependencies** from independent native [#548](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548) (family, physical material pickups, failed retest, interactive harmonic options and Denith shanty) and connects them to the **same actual `Opening` object** used by the F5 job, flight and postflight session. The independent F8/old-Lyra-first runtime is not made the new default. See imported source history in that draft; no revised story line, archive track or preview image is authorized as final art.

### Player route now intended for exact native QA

1. Godot **F5** starts the actual revised Ender job search. Examine Ionia's flyer, finish interview, recruit **Ionia first**, board engineering, inspect all three systems and complete preflight.
2. Start physical local 2D flight, see phase warning, select controlled water descent. A **real** hull sensor and stable float must be observed before shipboard Ender control resumes.
3. Walk to the reserve console, press E and **complete all three** Ender/Ionia observation lines. At this point the strict v1 checkpoint can save (F5) and reload (F9) without any family/spoiler facts.
4. Press **R once** to request a nongeographic safe-recovery **review**. The status explicitly states that neither tow nor route nor harbor is simulated. Press **R a second time** to consent to a **STAGED** safe berth review location. No Lyra party/quest mutation happens on the first press or by mere arrival.
5. The real walkable family scene opens using that same original `Opening` object. Talen's optional block ship remains a child/noncombat encounter. Finish the full Ionia/Lyra/Ender conversation before Lyra joins **second**.
6. Interact with **two of three** independent logged clues and finish the shared theory conversation. The theory remains provisional. At the theory table, enter the actual connected physical-recovery workshop, retrieve and install two material fixtures, endure the failed retest, hear Ionia's **text-only draft** Denith humming clue, compare the three readable phase hypotheses, obtain Lyra's independent confirmation and Ionia's bench authorization. The resulting test is **a bounded bench candidate, never ship flight or automatic combat Art**.

## Explicit fail-closed constraints

- **Real physics before narrative:** `first_wake_game_session.gd` continues to admit splashdown only from actual reviewed `Area2D` body contact and stable buoyancy; no 3D cinematic frame or legacy state can substitute.
- **No fictitious geography:** two explicit R confirmations merely stage a safe-berth *review setting*. No 3D sailing, towing, rescue, harbor placement, world-route progression, travel duration or approved coastline exists in this patch.
- **No save-scheme escalation:** F5 remains a **postflight-diagnosis-only checkpoint**. After the family scene begins, **saving is denied**; the UI explains F9 returns to the prior postflight checkpoint, losing unsaved family progress. The new branch does **not** persist family/theory/repair progress, mint a novel checkpoint stage or reinterpret old Aetherwake save files. This is a significant player experience blocker that must be addressed in a distinct reviewed save v2.
- **No lore overwrite:** former captain Denith's knowledge/melody is not an approved sound asset; fuel composition and secret ship configurations remain unknown, Talen has no battle party role, Lyra joins only in safe order, later Five Lights remain unchanged.
- **No release/art acceptance:** visual placeholders, staged harbor, absent licensed original humming/music, full keyboard/gamepad input, post-family persistence, real voyage, Windows Defender-on custody, independent first-hour playtest and creator-signed dialogue/art are not delivered.

## Verification plan / QA evidence

`godot/tests/first_wake_game_entry_test.gd` now extends the original exact configured F5 route through physics and persisted restart into **two-step staged berth**, optional Talen, Lyra party join after dialogue, independently gathered clues, shared theory and the connected workshop, and checks that failed family-stage saves leave the prior checkpoint bytes untouched. It intentionally returns via **F9 to the postflight checkpoint** and verifies family progress is *not* misrepresented as persisted.

The existing native #547 pilot workflow additionally runs four unmodified imported #548 family/core/melody/headless scene tests; it fails closed if Godot emits a `SCRIPT ERROR` or relevant explicit fail marker. The standard native art/physics, browser smoke and Windows security workflows still run independently. **No CI PASS, human acceptance or target GPU result is asserted until checked at this branch's exact head.**

### Promotion sequence from here

- **CH1-01 partial:** inspect actual native end-to-end receipts and capture normal F5 family/workshop gameplay screenshots; unify source/scene authority without losing the original shipborne state.
- **CH1-06 remains OPEN:** approve real route/recovery and geographically authored family location, or visibly present this as an intentional noncanonical demo until a separate transition is implemented.
- **CH1-14 remains OPEN:** design a separately versioned, strict multi-stage save with exact progression fact reconstruction and negative tests; test full quit/restart at family and repair, preserve first-flight v1 compatibility.
- **P1 quality:** replace draft blocking with approved high-quality sprites, lighting, Aureate Wake geometry/weather, human-readable objective/hint conventions, accessible harmonic chart and owned Denith original shanty. Compare actual native frames and uncoached playtests.
- **Release boundary:** separate signed/verified Windows installer source includes this *specific* integrated game entry only after code review, target-hardware/security QA and explicit creator release approval.

**No merge, release, implied canonical harbor, full-chapter save completion, human art approval or physical relaunch.**
