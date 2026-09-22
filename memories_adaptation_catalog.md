# Memories 0.7.4 → Aetherwake JRPG: UI/UX Pattern Adaptation Catalog

**Source:** Memories 0.7.4 (RPG Maker MV / NW.js)  
**Target:** Aetherwake JRPG (p5.js single-file integrated runtime `aetherwake.js` with explicitly loaded supporting modules)  
**Date:** 2026-09-18  
**Already ported:** Scene_Boot loading screen UX (Loading.png sprite + "initializing the weave..." sub + auto-dismiss)

---

## 1. Window Chrome / Drawing System

### 1.1 Windowskin 9-Patch Border (rpg_windows.js:65–67, 659–685)

**What it is:** Every window loads a `Window.png` skin (128×128). The skin is a grid: corners are drawn as-is, edges are stretched 1px, center is stretched for the contents area. `refreshDimmerBitmap` creates a gradient overlay (transparent edges → opaque center) for the background dimmer.

**File/line:** `rpg_windows.js:65` (`loadWindowskin`), `663–677` (`refreshDimmerBitmap`)

**Aetherwake applicability:** **MEDIUM.** Aetherwake currently uses `drawPixelBorder` (nested rects with lerpColor). A proper 9-patch system would let a single PNG drive window frames of any size — critical for consistency across dialogue boxes, menus, character sheet, combat panel. Requires:
- A windowskin PNG in Aetherwake's assets
- A `draw9Patch(x, y, w, h, skin)` function that samples corner/edge/center regions
- Port the dimmer gradient as a `drawWindowDimmer(x, y, w, h)` function

**Effort:** Medium (new primitive + all existing windows need skinning pass)

---

### 1.2 Window Open/Close Slide Animation (rpg_windows.js:117–147)

**What it is:** Windows have an `openness` property (0 = fully closed, 255 = fully open). `updateOpen` increments by 32/frame, `updateClose` decrements by 32/frame. While opening/closing, `updateBackgroundDimmer` ties dimmer opacity to `openness`, so the dimmer fades in/out with the window. `open()` and `close()` set flags rather than instantly changing visibility — the window slides over multiple frames.

**File/line:** `rpg_windows.js:117–147`, `657–661`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's `drawMenu` instantly paints the backdrop + panel. Adding an `openness` animation state to menus, dialogue boxes, and character sheet would give them a "slide up from closed" feel. Each UI panel that has a show/hide cycle gets:
```js
if (panelOpenness < 255 && panelOpening) panelOpenness += 32;
if (panelOpenness > 0 && panelClosing) panelOpenness -= 32;
// Use panelOpenness as alpha multiplier on backdrop + border
```
Backdrop dimming tied to openness mirrors the Memories dimmer behavior.

**Effort:** Trivial (add 3 state vars + 4 lines in drawMenu/drawNPCDialogue/drawCharSheet)

---

### 1.3 Window Tone / Color Tint (rpg_windows.js:89–92, 111)

**What it is:** `updateTone` reads `$gameSystem.windowTone()` (an [R,G,B] array) and calls `setTone()` on the window, tinting the entire window bitmap each frame. This lets the game globally shift window color (e.g., red-tinted windows in a blood scene).

**File/line:** `rpg_windows.js:89–92`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake could add a global `UI.windowTone` color that tints all panel backgrounds. Set it per-scene: e.g., warm tint in shop, cool tint in dialogue, red tint in combat. Implemented as a single `fill(toneColor)` with low alpha over each panel's background rect.

**Effort:** Trivial (one global + 1 line per panel draw)

---

### 1.4 Background Dimmer Sprite (rpg_windows.js:637–661)

**What it is:** When a window calls `showBackgroundDimmer()`, a sprite is created behind it that draws a gradient: transparent at the edges, darkest in the center. The dimmer's opacity tracks the window's `openness`, so it fades in as the window slides open. This creates the effect of the window "focusing" the player's attention.

**File/line:** `rpg_windows.js:624–677`

**Aetherwake applicability:** **SMALL.** When Aetherwake opens a menu or dialogue box, the game world behind should dim. Currently `drawMenu` paints a flat `NAVY` at alpha 220. A proper gradient dimmer (darker in center, fading to edges) would feel more polished. Just needs a `drawDimmerRect(x, y, w, h)` that does a 3-stop gradient.

