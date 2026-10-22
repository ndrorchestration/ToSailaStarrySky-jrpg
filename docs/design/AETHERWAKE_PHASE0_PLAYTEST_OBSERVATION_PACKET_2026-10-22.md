# Aetherwake — Phase 0 Cold-Playtest Observation Packet
**Status:** ready-to-use research instrument; no sessions completed or outcomes claimed.  
**Applies to:** draft PR #330 First Wake vertical slice only.  
**Security gate:** do not distribute the Windows installer externally until Defender issue #293 is legitimately resolved.

## Build identity
Record before every session:

| Field | Value |
| --- | --- |
| Anonymous session ID | |
| Build / commit SHA | |
| Godot version | |
| OS | |
| Keyboard / controller | |
| Reduced motion | ON / OFF |
| Text size | |
| Sound | ON / OFF |
| Local trace consent | YES / NO |
| Facilitator intervention count | 0 |

Do not collect name, email, account identifiers, raw input logs, voice, video or screen recordings without separate explicit consent.

## Standard opening
Tell the participant:
> This is an unfinished game prototype. We are testing the game, not you. Please play as you naturally would and say what you are thinking if you are comfortable doing so. You can stop at any time. I will avoid helping unless you become stuck.

Do **not** explain SIGNAL, Ionia, Guard/Echo, the correct choice, or the intended payoff.

## Observation timeline
Use wall-clock time from first visible frame. Mark **A** for attempted, **S** for successful, **H** for facilitator help.

| Event | Time | A/S/H | Observation |
| --- | ---: | --- | --- |
| First voluntary movement | | | |
| Notices SIGNAL marker | | | |
| First interaction attempt | | | |
| Successfully inspects signal | | | |
| Approaches Ionia | | | |
| Opens choice | | | |
| Can paraphrase both options | | | |
| Chooses crew / beacon | | | |
| Finds CHALLENGE | | | |
| Identifies warning as a Guard cue | | | |
| Uses Guard during warning | | | |
| Notices Echo state | | | |
| Understands quiet Strike is stronger | | | |
| Completes encounter | | | |
| Returns to SIGNAL | | | |
| Notices world-state payoff | | | |
| Notices optional Ionia reaction | | | |
| Opens dialogue history | | | |
| Changes text / motion / sound setting if desired | | | |

## Comprehension checks
Ask only after the relevant beat has occurred.

1. **Choice:** “What did the two choices mean to you?”
2. **Telegraph:** “What did you think the enemy was telling you when the warning appeared?”
3. **Echo:** “What changed after you guarded?”
4. **Strike:** “Why did the next attack seem stronger or different?”
5. **Payoff:** “What changed in the world because of your choice?”
6. **Character:** “What impression did Ionia leave on you?”
7. **Continue:** “What would you want to do next?”

Record the participant's wording rather than converting it into a design conclusion during the session.

## Delight/friction capture
For every spontaneous reaction, note the exact beat and whether it was:
- curiosity / surprise,
- satisfaction / mastery,
- emotional connection,
- confusion,
- boredom / waiting,
- visual readability issue,
- audio issue,
- control/input issue,
- accessibility discomfort,
- desire to continue.

A memorable moment is counted only when the participant identifies one without being given examples.

## Phase 0 decision rules
The five-person round is **formative defect discovery**, not statistical validation.

### Stop and repair before adding content
- any soft-lock or unrecoverable state;
- any essential cue available only through color or sound;
- local trace enabled without explicit opt-in;
- two or more participants miss the same required interaction;
- two or more cannot explain Guard → Echo → quiet Strike after completing the encounter;
- two or more do not notice the return-state consequence;
- repeated confusion caused by binding labels or controller focus.

### Strengthen, then retest
- fewer than three participants spontaneously name a memorable or satisfying moment;
- Ionia is described as generic, purely functional or forgettable by a repeated pattern of participants;
- the choice feels cosmetic despite the visible payoff;
- the encounter is understood but described as rote;
- players want to continue but cannot infer an interesting next possibility.

### Expansion gate
Do **not** add a dungeon merely because Phase 0 is complete. After repeated P0/P1 friction is repaired, the next reversible expansion is:
1. one short road/spatial beat;
2. one second enemy/telegraph pattern;
3. one optional companion/world reaction.

Only after those survive further testing should content scale materially increase.

## Session close
Ask:
- “What was the clearest moment?”
- “What was the most confusing moment?”
- “What felt most like Aetherwake should become?”
- “What felt like something you have already seen too many times?”
- “What single change would most improve your desire to keep playing?”

Then confirm whether any local trace data should be retained. If consent is withdrawn, discard it.

## Aggregation sheet
After all five sessions, summarize with denominators:

| Measure | Result |
| --- | --- |
| Moved within 60 seconds | /5 |
| Found signal without coaching | /5 |
| Understood both choices | /5 |
| Understood Guard warning | /5 |
| Understood Echo payoff | /5 |
| Noticed world consequence | /5 |
| Named a memorable moment | /5 |
| Wanted to continue | /5 |
| Needed facilitator intervention | /5 |
| Accessibility blocker encountered | /5 |

Include contradictory feedback and outliers. Do not promote Phase 0 observations into population, market, genre-wide, or scientific claims.

## Evidence linkage
- Research basis: `docs/research/AETHERWAKE_JRPG_EXCELLENCE_DEEP_RESEARCH_2026-10-21.md`
- Adopt/adapt/defer decisions: `docs/research/AETHERWAKE_DEEP_RESEARCH_DECISION_RECONCILIATION_2026-10-21.md`
- Test protocol: `docs/design/AETHERWAKE_COLD_PLAYTEST_PROTOCOL_2026-10-21.md`
- Current-code native receipt: `docs/reviews/native-evidence/2026-10-21-pr330/WINDOWS_LOCAL_VERIFICATION_0EA4.md`

No session may be described as external validation, creator approval, production acceptance, or release authorization.
