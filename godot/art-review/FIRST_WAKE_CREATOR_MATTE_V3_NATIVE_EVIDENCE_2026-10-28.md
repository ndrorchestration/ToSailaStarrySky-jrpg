# First Wake — creator full-body matte refinement P6 (2026-10-28)

**Authority:** Creator-selected five-character expedition sheet remains the source for Ionia (blonde, naturalist captain) and Ender (green-haired, goggles, Rift Scholar). This is **appearance-review art** only. The project's story, role, save, physical flight and landing canon are untouched.

**Status:** Native Windows **technical PASS**, genuine source-art screenshots inspected, **production FIELD_PACK HOLD**. Branch is stacked on draft [PR #583](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/583); do not merge or publish without creator review.

## What visibly changed in the actual game

The original two 1-pose full-body extractions had *only 0 or 255 alpha*, which caused hard edges and trapped ivory background inside limbs. A new, **non-generative** local finishing pipeline:

1. verifies the exact source PNG digests;
2. retracts the alpha edge by approximately one original-source pixel and adds subpixel feathering;
3. extends genuine inward figure colors across transparent edge texels to reduce bilinear paper fringe;
4. removes measured ivory background trapped in hand-specified underarm, leg and ground-gap regions;
5. exports two separately named private RGBA images, with deterministic digest verification.

**No anatomy, hair design, costumes, alternate-facing views, walking frames or proportions were invented.** The previous v1 cutouts and all old walking sprites remain available unchanged.

The existing `P` dock art switch now prefers the refined `*_field_matte_v3.png` when installed locally, falls back to the original v1 static art when unavailable, and otherwise leaves normal actors unchanged. The UI labels the displayed content **STATIC**; moving with the real `CharacterBody2D` cannot be misconstrued as authored foot/leg animation. Press P again to restore the original walkers. No state/save mutation.

## Source custody — private images not committed

| Character | Input unchanged PNG SHA-256 | Refined local matte SHA-256 |
|---|---|---|
| Ionia | `a37f1cde79fbee7b70d2f25ad9b1625fac1c8340f9c162b54f9333491d203f84` | `37d7cc3c852bbf5497e94e38502fb8aa35512f5492cf9a12abdf0eff49b11c49` |
| Ender | `7d95d72e6d8953b0db594511cb2705947925363025e737d2710bc247ee43ec4b` | `8127ec4b87086027887c145fbde72704c61ad1d20d44395b111b3145d98660ca` |

The **code-only** recipe `godot/art-review/pipeline/refine_creator_field_matte_v3.py` can be run with `--input PRIVATE_SOURCE_DIRECTORY --output PRIVATE_OUTPUT_DIRECTORY` in an **isolated** Python environment with OpenCV and NumPy. It checks exact SHA-256 before *and after* processing. It was run against the real local originals and reproduced **both exact refined PNG SHA-256 digests**, with no external source-art upload.

The source sheet, original and refined PNGs, previews, and comparison captures stay only inside the creator's Windows QA sandbox; no private art files are in this GitHub branch.

## Actual native Godot evidence

Tested on the Windows host with **official Godot 4.7.2.stable**, Intel Iris Xe, OpenGL 3.3 Compatibility, genuine **960 × 640** framebuffers, with the creator's original source art installed. The source-only head `43270a29fa40ee70f262a8f4a592578ed50304f7` produced:

- Native Godot editor/source import: PASS
- Native art toggle, source identity, fallback and static-only honesty: **18 checks PASS**
- Full playable First Wake: **48 checks PASS**, including real water contact, postflight player, save/resume, legacy save isolation
- True private-v3 artist-supplied image rendering: PASS

The screenshot script was adjusted to synchronize the actual on-screen P-key status before capture; the exact **capture source head `3edffde9fa5ee4352fd7937075281af669722e6e`** produced:

| Native 960×640 screenshot | Verified SHA-256 |
|---|---|
| Refined creator artwork v3 | `37d64796c36416db8f8a1db1bc40dee96419d0e496d59e5f13a4274b75d3271e` |
| Unchanged original walking fallback | `bd11c81f1bbc07db6760ae52579cf2da240d8b6ecc54b9f289d757a38cae3547` |
| Historic original cutout v1 | `3c64c6aa1f7a973e5680a4109265ccbb661ac285a61c96fbeb855dc55b24a90e` |

The three genuine frames and checksum `EVIDENCE.json` live at the creator's **Desktop / Aetherwake / Verification Sandbox / FirstWake-Field-Matte-V3-20261028**. The existing **SEE FIRST WAKE - Character Art Comparison** desktop shortcut opens a local HTML gallery showing v3, v1 and old walkers. The **PLAY FIRST WAKE - Compare Character Art** shortcut still launches the isolated draft's real F5 game; P toggles the art. None of these outputs is a public installation package.

### Independent judgement

The matting is meaningfully cleaner in 1:1 dark-background alpha inspection; it removes particularly distracting pale background slits between the characters' limbs. At 960×640 the effect is subtle because the actors are small. Their portrait fidelity remains much higher than their field-resolution presentation; the dock and terrain remain stylized/provisional.

**Not approved as completed walking sprites:** still **two full-body static poses, one per character, zero newly authored facing directions, zero true gait frames**. Future work must author source-faithful genuine south/north/east/west poses and multi-frame travel, test staff/tool continuity, boot-ground contact and masking in motion. Do not replace missing directional frames with mirrored or clock-driven fake frames. Environmental art remains a separate quality gate. Windows Defender/installer release approval is separate and remains blocked.

## Review and promotion boundary

The public CI proves source-optional native code import, fallback and First Wake gameplay; it **does not** have the private source PNGs and cannot certify their look. The native Windows screenshots above provide the independent actual-art proof. Neither technical gate implies visual approval. This branch is **draft, unmerged, not published**, with no story or installer authority.
