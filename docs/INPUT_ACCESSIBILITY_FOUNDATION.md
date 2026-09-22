# Input, controller, and accessibility foundation

This foundation exists **before** Aetherwake expands its menu surface, five-character party UI, inventory/equipment screens, and content scale.

## Current implementation state

**PARTIAL IMPLEMENTATION FOUNDATION — not full controller/accessibility parity.**

Implemented on this branch:

- semantic keyboard-action registry and validation;
- live runtime consumption of semantic actions for safe edge actions;
- deterministic shared focus manager;
- Save/Load focus with stable slot restoration and a non-color `▶` marker;
- standard-mapping browser gamepad adapter with per-frame `navigator.getGamepads()` polling;
- live controller dispatch limited to the **title and Settings UI**;
- independent schema-v1 user-settings persistence under `nw.App.dataPath/settings.json` with localStorage fallback;
- title-accessible Settings screen;
- immediate application of reduced motion, screen shake, dialogue text speed, Effects volume, and Dialogue volume;
- synthesized SFX module loaded in the embedded runtime, preserving the historical default master gain.

Not yet implemented:

- WORLD controller movement/action dispatch;
- full dialogue/AIRSHIP/combat controller parity;
- player remapping UI and prompt rebinding;
- text-scale and high-contrast rendering;
- subtitle size/background and speaker-label rendering;
- controller vibration;
- music-volume application (no canonical runtime music bus yet);
- executed First Wake keyboard/controller parity.

## Architectural decision

Runtime code consumes **semantic actions** such as `confirm`, `cancel`, `interact`, `quest-log`, `open-settings`, and `airship-dock`. Physical keyboard/gamepad bindings belong to the input layer so they can evolve without rewriting gameplay logic.

Controller behavior is context-prioritized. A physical button must not emit contradictory actions in the same state. For example, the south button is Confirm in menus, Interact in ordinary WORLD, Confirm during the WAKE resolution, and Dock in AIRSHIP.

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

## Next implementation tranche

1. migrate WORLD movement/actions onto safe shared semantic dispatch;
2. migrate dialogue and AIRSHIP semantics;
3. add First Wake controller parity regression coverage for those contexts;
4. design combat action focus rather than mapping eight numbered actions ad hoc;
5. implement remapping and prompt rebinding;
6. integrate text scale, contrast, subtitles/speaker labels, vibration, and later music volume.

## Critical invariants

- no essential action requires a chord without a navigable single-press alternative;
- remapping must eventually update displayed prompts;
- focus is visible and predictable;
- Settings remain available before gameplay;
- text advance remains player-controlled;
- essential information cannot rely on sound or fixed color alone;
- game save data and user settings remain independently versioned.
