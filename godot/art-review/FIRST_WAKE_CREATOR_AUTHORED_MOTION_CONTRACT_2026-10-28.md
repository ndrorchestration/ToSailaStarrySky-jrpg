# First Wake — source-authored four-way motion admission contract (2026-10-28)

**Status:** Native Godot **implementation/physics PASS**, first-party Ionia/Ender reference identities preserved, authored high-fidelity **motion art NOT YET AVAILABLE**, creator art approval **HOLD**. Draft review only, unmerged.

## What is now in the actual playable game

The same real `CharacterBody2D` Ender and Ionia actors accept a private, strict **four-direction / six-frame per direction** transparent atlas as **separate per-frame PNGs**. The motion is driven by the distance the actual physics actor walks—not time-based bobbing, a duplicated still, or a mirrored side view. Facing uses the existing north/south/east/west route and player movement logic.

While on the opening dock:
- **P** switches between private static full-body creator artworks and prior field preview.
- **L** previews golden-hour coloring of those static figures.
- **M** compares original and weathered coastal pier.
- **V** toggles source-accurate dialogue portraits.
- **O** enables/disables **source-authored motion only if BOTH characters have complete, valid private frame sets**. Otherwise Godot displays a clear missing-art message, without changing field art or the story. Leaving motion mode restores the exact previous static-source presentation if one was enabled.

**No new walking frames were generated in this PR.** The original source stills remain unchanged. Existing unapproved old SVG field sprites are retained only as a compatibility fallback and are not promoted as correct canonical art.

## Source-art file contract — two individually authored motion sets

Each character has a PRIVATE local directory:

```text
godot/art-review/creator-motion-private/
  ender/
    manifest.json
    south/00.png ... south/05.png
    north/00.png ... north/05.png
    east/00.png  ... east/05.png
    west/00.png  ... west/05.png
  ionia/
    manifest.json
    south/00.png ... south/05.png
    north/00.png ... north/05.png
    east/00.png  ... east/05.png
    west/00.png  ... west/05.png
```

That is **24 truly drawn frames per character, 48 images total**, each PNG 96×144 RGBA8, with clean transparent background and boots near the defined y136–143 foot-contact guide. Individual files must show correct hair, eye colors, clothing, tools, gear placement and real posture changes without merely mirroring/cropping a source portrait. Six motion phases should show believable opposing leg cycles, foot plants, passing and recovery; no duplicate stills. Distinct N/S/E/W views are mandatory.

Each `manifest.json` must have this shape:

```json
{
  "schema_version": 1,
  "character": "ender",
  "intent": "review_only",
  "source_reference": "Specific original creator-selected character visual-bible/art provenance",
  "directions": {
    "south": ["<64-character sha256 for 00.png>", "... 5 more distinct hashes"],
    "north": ["...", "..."],
    "east": ["...", "..."],
    "west": ["...", "..."]
  }
}
```

Authoring helper, code-only and safe to commit:

`godot/art-review/pipeline/build_private_creator_motion_manifest.py --root PRIVATE_ENDER_DIRECTORY --character ender --source-reference "exact creator art source"`

Repeat for Ionia with `--character ionia`. The script requires **Pillow** in the artist's private Python environment, writes no PNG, refuses incomplete/wrong-size/untransparently filled/repeated/near-identical poses and writes the manifest atomically. Existing manifests require an explicit `--overwrite`. Neither utility nor CI uploads artwork.

**Source identity targets:** user-approved Ionia is the blonde green-eyed naturalist/captain with botanical expedition attire; Ender is the green-haired, goggle-equipped mechanic/Rift Scholar. The older incorrectly generated anime sprites and swapped caption concepts must not be used as final production inputs.

## Production admission conditions

`res://scripts/creator_motion_pack.gd` validates original PNG SHA-256 per file, four independent direction entries, exactly six frames each, 96×144 RGBA8, nontrivial alpha/foot coverage, nonduplicate raw files, sufficiently different adjacent phases and distinct direction-first poses. Its failure leaves the existing playable field art intact. The runtime then switches textures through actual travel distance and facing on Ender/Ionia and hides the prior fallback display, without adding or changing physics bodies.

These checks are intentionally **structural, not subjective**: a visually wrong but technically varied set could still pass. Creator visual acceptance, true anatomy/gear continuity, directional correctness, foot contact in motion, frame-timing feel and performance must be independently reviewed using native screenshots or live playback before production art promotion.

`snapshot()["approved_for_production"]` is always **false** at this stage and no manifest may self-authorize a public release.

## Verified Windows results

Exact tested implementation from the isolated detached Windows Godot 4.7.2 editor:

- Real Godot native import: **PASS**
- Synthetic-only **48-frame** test fixture contract: **87 assertions PASS** in source-optional CI-compatible mode; real private original **static** art adds 3 additional restore checks, **90 assertions PASS** on the Windows machine
- Tested both the Ender player path and Ionia's actual scripted route moving physics actors, updating correct authored-frame pointers by actual traveled distance
- Incomplete, duplicate, SHA-tampered, missing-direction and swapped-identity motion inputs all fail closed
- Existing source-matte display and lighting regression: **30 PASS**
- Existing physical dock material/rollback regression: **21 PASS**
- Full playable First Wake physical water contact, postflight control, save/resume and legacy save isolation: **48 PASS**
- Offline private-manifest Python helper invoked with test-only frames: **PASS**, checksum-bound `manifest.json` generated

**Critical evidence distinction:** the animated images in these tests are deliberately simplified **synthetic test shapes**, not the user's concept-art costumes and not approved animation frames. No fully correct motion render, 4-way 6-phase creator art or Windows installer is claimed. The real original Ionia/Ender static portrait and matte images remain privately present in the Windows test worktree and protected from public GitHub.

New Windows QA workspace: `Desktop/Aetherwake/Verification Sandbox/FirstWake-Motion-Contract-QA-20261028`. The earlier P7 visual worktree remains separate.

## Expert-panel release gates

| Discipline | Gate |
|---|---|
| Narrative and canon | Preserve Ionia-first opening, characters' precise identities and scene reveal order |
| Animation | Independent 4×6 pose art per character; genuine foot plant/weight shift and staff/goggle/hair continuity |
| 2.5D cinematography | Native 960×640 dock, night/coast materials, fixed source-color/lighting comparison with both moving figures |
| Godot engineering | Source privacy, PNG SHA, per-frame alpha/spacing, physics-driven timing, fail-closed fallbacks, memory/performance |
| QA/accessibility | No lost P/O/L/M/V inputs, no texture flicker, readable HUD, full water landing/save and older machine fallback |
| Production | Creator signs off actual motion, publication/source rights, main-branch merge and independent Windows Defender-on installer acceptance |

**Next recommended substantive production:** actually author the 48 source-faithful images. Until then, this is animation *infrastructure* and should remain a draft, not promoted to completed character sprites.

**No merge, public art upload, canon edit, production gameplay state change, release or security bypass occurred.**
