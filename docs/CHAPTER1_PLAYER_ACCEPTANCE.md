# Chapter 1 Player Acceptance — First Wake

Status: **NOT RUN**

This is the final human gate for the exact standalone Chapter 1 candidate. It does not replace technical release evidence and it does not authorize Chapter 2 work by itself.

## Candidate binding

Before play:
- record the exact `sourceCommit` from `CHAPTER1_RELEASE_EVIDENCE.json`;
- record the Setup.exe filename and SHA-256 from the same evidence;
- use that exact installer without developer tools, browser launch, source checkout, or live coaching.

If the candidate identity changes, repeat this acceptance on the new candidate.

## Uncoached play rule

The player may receive only:
- the Setup.exe;
- the instruction: **“Install and play Chapter 1. Use the controls the game presents. Tell us where you become confused, blocked, or stop trusting what the game is asking you to do.”**

Do not explain the route, puzzle/clue order, hazard locations, combat solution, save system, final choice, or expected ending during the run.

## Required observations

Record PASS/FAIL plus notes for each item:

1. **Install and launch**
   - installer completes without administrator elevation;
   - Aetherwake launches as a standalone window;
   - the window can be resized/maximized;
   - title/menu identity is recognizable.

2. **Opening comprehension**
   - player can start a new game without coaching;
   - player understands that Sequences 05–09 are explorable;
   - player finds Lyra and Ionia naturally enough to continue;
   - the 2-of-3 investigation gate is understandable from play.

3. **World objective**
   - player can identify the current objective after the opening;
   - quest/journal information is understandable when needed.

4. **Combat**
   - the player reaches all required Crossing encounters;
   - combat choices are understandable as stat/ability actions rather than hidden dice;
   - at least one defeat/retry, if encountered, does not strand the run;
   - all four hazards can be cleared without developer intervention.

5. **Persistence**
   - player creates or reaches a valid save;
   - closes Aetherwake completely;
   - relaunches the installed game;
   - Continue restores a sensible playable state.

6. **Chapter resolution**
   - player reaches CONTACT and understands that all required conversations matter;
   - player makes a final choice without coaching;
   - WAKE/DONE resolution is understandable;
   - replay/return behavior works.

7. **Presentation**
   - no blocking blank/purple screen;
   - no unreadable text or broken overlay prevents progress;
   - music transitions do not block or confuse play;
   - no visible debug/developer-only behavior intrudes on normal play.

## Blocking defect rule

A defect is blocking if it:
- prevents installation or launch;
- prevents progress without developer intervention;
- loses or corrupts the player’s usable save;
- makes the required objective/combat/choice path materially unintelligible;
- crashes or hard-locks the exact candidate;
- invalidates the exact release evidence.

Cosmetic defects should be recorded but do not automatically block acceptance.

## Acceptance record

Record:
- player/reviewer name or stable alias;
- date/time;
- exact source commit;
- installer SHA-256;
- whether the run was uncoached;
- total approximate play time;
- each required observation as PASS/FAIL;
- defects with reproduction steps;
- final result: `PASS` or `FAIL`.

Chapter 1 may be called player-accepted only when:
- the exact candidate already has passing `CHAPTER1_RELEASE_EVIDENCE.json`;
- the run is uncoached;
- every required observation passes;
- no blocking defect remains open.

A self-test by the creator is useful defect discovery, but it is not a substitute for this uncoached acceptance gate.
