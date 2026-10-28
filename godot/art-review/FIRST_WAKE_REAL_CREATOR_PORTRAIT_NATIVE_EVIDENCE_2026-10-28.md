# First Wake: authentic creator portrait native-Godot evidence — 2026-10-28

**Status:** Actual portrait rendering **VERIFIED**; portrait integration mechanics **PASS**; final visual art **HOLD**; Windows release security **HOLD**. Documentation-only evidence; no source images or screenshots added to the public repo.

## Exact environment and source custody

- Code head actually rendered: `f8f9508bc545e271e36eecf7fa1482889212c635` (stacked draft [PR #578](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/578)).
- Official Windows editor: `Godot Engine 4.7.2.stable.official.ed1daf0bf`.
- Renderer: genuine native OpenGL 3.3 Compatibility, Intel Iris Xe Graphics, 960 × 640 framebuffer. This is **not** a photomontage, generated image, headless solid-color fixture, or browser canvas.
- Workspace: isolated detached Git worktree in a local *Verification Sandbox*. The user's existing desktop visual-review checkout remains unchanged.
- Asset 1: creator-provided **Ender** 432×432 JPEG at `res://art-review/creator-portrait-preview/ender_hifi_review_crop.jpg`; exact source SHA-256 `2e7d296698755157da194275a68f01a96b8e69131e69c0128995fee66895e413`.
- Asset 2: creator-provided **Ionia** 432×432 JPEG at `res://art-review/creator-portrait-preview/ionia_hifi_review_crop.jpg`; exact source SHA-256 `ff38540a3b845f20078989d7523cb2e3e6911a8ff886fe8647c1a46fa3e7c07c`.
- The original source images were copied unmodified from the user's local P4 review ZIP **to the private worktree**, hash verified and imported in the native Godot editor. They were **not** committed to GitHub.
- Code's role tags: `ENDER / RIFT SCHOLAR`, `IONIA / CAPTAIN`. These do not change the established story roles.

## Native checks at exact head — all PASS

| Check | Result |
|---|---|
| Official Godot import of both user JPEGs | Exit 0 |
| `res://tests/first_wake_creator_portrait_preview_test.gd` | PASS, 34 checks (real flyer/interview speaker path and fail-closed later-character guard) |
| `res://tests/first_wake_game_entry_test.gd` | PASS, 48 checks (real water contact, postflight player control, save/resume, legacy save isolation) |
| `res://tests/capture_first_wake_creator_portrait_real_art.gd` | PASS, two actual source-JPEG native GL screenshots, scene story unchanged |
| Ender-to-Ionia visual delta | 299.4 measured by capture script |
| Original default review checkout | Clean/unchanged; test ran in separate worktree |

Two final 960×640 native PNG hashes:

- Ender at genuine job flyer: SHA-256 `e1739b52bca8a391233b713acf084ddf1b1bf32ea13ea35665b1a96814971009`
- Ionia at genuine captain interview: SHA-256 `ff18158df89c0c8334cdcb9586da9d92660ecbfe54366ab17ad713889afa1684`

The full PNGs and `EVIDENCE.json` live only in the creator's local **Aetherwake / Verification Sandbox / FirstWake-CreatorPortrait-Evidence-20261028 / Verified-Head-f8f9508** folder. Added local double-click shortcuts in the user's existing Aetherwake desktop folder to run the isolated First Wake review build and view the actual screenshots. Neither shortcut is a standalone installer, public deployment, nor a released game.

## Actual visual inspection (independent of test PASS)

**Verified positive findings:** both correct creator-supplied faces render visibly; clear distinct character/role captions; correct speaker switched with actual events; 216×216 square full-image presentation; frames remain clear of actor walking collision region and readable dialogue area.

**Unresolved artistic gaps:** real dock environment is visibly simplified geometric/pixel art versus cinematic painterly reference. Current small field-walking character sprites do **not** yet match the exact high-fidelity Ionia/Ender faces, hair and equipment; correct four-direction six-phase transparent motion atlases remain absent/unapproved. Portrait JPGs are stills, not walking animations. This evidence does **not** constitute final JRPG art approval.

## Next authorized production work

1. Move visual investment to **the actual field actors and environment**, not more synthetic screenshots or portrait-frame variants. Correct Ionia and Ender source identity is mandatory.
2. Author separate high-fidelity transparent north/south/east/west motion sets with at least six consistent phase frames per direction, preserve exact source and provenance, confirm correct costume epoch with creator and true foot-plant/occlusion native playback.
3. Upgrade the opening coastal dock environment toward the supplied high-fidelity science-fantasy reference while preserving genuine playable events and physical splashdown. Compare genuine in-engine 960×640 frames, not mockups.
4. Only after visual approval, integrate into the canonical story and work through the separately blocked Windows Defender/installer security evidence. Do not promote source images or public media without creator authorization.

**No merge, release, asset-publication, canon change, gameplay mutation or Windows security bypass was performed.**
