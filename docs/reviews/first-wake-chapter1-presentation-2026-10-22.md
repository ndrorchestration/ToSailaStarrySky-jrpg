# First Wake Chapter I presentation review — 2026-10-22

**Runtime/evidence source:** `4110cdbd825307dfde2582275a16e8cea701a3ef`  
**Viewport:** 960×640  
**Status:** engineering visual review only; creator visual acceptance and human player acceptance remain **PENDING**.

## Exact verification
At this source, the following passed on the authorized Windows host:

- Chapter I readability contract
- Chapter I presentation contract
- full Playwright smoke
- fresh seven-frame player-evidence capture
- no browser/runtime errors in the capture manifest

The evidence capture recorded the real title, arrival, Lyra join, Ender+Lyra boundary, world handoff, Captain Ionia dialogue, and combat-entry states.

## What improved
### Title
The title now reads as a deliberate game entry point rather than a debug/menu screen:
- larger AETHERWAKE wordmark;
- explicit FIRST WAKE identity;
- clear START FIRST WAKE primary action;
- original procedural Aureate Wake silhouette;
- stronger dawn/sky depth and less dead space;
- controls moved into a secondary hierarchy.

### Opening
The authored First Wake text now sits in an original layered dawn/cloud-sea composition with:
- visible sunrise;
- floating reach silhouettes;
- readable Aureate Wake silhouette;
- scene-progress marker;
- stable lower status/control footer.

The opening remains procedural review art rather than an approved cinematic.

### World handoff
The right half of the fixed 32×32 world viewport now functions as a context rail rather than empty grid:
- active crew is visible;
- FIRST WAKE // CHAPTER I stays legible;
- essential exploration shortcuts are surfaced;
- existing quest NEXT guidance remains above it.

### Dialogue
Transient notifications are moved away from dialogue. Opening join notices are cleared at the world handoff, the deliberate chapter banner expires before settled dialogue evidence, and Captain Ionia's text remains readable inside the expanded box.

### Combat
An empty combat log no longer covers the encounter stage. The log appears only after entries exist and is repositioned below the enemy stage. At combat entry the Sky-Predator name, body and turn label are fully visible.

## Still visibly provisional
- Wake Dock ground tiles and props remain intentionally simple prototype art.
- Character sprites remain small at native scale and are not the final approved character-art pipeline.
- Combat terrain remains sparse and does not yet deliver the intended modern 2.5D JRPG spectacle.
- Opening ship/sky graphics are procedural composition placeholders, not commissioned/final art.
- No creator visual acceptance is established by these screenshots.
- No external player has yet demonstrated that the presentation is fun, beautiful, emotionally resonant or easy to understand.

## Decision
This branch is a material presentation improvement and is suitable for **private owner playtesting** once the Windows package is rebuilt and exact-byte QA passes. Do not merge or promote it over PR #334 solely from these screenshots; package/security verification and separate creator review remain required.
