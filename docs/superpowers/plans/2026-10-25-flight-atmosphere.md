# Flight atmosphere implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline, with one fresh whole-branch reviewer.

**Goal:** Improve the existing PR #370 coastal flyover's depth, material readability and ambient motion at 960×640.
**Architecture:** A separate presentation node installs reusable sky, water, terrain and foliage materials onto the existing slice. Preserve its terrain sampler, LOD, route, ship geometry and original presentation behind `--baseline` for matched comparison.
**Tech Stack:** Godot 4.7.2 Compatibility, Godot shaders, GDScript study adapter only.
**Spec:** The user's Astra assignment, docs/VISUAL_BIBLE.md and the scoped specification below.

## Scoped specification / constraints
- Study-only: no C# product decision, original PR edits, secrets, saves, Chapter I changes or canon promotion.
- Warm horizon and cool upper sky, cloud strata, moving ocean highlights and shoreline foam; soil/rock/snow separation with restrained foliage motion.
- Native 960×640; deterministic explicit effect clock; pause freezes effects; reduced motion freezes wind/water/cloud movement.
- Quality toggle reduces cloud/water detail without changing geometry or navigation. No new external assets/dependencies.
- Keep geometry and sampled height unchanged. The scene remains local planar auto-flight, not planetary navigation or the approved Dragonfly.
- Capture matched before/after stills, a native movie, and honestly bounded software timings. Visual approval remains open.

## Review focus
- Pause/reduced motion must control shader time, not just ship motion.
- Capture must freeze a requested pose, render warmups, check writes and exit nonzero on failure.
- Shoreline effect must sample existing geometry height, not an unrelated decorative coast.
- Quality changes must preserve navigation and silhouette; runtime toggles must work.
- Native renderer must compile shaders; headless parse alone is insufficient. Frame comparisons are evidence, not artistic approval.

## Task 1: Presentation materials
**Files:** main.gd adapter; new visuals.gd; shaders/*.gdshader; tests/test_visuals.gd.
**Interfaces:** `visuals.bind_terrain(terrain)`, `visuals.set_clock(seconds, reduced)`, `visuals.set_low_quality(enabled)`. Existing `sample_height`, terrain children and `_clock` remain unchanged.
- [x] Add/run failing native test for presentation binding, retained sampler/64 chunks, deterministic effect clock, low/high switch and pause.
- [x] Implement material adapter, bounded height texture, cloud sky, depth-colored water, terrain layers and tiered conifers.
- [x] Run native tests and actual renderer; tune composition/materials from matched frames.
- [x] Commit source and tests.

## Task 2: Evidence and review
**Files:** tests/capture_study.gd, tests/capture_movie.gd, tests/profile_visuals.gd; README and evidence review.
- [x] Capture exact frozen coast/forest/highland states with and without the presentation adapter.
- [x] Capture native 960×640 fixed-step flyover movie; record separate main-loop timing observations and limitations.
- [x] Run original suite, new tests, renderer checks, and final fresh review; fix important findings.
- [ ] Save private deliverables and open a separate draft PR stacked on #370. No merge/release.
