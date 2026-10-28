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
