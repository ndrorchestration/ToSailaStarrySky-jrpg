# To Sail the Starry Sky

**An original science-fantasy JRPG in development.** Formerly developed under the *Aetherwake* name, this project is building a character-led, cinematic 2.5D exploration experience around the **Aureate Wake**, an extraordinary ship whose capabilities unfold through the story.

The repository currently contains **two distinct playable development paths**: an earlier p5.js browser prototype at the root, and a **native Godot 4.7.2 Chapter I review** in [`godot/`](godot/). The revised Godot story opening is under review in unmerged draft PRs; it does not replace the original main-branch gameplay or authorize a new release.

## In-engine visual gallery

### Chapter I: First Wake, salvage and the Aureate Wake

<a href="docs/reviews/native-evidence/2026-10-28-first-wake/chapter1-six-native-stage-frames.svg">
  <img src="docs/reviews/native-evidence/2026-10-28-first-wake/chapter1-six-native-stage-frames.svg" width="100%" alt="Six actual native Godot Chapter I 960×640 render frames showing the waterborne Aureate Wake, a secured provisional berth, the family meeting, the quay cache, the stores annex and the engine workshop">
</a>

*Six **genuine lossless 960×640 native Godot 4.7.2 frames**, verified against original PNG SHA-256 receipts and assembled without altering the screenshots. They represent **deterministic development review scenes**, not a finished visual production pass: provisional ship, shore and salvage geometry, dialogue/UI staging and unapproved material identities. [Source capture run](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40648637058) · [Individual frame SHA-256 records](docs/reviews/native-evidence/2026-10-28-first-wake/README.md). This review graphic is staged on a draft branch, not yet part of the default README.*

### Earlier Ender and Ionia directional studies

<table>
  <tr>
    <td width="50%" align="center">
      <a href="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-south-full.png">
        <img src="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-south-full.png" width="460" alt="Actual 960×640 Godot review rendering: Ender and Ionia facing south at fixed positions in the dock scene">
      </a>
      <br><sub><strong>Ender and Ionia — south-facing native frame</strong></sub>
    </td>
    <td width="50%" align="center">
      <a href="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-east-full.png">
        <img src="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-east-full.png" width="460" alt="Actual 960×640 Godot review rendering: Ender and Ionia facing east at the same scene anchors">
      </a>
      <br><sub><strong>Ender and Ionia — east-facing native frame</strong></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-north-full.png">
        <img src="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-north-full.png" width="460" alt="Actual 960×640 Godot review rendering: Ender and Ionia facing north">
      </a>
      <br><sub><strong>Ender and Ionia — north-facing native frame</strong></sub>
    </td>
    <td align="center">
      <a href="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-west-full.png">
        <img src="docs/reviews/native-evidence/2026-10-21-pr319/joint-fixed-west-full.png" width="460" alt="Actual 960×640 Godot review rendering: Ender and Ionia facing west">
      </a>
      <br><sub><strong>Ender and Ionia — west-facing native frame</strong></sub>
    </td>
  </tr>
</table>

