# Cinematic Clip Contract

Status: **CANONICAL MEDIA INTEGRATION CONTRACT**
Scope: short authored video clips used at specific plot points.

## 1. Purpose

Pre-rendered clips exist to show moments that would be disproportionately expensive or visually constrained in the normal runtime.

Use them selectively.

Good candidates:

- opening imagery;
- first Dragonfly reveal;
- major protagonist introductions;
- first open-sky departure;
- boss entrances;
- catastrophic environmental events;
- signature air/sonic magic;
- Aether Seal events;
- chapter transitions;
- world-state changes;
- rare master-level or postgame magic.

Routine dialogue and ordinary traversal remain in-engine.

## 2. Preferred duration

Normal target: **5–15 seconds**.

Longer moments should usually be composed from multiple clips or interleaved with in-engine interaction.

## 3. Delivery format

Primary runtime target:

- container: MP4;
- video: H.264;
- audio: AAC where audio is baked into the clip;
- aspect ratio: 16:9;
- master target: 1920×1080.

Higher-quality archival masters may live outside the runtime package.

Do not assume every delivery clip contains music. Music may remain runtime-controlled when continuity is more important.

## 4. Repository layout

~~~text
assets/
  cinematics/
    opening/
    character/
    airship/
    magic/
    bosses/
    world-events/
    endings/
~~~

Every runtime clip should have a sidecar JSON manifest with the same basename. Runtime manifests are validated by `tests/cinematic-manifest-contract.test.js` against the repository contract in `assets/cinematics/cinematic-manifest.schema.json`.

Example:

~~~text
dragonfly_tower_sonic_boom.mp4
dragonfly_tower_sonic_boom.json
~~~

## 5. Manifest schema

Minimum fields:

~~~json
{
  "id": "dragonfly_tower_sonic_boom",
  "version": 1,
  "file": "dragonfly_tower_sonic_boom.mp4",
  "storySequence": "TBD",
  "trigger": "TBD",
  "skippable": true,
  "replayable": true,
  "blocksProgression": false,
  "fallback": {
    "type": "still-or-in-engine",
    "asset": "TBD"
  },
  "audio": {
    "mode": "baked-or-runtime",
    "duckRuntimeMusic": true
  },
  "subtitles": {
    "required": false,
    "track": null
  },
  "nextState": "TBD"
}
~~~

Story-specific fields remain provisional until bound to a canonical plot sequence.

## 6. Runtime requirements

The cinematic subsystem must:

- preload before the trigger where practical;
- fade cleanly from runtime into video;
- preserve or deliberately transition music;
- allow skipping when the manifest permits;
- never dead-end progression if video playback fails;
- fall back to a still or in-engine equivalent;
- return deterministically to the declared next state;
- avoid autoplay assumptions that fail under platform restrictions;
- log media load/decode failures for diagnostics;
- avoid blank screens during decoder startup.

## 7. Fail-closed progression rule

A video is presentation, not authority over game progression.

If playback fails:

1. record the failure;
2. display the fallback;
3. preserve the intended story-state transition;
4. continue safely.

No main-story progression may require a successful codec decode.

## 8. Visual continuity rules

A clip must match the surrounding game in:

- character identity;
- costume;
- Dragonfly configuration;
- location architecture;
- geography;
- time of day;
- weather;
- palette;
- magic behavior;
- story state.

The clip may increase fidelity but may not silently redesign canon.

## 9. Transition design

Where possible:

- first clip frame should visually follow the preceding in-engine shot;
- final clip frame should align with the re-entry scene;
- preserve screen direction;
- preserve major light sources;
- preserve Dragonfly orientation;
- avoid unexplained camera-axis flips.

## 10. Audio policy

Three supported modes:

### Baked
Dialogue/SFX/music are inside the clip.

### Hybrid
Dialogue/SFX baked; runtime score continues or crossfades.

### Runtime-controlled
Video carries no critical audio; runtime controls score and cues.

Select deliberately per clip.

## 11. Accessibility

For clips containing critical dialogue:

- subtitle support is required;
- critical information must remain available after playback;
- skipped clips must not remove necessary exposition;
- replay may be exposed from an appropriate archive/menu when canonically useful.

## 12. Candidate early clips

High-value early candidates:

- opening horizon / first cloud-sea reveal;
- first Dragonfly hero reveal;
- first open-sky departure;
- Ender high-impact air/sonic signature moment;
- major tower-collapse / sonic-boom event;
- first major world-state transition.

## 13. Acceptance gates

A clip is runtime-ready only when:

- canonical story placement is known;
- manifest is complete;
- fallback exists;
- surrounding runtime states are known;
- encoding plays in the target NW.js build;
- skip path works;
- failure path works;
- transition back to gameplay works;
- visual continuity review passes.
