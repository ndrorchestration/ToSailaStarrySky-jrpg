# Input, controller, and accessibility foundation

This foundation exists **before** Aetherwake expands its menu surface, five-character party UI, inventory/equipment screens, and content scale.

## Current implementation state

**PARTIAL IMPLEMENTATION FOUNDATION — broad controller traversal exists, but full combat/remapping/rendering parity is not established.**

Implemented on this branch:

- semantic keyboard-action registry with context-specific physical bindings;
- deterministic shared focus manager;
- Save/Load focus with stable slot restoration and a non-color `▶` marker;
- standard-mapping browser gamepad adapter using fresh `navigator.getGamepads()` polling;
- context-prioritized controller semantics so one physical button does not emit contradictory actions;
- controller dispatch for BOOT, title, Settings, authored First Wake opening, WORLD, dialogue, read-only overlays, and AIRSHIP;
- bounded controller movement repeat matching the existing keyboard cadence;
- independent schema-v1 user-settings persistence under `nw.App.dataPath/settings.json` with localStorage fallback;
- Settings reachable before gameplay with keyboard **S** or controller **Menu**;
- immediate application of Reduced Motion, Screen Shake, Text Speed, Effects Volume, and Dialogue Volume;
- synthesized SFX loaded in the embedded runtime while preserving the historical authored default loudness;
- a Playwright controller-parity regression that drives the real gamepad polling path through Settings, First Wake, WORLD, dialogue, and Dragonfly flight.

Not yet established:

- combat action focus/selection with controller;
- player remapping UI and prompt rebinding;
- single-press navigable controller Save/Load route;
- Text Scale and High Contrast rendering;
- subtitle size/background and speaker-label rendering;
- controller vibration;
- Music Volume application because no canonical runtime music bus exists yet;
- an executed exact-head hosted parity result while the repository runner remains unavailable.

## Architectural decision

Runtime code consumes **semantic actions** such as `confirm`, `cancel`, `interact`, `quest-log`, `open-settings`, and `airship-dock`. Physical keyboard/gamepad bindings belong to the input layer so they can evolve without rewriting gameplay logic.

Controller behavior is context-prioritized. The south button is Confirm in menus/opening, Interact in ordinary WORLD, Confirm during the WAKE resolution, and Dock in AIRSHIP. WORLD keeps WASD + arrows; AIRSHIP steering uses arrows so keyboard `D` remains Dock rather than becoming an ambiguous move-right action.

## Focus contract

The shared focus manager provides deterministic order, wraparound navigation, stable-ID restoration, and inspectable snapshots. Focus indication must never depend on color alone.

Save/Load and Settings are the first reference surfaces using this contract.

## Settings persistence

User settings are **not owned by individual save slots**.

Desktop: `nw.App.dataPath/settings.json` with temporary-file promotion and backup recovery.

Browser/headless: `localStorage` with validated backup fallback.

Settings own schema version 1 independently from the whole-game save envelope.

## Currently applied settings

- Reduced Motion
- Screen Shake
- Text Speed
- Effects Volume
- Dialogue Volume

The remaining preferences are persisted and visible in Settings but are not described as active until their rendering/audio hooks exist.

## Controller verification lane

`tests/controller-parity-playwright.js` injects a standard-layout test gamepad through `navigator.getGamepads()` and exercises the actual polling + semantic adapter + runtime dispatcher. It covers:

- BOOT → Settings;
- deterministic Settings focus and persisted Reduced Motion;
- title → authored First Wake;
- controller-only advancement through Sequences 00–09;
- WORLD movement;
- Quest Log open/close;
- dialogue interact/cancel;
- Dragonfly boarding;
- altitude change, cast-off, movement, re-dock, and landing.

Combat selection is deliberately excluded until combat has an explicit focus model.

## Next implementation tranche

1. design controller combat focus and action execution around semantic actions rather than numbered-key emulation;
2. provide navigable Save/Load access for controller users;
3. implement remapping + dynamic prompt rebinding;
4. integrate text scale, contrast, subtitles/speaker labels, and vibration;
5. bind Music Volume only after the title/runtime music bus is canonical;
6. execute the full exact-head lane when a runner is allocated and keep the benchmark fail-closed until then.

## Critical invariants

- no essential action requires a chord without a navigable single-press alternative;
- remapping must update displayed prompts;
- focus is visible and predictable;
- Settings remain available before gameplay;
- text advance remains player-controlled;
- essential information cannot rely on sound or fixed color alone;
- game save data and user settings remain independently versioned;
- controller support is not called complete until combat, Save/Load access, remapping, rendering hooks, and exact-head execution are all proven.
