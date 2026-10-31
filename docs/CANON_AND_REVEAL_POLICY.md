# Canon, narrative authority and reveal policy

**Status:** Public-safe digest; **not** a replacement for full creator-controlled narrative records. Effective title and engine overrides below supersede older statements retained in the historical records.

## Creator-established foundations

- Official game title: **To Sail the Starry Sky** (creator decision 2026-10-23). *Aetherwake* may still describe historical work and in-world aether phenomena. **First Wake** is Chapter I.
- An aspirational, emotionally grounded JRPG about finding belonging through travel, repair, curiosity and collaboration; no shallow good-versus-evil cosmology or exposition-only companions.
- Authored playable roster: **Ender, Lyra, Ionia, Reson, Aepex**, joined through the story in that order. The combat/menu target expands from 1 to all 5; never reduce the final architecture to a permanent three-character maximum.
- **Lyra is Talen's mother**; **Talen is 5** and is a non-playable child unless a later creator decision changes this. **Ionia is Lyra's cousin** and a caretaker figure; she is not an elderly farmer.
- **Ionia owns/captains the Aureate Wake** after serving Captain Denith for ten years; Denith died of old age and entrusted the ship to her. Ionia wants it to become a **permanent mobile home**, and Ender's early work helps make that possible.
- Ships, homes, crew bonds, maintenance, meals, individual ambitions, and choices about what a better world looks like should matter mechanically and narratively, not just as fantasy set dressing.
- **The Five Lights** is an important in-world symbol/cosmological research direction; ultimate metaphysics, proposed names, and literal causal ontology are *not frozen canon*. Keep observational phenomena, characters' beliefs, and private authorial truth separate.
- Travel discovery unfolds through ground travel, ordinary flight, reliable sky lanes and later extraordinary navigation. An advanced auroral traversal capability has a **five-protagonist/full-ship-equilibrium access gate**; foreshadowing is not traversal permission.

## Storytelling safeguards

- Do not conflate **Lumen** the established magic domain with **Lumen** a proposed cosmological Light. Nor turn proposed Lights into five ordinary spell schools, five moral alignments, or one culture per Light.
- Preserve distinctions among **soul**, **memory**, **Echo**, **ghost**, **wake**, **dream**, and **reconstruction**. The ontology of consciousness after death is not solved by default.
- Do not invent, publicize or implement Talen's unreleased plot-specific phenomena or powers. He is not a routine playable combat mage, hostage, prophecy device or exposition vessel.
- Research and navigation clues can build gradually through Ender's Rift Scholar methods. Early investigation is not permission to invent a portal network or unlock advanced routes.
- Do not assign final kingdom, continent, ocean, culture, state, ship alias, or moon/postgame mystery details from attractive concept art.

## Restricted late-game material — deliberate omission

Notion contains creator-specified late/postgame celestial-navigation answers. **This public repository deliberately does not reproduce their conditions, clue interpretation, destination details or resolution.** Agents without authorized private story access must label implementation of those details **BLOCKED_ON_RESTRICTED_CANON**, rather than guess. Do not put the full answer in a public GitHub issue, PR description, comment, test name, filename, release note, or marketing material.

The private author-controlled Notion record for the title and restricted narrative contract should be consulted only through approved access; do not copy it into a public location merely to make automated agents more convenient.

## Creator canon additions — ship roles and the Ender/Aepex pairing (2026-10-30)

Stated by the creator in a development conversation on 2026-10-30. Mirrored to the authoritative Notion Narrative & Canon record (verified 2026-10-30); keep GitHub and Notion synchronized without duplicating entries.

- **CREATOR CANON — Ionia and Reson:** Ionia is Captain of the Aureate Wake. Reson, the party's combatant, is also an Ace pilot. This lets Ionia act more as captain and less as the one at the helm herself.
- **CREATOR CANON — Ender and Aepex:** Ender is a harmonic-resonance specialist by natural talent (consistent with his established Resonance/Harmonic affinity in [MAGIC_SYSTEM.md](MAGIC_SYSTEM.md)). By chance he understands a little about how the Wakeheart, the ship's core, works. Ender and Aepex then work together with the team to unlock the ship's potential. Non-diegetic design touchstone only: a complementary-expertise science/engineering duo, with Ender as the resonance expert and Aepex as the engineer.
- **CREATOR CANON — Ender's staff:** Ender keeps his full-length staff. He uses it infrequently until Aepex joins and upgrades it.
- **PROPOSAL (not canon):** Ionia flies by necessity before Reson joins, then hands the helm to Reson and shifts toward command. Aepex's staff upgrade is a recruitment-time event. The current Chapter I opening recruits Ionia first, Lyra second after splashdown; the broader intended order is Ender → Ionia → Lyra → Reson → Aepex. Exact later recruitment timing remains OPEN.
- **OPEN:** whether "Ionia is the helm" in the Wakeheart dialogue is a resonance role or literal steering; what "unlock the ship's potential" means mechanically (no link to restricted late-game material is implied, and anything that depends on it is **BLOCKED_ON_RESTRICTED_CANON**); the exact nature of the staff upgrade.
- **Wording guard:** keep story-facing Wakeheart language at the level of diagnostic resonance, not a core-spirit premise (see [../gap_analysis.md](../gap_analysis.md)).
- **Existing text to review (not changed by this note):** `modules/world.js` lines 133 and 304 and their mirrors in `tosailthestarrysky.js`; `modules/core.js` line 718 ("hand upon the helm"). The legacy JS baseline also makes the staff a primary Ender action (`staffStrike`, two staff charges), which conflicts with "uses it infrequently"; treat that as a Godot design question, not a JS change.

## Open decision examples

- Planet name, continent count and coastlines, governments and borders.
- Local Chapter I dock-vs-islands topology (**AW-WORLD-SURFACE-01**); no A/B/C option has been authorized.
- Dragonfly/Aureate Wake/*The Unfinished Song* naming relationship; exact final interior and wing deployment.
- Auroral network ontology, history, absolute speeds and interregional chronology.
- Cosmological Five Lights names/nature; proposed predecessor cultures.
- Unresolved character classes, magical affinities, final art acceptance and later recruitment timing details.

## Source precedence and status vocabulary

`CREATOR CANON` (explicit) > `ESTABLISHED SPEC / IMPLEMENTED` (verified scope) > `WORKING INTERPRETATION` > `PROPOSAL`; `OPEN` blocks irreversible assumptions; `RESTRICTED` is not public output. Historical claims stay as provenance, not current mandates. Code, Notion and PRs may disagree: document the conflict and defer to newer explicit creator choices, not document edit time.

See [source index](NOTION_SOURCE_INDEX.md), [character locks](CHARACTER_AND_ART_AUTHORITY.md), and [../SPEC.md](../SPEC.md) for implementation-specific contracts.

### 2026-10-30 reconciliation receipt

- Authoritative [Notion Narrative & Canon](https://app.notion.com/p/3e0f5bad238b812bac52c594d1465c29) **already contains** the ship-role and Ender/Aepex decisions, their proposal labels and the October 27 opening override. No second Notion canon entry is required.
- **Aureate Wake** is the dragonfly-inspired protagonists' home vessel; **Dragonfly** is a separate, larger Frigate-class ship. Legacy browser lore that uses Dragonfly in descriptions of the protagonists' vessel requires review; this documentation-only branch does not rewrite historical or executable text.
- Approved character *appearance* does not automatically authorize labels printed in an art sheet as classes, jobs or mechanical abilities. Remain OPEN until creator-directed reconciliation.
- Legacy staff-attack behavior is a **runtime design discrepancy**. No combat action, resource rule or save schema has been changed on this branch.
