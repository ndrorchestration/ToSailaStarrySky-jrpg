# First Wake — creator-reference cinematic dialogue overlay (opt-in art promotion)

**Status:** implementation prototype, not final sprite art, aesthetic acceptance or release. Base exact native Chapter One draft #555 `40e086d04c641ee98cd8bed69f8d2c1021cb0930`. Review-only branch.

## Actual runtime integration

- Native **F5** begins with the existing Ender job flyer and Ionia dock interview; the same dialogue now selects the appropriate cinematic *still portrait* from `first_wake_creator_portrait_preview.gd`. Postflight scenes following genuine water contact similarly show the current speaker during depleted-reserve dialogue. The UI hides outside dialogue.
- Portraits only appear for explicit `ENDER:` and `IONIA:` tags, or a single known standalone speaker. Ambiguous `IONIA / ENDER` without per-line speaker attribution and all later protagonists fail closed; no early Aepex/Lyra/Reson reveals.
- **V** toggles preview visibility at any time. If the image files are missing, gameplay and dialogue continue with original UI, no fallback to old incompatible character SVGs. UI is mouse/input-transparent.
- This is an additive canvas image overlay, not an edited CharacterBody2D, field animation, spell, dialogue script, party save, recruitment or physics change.

## Local creator art required for visible graphics

The draft GitHub code intentionally does **not** contain the creator's supplied cinematic images. Install the separately provided asset files, with exact paths, into the same imported Godot project:

- `godot/art-review/creator-portrait-preview/ionia_hifi_review_crop.jpg` (SHA-256 `ff38540a3b845f20078989d7523cb2e3e6911a8ff886fe8647c1a46fa3e7c07c`)
- `godot/art-review/creator-portrait-preview/ender_hifi_review_crop.jpg` (SHA-256 `2e7d296698755157da194275a68f01a96b8e69131e69c0128995fee66895e413`)

Both are 432×432 **lossy JPEG portrait crops** from the user's supplied latest visual sources, not alpha motion sprites or approved line artwork. Source custody is local in the supplied review package; source assets can be incorporated into a vetted project branch only once provenance, user intent, review/export and repo-publicity checks are satisfied.

## QA evidence boundaries

- `res://tests/first_wake_creator_portrait_preview_test.gd`: official native scene test with synthetic in-memory textures for Ender/Ionia labels, checks actual job dialogue role transitions, input transparency, fail-closed absent external assets, and no party or checkpoint state mutations. The synthetic texture test is **not** a genuine user art render.
- Existing `first_wake_game_entry_test.gd` remains the real First Wake story + physical water contact and save regression.
- Still needed: same-branch authentic OpenGL 960×640 screenshots with installed creator image assets, manual comparison against high-resolution reference, occlusion/text contrast checks, performance, source signoff. The user images are deliberately not in CI, so do not claim native screenshots validate those colors.
- Real Windows QA, Defender security policy, full installer and production gameplay merge are independent HOLD gates.

**Visual source versus story role:** blonde Ionia is still captain/navigator; teal-haired Ender remains Rift Scholar; Aepex inventor, Lyra dream-sensitive mother of Talen, Reson weapon master. Costume and previous approved source conflicts remain under creator review per [visual reference handoff](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/577).

Do not merge without both creator acceptance and actual graphics-available renderer QA.


## P2 — Cinematic framing and actual Godot render evidence (October 28)

The previous 183×290 crop/cover rectangle cut off useful source framing. P2 presents the **same unmodified 432×432 creator portrait** in a 216×216 square, `STRETCH_KEEP_ASPECT_CENTERED`, inside a 236×258 deep-blue/brass dialogue frame at origin (704,269). Bottom edge is **y=527**; the authored First Wake dialogue footer starts at **y=535**. V still toggles visibility; absent creator files still hide the portrait. No dialogue, progression, save or physics changes.

- New official [native Godot 4.7.2 P2 scene/GL workflow](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40663324708) **PASS**: exact original main F5 entry; flyer + Ionia speaker transitions; aspect/card geometry; genuine 960×640 OpenGL framebuffers. The layout render uses two **synthetic 432×432 solid-color test textures** injected in memory, **not** the private creator JPGs. This proves placement, visibility and speaker switching, **not correct visual fidelity**.
- Native frame hashes (runner-local PNGs): Ender `ee7bb88b3566847564746313c5cf4aca51ec0afd50af9b2d7a54868334469807`; Ionia `732f9bff2083f92d158af5f20b1a4d802e6b7c08098e52674a19260ae7632756`.
- Inherited official First Wake gameplay and Ionia native visual tests also passed at P2 exact code head; independent Windows Defender custody remains a separate release gate.
- A local user-delivered **Visual P2** ZIP includes both unchanged verified JPEGs, a fresh-install PowerShell script for the exact older Godot First Wake source, an exact-hash safe upgrade script for prior patch users, and separately labeled image compositing mockups. The ZIP is **not** a Windows game installer and is **not** in public GitHub.
- Still missing: actual native GL capture **with the creator JPG files installed**; explicit creator aesthetic approval; independent transparent 4-direction motion atlases; public-media-release permission and Windows installer security approval.

