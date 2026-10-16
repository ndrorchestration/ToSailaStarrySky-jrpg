# First Wake feedback: measured text containment

This candidate combines #278's narrative fallback with the existing measured HUD fitting in #279 (`70f499c6c5ee2cea0ce7c889e8cec65ffeb93426`). It adds runtime/browser coverage, fixes a dormant test-oracle lookup, and preserves Unicode code points in the reused helper. It does not integrate an older controller or alter authored copy, scene gates, sprites or canon.

## Recovered source and reproduced defect

The controller missing from the newer visual stack is recoverable as an **unmerged candidate**, not accepted runtime authority:

- V46 #206 baseline `148e97592aa584befdd9596d40fb46aa2c65c5e5`, controller blob `ca281f2b8484d6a52ad50de28c935371c59a9ee9`.
- Playable Rift Scholar #258 `d4145ab9aedbfd70640fc2bac9890f0459d3d927`, controller blob `f6798f482d25b3eb9b231e6c928d23f8dfa11efb`.

Both provide `wakeExploration`, `wakeExplorationView` and `nearbyWakeHotspot`. The current #278 controller does not. The earlier investigation checked protected main and #272/#273; this expands the search into the older playable lineage and resolves source discovery, not admission.

A Linux Chromium153 direct-renderer compatibility probe combined the exact #258 controller with #278 renderer `001df164c49a56ee72b04bd5a1713d3a6b50e3f5` at 960x640. It invoked actual controller interactions/views in 144 distinct diagnostic states and both day/night vignette modes (288 draws). These direct state probes are not a player route or an admitted mixed-source build.

Existing candidate feedback `The Core route stays sealed. You need more than one way of seeing the problem.` was clipped by the old 72-character rule to a rendered line **522px wide inside a 520px panel**. Four probes reproduced overflow (two clue states, two vignette modes). Longest measured objective was 311px inside its 320px backing. Existing #279 fitting is reused for both objective and feedback, including its 12px side padding.

## Bounded repair and checks

The reused binary-search helper measures the active font with `textWidth`, preserving short strings and shortening only until the line plus ellipsis fits its content width. A new regression exposed a surrogate-pair split in the original #279 helper; searching code points fixes it. Font, panel, color, coordinates, authored strings and interaction semantics stay the same.

- Runtime regression RED before repair, GREEN after: authored candidate message, short text, wide glyphs, Unicode and empty fallback.
- Same recovered-controller compatibility probe after repair: 288 draws, zero overflow or page errors, maximum feedback495px within496px content width. No state mutation.
- Real Chromium regression: 40 diagnostic width cases across both vignette modes and 0–3 clue pips; all fit, short text unchanged; four existing narrative scenes still render authored text/continue cues.
- Existing First Wake visual contract, narrative fallback and presentation clock checks pass locally.
- The inherited visual test searched for the helper after its declaration and failed when actually executed. Its extraction now uses the full source. The visual contract and Node width regression are explicitly added to smoke; browser width cases extend the already wired Chromium canvas test. Hosted results must be read at the final candidate head.

## Integration remains separate

Do not replace the current controller wholesale: old v0.8 uses `sceneTicks`/`presentationReady`, different scene identity (`wrong_song` versus `lyra_join`) and additional dock/berth/Talen/exploration progression gates. Recover its controller/input contract into a separately reviewed candidate while preserving current clock, narrative, approved party/canon and save semantics. This width fix is safe for a future exploration-capable controller but does not make that controller live.

No screenshot deliverable or public deployment is created. Linux measurements do not establish Windows font metrics or creator appearance acceptance. VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING; PROMOTION=NOT_AUTHORIZED.
