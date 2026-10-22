# Aetherwake JRPG Deep Research — Decision Reconciliation
**2026-10-21 · 69-source report completed · implementation authority remains review-only**

Source report: `AETHERWAKE_JRPG_EXCELLENCE_DEEP_RESEARCH_2026-10-21.md`  
Research run: `01a1617c-2ee9-7a36-bb45-48c9eb8aa970`

This document converts research findings into explicit **ADOPT / ADAPT / DEFER / REJECT-FOR-NOW** decisions so the project does not turn source material into accidental canon.

## ADOPT
- **Strategic-prediction combat for First Wake.** Guard/Echo remains menu/turn driven; no reflex window.
- **Legibility before depth.** GUARD and ECHO/STRIKE have text + shape/ring cues and distinct native frames.
- **Immediate agency.** Keep movement available from the opening rather than front-loading exposition.
- **Character specificity through small reactions.** Optional Ionia post-payoff reaction is preferred to a longer compulsory cutscene.
- **Binding-aware controls.** Named interaction/choice/history actions preserve custom remaps and controller defaults.
- **Dialogue history and readable text.** History is now available as a movement-pausing overlay; text sizing and reduced motion remain.
- **Original recurring motif.** The two-note signal question/answer is procedurally generated and has mute-safe visual equivalents.
- **Dense, purposeful places.** Improve the existing compact dock before enlarging geography.
- **Consent-aware observation.** Playtest timing remains local, in-memory, opt-in, and cleared on opt-out.

## ADAPT
### Town → road → dungeon → save pacing model
Use this as a **longer production-loop reference**, not a mandate to cram all four beats into the current ten-minute dock study. Current First Wake is a deliberately smaller proof:
**discovery → choice → prediction challenge → visible payoff → optional companion reaction**.

Next expansion, if cold playtesting justifies it, should add **one short road/spatial beat**. Do not build a full dungeon merely to satisfy a generic pacing template.

### Playtest sample size
Keep the existing **5-person cold-playtest** as the first formative usability pass. Its purpose is defect discovery, comprehension, and qualitative delight—not population estimates.

After obvious friction is repaired and distribution/security gates permit, expand to a **20–30 participant target-demographic validation round** as recommended by the research. Larger 40–60 / longitudinal rounds belong later and are contingent on the slice earning them.

### Encounter duration targets
Treat ≤35 seconds / other report timings as hypotheses for measurement, not hard design law. First measure whether players understand and enjoy the pattern; then optimize duration without sacrificing comprehension.

## DEFER
- Echo AP/limited-use resource until actual play shows the current loop is spammy or dominant.
- Three telegraph/enemy families until the single tutorial pattern is understood without coaching.
- Ambient NPC chatter system until one companion/NPC beat demonstrates value.
- Three-theme adaptive score production until the two-note Echo motif and one location identity survive review.
- Road/dungeon/airship content scale until First Wake passes formative player testing.
- Ionia production art admission until creator review resolves the provisional sources.
- External installation/playtest distribution until Defender issue #293 is legitimately resolved.

## REJECT FOR NOW
- Direction B reflex/timing Guard as the default First Wake design.
- Direction C tactical positioning.
- Forced minigames.
- Grind-based progression as a substitute for tactical understanding.
- A long exposition opening.
- Expanding the map solely to make the slice look larger.
- Treating research popularity, Reddit consensus, or green engineering tests as evidence of player delight.

## Current implementation/evidence
At exact local code head `0ea4a8058139fe34452b491ed14020735dfaca21`, verified Godot 4.7.2 Windows native contracts pass for choice state, echo counterplay, contextual prompts, input policy, procedural signal audio, accessibility/history/timing, and real scene logic.

The latest reviewed renderer state at `641867dd1cb04a4da35c7198664dc09f276c6133` passes six distinct 960×640 frames including dialogue history; the persistent HUD was simplified after native inspection to avoid wrapping.

Hosted GitHub Actions remains blocked before execution by the account billing/spending-limit annotation. This is not a gameplay-test failure.

## Next evidence sequence
1. Keep code small; do not add a dungeon.
2. Finish first-loop observation instrumentation and cold-playtest packet.
3. Resolve legitimate distribution/security path before external installation.
4. Run five-person formative cold playtest.
5. Repair repeated friction before adding content.
6. Only then prototype a short road/spatial beat and second enemy pattern.
