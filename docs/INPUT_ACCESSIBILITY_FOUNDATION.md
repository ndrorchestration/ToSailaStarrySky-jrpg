# Input, controller, and accessibility foundation

This contract exists **before** Aetherwake expands its menu surface and five-character party UI.

## Architectural decision

Runtime code should consume **semantic actions** such as `confirm`, `cancel`, `interact`, `quest-log`, and `airship-dock`. Physical keyboard/gamepad bindings belong to an input layer and can be changed without rewriting gameplay logic.

The current hard-coded key paths remain runtime authority until this migration is implemented and verified. This document is a production contract, not a claim that controller/remapping support already exists.

## First implementation tranche

1. Add a pure semantic-action registry and validator.
2. Adapt existing keyboard events into semantic actions without changing player behavior.
3. Establish deterministic menu focus and a non-color-only focus indicator.
4. Add controller polling as a second producer of the same semantic actions.
5. Add user settings persistence separately from game-save slots.
6. Add title-accessible settings UI and integrate text/motion/audio/subtitle settings.
7. Add keyboard/controller parity to the First Wake benchmark.

## Critical invariants

- No essential action may require simultaneous inputs without an alternate single-press route.
- Save/Load controller shortcuts may exist, but the accessible route is through a navigable menu.
- Remapping must update displayed prompts.
- UI focus must always be knowable and recover predictably after closing overlays.
- Accessibility settings must be reachable before gameplay.
- Text advance remains player-controlled.
- Essential information cannot depend only on sound or a fixed color.
- User settings persist independently from individual game saves.

## Why now

The cheapest time to establish these contracts is before inventory/equipment screens, formation UI, five-character combat presentation, crafting/economy menus, and large content catalogs multiply the number of interactive surfaces.
