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
save, airship, audio, character creation, and p5.js.

A file is executable runtime authority only when a supported entrypoint
explicitly loads it or when an explicitly loaded runtime file imports/uses it.

## Retired non-runtime mirrors

The following five historical/modular mirrors were retired in favor of the
integrated `aetherwake.js` runtime. They are no longer in the repository:

```text
modules/core.js
modules/combat.js
modules/world.js
modules/ui.js
modules/ui-adapter.js
```

Before retirement they began with the marker:

```text
NON_RUNTIME_MIRROR
```

They were not loaded by either playable entrypoint. Changes to them did not
change the current playable game. Do not diagnose current gameplay behavior
from a non-runtime mirror — verify the entrypoint script chain and inspect
`aetherwake.js` first.

## Authority markers

`aetherwake.js` must begin with:

```text
PLAYABLE_RUNTIME_AUTHORITY
```

The non-runtime mirrors listed above must begin with:

```text
NON_RUNTIME_MIRROR
```

CI enforces the playable runtime authority marker through `npm run test:runtime-authority`.

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
