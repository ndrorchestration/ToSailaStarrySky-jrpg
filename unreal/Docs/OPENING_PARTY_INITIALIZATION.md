# Unreal opening-party initialization

The Explorer now exposes `InitializeFirstWakeStartingParty` for author-supplied Ender combat stats. It checks that First Wake has not started, the party has not been initialized, the character ID is Ender, and combat stats satisfy existing save validation. No production starting values are supplied by this branch.

The companion regression tests use synthetic numeric fixtures, not canonical balance. A level or game-start actor must still obtain approved Ender data and invoke the method. A native Unreal build, test execution, map test and first-save proof remain pending. Existing gameplay and saves are not automatically migrated.

This change is draft only, with no main merge or public release.
