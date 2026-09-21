# Runtime Authority

This file defines the executable source-of-truth boundary for Aetherwake.

## Playable runtime authority

The integrated gameplay runtime is:

```text
aetherwake.js
```

Both supported playable entrypoints load that file:

```text
index.html
index-embedded.html
```

The entrypoints also load explicit supporting runtime modules before and after
`aetherwake.js`, including input, combat policy/formula, registries, party,
save, airship state/navigation/UI, audio, character creation, and p5.js.

Current extracted executable support modules include `modules/air-navigation.js`; runtime behavior remains authoritative only when the supported entrypoint actually loads the module.

A file is executable runtime authority only when a supported entrypoint
explicitly loads it or when an explicitly loaded runtime file imports/uses it.

## Non-runtime mirrors

The following files are historical/modular mirrors and are **not** loaded by
either playable entrypoint:

```text
modules/core.js
modules/combat.js
modules/world.js
modules/ui.js
modules/ui-adapter.js
```

They must begin with the marker:

```text
NON_RUNTIME_MIRROR
```

Changes to those files do not change the current playable game.

Do not diagnose current gameplay behavior solely from a non-runtime mirror.
Verify the entrypoint script chain and inspect `aetherwake.js` first.

## Authority markers

`aetherwake.js` must begin with:

```text
PLAYABLE_RUNTIME_AUTHORITY
```

The non-runtime mirrors listed above must begin with:

```text
NON_RUNTIME_MIRROR
```

CI enforces these markers through `npm run test:runtime-authority`.

## Debug runtime projections

The playable runtime exposes its initialized subsystem projections as:

```text
window._world
window._combat
window._charcreate
```

Debug surfaces must use those names. `window.world` and `window.combat`
are not authoritative projections and must not be used to report load state.

## Migration direction

The mirrors are not intended to remain parallel sources indefinitely.

When a subsystem is genuinely extracted from the integrated runtime, the target
architecture is:

```text
entrypoint -> loaded runtime module -> one authoritative implementation
```

not:

```text
aetherwake.js -> generated or manually synchronized mirror
```

Until extraction is explicit and covered by the runtime-authority contract,
`aetherwake.js` remains the gameplay authority.

## Fail-closed rule

If the script chain, authority markers, mirror classification, or debug
projection contract drifts, CI must fail rather than allowing two plausible
runtime authorities to coexist silently.
