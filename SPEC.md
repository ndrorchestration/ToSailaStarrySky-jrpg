# Aetherwake JRPG — Technical Specification
**Target:** Single self-contained p5.js HTML file. P2D renderer. 800x600 canvas (responsive).

## Characters
### Young Ender (protagonist, fixed)
- Age 28, Rift Scholar + Dreamwright multi-class
- Vit 13, Echoes 3/3
- Wits +2, Presence +1, Spirit +1, Might -1
- Abilities: Uncover Truth, Shared Dream, Mycelial Ledger
- Gear: Loom backpack (solar green tubes, 2.0kWh/400W), Resonator Staff (gunmetal shaft, claw mount, cyan crystal — no wood)
- Visual: short trimmed beard, green goggles, mycelial tattoos teal
- Combat: Staff deals EMP 1d6+2, range 10ft melee / 60ft beam, 2 charges, Prop: Commons Field

### Party (3 total, Ender fixed + 2 playable)
- Need 2 more slots for character creation (assign jobs/rank 1 + synergy)

## Combat System (Turn-Based 2D6 PbtA)
- **Initiative:** Grace + Wits
- **Resolution:** 2D6 + relevant stat
  - 10+ = full success
  - 7-9 = partial success (cost/complicance)
  - 6- = failure (GM move)
- **Resources:** Scrap 7, Aether 4/6, Heat 1/3, Charge 2.0kWh/400W
- **Action economy:** Main actions with +1/+2/+3 resource spend; secondary actions +1 extra
- **Ender abilities in combat:**
  - Uncover Truth: reveal enemy weakness/strategy (2D6+Wits)
  - Shared Dream: ally gets +1 next action or heals 1-2 Vit (2D6+Spirit)
  - Mycelial Ledger: track/remember — gain scrap or aether from encounter (2D6+Presence)
  - Resonator Staff: EMP damage 1d6+2, beam 60ft, 2 charges, recharges in sunlight

## World
- **Map:** 32x32 tiles, Columbus + Sky layers
- **Movement:** WASD
- **Interaction:** E = talk, Q = plant Covenant Field (teal circle), F = board ship (Unfinished Song), Tab = toggle ground/sky, L = ledger, M = shop (Repair Cafe)
- **Day-night:** 120s cycle, affects solar charge
- **Visual layers:** ground tiles, sky with 14 falling-upward islands, scanlines, teal accents

## Quest: "The Island That Falls Upward"
- **Signal (3 hooks):** distress / bounty / prophet dream
- **Crossing (3 hazards):** Wind Shear (Grace), Aether Leak (Wits), Sky-Predator (Might/Presence)
- **Contact (4 NPCs):** elder farmer, engine spirit (living nav), child prophet, corporate salvager (class-locked dialogue)
- **Choice (3 paths):** A) Save island/destroy engine, B) Preserve engine/evacuate, C) Allow ascent/discover above — each with 10+ and 7-9 sub-variants
- **Wake (6 epilogues):** based on Hull/Morale/Heat/Integration

## Visual Aesthetic
- Palette: Solar Teal #2AFFB5, Scioto Blue #7CC8E8, Deep Navy #1A102E, Parchment #E8DCC6, Dust Tan, Rust, Soil Brown, Biolum Green
- Fonts: VT323 (body), Press Start 2P (headers/UI)
- Effects: scanlines, teal glow (text-shadow 0 0 8px #2AFFB5), pixel borders, subtle grid
- Background: dark navy with teal grid overlay at low opacity

## Architecture (single HTML, inline JS modules)
```
core.js    — setup(), draw(), state machine, input, game loop
world.js   — tile map, movement, day-night, NPCs, quest FSM, covenant field
combat.js  — turn manager, initiative, 2D6 resolution, abilities, resource spend
ui.js      — HUD, char sheet, menus, dice display, turn log, ledger, shop
```
