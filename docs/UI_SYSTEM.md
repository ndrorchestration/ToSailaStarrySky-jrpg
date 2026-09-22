# Aetherwake Premium UI System

Status: **IMPLEMENTED FOUNDATION / VISUAL REVIEW PENDING**

## Purpose

Aetherwake keeps the useful interaction patterns recovered from Memories while replacing its inherited prototype presentation with a game-specific premium interface language.

The target is a polished modern JRPG presentation: immediate hierarchy, cinematic restraint, strong character/world identity, and controller/keyboard clarity. It must evoke the production quality expected from premium story-driven JRPGs without copying another game's proprietary interface.

## Visual grammar

**Aetherglass**
- deep navy translucent instrument glass
- a quiet secondary inset plane instead of a flat rectangle
- thin Scioto-blue structural edge
- restrained brass inner trim
- solar-teal reserved for selected/active states

**Typography**
- Press Start 2P: labels, state names, compact command names
- VT323: readable body copy, descriptions, key legends
- hierarchy before decoration; no dense instruction walls on hero surfaces

**Selection**
- current command receives the strongest teal edge
- selection fill remains quiet enough to preserve text readability
- brass appears as a crafted/material accent, not generic gold fantasy ornament
- inactive information uses muted blue-gray rather than disappearing

**Operational clarity**
- one primary action per hero surface
- input hint adjacent to its action
- fullscreen and utility controls are visually secondary
- unsupported commands must never be advertised
- Continue remains absent until general save/load authority exists

## Reused Memories interaction patterns

Retain where useful:
- window openness transitions
- last-command memory
- state-specific tone
- command feedback sounds
- type-in dialogue
- live-scene context behind overlays

Do not preserve merely because inherited:
- flat opaque full-screen rectangles
- cyan-on-navy everywhere
- debug-like control legends
- equal visual emphasis for all information
- generic sci-fi framing detached from Aetherwake materials/world

## Title screen gate

The title must:
1. reuse the shared Dragonfly renderer;
2. present a distinct logo lockup and subtitle;
3. present NEW GAME as a genuine selected command, not explanatory text;
4. keep the sky and Dragonfly as the dominant visual image;
5. expose only immediately useful controls;
6. show the Skyward Arpeggio title music whenever the canonical audio asset is present and playback is permitted;
7. remain fully playable if audio fails.

## Menu rollout order

1. Title / New Game
2. Pause/system hub
3. Character sheet and five-member party overview
4. Combat command/status frame
5. Quest log
6. Inventory/shop
7. Save/load
8. Settings/accessibility

Every migrated surface should use shared primitives from `modules/aether-ui-system.js` rather than defining a new panel grammar.

## Current implementation

`modules/aether-ui-system.js` establishes shared premium primitives.
`modules/title-visual-stage.js` v0.2.0 is the first consumer.

Status remains **IMPLEMENTED CANDIDATE / NOT YET VISUAL PASS** until an exact-head screenshot is reviewed.
