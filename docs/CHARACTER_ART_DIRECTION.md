# Aetherwake Character Art Direction Contract

This document mirrors the canonical Notion character dossiers for implementation and art production. It intentionally separates **creator canon** from **visual interpretation** and **open visual decisions**.

## Shared art direction

The five protagonists should read as one coherent party: compact heroic proportions, painterly/illustrative portrait treatment, simplified but distinctive costumes, strong silhouettes, warm fantasy-material rendering, and Aetherwake's solarpunk/aether-tech identity. Final Fantasy Tactics is an art-direction reference for proportion/readability/material warmth, not a character-copying target.

Hair color, eye color, ethnicity, and exact costume remain open art-direction decisions unless later creator canon fixes them. **Ender is an explicit exception:** his creator-approved reference now locks very short dark copper-brown/auburn hair and bright green eyes.

| Character | Canon visual constraints | Avoid |
| --- | --- | --- |
| **Ender, 22** | Rift Scholar; slender-to-average and explicitly not especially brawny; anxious, idealistic, intellectually oriented; relatively new aboard the Wake; **very short dark copper-brown/auburn hair; bright green eyes; light freckles; brass/bronze forehead goggles with green lenses**; **main weapon: fighting staff**; study/spatial-aetheric instrumentation/practical shipboard language | bodybuilder proportions; generic wizard robes; generic battle mage; dark medium-length/tousled hair; hazel/light-brown eye substitution; treating staff as required for magic |
| **Lyra, 24** | Adult frequency/dream-sensitive receiver; comparatively untrained; single mother of Talen, age 5; listening/resonance/dream motifs; **main weapon: chakram** | childlike presentation; green nature mage; forest priestess |
| **Ionia, 28** | Captain and owner of the Aureate Wake; Lyra's cousin; caretaker presence; served Captain Denith for 10 years; navigator/sky-lane/Core expertise; **main weapon: mace** | elderly captain; farmer archetype; invented spellcaster identity |
| **Reson, 25** | Young, burly Weapon Master; former military service after paramilitary upbringing; very high durability; **main weapon: sword; confirmed secondary/ranged weapon: assault-style rifle**; pike remains broader weapon-vocabulary/history canon; broadest/heaviest party silhouette | frail build; magic-first silhouette; invented faction insignia |
| **Aepex, 27** | Inventor/machinery specialist/tech-head; formally educated plus self-taught; computers and technology as important as mechanics; relaxed confident systems-specialist posture; diagnostics/interfaces/tools/gizmos; **main weapon: martial arts** | generic wizard imagery; default magic staff; mechanic-only presentation that omits computation |

## Open decisions

Do not silently canonize:
- Lyra's final class or exact magical classification.
- Ionia's secondary/ranged weapon, final class, or any spellcasting identity.
- Aepex's secondary/ranged weapon or final class.
- Reson's invented former-service faction insignia.
- Any protagonist's hair color, eye color, ethnicity, or exact costume **except Ender's hair and eye color, which are creator-locked**.

## Implementation binding

Machine-readable source: `modules/character-canon.js`.

Persistent roster source: `modules/party-state.js`.

Numeric rank-1 stats are balance tuning tagged `PROVISIONAL_NOT_CANON`; they are not evidence for narrative or visual canon.


## Starting weapon authority — 2026-09-28
Creator-approved starting/main weapon identities:
- **Ender:** fighting staff.
- **Reson:** sword; confirmed secondary/ranged weapon is an assault-style rifle.
- **Aepex:** martial arts.
- **Ionia:** mace.
- **Lyra:** chakram.

Secondary/ranged weapon choices for Ender, Aepex, Ionia, and Lyra remain **OPEN**. Do not infer twin handguns, crossbow, staff-ranged tools, or chakram ricochet rules as locked equipment canon yet.

Magic and class abilities are **independent of weapon requirement** unless a future specific skill explicitly states otherwise. Ender's staff is a combat weapon, not a wizard-focus prerequisite.
