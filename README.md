# To Sail the Starry Sky

*A science-fantasy JRPG about finding a place to belong, restoring an extraordinary vessel, and discovering a world worth exploring.*

**Status: pre-alpha · Godot 4.7.2 development · October 28, 2026**

**To Sail the Starry Sky** follows Ender and the crew of the **Aureate Wake**, a distinctive dragonfly-inspired ship that becomes their home. The planned game combines character-driven exploration, a luminous planetary world, turn-based party combat, maritime and aerial travel, and cinematic 2.5D presentation.

The five authored playable protagonists are **Ender, Lyra, Ionia, Reson, and Aepex**. Their relationships, recruitment, and capabilities are revealed through the story. The **Five Lights** remain a central mythological motif; this public repository intentionally excludes restricted narrative resolutions.

## Play & download

| Build | What exists | How to access it |
|---|---|---|
| **New Godot First Wake** | Connected playable **development candidate**, with Ender's job search, Ionia-first engineering/flight, authentic local water contact, shipboard inspection, and a checkpoint. **Draft and unmerged.** | [Godot gameplay PR #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547) and instructions below |
| **Windows Godot installer** | `ToSailTheStarrySky-Setup.exe` has been built, installed, launched in a native maximizable window, and uninstalled successfully in **functional CI**. **Not publicly downloadable.** | [Windows installer/polish PR #551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551) and [test evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40639023133) |
| **Legacy Aetherwake browser/desktop prototype** | Historical playable implementation on `main`, using JavaScript/p5.js and the older Chapter I sequence. **Not** the new Godot game. | See [Legacy reference build](#legacy-reference-build) and [GitHub Releases](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/releases) for separately labeled older releases |

**There is no approved new Godot `Download for Windows` installer link yet.** The Windows functional test passed; the separate Windows Defender-on security prerequisite remains unresolved on the hosted runner, and signing, on-device player acceptance, creator release approval, and actual publication are outstanding. Draft releases, workflow logs, and earlier Aetherwake installers must **not** be presented as the new game download. No player should be asked to disable Windows Defender.

**Intended finished experience:** click **Download for Windows** in this README → download the verified Godot setup file → install normally → launch from a desktop/Start menu shortcut → play in a resizable, maximizable game window, with F11 / Alt+Enter full-screen. No editor, Python, terminal, or browser will be needed by players.

## Current development — what is real

The active engine for **new gameplay** is **Godot 4.7.2 / GDScript**, not the legacy JavaScript runtime. The newer work remains on independently tested **draft branches** rather than being silently projected onto `main`.

| Area | Current evidence | What remains open |
|---|---|---|
| **Chapter I gameplay** | [#547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547): Godot enters the revised Ender → Ionia opening, performs engineering checks, flies the Aureate Wake, settles through real local 2D physics, restores Ender control after splashdown, and saves/loads a separate postflight checkpoint. [Native test: 48 checks PASS](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40636277938). | Human playtest, refined art/audio, full chapter continuity and approved production save progression |
| **Aureate Wake cinematic visuals** | [#546](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/546): original-source 3D ship in a wide Godot view, phase-warning VFX and real physics-driven splashdown. [Native graphical tests PASS](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40634568090). | Production ocean, atmosphere, finished hull/helm art, animation and artist acceptance |
| **Next chapter and ship detail** | Separate drafts [#548](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548), [#552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/552), and [#553](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/553) advance follow-on chapter progression and ship presentation. | Cohesive review and deliberate integration; passing individual branches does not mean a combined game |
| **Windows delivery** | [#551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551): real NSIS setup, Start/desktop shortcuts, Windows Installed Apps registration, safe uninstall and native maximize/restore **all passed functional Windows QA**. | Separate Defender/security gate, signing, final install/play acceptance, publication approval and live README asset link |
| **Polish and QA** | [#554](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/554) proposes an explicit Chapter I visual/gameplay acceptance checklist. | Creator validation and evidence-backed promotion to the integrated game |

**Story continuity:** The revised native opening has Ender seeking work from Captain Ionia, who joins **before** the Aureate Wake's first test flight. The emergency water landing comes before later character introductions. Older **Lyra-first** onboarding and `Signal → Crossing → Contact → Choice → Wake` are preserved as *legacy executable/reference behavior*, **not** the intended revised Chapter I chronology. Related historical docs may still need reconciliation; do not merge conflicting quest/save state machines.

## Try the Godot development build

The **`main` branch does not yet contain the new Godot project**. To inspect the currently tested integrated game code:

1. Check out branch `feat/first-wake-game-entry-checkpoint-20261028` from [PR #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547).
2. Open `godot/project.godot` using **Godot 4.7.2 (standard edition)** and press **F5** to launch the project.
3. Play Ender's revised job/engineering/flight sequence. Use the **arrow keys** to move, **E** to interact, and **F** for the first-flight handoff; once in the flight scene, **E** advances the appropriate phase interactions. After actual landing, explore and inspect the reserve. Within the running game **F5 saves** the valid postflight checkpoint and **F9 loads** it.
4. For the polished installer/window behavior, use the separate stacked [#551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551) candidate; do not confuse it with a downloadable release.

This is a **developer preview**, not an uncoached player-accepted finished chapter. A normal installer is the end-user goal; these editor steps are temporary development instructions.

## Direction

- **World:** globe-scale oceans, continents, polar regions and distinct biomes, with local horizon-aware exploration and layered travel. Geography and final art remain subject to creator review.
- **Ship:** a compact Aureate Wake with legible dragonfly silhouette, articulated wings, practical crew living spaces, and deeper capabilities introduced at the appropriate narrative moments.
- **Gameplay:** exploration, character relationships, equipment and magic, a **conventional JRPG formula model**, party resonance and deliberate progression gates, developed as modular native Godot systems. The long-term roster contract remains `ROSTER[5] → ACTIVE_PARTY[1..5]`; individual draft gameplay systems are not yet a merged five-character production combat loop.
- **Visual quality:** authored pixel-art characters in a cohesive cinematic 2.5D world; production materials, weather, music and cinematography must be judged in actual gameplay, not only reference renders.

New content must preserve the character and reveal boundaries in [AGENTS.md](AGENTS.md) and [Canon and reveal policy](docs/CANON_AND_REVEAL_POLICY.md). No prototype or automated test alone grants canon, final art, or release approval.

## Development and provenance

- [Agent handoff index](docs/AGENT_HANDOFF_INDEX.md) — where collaborators start.
- [Godot migration coordination](docs/GODOT_MIGRATION_COORDINATION.md) — legacy vs native branch responsibilities. Its dated branch examples are historical; always inspect current heads.
- [Visual bible](docs/VISUAL_BIBLE.md), [world and ship direction](docs/WORLD_SHIP_VISUAL_DIRECTION.md), [cinematic contract](docs/CINEMATIC_CLIP_CONTRACT.md) — art and presentation authority.
- [Original `main` README snapshot, October 25](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09/README.md) — immutable legacy architecture, JS commands, combat tables and October 6 Aetherwake release evidence.

### Legacy reference build

The preserved JavaScript/p5.js prototype still lives on `main` in `index-embedded.html`, `aetherwake.js` and `modules/`. Its `modules/char-create.js` is a **Historical compatibility adapter; not the normal New Game path**. This history belongs to the older runtime, not the revised Godot story. For **legacy-only development diagnostics**, run a local web server from the repository directory:

```bash
python -m http.server 8080
```

Then visit `http://127.0.0.1:8080/index-embedded.html`. This is **not** how the intended new Godot game will be installed or played. The old Aetherwake Preview 0.1 package evidence and hashes remain in the immutable [historical README](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09/README.md); its player/art acceptance was separate from technical proof.

---

**Created by Andrew Hensel (ndrorchestration).** Legacy filenames and study provenance are retained for reproducibility, not as instructions to extend the old engine. The repository is a public development surface; restricted story answers and unapproved media are deliberately not included.