## P3 — Above-dock cinematic portrait framing and local real-source capture

The P2 screenshot revealed a portrait card overlapping the actual dock walking area. P3 fixes the placement: card `Rect2(704,122,236,258)`, **bottom y380**, fully above the dock physics area (begins near y405), while keeping the full **216×216 uncropped JPG**. Added modest speaker-specific frame accents, accurate `IONIA / CAPTAIN` and `ENDER / RIFT SCHOLAR` role captions, and input-transparent shadow. None of this edits original image bytes or field actors.

**Native proof:** [official Godot 4.7.2 P3 source/collision/speaker+GL workflow](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40665118792), **PASS** at `f9ab9e8ee071071df21fa7bb78c98755b38f4bee`. Real 960×640 OpenGL frame hashes with **test-only synthetic colors**, from actual First Wake dock:
- Ender: `5b7f6d2ffea214b6dd991e917e061b6cadeeb3f6910865cb054bdb65a028a5ea`
- Ionia: `7b4772551c055d3f00eadae495856bd865626c0a27302759793bed1a4fae386d`

**Real artwork validation:** `res://tests/capture_first_wake_creator_portrait_real_art.gd` is an **opt-in local-only capture script** (not run in public CI) that refuses absent or SHA-mismatched source portrait JPGs, runs the *real Ender flyer → Ionia interview* event path, captures two native 960×640 framebuffers to local `user://first_wake_native_portrait_evidence`, and checks rendered portrait changes and unchanged story party. A user-delivered Visual P3 ZIP contains two unchanged source-custody JPEGs, safe fresh/update scripts and a Windows PowerShell wrapper to run the native capture with a user-selected Godot 4.7.2 executable. No actual-source engine screenshot has yet been observed in this tool session; **native test-color PASS is not artist approval**.

**Safety:** public PR remains source-code only, unmerged, no new party members, combat/magic/canon/landing/checkpoints, and no Windows release/Defender gate changes.


## Local Visual P4 — single-launch First Wake + genuine-art screenshot evidence

The previously delivered P3 screenshot wrapper had a local integration mismatch: it searched for a `TSTSS_CREATOR_REAL_ART_CAPTURE_FOLDER` marker and `first_wake_*_creator_native_960x640.png` files; the actual previously bundled Godot SceneTree script emits `REAL_CREATOR_PORTRAIT_CAPTURE_FOLDER:` and writes `first_wake_ender_native_960x640.png` / `first_wake_ionia_native_960x640.png`. This mismatch prevents the wrapper from safely locating the actual engine files. **The standalone source script and its provenance checks remain intact.**

The locally packaged **One-Click Portrait P4** fixes that wrapper agreement and adds:
- `PLAY-FIRST-WAKE.cmd`: a first-run project/Godot file selector and later double-click launcher using the existing native F5 scene. Checks the matching known First Wake main entry, JPG SHA-256 and existing portrait adapter hash; attempts only known safe new installation or older-P2 upgrade, and backs up any patched code.
- `CAPTURE-REAL-ART.cmd`: launches the existing local actual-JPG native Godot script (not synthetic test colors), parses its real stdout completion marker, insists on both original 960×640 PNG files, then copies the PNGs plus an SHA-256 `EVIDENCE.json` to `Pictures/ToSailtheStarrySky/FirstWake-VisualQA/<timestamp>/` for easy retrieval and review.
- `PACKAGE_MANIFEST.json`: offline SHA-256 checks for both user source images and all packaged scripts; screenshot/art acceptance remains false.
- The ZIP is a chat-delivered private local patch; it is **not checked into this public GitHub PR**, is **not a Windows native game installer**, and uses an already-installed Godot 4.7.2 editor and First Wake source project.

**Verified in this tool session:** file/ZIP CRC integrity, original Ionia and Ender source-byte digests, GDScript stdout filename/marker contract and wrapper parsing string agreement. **Not verified:** executing Windows PowerShell, actual local P4 native Godot/JPG capture, artistic fit of genuine framebuffer, full PC installer, Windows Defender release security. The linked [previous exact-head CI](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40665479977) passes synthetic native portrait layout/real First Wake physics; [Windows exact QA](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40665479975) remains blocked by the unchanged Defender custody requirement.

This convenience step has **no changes** to story canon, party recruitment, animations, actor sources, gameplay path, saves, official release claims or the original user-supplied images.
