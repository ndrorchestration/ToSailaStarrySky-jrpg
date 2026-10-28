# First Wake — Chapter One Continuation Save v2 (Native Review)

**October 28, 2026 • Draft P0 CH1-14 • Separate from first-flight checkpoint v1**

The actual F5 Godot game now has a second **strictly scoped** save file, `user://first_wake_chapter1_review_v2.json`, for clean progression after the physically proven ocean splashdown. It is an **additive local gameplay checkpoint**, not an upgrade of the old Lyra-first legacy save or a canonical planetary-world route.

## Contract

- **v1 authority is preserved byte-for-byte:** `first_wake_first_flight_v1.json` remains the source for historical verified local `RigidBody2D` ocean contact, buoyancy and Ender+Ionia reserve inspection. V2 is denied unless that exact primary v1 file exists, parses and passes its own unchanged evidence schema. The new chapter record stores the raw v1 file SHA-256 and cannot outlive a rewritten or missing v1 file.
- **Separate v2 schema:** `tstss.first-wake.chapter1-review.v2`, `parent_schema=tstss.first-wake.first-flight.v1`, digest, explicit one of family-arrival/investigation/working-theory/repair-review, two permitted story party configurations, unique independent clue IDs, optional noncombat Talen block-ship flag and an exact bounded repair-phase state.
- **Stage semantics:** no Lyra party before the full family introduction; at least two clues and creator-directed co-theory before the material workshop. Valid core phases require the precise number of real recovered and installed parts, failed retest before Denith's remembered melody, and only a bounded benchmark candidate after Lyra's independent observation and Ionia's containment authorization.
- **No unsafe mid-dialogue or modal save:** only clean points between conversations and harmonic chart interactions; press **F5** to save a separate stage, **F9** to restore. The player can preserve progress without clearing chapter story gates or fabricating an ocean crossing.
- **Atomic storage/backup:** `.tmp` → validated primary, previously verified `.bak`, and fallback only to a valid same-v1-generation record. Schema mismatch, unauthorized party, impossible phase/retest, parent file change, extra/unknown fields and corrupt v2/backup never promote progress. If both v2 files are invalid, F9 returns to verified v1 postflight Ender+Ionia without modifying disk evidence.
- **Recovery:** loading v2 first reloads **verified v1**, then explicitly reconstructs permitted family, independent observations, working theory and exact core-phase transitions through original creator-directed `Opening` and `Core` methods. On replay failure, rollback to v1. The restored shop remains a visual **review fixture**, with no new real physical workshop/harbor journey or original Denith song recording.
- **Security distinction:** SHA-256 file binding and semantic validation are for accidental corruption and local progression consistency, **not** a tamperproof signed save or anti-cheat mechanism. The user's local file store is not a trusted hardware boundary.

## QA and acceptance

The existing normal F5 real Godot game-entry test now verifies:
1. Ender job → Ionia → preflight → *real* Area2D water contact and stable float → postflight diagnostic v1 save.
2. Two explicit geographically non-authoritative R confirmations → F5 family-arrival v2, followed by Lyra and Talen story/hypothesis → additional F5 theory v2.
3. Real physical pickup, assembly, failed retest, shanty and chart investigation → F5 phase snapshots → bounded candidate, F9 roundtrip reconstructing the entire historical state.
4. Source v1 file bytes preserved across v2 saves/loads; child combat party and forged failed-retest fields rejected.
5. Current v2 corrupt, valid backup previous phase recovery; both corrupt, safe original v1 fallback.

**CI status:** do not claim acceptance until the *exact head* GitHub native Godot pilot and isolated nine-frame F5 GL capture workflow return PASS. Independent developer art review, licensed music, actual world route, Windows Defender-on custody and final release remain OPEN.

## Explicit exclusions

Does not write to legacy Aetherwake `user://` paths, authorize the next test flight, grant later Five Lights, convert story music to combat Arts, define the fuel formula or Moon Bridge, change the globe/ship, or issue public builds. **Stacked on draft #568**; remains draft and unmerged. The checklist's CH1-14 becomes **engineering proof** only when native tests pass, and stays **full-production OPEN** until real install/relaunch QA and creator signoff.
