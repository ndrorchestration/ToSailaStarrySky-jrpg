# Party Resonance — native design foundation v0.1

**PROPOSAL / NOT EXECUTABLE.** This public-safe data scaffold cannot apply battle effects, charge resources, advance turns, alter saves, or authorize an actor's combat turn. It is not canon approval or a playable Dual Art.

## Canon boundary

Innate narrative Light identities: Ender—Spirit; Lyra—Water (pink spirit-energy accent retained); Ionia—Earth; Reson—Fire; Aepex—Air. These remain with a protagonist in *all* jobs, including nonmagical martial or technical paths. They are **not** learned spell-school affinities or current action permissions. Older magic profile and production authority must not be overwritten.

## Proposal-level combinations

| Art | Contributors | Emergent behavior |
| --- | --- | --- |
| Tidebound Promise | Ender + Lyra | Shared flowing ward |
| Skyroot Bastion | Ionia + Aepex | Wind-routed projectile cover |
| Embermist Veil | Lyra + Reson | Vapor field with friend-and-foe targeting tradeoff |
| Horizon Relay | Ender + Ionia + Aepex | Coordinated reposition with anchored cover |

All names and effects are provisional. Confluence design requires necessity, emergence and character truth, not additive damage. Cost economics, relationship readiness, equipment/job variants, action reservation, target defense/resistance, FX/UI and progression are **OPEN**.

## Implementation

`godot/scripts/party_resonance_catalog.gd` returns defensive copies of four design definitions with an innate Sigil mapping. `inspect_candidate` gives a **non-authoritative preview**, checking explicit unlocked list, party membership, alive/able state and catalog integrity. Its apparently valid outcome still has `canExecute=false`. `try_execute` always denies. Existing `first_wake_party_combat_authority.gd` remains the combat authorization boundary.

Run on Godot 4.7.2 Standard after project import:

```sh
Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --editor --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --script res://tests/party_resonance_catalog_test.gd
```

The test covers identity, typed-gate refusal, mutation isolation and preservation of native party combat authority. Passing contract tests does **not** imply a working battle cut-in or cinematic acceptance. Next: one isolated Dual Art scene after native shared resolver, costs/rollback and creator-approved unlock semantics. No protected-main merge or release.
