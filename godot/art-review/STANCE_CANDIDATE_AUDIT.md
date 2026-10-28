# Explicit stance-window candidate audit — native character-art review (UNAPPROVED)

Date 2026-10-27. Scope: only an isolated Godot 4.7.2 lab stacked on PR #469. **Not** an admitted character animation, final costume, Chapter One recruitment, magic job or release.

## The actual problem

PR #469 verified 72 imported SVG frames and their boot-alpha baselines. The candidate source pixel still travels up to **12.00 logical pixels during a held single atlas frame** on real physics routes for each character and direction. The source artwork does not contain artist-confirmed anatomical toe/heel identities or planted-foot windows. Thus we cannot certify contact from the 12 px result or create a genuine planted-foot animation by declaration.

## Explicit provisional hypotheses

`scripts/character_stance_hypothesis.gd` now contains exactly **72 versioned hypothesis labels**: one per Lyra/Aepex/Reson × south/west/north/east × six phase indices.

Per six-phase source sequence, the **screen-left alpha half** is tentatively considered a contact candidate in phases 0–1, **screen-right alpha half** in phases 3–4, and phases 2 and 5 are **unmarked**. These are deliberately consistent placeholder windows across all directions; they are **NOT hand-annotated anatomical feet, real stance truth, left/right character limbs, jump phases or canon**. Side-facing art makes screen-side vs anatomical-side especially ambiguous. Stance and swing sequencing must be replaced by artist-authored data before production.

`character_stance_candidate_overlay.gd` uses the existing raw imported alpha-boot source sample and the actual `CharacterBody2D` world transform to draw an opt-in orange tether from the first observed candidate screen-half pixel to its later world location within that proposed window. Press **K** to toggle only this experimental contact guide. It is independent from **P** (raw alpha support guides). No compensation is applied to movement, sprite X offsets or physics. There is intentionally **no zero-slip claim or artificial cosmetic stabilization**.

## Evidence

`tests/character_stance_candidate_audit_test.gd` requires explicit non-certified labels, schema rejection, 24 left + 24 right + 24 unmarked phase rows, source sample validity, real native physics movement across all routes, candidate per-window coverage for **all 24 character×view×screen-side cases**, reproducible world-space displacement receipts, no hidden approval flags and reversible guide state. An implausible/absent measurement fails the engineering test; *nonzero displacement is recorded as an art deficiency, not treated as a quality pass*.

`tests/capture_character_stance_candidates.gd` captures a real 960×640 Godot OpenGL frame after actual world movement, holds all three character roots at the same positions and frames, and captures guide ON/OFF screenshots, with source full-resolution hashes and bounded private JPEG inspection crops.

These receipts are separate from the exact-GPU/target-platform performance gate. Full screenshots remain runner-local because the artifact upload quota is separately blocked.

## Next quality-critical work

1. Artist-author contact points and anatomical identity in each source pose, using reviewed layered art. Replace each placeholder with approved `stance_left`, `stance_right`, `transition`/unmarked phases.
2. For an accepted stance span, verify planted world contact under moving and turning physics using genuine source pixel positions and tests with bounded drift (rather than automatically offsetting art to fake it).
3. Retune frame cadence / stride and author interpolation as needed, then repeat actual Godot screenshot/movie QA at 1× including motion accessibility and transitions.
4. Keep the Ionia-first Chapter One story, distinct innate elemental energies and combat-job independence untouched. **Draft and unmerged until creator review.**