**Effort:** Small (one helper function, swap into backdrop draws)

---

## 2. Dialogue / Message Box Behavior

### 2.1 Type-In Text with Wait Codes (rpg_windows.js:4297–4564)

**What it is:** `Window_Message` processes text character-by-character via `updateMessage`. Each frame it calls `processCharacter` on the `_textState` until paused. Three escape codes control speed:
- `\.` — wait 15 frames (brief pause, like a comma)
- `\|` — wait 60 frames (longer pause, like a period)
- `\!` — start a full pause (waits for player input to continue)
- `\>` — show fast for the rest of the line (skip type-in)
- `\<` — revert to slow type-in
- `\^` — skip all pauses entirely (auto-advance)

The message auto-advances when the player presses ok/cancel/touch. When all text is shown, it enters a pause; pressing a button dismisses.

**File/line:** `rpg_windows.js:4528–4564` (escape codes), `4407–4429` (updateMessage loop)

**Aetherwake applicability:** **MEDIUM.** Aetherwake's `drawNPCDialogue` shows all text instantly (3 lines max). Porting the type-in behavior would add dramatic pacing. The escape codes `\.` `\|` `\!` could be embedded in dialogue strings. Key pieces:
- A `dialogueState` object tracking current character index, wait count, pause flag
- `updateDialogue()` called each frame that types one character unless paused
- Wait/pause codes parsed inline
- Auto-advance on any keypress when fully typed

The "show fast on button press" behavior (`>` code) is especially nice — players who hold enter breeze through, casual players see the type-in.

**Effort:** Medium (state machine + parsing + integration with dialogue trigger system)

---

### 2.2 Face Display in Dialogue (rpg_windows.js:4489–4500)

**What it is:** When a message has a `faceName` set, `loadMessageFace` reserves the face image, then `drawMessageFace` draws it at the left edge of the message window (144×144). The face bitmap is loaded asynchronously — `updateLoading` checks `isReady()` and pauses message display until it loads.

**File/line:** `rpg_windows.js:4489–4500`

