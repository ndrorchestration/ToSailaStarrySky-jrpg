# Aetherwake — Player Experience Implementation Roadmap
**2026-10-21 / draft only / research integration pending**

This is a decision and implementation scaffold, not a claim that player research is complete, a canon rewrite, or authorization to ship. Preserve creator-confirmed character identities **Ionia, Ender, Aepex, Lyra, Reson**; approved Ender appearance and original source custody; Ionia's unapproved V5/V4 study; security hold #293; and protected-branch review.

## Experience promise
**Small acts of courage and attention restore connection, and the world responds.** The core loop is **notice → understand → choose → act → witness a change**. In ten minutes the player should experience movement agency, a place with character, a companion interaction, one legible challenge, and a visible consequence. Build feeling through meaningful feedback and specificity rather than compulsory exposition or content volume.

## Three viable directions to prototype, not combine blindly
| Direction | Player delight hypothesis | Engineering cost / risk | Decision |
| --- | --- | --- | --- |
| **A. Resonant repair** — compact exploration, readable turn-based signal challenges, choice-driven environmental restoration | Immediate cause-and-effect and hopeful payoff; accessible onboarding | Moderate state/feedback work; can feel too gentle if challenge lacks agency | **First prototype**: existing draft #330 |
| **B. Airship expedition** — navigational discovery, changing sky conditions, crew roles, tactical preparation | Wonder, place identity, sense of journey | Expensive navigation/content/AI and large environments; high scope creep | Prototype a single navigational vignette only after A playtests |
| **C. Companion crossroads** — relationship-led short stories, cooperative skill choices, reactive towns | Emotional investment and memorable character voices | Dialogue volume, branching QA, localization/accessibility costs | Prototype one meaningful optional companion beat after A |

The directions are original hypotheses; none is asserted to be a proven genre best practice until the requested Deep Research report and player evidence are reviewed.

## Workstreams and practical acceptance gates
| Workstream | Next small deliverable | Evidence needed before expansion |
| --- | --- | --- |
| Exploration | Two visual/audio clues on one dock; E prompts, clear objective and recovery | 4/5 new testers discover the first interaction without coaching; record misses |
| Characters/story | One original Ionia/Ender conversation with a nonpunitive exclusive choice | Players can summarize both options and expected stakes; creator approves any canon change |
| Combat/challenge | One strike/guard telegraph, no grind, fast retry | Players explain the cue after one encounter; no soft-lock; accessible text warning |
| Consequences/progression | Distinct crew/beacon dock return states | Deterministic tests prove both branches; players notice the consequence |
| Visual direction | Consistent readable 960×640 silhouette, warm signal motif, layered dock depth | Real native screenshots and creator comparison; no automatic sprite admission |
| Audio | Original two-note question/answer signal, quiet-to-warm layered response, silence-friendly design | Composer/originality review, mute and non-audio-equivalent cues; no borrowed themes |
| UX/accessibility | Text sizing, reduced motion, high-contrast labels, input remapping, dialogue history | Keyboard and controller task walkthrough; no essential cue only in sound/color |
| Playtesting/telemetry | Opt-in local event timings and scripted observer questions | No personal data/networking; voluntary 5-person cold-playtest and documented consent |
| Engineering/QA | Exact-head Godot import, scene and state tests, native renderer captures | Green native jobs; reproducible source/hash receipts; no release/security gate bypass |

## Original narrative and artistic motif prompts (noncanonical)
- **A question that travels:** a fractured dock beacon repeats a two-note signal; answering it changes the light in one small corner of the world. This is a *test fixture*, not established Aetherwake plot.
- **The world listens back:** a once-quiet lantern responds to a choice with an original light pattern, NPC acknowledgement and optional music layer.
- **Crew as community, not inventory:** a companion offers an interpretation and a different practical cost, not merely a quest marker.
- **Art:** teal dusk, amber lanterns, textured deck geometry, distinctive actor silhouettes, consistent staff visibility, readable contrast at 960×640. These are palette and staging hypotheses, not replacements for creator-approved sources.
- **Music:** original two-note call/answer evolving into a longer phrase; optional adaptive stems and silence. Do not reuse existing JRPG melodies, samples or protected assets.

## Roadmap with explicit stop/go gates
### Days 1–30: Prove the first ten minutes
- Ship **draft-only** standalone Godot slice and deterministic scene tests; inspect 960×640 discovery, choice and payoff frames.
- Add clear context prompts, reversible choices, telegraph clarity, local-only metrics, text sizing and reduced motion.
- Conduct a five-person observed cold-playtest (if participants and consent are available). Track time to first action, confusion points, understanding, delight/surprise, and voluntary desire to continue.
- **Stop/go:** do not expand story or combat if the first interaction or encounter is consistently misunderstood.

### Days 31–60: Make one moment memorable
- Revise the weakest first-ten-minute moment using playtest evidence.
- Commission or author original audio/visual responses, and seek explicit creator sign-off on any character/canon-facing change.
- Prototype one additional companion reaction and one optional exploratory clue. Add dialogue history, remappable inputs and controller checks.
- **Stop/go:** avoid full-world expansion until choice payoff and accessibility survive repeat playtests.

### Days 61–90: Prepare a production candidate, not an automatic release
- Produce a coherent vertical slice with approved assets, stable performance, recoverable failure states, localization-ready text and a small test matrix.
- Reconcile overlapping art/dialogue/gait branches by exact source provenance and authorized review; keep independent scientific claims separate.
- Resolve the Defender #293 security hold through legitimate investigation before any installer distribution. Preserve protected-main and release authorization.
- **Stop/go:** creator art/canon approval, independent playtest evidence, QA sign-off and security review are all required; green CI alone is insufficient.

## Ordered engineering backlog
1. **P0 / shipped to draft:** deterministic clue → choice → challenge → return-state model and standalone Godot scene; native state/scene tests.
2. **P0 / shipped to draft:** reduced-motion default, adjustable story text size, labeled world objects, ephemeral opt-in event trace.
3. **P0 / verification:** real renderer screenshots of search/dialogue/payoff with private custody; inspect legibility and player-scale art.
4. **P0 / next:** contextual prompts and a first-run objective that works without instructions from the developer.
5. **P0 / next:** formal encounter failure/retry regression; no trapped movement or permanent loss.
6. **P1:** original two-note audio proof with mute/visual parity, then creator review.
7. **P1:** dialogue history, input rebinding/controller navigation, focus/contrast checks.
8. **P1:** five-person cold-playtest and prioritized fixes with recorded denominators.
9. **P2:** additional companion vignette, airship discovery vignette and long-form progression **only if** P0 gates pass.
10. **Held:** production asset admission, field pack, installer, release and protected-main merge until separate approval.

## Research integration and evidence hygiene
The exhaustive JRPG/Reddit/game-development research request is running separately. When delivered, tag each recommendation **source-supported**, **player anecdote**, **design inference**, or **untested hypothesis**, include source links, identify counterexamples, and rank by *player impact versus build risk*. Do not retroactively describe these prototype decisions as research findings. Keep draft PR #330, Ionia visual baseline #326, gait PRs #328/#329, and security issue #293 separate; maintain dated Notion status with exact heads and no false admission.
