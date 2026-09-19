# Aetherwake — The Last Solarpunk Airship

A turn-based 2D6 PbtA JRPG. You are Ender, deckhand and engineer-in-training aboard the *Aureate Wake* — the last solarpunk airship. The ship's aether-core is singing wrong. Something has to be done about that.

![Loading screen](screenshot.png)

## How to Play

Open `index-embedded.html` in any modern browser. **No internet, no install, no CDNs** — everything is embedded: fonts, the reference-game loading image, and all TTS dialogue audio.

### Controls

| Key | Action |
|-----|--------|
| **WASD** | Move |
| **E** | Talk / advance dialogue |
| **Q** | Plant covenant field (spends 1 aether) |
| **F** | Board the ship (near the core chamber) |
| **Tab** | Toggle sky / ground layer |
| **L** | Mycelial ledger |
| **M** | Repair Cafe (shop) |
| **R** | Character sheet |
| **T** | Quest log |
| **N / Enter / Space** | Start game / confirm |
| **C** | Trigger a Sky-Predator encounter (dev) |

### Combat

Turn-based 2D6 PbtA. Five actions:

| # | Action | Stat | Cost |
|---|--------|------|------|
| 1 | Resonator Staff — EMP strike | might | 1 charge |
| 2 | Uncover Truth — read the weave | wits | 1 echo/aether |
| 3 | Shared Dream — lend your vision | spirit | 1 echo/aether |
| 4 | Mycelial Ledger — account the commons | presence | free |
| 5 | Hold — conserve | — | free |

Roll 2D6 + stat: **10+** success, **7–9** partial (with cost), **6–** failure. Wind Ward, Aether Seal, and Rest unlock at levels 3 and 5.

### The Quest

Four stages — **Signal → Crossing → Contact → Choice → Wake**.

- **Signal** — three hooks to find (harmonic buoy, sky-lane warning, below-frequency caller)
- **Crossing** — three hazards (sky-predator, harmonic shear, corporate intercept)
- **Contact** — four NPCs (Ionia, The Core, Lyra, Verrick)
- **Choice** — three paths (sing it down, sell it, drive it up)
- **Wake** — 10 epilogues, stat-driven and path-specific

### NPCs

| NPC | Voice | Role |
|-----|--------|------|
| **Ionia** | en-US-EricNeural | Captain of the Third Watch — tired, exact, fond of Ender |
| **The Core** | en-US-AriaNeural | Aether-core voice — ghost-song in copper and light |
| **Lyra** | en-US-JennyNeural | Child dreamer — hears frequencies above and below |
| **Verrick** | en-US-BrianNeural | Copper Syndicate acquisition officer — transactional, pragmatic |

Each has 5–8 lines of intro dialogue, 3 lines of class-specific follow-up, and a generic follow. Every line has a TTS voice clip.

## Technical Notes

- **Single-file HTML** (`index-embedded.html`) — open directly, no server needed
- **p5.js** in global mode, 960×640 canvas
- **Embedded assets**: VT323 + Press Start 2P fonts (base64), reference-game `Loading.png` (base64), 37 TTS MP3s (4 NPCs × ~9 lines)
- **Offline-ready**: no external requests of any kind
- **Loading screen**: mirrors the reference game's RMMZ `Scene_Boot` UX — Loading.png sprite, "AETHERWAKE" title, "initializing the weave…" sub, auto-dismisses when the p5 canvas comes live

## Author

Andrew Hensel (ndrorchestration) — Columbus, OH. Solarpunk airship fantasy, 2D6 PbtA combat, generated TTS dialogue.

## Credits

Reference loading-screen UX from *Memories 0.7.4*. Fonts: VT323 (Rik '../'), Press Start 2P (codeandweb) via Google Fonts. TTS: Microsoft Edge TTS.
