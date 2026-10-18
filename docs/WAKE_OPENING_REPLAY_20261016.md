# Opening replay: reset companion availability

This draft follows #284 exact `b61ef6fcdc973dacccf84a90718bf6b2da636491`. Restarting the opening created fresh story state and selected Ender, but `setActivePartyIds(['ender'])` intentionally retained previously recruited companions' playable flags. A replay therefore began with unavailable-story companions already unlocked despite an Ender-only active formation.

The party service now provides an opening-specific `resetOpeningAvailability`. It validates the existing roster/profile contracts before resetting playable availability to Ender alone, then uses the existing formation/synchronization path. Generic formation changes still retain unlocked companions. Roster/active-party arrays, canonical character objects, the bound Ender/world-player reference and magic-profile references are preserved.

The production opening entrypoint requires this reset contract. It constructs the next opening state locally, performs the party reset, then assigns the new state. A missing contract, unbootstrapped party or invalid profile fails without replacing the retained opening. Profile prevalidation failures also preserve availability.

This is an opening availability/story-reset correction. It does not wipe world progress, inventory, statistics, learned profiles or saved games, and does not establish a complete fresh-save or save/resume implementation.

## Verification

- Initial real-party-service regression RED: after recruitment and restart, playable flags remained `[true,true,true,false,false]`. GREEN after the opening-specific reset. A later explicit late-progress fixture also covers all four companion flags; it is not authorization for opening recruitment.
- The new test executes the actual opening entrypoint and real party service, checks fresh dialogue offset/clues/motion/join history, canonical reference/profile preservation, repeat recruitment without duplicate references, ordinary formation semantics and failure retention.
- Wrong-owner profile fixture verifies both playable flags and prior opening survive prevalidation failure. Unbootstrapped/missing-reset contracts also preserve the prior opening. Same-system reviewer independently passed these additions and found no blocking issue.
- Ten selected opening Node checks pass, plus party-capacity, character-canon-alignment and party-magic-profile integration checks. Syntax checks pass.
- Linux Chromium153 at960×640 completed the opening/Core/world route twice. Between routes the test invokes the actual production `startGame()` entrypoint; it does not simulate a visible restart-menu button or assign game/scene state. Each route then uses physical keyboard events. The restart checks fresh story/exploration fields, canonical references, Ender-only availability; the second route again enforces pre-acknowledgement companion locks, renders all authored dialogue pages, observes motion and completes with Ender+Lyra only. Browser pageErrors were empty. Test-only text/motion collectors reset between runs.
- The new Node regression is explicitly smoke-wired; the existing standalone browser route now performs both runs. Full hosted verification must be bound to the final candidate tree.

No authored text, art admission, recruitment order, progression gate, Windows package, uncoached player acceptance, creator visual approval, main merge, release or public deployment is established. VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING; PROMOTION=NOT_AUTHORIZED.