**Aetherwake applicability:** **SMALL.** Aetherwake should show NPC portraits in dialogue boxes. Currently it only shows the NPC name. Adding a portrait (loaded from Aetherwake's character assets) on the left side of the dialogue box, with async loading safety, would match the RPG convention.

**Effort:** Small (add portrait draw + loading check to drawNPCDialogue)

---

### 2.3 Floating / Tracking Message Boxes (GALV_MessageStyles.js:403–498)

**What it is:** When a message uses `\pop[eventId]`, the message window detaches from the bottom-center and floats near the targeted event/actor/screen-position. It tracks the target's screen X/Y every frame (`updateFloatPlacement`), attaching a directional arrow sprite (the "tail") that points from the box toward the target. The box clamps to screen edges and flips between top/bottom positioning intelligently.

**File/line:** `GALV_MessageStyles.js:403–498` (`updateFloatPlacement`), `789–809` (`updateChoiceFloat`)

**Aetherwake applicability:** **LARGE.** This is a big lift but very distinctive. In Aetherwake's world map, NPCs could "speak" with a dialogue box that floats near them rather than always at the screen bottom. The arrow/tail pointing to the speaker is a strong visual cue. Implementation needs:
- A target position (world-space → screen-space transformed)
- Per-frame repositioning of the dialogue box
- A directional arrow/triangle sprite attached to the box
- Edge-clamping logic

If Aetherwake stays with screen-bottom dialogue only, this can be skipped. If world-space NPC dialogue is planned, this pattern is worth the effort.

**Effort:** Large (tracking, arrow sprite, edge logic, integration with camera transform)

---

### 2.4 Message Window Resizing to Fit Content (GALV_MessageStyles.js:581–639)

**What it is:** `changeWindowDimensions` calculates the maximum line width and total text height, then sets the window's `width` and `height` to fit the text exactly (clamped to screen width). The window skin tail (arrow) is repositioned based on the final box position. This means short messages get small boxes, long messages get wide boxes — no wasted space.

**File/line:** `GALV_MessageStyles.js:581–639`

**Aetherwake applicability:** **SMALL.** Aetherwake's dialogue box is fixed 600×90. If the type-in system is ported, dynamic sizing (box shrinks for short lines, expands for long ones) would look cleaner. Just needs text measurement before drawing.

**Effort:** Small (measure text width/height first, set box dims)

---

### 2.5 Choice Window Positioning Relative to Message (GALV_MessageStyles.js:789–809, rpg_windows.js:3849–3870)

**What it is:** When a choice window opens, its position is calculated relative to the message window: if the message is in the top half of the screen, choices appear below it; if in the bottom half, choices appear above. The choice window also supports three horizontal alignments (left/center/right) based on `$gameMessage.choicePositionType()`.

**File/line:** `rpg_windows.js:3849–3870` (`updatePlacement`), `GALV_MessageStyles.js:789–809`

**Aetherwake applicability:** **SMALL.** Aetherwake doesn't have a choice system yet. When it does, positioning choices relative to the dialogue box (above if box is low, below if box is high) avoids overlap and feels natural. The horizontal alignment (center vs left vs right) is a nice touch for different dialogue tones.

**Effort:** Small (calculate relative position in choice UI code)

---

## 3. Menu Structure / Navigation

### 3.1 Window_Command System (rpg_windows.js:1288–1439)

**What it is:** A command window is a selectable list of named commands, each with a `symbol` (e.g., `'item'`, `'skill'`) and an `enabled` flag. Commands are added via `addCommand(name, symbol, enabled)`. The window auto-sizes to fit the number of commands. `callOkHandler` dispatches to a handler registered via `setHandler(symbol, method)`. Disabled commands are drawn with reduced paint opacity (160/255). `selectLast` restores the previously selected command symbol across menu openings.

**File/line:** `rpg_windows.js:1288–1439`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's `openMenu` / `drawMenu` already has a list of options with callbacks. The command pattern adds:
- A `symbol` field on each option (so handlers can be registered by symbol, not index)
- Enabled/disabled rendering (dimmed text + can't select)
- `selectLast` memory (remembers which menu option was last selected, restores on re-open)
- Auto-height to fit command count

This is basically a formalization of what Aetherwake already does informally.

**Effort:** Trivial (extend the menu option objects with `symbol`, `enabled`; add last-selected memory)

---

### 3.2 Horizontal Command Layout (rpg_windows.js:1441–1468)

**What it is:** `Window_HorzCommand` overrides `numVisibleRows` to return 1 and `maxCols` to return 4. Commands are laid out in a single row of 4, centered text. Used for the equip command (3 cols: Equip/Optimize/Clear) and shop command (3 cols: Buy/Sell/Cancel).

**File/line:** `rpg_windows.js:1441–1468`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's shop menu (when implemented) would benefit from a horizontal Buy/Sell/Cancel row. Also the character sheet's resource panel could use horizontal layout. Just a layout mode flag on the menu system.

**Effort:** Trivial (add a `layout: 'horizontal'` option to menu config)

---

### 3.3 Grid-Based Status Display (SRD_MenuStatusCustomizer.js:556–623)

**What it is:** The menu status window is divided into a grid of `statusCols` columns and `statusRows` rows. Each status field (name, class, level, HP bar, MP bar, TP bar, EXP bar, icons, custom evals) is placed at a specific `(row, column)` in the grid. The grid auto-calculates cell width from the window width and column count. Fields outside the grid bounds are silently skipped.

**File/line:** `SRD_MenuStatusCustomizer.js:556–623`

**Aetherwake applicability:** **SMALL.** Aetherwake's character sheet currently has a fixed layout (portrait left, stats right, abilities/gear/resources below). A grid-based approach would let the layout be configurable — e.g., 3 columns × 4 rows, with each stat/field assigned to a cell. This makes it easy to rearrange or hide fields without rewriting draw calls. Per-actor custom fields (like the `Status N Eval` in SRD) could let different characters show different info.

**Effort:** Small (refactor drawCharSheet to use a grid concept)

---

### 3.4 EXP Bar with Gradient + Label (SRD_MenuStatusCustomizer.js:578–587)

**What it is:** `drawActorExp` draws a gauge bar (gradient from color1 to color2) showing XP progress to next level, with a text label ("To Next Level") above it. The bar uses `drawGauge` (gradient fill) with custom colors set via plugin parameters.

**File/line:** `SRD_MenuStatusCustomizer.js:578–587`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake doesn't have an XP system yet, but when it does, this pattern — gradient gauge + label — is the right shape. Already matches Aetherwake's `drawAnimatedHPBar` approach.

**Effort:** Trivial (copy the gauge + label pattern)

---

### 3.5 Last-Command Memory Across Menus (rpg_windows.js:1572–1588, 1686–1688)

**What it is:** `Window_MenuCommand._lastCommandSymbol` stores the symbol of the last-selected menu command. On re-opening the menu, `selectLast` restores that selection. `initCommandPosition` resets it. This is also done for the title screen (`Window_TitleCommand`, lines 5739–5775) and actor commands (`Window_ActorCommand`, lines 5438–5451), where the last-used battle command is remembered per-actor.

**File/line:** `rpg_windows.js:1572–1588`, `5739–5775`, `5438–5451`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's menu always highlights the first option. Remembering the last selection per menu (item, skill, equip, etc.) makes navigation faster for players who frequently switch between menus.

**Effort:** Trivial (one global per menu type, restore on open)

---

## 4. Save / Load UI

### 4.1 Save File Window with Playtime and Characters (rpg_windows.js:2788–2877)

**What it is:** `Window_SavefileList` displays save files with: file number ("File 1"), game title (if saved), party characters drawn as sprites (if saved), and playtime string. Invalid/empty slots are dimmed. The window auto-sizes item height to fit 5 visible items.

**File/line:** `rpg_windows.js:2788–2877`

**Aetherwake applicability:** **MEDIUM.** Aetherwake needs a save/load system. This pattern gives a concrete UI: each save slot shows file #, a thumbnail or character indicator, and elapsed playtime. The "dim invalid slots" convention is standard. Implementation needs:
- A save data format (JSON in localStorage or file)
- Per-slot: timestamp, playtime accumulator, party state snapshot
- Draw: file number + playtime string + small character indicator

**Effort:** Medium (save system + UI; the UI pattern itself is straightforward)

---

### 4.2 Savefile Playtime Formatting (rpg_windows.js:2873–2877)

**What it is:** Playtime is stored as a string (formatted by `DataManager`) and drawn right-aligned in the savefile slot. The playtime is only shown if the save data has a `playtime` field.

**File/line:** `rpg_windows.js:2873–2877`

**Aetherwake applicability:** **TRIVIAL.** When saving, accumulate playtime (seconds since load) and store as a formatted string ("01:23:45"). Display it in the save slot.

**Effort:** Trivial (time tracking + formatting + save field)

---

## 5. Scene Transition Effects

### 5.1 Scene Fade In/Out System (rpg_scenes.js: — Scene_Base fade methods)

**What it is:** `Scene_Base` has `startFadeIn(duration, white)` and `startFadeOut(duration, white)`. A `_fadeSprite` is created that fills the screen with a color (white or black). `updateFadeIn` increments the sprite's opacity from 0 toward 255 (fade in = fade out the overlay), `updateFadeOut` decrements from 255 to 0 (fade out = fade in the overlay). The fade is tied to the scene's `_fadeSign` and `_fadeDuration`. Scenes call `startFadeIn` on `start()` and `startFadeOut` on `stop()`.

**File/line:** `rpg_scenes.js` Scene_Base prototype (fadeSign, fadeDuration, fadeSprite, startFadeIn, startFadeOut, updateFade)

**Aetherwake applicability:** **TRIVIAL.** Aetherwake has `triggerScreenFlash` (a short colored flash) but no scene-level fade transitions. Adding `sceneFade(color, duration)` that paints a full-screen rect fading in/out would give scene changes (map → menu → battle) a smooth feel. Black fade for most transitions, white fade for "wake up" moments.

**Effort:** Trivial (3 state vars + update + draw call)

---

### 5.2 Scene_Boot Loading Screen with Subtitle (rpg_scenes.js: Scene_Boot, referenced in GALV_MessageStyles.js:750)

**What it is:** `Scene_Boot.loadSystemImages` loads all system images. This is where the loading screen sprite + "initializing" subtitle pattern lives (already ported to Aetherwake — confirmed existing).

**Aetherwake applicability:** **CONFIRMED PORTERD.** Already in Aetherwake.

---

### 5.3 Map Name Fade Display (rpg_windows.js:4656–4726)

**What it is:** `Window_MapName` shows the current map's display name at the top of the screen when entering a new map. It fades in (contentsOpacity += 16/frame for 150 frames), holds, then fades out. The name has a gradient background bar behind it (dark at edges, transparent in middle).

**File/line:** `rpg_windows.js:4656–4726`

**Aetherwake applicability:** **SMALL.** When Aetherwake transitions between world zones (e.g., entering a new island, a dungeon, a covenant site), a brief "zone name" display fading in/out at the top of the screen would add polish. The gradient background bar mirrors the dimmer tech.

**Effort:** Small (one-off display function triggered on zone change)

---

## 6. Visual Effects

### 6.1 Screen Shake via Window Positioning (SRD_BattleStatusCustomizer.js:875–923)

**What it is:** Not screen shake per se, but per-window motion. When an actor is selected for input, their battle status window slides by `_offsetY` (set by `inputY` speed and `inputYMax` distance). When deselected, it slides back. Same for select motion. This gives a physical "the window nudge when it's your turn" feel.

**File/line:** `SRD_BattleStatusCustomizer.js:875–923` (`updateMotion`), params at 106–143

**Aetherwake applicability:** **SMALL.** Aetherwake could add a subtle "nudge" to UI panels when they become active — e.g., the combat panel shifts up 4px when combat starts, the dialogue box jiggles slightly when a new line appears. The SRD params model this well: speed + max distance for input/select states.

**Effort:** Small (add offset state to panels, animate toward target offset)

---

### 6.2 Gauge Drawing with Gradient + Back Color (rpg_windows.js:465–470, SRD_BattleStatusCustomizer.js:1063–1091)

**What it is:** `Window_Base.drawGauge` draws a 6px-tall bar: a solid back color rect, then a gradient fill rect from `color1` to `color2` for the filled portion. `SRD_BattleStatusCustomizer` extends this with `drawGaugeUpgrade`: adds an explicit back color (can be "clear" for no back), draws a 1px black border around the gauge, and supports variable height.

**File/line:** `rpg_windows.js:465–470`, `SRD_BattleStatusCustomizer.js:1063–1091`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake already draws gradient bars in `drawAnimatedHPBar` and `drawSolarMeterHUD`. The SRD pattern adds: explicit back color, 1px border, configurable height. These are easy wins for the existing bar draws.

**Effort:** Trivial (add border + back color params to existing bar functions)

---

### 6.3 Damage Popup / Number Float (rpg_windows.js:4903–4905, referenced throughout Window_BattleLog)

**What it is:** `Window_BattleLog.popupDamage(target)` calls `target.startDamagePopup()`, which triggers a floating number sprite (the damage value) that rises and fades above the target. The actual sprite work is in `Sprite_Damage` (not in the files read), but the trigger pattern is here: battle log pushes a popup event, the target spawns the float.

**File/line:** `rpg_windows.js:4903–4905`

**Aetherwake applicability:** **MEDIUM.** Aetherwake's combat has dice rolls but no floating damage numbers. Adding a "number float" that rises from the combat target and fades would be a strong combat UI element. Needs:
- A particle-like system for floating text (separate from the particle system in ui.js)
- Trigger on combat result (damage/heal/crit)
- Rise + fade animation over ~40 frames

**Effort:** Medium (new float text system, trigger integration)

---

### 6.4 Type-Out / Text Scroll (rpg_windows.js:4567–4653)

**What it is:** `Window_ScrollText` displays scrolling text (no window frame). It calculates the total text height, creates a contents bitmap that tall, sets `origin.y = -height`, and each frame increments `origin.y` by `scrollSpeed`. Fast-forward is triggered by holding ok/shift/touch. `scrollSpeed` is `messageSpeed / 2`, tripled when fast-forwarding.

**File/line:** `rpg_windows.js:4567–4653`

**Aetherwake applicability:** **SMALL.** Aetherwake could use a scrolling text effect for: quest log entries that scroll in, lore snippets, or end-of-combat summaries. The "hold to fast-forward" convention is familiar to RPG players.

**Effort:** Small (one scrolling text display function)

---

### 6.5 Battle Log Backdrop (rpg_windows.js:4757–4782, 5001–5015)

**What it is:** `Window_BattleLog` creates a `_backBitmap` and `_backSprite` behind the log text. Each refresh, it fills the back bitmap with a dark color at 64% opacity, sized to the current number of log lines. This creates a semi-transparent dark band behind the scrolling battle text.

**File/line:** `rpg_windows.js:4757–4782`, `5001–5015`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's combat log panel (`drawCombatLog`) already has a solid NAVY background. Matching the Memories approach — a backdrop sized to the number of visible entries — would let the panel shrink when there are few entries. But the solid background already works fine.

**Effort:** Trivial (optional; Aetherwake's current approach is adequate)

---

### 6.6 Input Indicator / Cursor Arrow (GALV_MessageStyles.js:684–733)

**What it is:** `Galv.Mstyle.Window_Message__refreshPauseSign` positions a pause sign sprite (the "input indicator") around the message window. The position is configurable via numpad directions (1–9) + X/Y offset. The indicator and arrow sprites are zoomable via `iZoom` (e.g., 100% = normal size). This tells the player "press a button to continue" with a visual arrow.

**File/line:** `GALV_MessageStyles.js:684–733`

**Aetherwake applicability:** **SMALL.** Aetherwake's dialogue shows a "continue prompt" but could benefit from a visual indicator (a blinking arrow or icon below the dialogue box) that pulses to signal "press to continue." The numpad-position system is over-engineered for Aetherwake, but the pulse + zoom concept is simple.

**Effort:** Small (add a pulsing arrow/icon below dialogue boxes)

---

## 7. HUD / On-Screen Display

### 7.1 HUD Maker — In-Game HUD Construction (SRD_HUDMaker.js)

**What it is:** SRD_HUDMaker lets developers build map-based HUDs from image pieces placed in `/img/SumRndmDde/hud/`. Pieces are: Pictures (static images), Image Numbers (digit graphics), Image Gauges (fill images), Gauge Backs. Each piece has position, condition rules, and visibility behavior during events (hide/show/transparent). Global conditions can enable/disable the entire HUD.

**File/line:** `SRD_HUDMaker.js` full file (69KB)

**Aetherwake applicability:** **NOT DIRECTLY PORTABLE.** Aetherwake's HUD is already hand-drawn in p5. The SRD approach (image pieces placed on a map) is an RPG Maker MV-specific workflow. However, the *concept* of condition-driven HUD visibility is useful: Aetherwake's HUD could have global conditions (e.g., "hide HUD during cutscene," "show extra info in combat") that toggle panels on/off.

**Effort:** N/A (concept only, not a code port)

---

### 7.2 Battle Status Customizer — Per-Actor Windows (SRD_BattleStatusCustomizer.js:658–696)

**What it is:** Instead of one shared battle status window, each actor gets their own `Window_BattleStatusUpgrade`. Each window is positioned by formula (`oriX`, `oriY` for the first; `sectionX`, `sectionY` for subsequent, using `prev` to reference the previous window). Each actor's window can have its own skin, tone, and opacity via notetags (`<Battle Status Window Skin: Window2>`, `<Battle Status Window Tone: 100, -50, 0>`, `<Battle Status Window Opacity: 192>`). Windows slide when the actor is selected for input.

**File/line:** `SRD_BattleStatusCustomizer.js:658–696` (scene integration), `763–805` (window init), `930–955` (tone/skin/opacity)

**Aetherwake applicability:** **SMALL.** Aetherwake's combat panel shows the player's stats. If multi-character parties are added, each character could get a small status panel positioned along the side, with per-character color theming (tone) and optional custom skin. The "slide on select" motion adds feedback.

**Effort:** Small (if multi-character party is planned; otherwise N/A)

---

### 7.3 Window_PartyCommand — Bottom-Command Layout (rpg_windows.js:5318–5357)

**What it is:** The party command window (Fight/Escape) is positioned at the bottom of the screen (`y = Graphics.boxHeight - windowHeight`). It's 192px wide, 4 rows. The battle actor command window uses the same positioning.

**File/line:** `rpg_windows.js:5318–5357`

**Aetherwake applicability:** **TRIVIAL.** Aetherwake's combat action grid is on the left side. A bottom-row command strip (Fight/Run/Items) could complement it, matching the RPG convention. The positioning formula (bottom of screen, centered or left-aligned) is straightforward.

**Effort:** Trivial (position a menu at screen bottom)

---

## 8. Text / Font System

### 8.1 Windowskn-Defined Color Palette (rpg_windows.js:173–241)

**What it is:** All text colors are sampled from the windowskin image at fixed pixel positions. `textColor(n)` reads pixel at `(96 + (n%8)*12 + 6, 144 + floor(n/8)*12 + 6)`. This gives 32 named colors: `normalColor` (0), `systemColor` (16), `crisisColor` (17), `deathColor` (18), `gaugeBackColor` (19), `hpGaugeColor1/2` (20/21), `mpGaugeColor1/2` (22/23), `tpGaugeColor1/2` (28/29), `powerUpColor` (24), `powerDownColor` (25), `pendingColor` (from pixel 120,120).

**File/line:** `rpg_windows.js:173–241`

**Aetherwake applicability:** **NOT PORTABLE (but concept is).** Aetherwake uses a hardcoded PAL object. The windowskin-color-sampling trick is MV-specific. However, the *idea* of a unified color palette object that all UI draws reference (instead of scattering hex values) is exactly what Aetherwake's PAL already does. The naming convention (normal/system/crisis/death/gaugeBack/hpGauge1/2/mpGauge1/2) could inform PAL additions if Aetherwake adds more gauge types.

**Effort:** N/A (PAL already exists; maybe add named gauge colors)

---

### 8.2 Escape Character Font Sizing (rpg_windows.js:372–396)

**What it is:** Text within a message can use `\{` to increase font size by 12 and `\}` to decrease by 12 (clamped: max 96, min 24). This lets a single message line have mixed font sizes — e.g., a large title word followed by smaller explanation text.

**File/line:** `rpg_windows.js:372–396`

**Aetherwake applicability:** **SMALL.** Aetherwake's dialogue could support inline font size changes for emphasis. E.g., a dialogue string like `"\{WARNING!: 플레이어} the rift is unstable"` would render "WARNING!" large and the rest normal. The `\신선` approach (inline markup in strings) is lightweight.

**Effort:** Small (parse `\{`/`}` in dialogue strings, adjust font size on the fly)

---

## 9. Quick-Reference Summary Table

| # | Pattern | Source File:Line | Aetherwake Use | Effort |
|---|---------|-----------------|---------------|--------|
| 1.1 | 9-patch window skin | rpg_windows.js:65–67, 663–677 | Replace nested-rect borders with skin-based drawing | Medium |
| 1.2 | Window slide open/close + dimmer tie | rpg_windows.js:117–147, 657–661 | Animate menu/dialogue/sheet openings | Trivial |
| 1.3 | Window tone / global tint | rpg_windows.js:89–92 | Per-scene panel tint color | Trivial |
| 1.4 | Gradient background dimmer | rpg_windows.js:637–661 | Better menu backdrop than flat alpha fill | Small |
| 2.1 | Type-in text + wait codes (\., \|, \!) | rpg_windows.js:4528–4564 | Paced dialogue with auto-advance on input | Medium |
| 2.2 | Face display in dialogue | rpg_windows.js:4489–4500 | NPC portrait in dialogue box | Small |
| 2.3 | Floating message tracking + arrow tail | GALV_MessageStyles.js:403–498 | World-space NPC dialogue near speaker | Large |
| 2.4 | Dynamic message box sizing | GALV_MessageStyles.js:581–639 | Box sized to text content | Small |
| 2.5 | Choice positioning relative to message | rpg_windows.js:3849–3870 | Choices above/below dialogue box | Small |
| 3.1 | Command window (symbol + enabled + selectLast) | rpg_windows.js:1288–1439 | Formalize menu option system | Trivial |
| 3.2 | Horizontal command layout | rpg_windows.js:1441–1468 | Buy/Sell/Cancel row, resource strips | Trivial |
| 3.3 | Grid-based status layout | SRD_MenuStatusCustomizer.js:556–623 | Configurable character sheet grid | Small |
| 3.4 | EXP bar with gradient + label | SRD_MenuStatusCustomizer.js:578–587 | Future XP system | Trivial |
| 3.5 | Last-command memory | rpg_windows.js:1572–1588, 5739–5775 | Remember last menu selection per menu | Trivial |
| 4.1 | Save file window (playtime + characters) | rpg_windows.js:2788–2877 | Save/load UI | Medium |
| 4.2 | Playtime formatting | rpg_windows.js:2873–2877 | Save time tracking | Trivial |
| 5.1 | Scene fade in/out | rpg_scenes.js Scene_Base | Smooth scene transitions | Trivial |
| 5.2 | Map name fade display | rpg_windows.js:4656–4726 | Zone name announcement on entry | Small |
| 6.1 | Window nudge on select/input | SRD_BattleStatusCustomizer.js:875–923 | Panel motion on activation | Small |
| 6.2 | Gauge with border + back color | rpg_windows.js:465–470, SRD:1063–1091 | Polish existing bar draws | Trivial |
| 6.3 | Floating damage numbers | rpg_windows.js:4903–4905 | Combat result floats | Medium |
| 6.4 | Scrolling text with fast-forward | rpg_windows.js:4567–4653 | Quest log / lore scroll effect | Small |
| 6.5 | Battle log backdrop band | rpg_windows.js:5001–5015 | (already adequate in Aetherwake) | Trivial |
| 6.6 | Input indicator arrow + pulse | GALV_MessageStyles.js:684–733 | "Press to continue" visual cue | Small |
| 7.1 | HUD condition-driven visibility | SRD_HUDMaker.js | Toggle HUD panels by context | N/A (concept) |
| 7.2 | Per-actor battle windows | SRD_BattleStatusCustomizer.js:658–696 | Multi-character party panels | Small |
| 7.3 | Bottom-command layout | rpg_windows.js:5318–5357 | Combat action strip at screen bottom | Trivial |
| 8.1 | Unified color palette object | rpg_windows.js:173–241 | (PAL already exists) | N/A |
| 8.2 | Inline font size escape codes | rpg_windows.js:372–396 | Emphasis in dialogue text | Small |

---

## 10. Recommended Priority Order

### Immediate (Trivial — do now)
- **1.2** Window slide open/close animation (3 state vars, 4 lines)
- **1.3** Window tone / per-scene tint (1 global + 1 line per panel)
- **3.5** Last-command memory per menu (1 var + restore on open)
- **5.1** Scene fade in/out transitions (3 state vars + update + draw)
- **6.2** Gauge border + back color (add 2 params to bar functions)
- **8.2** Inline font size in dialogue (`\{` / `\}` parsing)

### Short-term (Small — this session / next)
- **1.4** Gradient dimmer backdrop (1 helper function)
- **2.2** NPC face portrait in dialogue box
- **2.4** Dynamic dialogue box sizing
- **2.5** Choice positioning relative to dialogue
- **3.2** Horizontal command layout mode
- **3.3** Grid-based character sheet refactor
- **5.3** (new) Zone name fade-in display
- **6.1** Panel nudge on activation
- **6.4** Scrolling text for quest log / lore
- **6.6** Input indicator arrow below dialogue

### Medium-term (Medium — next sprint)
- **1.1** 9-patch window skin system (new primitive + pass over all panels)
- **2.1** Type-in dialogue with wait codes (state machine + parsing)
- **4.1** Save file window + save system
- **6.3** Floating damage numbers (new float text system)

### Large / Conditional (only if scope expands)
- **2.3** Floating message tracking (requires world-space NPC dialogue)
- **7.2** Per-actor battle windows (requires multi-character party)

---

*Report generated from Memories 0.7.4 source files (rpg_windows.js 6028 lines, rpg_scenes.js 2697 lines, GALV_MessageStyles.js 818 lines, SRD_HUDMaker.js 69KB, SRD_MenuStatusCustomizer.js 625 lines, SRD_BattleStatusCustomizer.js 1119 lines) and Aetherwake JRPG integrated UI in `aetherwake.js` (hand-rolled 4-band layout, §4 Memories-style character sheet).*
