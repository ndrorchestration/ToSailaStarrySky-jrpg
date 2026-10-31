# First Wake — authored Ender stat asset startup gate

**Draft source, not native verified.** This branch connects the explicit Ender-only party initialization API to the Explorer's `BeginPlay` via the current `ATSTSSGameMode`. It adds `UTSTSSOpeningPartyData`, an editable Unreal `UDataAsset` with a `StartingEnder` combatant and a **default-false** `bReviewedForPrototype` flag.

The GameMode has an `OpeningPartyData` property with no default asset assigned. At startup, it initializes the new Explorer **only if** the asset is assigned, the review flag is true, and the Ender identity/HP/resource/stat validation succeeds. Otherwise the existing empty-party save protection remains active. The project does not silently generate canonical balance values.

## Unreal Editor setup after native compilation
1. Create a Data Asset of class `TSTSSOpeningPartyData` in the Unreal Content Browser.
2. Enter Ender's reviewed opening combat stats from the authoritative character balance design. Do not use automation-test numbers as game balance.
3. Set `Reviewed For Prototype` only after the source and values have been reviewed.
4. Create/select a GameMode subclass based on `TSTSSGameMode`, assign `OpeningPartyData`, and set it as the intended First Wake map's GameMode. The native C++ GameMode class itself has no asset hardcoded.
5. Start a new First Wake session: verify exactly Ender in the opening party, first save and reload, then Ionia's later authorized join order. Check rejected asset / missing approval / invalid-stat cases.

The `TSTSS.Save.OpeningPartyAssetRequiresReview` Unreal automation test checks all gating combinations using synthetic fixture values. It is not native-executed or artistic approval. The current startup call is an initial integration bridge, not a validated multiplayer/session lifecycle or a complete first playable scene. Native UE 5.8 compile, test runner results, gameplay map and Windows installer remain pending. No changes to main or canonical numbers.
