# First Wake — The Captain's Shanty: physical recovery and core re-alignment

**Authority:** Creator-directed 2026-10-27 Chapter I fuel-mystery **resolution beat**, complementary to the previously creator-directed Ender → Ionia → Lyra opening. This specifically **supersedes the old assumption that the FW-10 two-of-three-clue working theory is the *end* of the mystery**. It does not establish the actual fuel composition, exact source, quantities, melody/lyrics, musical interval values, ship internal engineering specifications, optional final chapter endpoint, or final voice performances.

**Source relationships:** [Revised opening storyboard and dialogue PR #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425); [playable recruitment and preflight #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430); [revised opening/roster #450](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/450); [read-only combat/Resonance composite #465](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/465); [v2 revised-opening checkpoint #480](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/480); [main entry opt-in F8 route #495](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/495). These are separate drafts, not merged or newly certified by this narrative specification.

## Required creator-directed dramatic sequence

1. **Material shortage is real.** After the managed ocean splashdown, safe Lyra/Talen reunion and the three-adult working fuel theory, the party investigates, physically **finds and retrieves the necessary additional physical fuel materials, replacement components or supply elements** and installs/prepares them. The search must have on-world consequences: explored spaces, tangible carried/recovered items, repair tasks and meaningful team cooperation. The material recovery may be a multipart quest; do not silently give the player free materials or name/prove the ingredients before their design is approved.
2. **Material fix appears insufficient.** A controlled post-repair restart has usable fuel and mechanical/containment prerequisites, but the levitation core still *will not phase-lock*; the Aureate Wake remains grounded. The player sees the actual failure despite the physical effort. Avoid an unexplained “insufficient power” reset or false implication that the player's material quest was pointless.
3. **Ionia hums involuntarily.** During the tired, anxious silence after the failed test, Ionia softly hums an old seafaring work song/shanty she had heard her former captain **Denith** sing. It is a remembered human habit and connection to her grief, *not* a deliberately planted security password, scripted incantation, automatic combat magic or retroactive claim that Denith invented the fuel.
4. **Ender notices an acoustic relationship.** Ender hears an interval/rhythm/held-note relationship in the humming that corresponds *precisely* to the unresolved harmonic variables he has measured while repairing the core. He asks Ionia to **come closer and sing it again**; she owns the memory, repeats the melody by choice, and gives its Denith context. She is not treated as an incidental audio recording.
5. **Observation corroborates insight.** With Ionia singing and Ender reading the instrumentation, Lyra observes a previously unstable physical response settling into a repeatable pattern. The music is a *calibration reference*: relative pitches/interval succession, phase, rhythm, hold duration and entry/exit timing map to the core's alignment settings. The craft-specific exact numeric sequence is **TO COMPOSE/VERIFY**, not fabricated here. This is where the crew recognizes a viable alignment sequence; at first it remains a tested candidate.
6. **Safe measured correction.** Ionia authorizes a bounded test; Ender manually applies the derived calibration **only after** restored fuel/material supply, mechanical checks and containment safety. Lyra corroborates the stable response. An authentic instrument reading confirms stable phase-lock before any later liftoff is portrayed. The revelation does not conjure fuel, repair broken hardware, add spells, force a player to sing into a microphone or authorize a combined combat Art.
7. **Character payoff:** Ionia's living memory of Denith and Ender's trained listening make the discovery emotionally earned; Lyra helps make the hypothesis testable, rather than becoming a passive audience. The breakthrough says something about how these three listen to and trust one another. The realization can close the grounded/recovery arc or begin a new launch beat depending on approved chapter pacing.

**Two required locks, in sequence:** `PHYSICAL_SUPPLY_READY` (material/repair quest) **AND** `PHASE_SEQUENCE_VERIFIED` (shanty-based acoustic calibration). Material readiness alone **must fail** to authorize flight; a valid melody alone **must fail** with depleted supply. Distinguish “calibration candidate evidenced” from “real flight physics/player-accepted liftoff proven.”

## Proposed cinematic and dialogue treatment — not final dialogue canon

**Location:** the engineering space adjoining the Wake's helm, at dusk or after a long repair day; no fixed geography committed. The replacement stock is in place. The regulator's glow briefly climbs, stutters, and falls; engine needles lose the stable interval. No dramatic explosion. Work leaves grease on the tools and weary hands.

*Ionia checks a readout a second time, presses her fingers against the edge of the helm console, and quietly hums a familiar old tune without addressing anyone. Beneath her voice, the inactive core makes a soft, uneven sympathetic vibration. Ender, already about to clear the measurement chart, stops.*

- **Ender:** “Hold on. That tune—where did you learn it?”
- **Ionia:** “Denith used to sing it. Mostly when something was taking longer than he liked.”
- **Ender:** “Would you come over here? Sing it again. Just the way he did.”
- **Ionia:** “Now? With all this going wrong?”
- **Ender:** “Especially now. I think the core's been trying to tell us something, and I've been listening for the wrong thing.”

*She draws near and repeats the phrase. He marks successive intervals on the phase chart as the second held note seems to catch the oscillation, then releases it too early. He asks to hear the phrase again, not to prove her wrong but to distinguish the timing.*

- **Ender:** “It's the spacing. The way the notes move—and where you let that one wait. That's what our alignment sequence is missing.”
- **Lyra:** “The vibration isn't wandering anymore. It settled when she held that note.”
- **Ionia:** “He sang that for years. I never thought…”
- **Ender:** “You remembered what I couldn't measure. Now we can measure it.”
- **Ionia:** “Then we test it properly. Everyone clear, containment first.”

*Once the core is steadily aligned, allow a moment of relief. Do not instantly smash to a combat tutorial or suggest the full flight is certified; staging a later safe liftoff deserves its own physical/visual gate.*

### The song as an original composition

A composer should develop a **new, ownable** shanty melody whose working-rhythm feels naturally memorable and singable. Use a short identifiable motif that can recur earlier on the ship as a nearly unconscious Denith/Ionia memory, without revealing its technical role. The diagnostic sequence should be explainable in musical-theory terms (interval class/direction, phrase divisions, pulse ratios, sustained-note dwell timing, harmonic overtone relationship) **and mapped to deterministic sampled core readouts**. No fixed frequencies, key, tempo, notes or lyrics are canon yet. Protect the reveal by giving the player both sound and non-audio representations; do not require voice recognition or musical pitch accuracy from players.

## Suggested playable quest/activity chain (stage IDs are implementation proposals)

| ID | Required gameplay/evidence | Anti-shortcut acceptance |
| --- | --- | --- |
| FR-01 Repair Inventory | After Lyra's safe postflight join and the provisional theory, identify multiple *tangible* shortages/defects in ship inspection | Do not invent item names/chemistry/quantities before material design |
| FR-02 Material Recovery | Physically locate/retrieve the approved supplies/components in approved playable areas; track their custody | A repaired panel alone does not count without recovered parts |
| FR-03 Installation | Install/check supply, feed and containment on the Wake | Engine still grounded; no auto-phase-lock from material install |
| FR-04 Failed Retest | Conduct a **safe**, deliberate control retest showing physical readiness but unstable phase | Mandatory in story; creates the earned discouragement before melody |
| FR-05 Humming | Trigger Ionia's natural anxious humming in a post-failure low-action moment | No early shortcut from hearing background music before physical recovery |
| FR-06 Sing It Again | Ender asks Ionia to approach and repeat; she shares Denith's connection | Ionia's consent and history are required; do not silently auto-calibrate |
| FR-07 Understand the Phrase | Interpret the original harmonic motif using phase readings and Lyra's sensory corroboration | Audio, visual and controller-only access; negative attempts should guide, not punish |
| FR-08 Verify Phase-Lock | Ender applies a bounded sequence, Lyra independently confirms, Ionia commands safety, containment remains stable | Only **verified candidate lock**; actual liftoff needs a separate flight/physics checkpoint |

**Narrative revision note:** FW-09 “Wrong Song” becomes **early foreshadowing/unstable harmonic listening**, and FW-10 still ends at the *working hypothesis*. They should not prematurely supply the final phase sequence. New FR-01–08 *follow* that theory and a real material retrieval sequence. The original two-of-three clues remain flexible, but no shortcut to final alignment.

## Prototype and QA boundary

The additive isolated Godot pilot `first_wake_shanty_resolution_contract.gd` is a **pure evidence-order model only**, intended to follow `first_wake_revised_opening_contract.gd` at `working_theory`. It asserts correct party and reunion, real material/installation evidence, failed controlled retest, Ionia's humming/repeat, Ender's musical-pattern analysis, Lyra's independent observation and Ionia's safety approval. It never names ingredients, generates audio, measures actual DSP, performs ship physics, saves into the v2 preflight-only schema, invents a combined combat spell, or authorizes live lift. The test must prove material-only and song-only pathways both deny, every out-of-order event is blocked, invalid evidence leaves state unchanged, and a valid trace reports **alignment_candidate** only.

**Outstanding independent reviews:** creator sign-off for wording and placement; original shanty melody/licensing, Denith relationship continuity, Lyra/Talen family context, three-party production dialogue, gathering locations and real inventory assets, sample-accurate audio/phase meter matching, pitch-deaf accessibility, controller input and reduced motion, native flight/ocean physics, journal and saved quest migration, artwork and emotional player testing, native Godot CI and Windows Defender release security. Existing draft branches remain unmerged.
