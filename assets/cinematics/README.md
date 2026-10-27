> **CURRENT ENGINE/CANON NOTE — 2026-10-27:** This is the preserved, established **legacy runtime cinematic-clip contract**, not proof that H.264 clips, captures or a reusable Godot 4.7.2 playback pipeline are implemented. Future authored Godot cinematics should reuse appropriate manifest/fallback/provenance/accessibility principles after native integration and verification. *To Sail the Starry Sky* is the current project title. “Dragonfly” historical examples below must not silently represent the protagonists' smaller **Aureate Wake**; the separate **Dragonfly** is a larger Frigate. Keep existing `cinematic-manifest.schema.json` and real manifests intact. [Audit and current visual QA](../../docs/2026-10-27_CINEMATIC_PRODUCTION_ORPHAN_AUDIT.md).

---

# Aetherwake Cinematic Assets

This directory is the canonical runtime landing zone for short authored video clips.

## Directory structure

~~~text
assets/cinematics/
  opening/
  character/
  airship/
  magic/
  bosses/
  world-events/
  endings/
~~~

Git does not preserve empty directories, so category folders should be created when the first real asset for that category is added.

## Required file pair

Every runtime clip must use a same-basename pair:

~~~text
clip-name.mp4
clip-name.json
~~~

Example:

~~~text
dragonfly_tower_sonic_boom.mp4
dragonfly_tower_sonic_boom.json
~~~

The JSON manifest must validate against:

`assets/cinematics/cinematic-manifest.schema.json`

## Naming

Use lowercase kebab-case.

Good:
- `first-dragonfly-reveal.mp4`
- `ender-sonic-boom-tower.mp4`

Avoid:
- spaces;
- version labels in runtime filenames;
- creator names;
- dates unless the date is part of canonical story naming.

Versioning belongs in the manifest and source-control history.

## Runtime target

Primary delivery target:

- MP4 container;
- H.264 video;
- AAC audio when baked audio is used;
- 16:9;
- 1920×1080 master target;
- normally 5–15 seconds.

## Progression safety

Video playback is not allowed to own canonical story progression.

Every clip requires a fallback strategy. A decode/load failure must still permit the intended story-state transition.

## Source masters

High-bitrate source masters, editable project files, prompts, or image-sequence intermediates do not need to ship inside the runtime package unless deliberately required.

Keep player-facing runtime media compact and deterministic.

## Authority

See:
- `docs/VISUAL_BIBLE.md`
- `docs/CINEMATIC_CLIP_CONTRACT.md`