*These are **real, previously committed Godot 960×640 native renderer captures** from the October 21 character-direction review (PR #319), **not** screenshots of the latest Chapter I salvage or save system. They document earlier visual implementation, not approved final character art, a cinematic-quality sign-off, or a released build.*

<details>
<summary><strong>More artwork and native character comparisons</strong></summary>

**Four-way character contact sheet — authentic in-engine render study**

![Four native Godot character views, captured at fixed dock positions](docs/reviews/native-evidence/2026-10-21-pr319/fourway-contact-sheet.svg)

**Ionia front/rear cohesion comparison — archived native render study**

![Ionia V4/V5 front and rear actual native visual comparison, art review only](docs/reviews/native-evidence/2026-10-21-pr325/ionia-front-rear-v4-v5-actual-native-comparison.svg)

**Ender original high-resolution art reference — reference illustration, not a native screenshot**

<img src="godot/art-review/ender-approved-reference.png" width="400" alt="Ender high-resolution character art reference, separate from in-engine review renders">

</details>

**Visual evidence boundary:** The featured Chapter I sheet above now embeds six exact native review frames and includes their verified hashes. Independent full-resolution PNG downloads for those six frames are **not** published as separate files; their lossless pixels are embedded in the SVG review graphic. The v3 saving interface is **not pictured**, and no artistic acceptance or playable release is implied. The earlier directional studies below are from October 21. [Chapter I native gameplay evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40646186594) · [new frame capture evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40648637058).

## Play the native Godot Chapter I review

1. Install **Godot 4.7.2**, open **Godot Project Manager**, and import **[`godot/project.godot`](godot/project.godot)**. The project file is intentionally nested beneath the repository root.
2. Open the imported project and press **F5** (Run Project). The default scene is the preserved original Chapter I review. Press **F8** to visit the revised, *Ionia-first* First Wake prototype; this is an opt-in development route.
3. Use **arrow keys** to walk and **E** to interact. After completing hiring, engineering checks, and the safety review, **F** enters the first-flight sequence. In the revised salvage area, **K** saves and **L** loads its separate v3 review checkpoint; from a fresh revised dock, **J** opts into a prior v3 salvage resume. **F8** returns to the original scene.

The v3 checkpoint and recent in-game visuals are **draft branch features**, not yet merged into the main downloadable build. The planned single-click Windows installer is still **blocked by independent Defender custody/security preflight**, even though other native Godot tests pass; no new release download is advertised here.

## Legacy browser development status

The root **p5.js/NW.js preservation build** remains runnable for historical comparison and regression coverage. It is **not** the source of authority for the revised native Godot story, present combat commands, job/school progression or release status.

- **Historic playable scope:** browser startup, exploration, dialogue/quests, a combat loop and legacy choice outcomes.
- **Historic systems:** browser party state, eight-slot action metadata, formula adapters and progression registries remain in `modules/` and `tests/` as compatibility evidence.
- **Current development focus:** the separate, opt-in native Godot Chapter I review; its original configured scene is preserved while the Ionia-first route and postflight recovery remain draft/unmerged.
- **Five authored protagonists:** a story and roster design commitment, not proof that each currently has finished recruitment, native combat actions, equipment visuals or approved spell schools.

The older [technical specification](SPEC.md) and [development notes](docs/DEVELOPMENT.md) include migration history. Check the exact file and branch before treating their legacy implementation claims as current gameplay.

## Run the legacy browser prototype

Use a local HTTP server for the reliable launch path. The canonical smoke test uses this same model.

From the repository folder:

```bash
python -m http.server 8080
```

Then open:

```text
http://127.0.0.1:8080/index-embedded.html
```

On Windows, you can also use:

```powershell
py -m http.server 8080
```

Opening the file directly may leave the loading screen or produce a blank canvas in some browser configurations because the verified runtime path is served over HTTP.

The development runtime is designed to work offline and uses:

- embedded fonts,
- bundled p5.js,
- embedded/reference loading assets,
- local JavaScript modules,
- optional generated TTS assets when present.

Legacy browser logical canvas: **960×640**.

## Legacy browser controls (not the Godot combat menu)

| Key | Action |
|---|---|
| **WASD / arrows** | Move |
| **E** | Talk / interact / advance dialogue |
| **Q** | Plant Covenant Field |
| **F** | Board / interact with ship |
| **Tab** | Toggle sky / ground layer |
| **L** | Mycelial ledger |
| **M** | Repair Cafe / shop |
| **R** | Character sheet |
| **T** | Quest log |
| **N / Enter / Space** | Start / confirm |
| **C** | Trigger Sky-Predator encounter (development/testing) |
| **1–8** | Combat actions |
| **S** | Secondary combat action when available |

## Combat and Resonance — implementation status

**There is no single approved eight-action combat menu for the current Godot game.** The earlier numbered ability list and level-based unlock claims describe the *legacy JavaScript preservation build*, not a current Chapter I skill tree, combat command layout, or creator-approved progression.

| Source | Verified or implemented scope | What it does **not** establish |
|---|---|---|
| **Native combat formula contracts** | [Godot formula resolver](godot/scripts/first_wake_combat_formula.gd) handles a bounded Ender-oriented subset for damage, analysis, resource handling and recovery; [party combat authority](godot/scripts/first_wake_party_combat_authority.gd) constrains who may use that subset. | A complete five-protagonist battle system, new character abilities, an eight-slot Godot command menu, or production integration into the revised opening. |
| **Playable encounter experiments** | The separate [telegraph encounter](godot/scripts/vertical_slice_encounter.gd) tests turn-based **Guard / Strike** prediction and an **Echo** payoff, as documented in the [combat-direction decision](docs/design/AETHERWAKE_COMBAT_DIRECTION_DECISION_2026-10-21.md). | Final encounter pacing, a timing/reflex system, universal action rules, or production combat balance. |
| **Combined-party Resonance research** | [Proposed Arts metadata](godot/scripts/party_resonance_catalog.gd), [read-only eligibility preflight](godot/scripts/first_wake_resonance_composite_preflight.gd) and a separate [visual/interaction lab](godot/scripts/resonance_dual_review.gd) allow controlled review of candidate combinations. | An unlocked ability in the Chapter I battle menu: composite admission explicitly remains **`canExecute=false`**, with no automatic grant from narrative Lights or story-party membership. |
| **Older browser combat** | The historical eight-slot metadata and level-progression rules remain in [`modules/ability-defs.js`](modules/ability-defs.js) and [`modules/progression-defs.js`](modules/progression-defs.js) for preservation/regression. | The current Godot combat authority, an approved list of spells, or the final skill/unlock economy. |

Combat direction is **strategic, legible turn-based decision-making** with clear telegraphs and meaningful consequences; the eventual full battle UX, equipment integration, party turn economy, magic schools, job progression, Dual/Triple Arts and their original visuals require their own tested production admission. Keep implementation, experiment and canon status separate.

## Party and Chapter I chronology

**Established protagonists:** Ender, Ionia, Lyra, Reson and Aepex. Their respective Five Lights identities are narrative foundations, **not** automatic magic-school abilities, combat actions or Resonance permissions. The production aspiration is a persistent five-character roster with **up to five active protagonists**, but that is an architectural target rather than proof of fully implemented five-character native combat.

**Revised Godot Chapter I review (draft, not merged):**

1. **Ender** starts alone, finds Captain Ionia's employment notice and joins her as a harmonic-levitation engine specialist.
2. **Ionia joins first**, before engineering preparation and the short first test flight of the Aureate Wake.
3. After the engine falls out of phase, the ship makes a physically tested *local 2D* splashdown and a provisional safe berth is reached.
4. **Lyra joins second**, only after Ender and Ionia return safely and the Lyra/Talen family reunion dialogue completes. Talen remains **noncombat**.
5. The adults gather independent clues, form a **working** fuel theory, find two provisional materials in separate review areas, and attempt a physical repair. That restart fails; Ionia's remembered Denith shanty becomes the basis of a **bounded bench alignment hypothesis**, not authorization to relaunch or cast a combination Art.

These events are connected in the revised [opening contract](godot/scripts/first_wake_revised_opening_contract.gd) and reviewed in the [Godot chapter implementation](docs/FIRST_WAKE_SALVAGE_V3_CHECKPOINT_PILOT.md). The original configured Godot Chapter I and the older browser Crossing/party order remain **historical or preserved parallel implementations** until an explicitly reviewed migration; do not describe their Lyra-first order as the revised story canon.

**Save boundary:** The revised opening's preflight-only v2 checkpoint and the opt-in two-area salvage v3 checkpoint are independent of the older Chapter I v1 save. Neither v3 restoration nor story-roster eligibility proves the prior ocean physics again or grants battle rights. [Story-roster / Resonance boundary](docs/RESONANCE_CH1_STORY_ROSTER_BOUNDARY_V0_1.md).

## Legacy browser quest slice (historical)

The preservation build contains a separate **Signal → Crossing → Contact → Choice → Wake** loop with signal hooks, navigation hazards, encounter and choice consequences. This is retained as earlier browser implementation provenance; it is **not** the revised Godot employment → flight → splashdown → reunion → repair chronology or the complete authored campaign.

## Repository layout — current vs historical

| Path | Role |
|---|---|
| [`godot/project.godot`](godot/project.godot) | Nested Godot 4.7.2 project; preserved original Chapter I startup with F8 opt-in revised route in the reviewed draft stack. |
| [`godot/scripts/first_wake_revised_opening_contract.gd`](godot/scripts/first_wake_revised_opening_contract.gd) | Revised **Ionia-first**, Lyra-after-reunion story/evidence gate. |
| [`godot/scripts/first_wake_combat_formula.gd`](godot/scripts/first_wake_combat_formula.gd) | Bounded native JRPG formula contract; not a complete live multi-character combat menu. |
| [`godot/scripts/first_wake_party_combat_authority.gd`](godot/scripts/first_wake_party_combat_authority.gd) | Separate, fail-closed native formula-turn authority; older Crossing roster reflected here must not override revised chronology. |
| [`godot/scripts/vertical_slice_encounter.gd`](godot/scripts/vertical_slice_encounter.gd) | Isolated strategic Guard / Strike / Echo trial. |
| [`godot/scripts/first_wake_resonance_composite_preflight.gd`](godot/scripts/first_wake_resonance_composite_preflight.gd) | Non-executing, read-only combination-Art preflight. |
| [`docs/FIRST_WAKE_SALVAGE_V3_CHECKPOINT_PILOT.md`](docs/FIRST_WAKE_SALVAGE_V3_CHECKPOINT_PILOT.md) | Scoped two-area salvage resume, save limits and verified review flow. |
| [`index-embedded.html`](index-embedded.html), [`aetherwake.js`](aetherwake.js) | Legacy browser entry and preserved integrated JavaScript runtime. |
| [`modules/`](modules/), [`tests/`](tests/) | Historical browser combat/progression implementation and regression checks; **not** a current native ability list. |
| [`SPEC.md`](SPEC.md), [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | Cross-generational design and development reference material; distinguish older implementation statements from new review branches. |

## Verification

Install dependencies and Chromium once:

```bash
npm install
npm run playwright:install
```

Run the architecture contracts and canonical smoke test:

```bash
npm run test:effects
npm run test:registries
npm run test:resolver
npm run test:resolver-integration
npm run test:enemy-metadata
npm run test:combat-input
npm run test:resource-eligibility
npm run test:progression-reachability
npm run test:secondary-action
npm run test:smoke
```

The verification suite covers the playable path from startup through the authored First Wake opening, world/overlay interactions, combat, flight-return seams, and return to the correct originating state. It also verifies roster/reference invariants, effect-vocabulary coverage, registry/runtime equivalence, transactional action affordability, progression reachability, party capacity, magic contracts, air-navigation behavior, live resolver routing, and post-combat write-back into the canonical lead record.

To produce local review material without converting it into acceptance, run:

```bash
npm run capture:player-evidence
```

This creates `evidence/player-acceptance/<source-sha>-<timestamp>/` with screenshots and a manifest whose human/player and visual acceptance fields remain explicitly pending.

## Visual authority

The canonical project-wide visual direction is defined in:

- `docs/VISUAL_BIBLE.md` — project-wide visual language;
- `docs/VISUAL_BENCHMARK_SCENE.md` — first final-quality acceptance scene;
- `docs/CINEMATIC_CLIP_CONTRACT.md` — authored short-video integration rules.

These documents sit above individual art branches. Existing pixel-art recovery work is implementation material and must be reconciled against the visual bible before broad promotion.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and extract the current ability/progression registries — **integrated on `main`**,
4. migrate production combat away from legacy 2D6 branches into explicit JRPG formula/contract resolution while preserving only quarantined compatibility behavior,
5. enforce current learned/unlocked action eligibility before broader mastery-tree work — **integrated on `main`**,
6. replace prototype companion creation with authored roster onboarding,
7. implement school/job/mastery progression,
8. add formation, Dual Arts, and Triple Arts,
9. expand campaign content after the architecture is stable.

Each phase should preserve a working combat loop.

## Provenance

Aetherwake adapts selected code structures, interaction patterns, and reference-game lessons from *Memories* while developing its own setting, characters, narrative, combat/progression model, and authored party structure.

See `memories_adaptation_catalog.md` for the working adaptation catalog.

## Author

Andrew Hensel (ndrorchestration)

## Credits

Reference loading-screen UX and adaptation study: *Memories 0.7.4*. Fonts include VT323 and Press Start 2P. TTS tooling uses Microsoft Edge TTS where generated voice assets are available.


## Windows desktop package

The intended player experience is **download one Windows artifact, launch/install it, and run Aetherwake in its own large resizable/maximizable desktop window**. The desktop presentation defaults to **1440×960** and scales proportionally when maximized, while preserving the 960×640 logical game layout. **Alt+Enter** or **F11** toggles native fullscreen; **Escape** exits fullscreen. Browser/HTTP instructions above are development and diagnostic paths, not the desired end-user experience.

### Current Preview 0.1 release authority — 2026-10-06

The runtime baseline before the documentation-only reconciliation was `875503662d9a9cff64eb6ec1bbbeedbfcc3ccbe3`. Documentation merges may advance protected `main` without changing player-runtime bytes. The current bounded Preview 0.1 remediation/review candidate remains PR #250 at exact head `46f50c581d992bf581bb6b6d7961a9421b8b779d`; candidate identity is bound to that exact SHA and artifact hashes, not to a moving `main` pointer.

Technical candidate verification is complete for that exact head:

- hosted smoke run `37557721548`: **PASS**;
- fresh seven-frame player-evidence capture on NeonPC: **CAPTURED** from exact head `46f50c...`;
- title/menu evidence timing: **corrected and observed**;
- prior opaque cyan/teal scanline defect: **not reproduced**;
- local packaged `Aetherwake.exe` first-frame readiness on NeonPC: **PASS**;
- workflow-dispatch Windows run `37559269564`: **SUCCESS** through package build, no-admin installer, exact installed launch, portable verification, SHA-256 manifest, and prerelease publication;
- the published installer was independently downloaded, SHA-256 checked, installed, and launched on NeonPC: **PASS**.

Current published Preview 0.1 candidate:

```text
SOURCE_SHA=46f50c581d992bf581bb6b6d7961a9421b8b779d
INSTALLER_SHA256=7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d
PORTABLE_ZIP_SHA256=4c6efc6ea1cecf6468fb983fd8ff5fd5d0ce8645262779551841f663c5326173
TECHNICAL_CANDIDATE_VERIFICATION=PASS
HUMAN_REVIEW=NOT_RUN
VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
```

PR #250 is ready for human review but is not merged. The historical Google Drive one-click launchers still point to older candidates and must not be treated as the current acceptance target.

For the exact uncoached human/player acceptance protocol, see `docs/PREVIEW_0_1_ACCEPTANCE.md`.

When a fresh candidate passes the exact Windows install/launch gate, the primary player artifact will be:

- **Aetherwake-Setup.exe** — conventional per-user installer; no administrator elevation; creates normal Start Menu and desktop shortcuts.
- **Aetherwake-Windows.zip** — portable fallback. Extract completely, then run **Aetherwake.exe**.

If Windows Defender flags an executable, do not whitelist or bypass it. Record the exact detection name and SHA-256 so the artifact can be audited.

See `docs/DESKTOP_BUILD.md` for the canonical packaging and verification contract.