# Aetherwake browser preservation — README historical sections (October 2026)

> **Archive only.** This page preserves the browser-era technical run instructions, action-slot and Windows Preview 0.1 evidence as a historical reference. It is **not** the current To Sail the Starry Sky Godot game, an up-to-date mechanic listing, or an authorized installer. Some statements under the historical sections describe their original October 6 verification state, not current release status.
>
> For the currently reviewed native First Wake and its correct **Ionia-first, Lyra-second** recruitment sequence, see [the repository README](../../README.md) and the [Godot project entry](../../godot/project.godot). A draft Windows build still lacks independent Defender custody/security clearance; never bypass it.

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



## Legacy browser quest slice (historical)

The preservation build contains a separate **Signal → Crossing → Contact → Choice → Wake** loop with signal hooks, navigation hazards, encounter and choice consequences. This is retained as earlier browser implementation provenance; it is **not** the revised Godot employment → flight → splashdown → reunion → repair chronology or the complete authored campaign.



## Windows desktop package

The player-facing goal remains **one safe Windows installer/download that launches To Sail the Starry Sky in its own maximizable desktop window**. **No current Godot Chapter I installer is cleared or linked from this README**: the independent Windows Defender custody/security preflight still blocks a new candidate. The details below document the **historical Aetherwake browser-wrapper packaging**, not an installable version of the revised Godot story. Historically, the intended player experience was **download one Windows artifact, launch/install it, and run Aetherwake in its own large resizable/maximizable desktop window**. The desktop presentation defaults to **1440×960** and scales proportionally when maximized, while preserving the 960×640 logical game layout. **Alt+Enter** or **F11** toggles native fullscreen; **Escape** exits fullscreen. Browser/HTTP instructions above are development and diagnostic paths, not the desired end-user experience.

### Archived browser Preview 0.1 verification — October 6, 2026 (not the latest Godot build)

The runtime baseline before the documentation-only reconciliation was `875503662d9a9cff64eb6ec1bbbeedbfcc3ccbe3`. Documentation merges may advance protected `main` without changing player-runtime bytes. The **then-current, October 6** bounded Preview 0.1 remediation/review candidate was PR #250 at exact head `46f50c581d992bf581bb6b6d7961a9421b8b779d`; candidate identity is bound to that exact SHA and artifact hashes, not to a moving `main` pointer.

Technical candidate verification is complete for that exact head:

- hosted smoke run `37557721548`: **PASS**;
- fresh seven-frame player-evidence capture on NeonPC: **CAPTURED** from exact head `46f50c...`;
- title/menu evidence timing: **corrected and observed**;
- prior opaque cyan/teal scanline defect: **not reproduced**;
- local packaged `Aetherwake.exe` first-frame readiness on NeonPC: **PASS**;
- workflow-dispatch Windows run `37559269564`: **SUCCESS** through package build, no-admin installer, exact installed launch, portable verification, SHA-256 manifest, and prerelease publication;
- the published installer was independently downloaded, SHA-256 checked, installed, and launched on NeonPC: **PASS**.

Archived October 6 browser Preview 0.1 candidate (not the current Godot game):

```text
SOURCE_SHA=46f50c581d992bf581bb6b6d7961a9421b8b779d
INSTALLER_SHA256=7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d
PORTABLE_ZIP_SHA256=4c6efc6ea1cecf6468fb983fd8ff5fd5d0ce8645262779551841f663c5326173
TECHNICAL_CANDIDATE_VERIFICATION=PASS
HUMAN_REVIEW=NOT_RUN
VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
```

At the time of this archived evidence, PR #250 awaited human review and had not been merged. **Do not infer its present PR status or availability from this historical record.** The historical Google Drive one-click launchers still point to older candidates and must not be treated as the current acceptance target.

For the exact uncoached human/player acceptance protocol, see `docs/PREVIEW_0_1_ACCEPTANCE.md`.

The earlier browser packaging contract named these intended outputs; they are **not links to an authorized current Godot release**:

- **Aetherwake-Setup.exe** — conventional per-user installer; no administrator elevation; creates normal Start Menu and desktop shortcuts.
- **Aetherwake-Windows.zip** — portable fallback. Extract completely, then run **Aetherwake.exe**.

If Windows Defender flags an executable, do not whitelist or bypass it. Record the exact detection name and SHA-256 so the artifact can be audited.

See `docs/DESKTOP_BUILD.md` for the canonical packaging and verification contract.
