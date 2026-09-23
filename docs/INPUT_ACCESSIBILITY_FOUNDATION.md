# Input, controller, and accessibility foundation

This foundation exists **before** Aetherwake expands its menu surface, five-character party UI, inventory/equipment screens, and content scale.

## Current implementation state

**IMPLEMENTED REPRESENTATIVE FOUNDATION / RENDERED ACCEPTANCE + EXACT-HEAD EXECUTION PENDING.**

Implemented on this branch:

- semantic keyboard-action registry with context-specific bindings;
- deterministic shared focus manager with non-color `▶` markers;
- standard-mapping gamepad polling through fresh `navigator.getGamepads()` objects;
- controller traversal across BOOT, title, Settings, Controls, authored First Wake opening, WORLD, dialogue, read-only overlays, COMBAT, SAVELOAD, and AIRSHIP;
- deterministic combat action focus routed through canonical `resolveTurn()`;
- single-press controller Save/Load through gameplay Menu → focused Save/Load overlay;
- remappable title Continue with `C` / controller North defaults and dynamic prompt ownership;
- independent schema-v1 user-settings persistence;
- independent schema-v1 keyboard/gamepad binding persistence;
- keyboard/gamepad remapping UI with immediate persistence, reset-to-defaults, and fail-closed conflict rejection;
- dynamic player prompts sourced from the active binding authority;
- Reduced Motion, Screen Shake, Text Speed, Music Volume, Effects Volume, and Dialogue Volume;
- Text Scale across the representative First Wake title/opening/WORLD/overlay/choice/wake/character/flight/combat surfaces;
- High Contrast palette overrides with vignette suppression;
- subtitle visibility, size, background, and speaker-label policies;
- controller vibration through standard haptic actuators with graceful no-hardware fallback;
- a Playwright controller-parity lane that exercises Settings, remapping, First Wake, WORLD, Save/Load, dialogue, Dragonfly flight, focused combat actions, rendering settings, and vibration.

## Still open

- **Rendered visual acceptance** at 100 / 125 / 150 / 175% text scale, including high-contrast and subtitle combinations. Source-level contracts are not a substitute for reviewing actual rendered frames.
- **Title-track asset admission/playback verification** remains open. `docs/audio-assets.json` now fixes the canonical path and verified source fingerprint; the canonical music bus owns Music Volume/registration/playback, and desktop staging preserves `assets/**`. The MP3 binary itself is still absent, so runtime registration remains false.
- **Exact-head executed verification** remains blocked while the private repository receives zero-step hosted runs.

## Architectural decision

Gameplay and UI consume semantic actions rather than physical keys/buttons. Binding changes therefore do not require gameplay rewrites, and visible prompts are rendered from the same active binding state used by input dispatch.

Bindings persist independently from both game saves and general accessibility preferences:

- desktop: `nw.App.dataPath/input-bindings.json`;
- browser/headless: localStorage;
- binding schema: version 1.

Conflicting same-context bindings fail closed. A rejected remap leaves the previous binding active.

## Focus and navigation contract

The shared focus manager provides deterministic order, wraparound navigation, stable-ID restoration, and inspectable snapshots. Focus indication does not rely on color alone.

Save/Load, Settings, Controls, and combat actions are current reference surfaces using this contract.

## Settings persistence

Accessibility/user settings are **not owned by individual save slots**.

Desktop: `nw.App.dataPath/settings.json` with temporary-file promotion and backup recovery.

Browser/headless: localStorage with validated backup fallback.

Settings own schema version 1 independently from the whole-game save envelope.

## Rendering behavior now implemented

- Text Scale: 100 / 125 / 150 / 175%;
- High Contrast UI;
- Reduced Motion;
- Screen Shake level;
- Subtitles on/off with fail-closed visible text when playable TTS is unavailable;
- Subtitle size;
- Subtitle background;
- Speaker labels;
- Music volume through the canonical fail-safe music bus;
- Effects volume;
- Dialogue volume;
- Text speed;
- Controller vibration.

Music Volume is active on the canonical music bus. With no registered track, the bus remains silent and reports unregistered playback fail-closed.

## Controller verification lane

`tests/controller-parity-playwright.js` injects a standard-layout test gamepad through `navigator.getGamepads()` and exercises the actual polling + semantic adapter + runtime dispatcher. It covers:

- BOOT → Settings;
- Text Scale / High Contrast / Reduced Motion persistence;
- Settings → Controls;
- persisted controller remapping;
- authored First Wake progression;
- WORLD movement;
- controller Save/Load round-trip;
- Quest Log and dialogue;
- Dragonfly boarding, altitude, cast-off, movement, re-dock, and landing;
- focused combat navigation/action execution;
- haptic dispatch when a supported actuator is present.

## Visual acceptance lane

`tests/accessibility-visual-matrix-playwright.js` now turns rendered review into a repeatable artifact lane rather than an ad hoc screenshot task.

It captures **54 canonical 960×640 review frames**:
- 11 representative surfaces at each Text Scale value: 100 / 125 / 150 / 175%;
- six High Contrast samples at 150%;
- four dialogue subtitle/speaker-label combinations, including the fail-closed Subtitles Off / TTS unavailable case.

The lane writes `artifacts/accessibility-visual-matrix/manifest.json` with `HUMAN_REVIEW_REQUIRED` and CI uploads the directory as an artifact. Screenshot generation is verification infrastructure; the frames still require human review before rendered acceptance can be claimed.

## Next production actions

1. execute and review the 54-frame accessibility visual matrix;
2. execute the exact-head controller-parity and First Wake benchmark suites when a runner is actually allocated;
3. admit the exact verified title MP3 at `assets/audio/aetherwake-skyward-arpeggio-main-title.mp3`, flip the governed manifest to admitted/runtime-registered, then verify exact-candidate playback;
4. if those pass, reassess whether PR #147 can leave draft without widening scope.

## Critical invariants

- no essential action requires a chord without a navigable single-press alternative;
- remapping changes displayed prompts;
- invalid binding conflicts fail closed;
- focus is visible and predictable;
- Settings and Controls remain available before gameplay;
- text advance remains player-controlled;
- essential information does not depend on sound or fixed color alone;
- game saves, user settings, and input bindings remain independently versioned;
- static/source contracts are not described as rendered or executed verification.
