# Aetherwake JRPG excellence research — interim synthesis
**2026-10-21 · interim only · exhaustive Deep Research still running**

This note captures a first, source-linked pass that can safely guide low-cost implementation while the larger research run completes. It distinguishes community anecdotes, developer evidence and accessibility guidance. It is **not** a popularity ranking and does not establish that any pattern will make Aetherwake fun without playtesting.

## 1. Places players want to inhabit, not just traverse
**Community evidence / anecdotal:** JRPG players repeatedly praise towns that feel dense, distinctive and lived-in rather than merely large. Examples in r/JRPG discussions emphasize recurring NPC stories, secrets, useful shops, side activities, changing dialogue, strong music and a coherent local theme. Players also explicitly dislike towns that become frustrating mazes or feel bloated.
- r/JRPG, “What JRPGs have the best Town or cities?” (2021): https://www.reddit.com/r/JRPG/comments/mj0m3m
- r/JRPG, “RPGs with the Best Towns and Why” (2023): https://www.reddit.com/r/JRPG/comments/1439h2d/rpgs_with_the_best_towns_and_why/
- r/JRPG, “Favorite towns/cities in JRPGs” (2024): https://www.reddit.com/r/JRPG/comments/1cjtoyv
- r/JRPG, “How would you rate a good JRPG village/town?” (2026): https://www.reddit.com/r/JRPG/comments/1w03md3/how_would_you_rate_a_good_jrpg_villagetown_what/

**Aetherwake implication:** Keep First Wake's dock compact, but make every visible element do more work. One NPC reaction, one optional clue, one prop with a useful interaction, one return-state change and one distinctive audio motif are likely higher-value than making the dock larger. Avoid maze complexity in the first ten minutes.

## 2. Party chemistry matters between major cutscenes
**Community evidence / anecdotal:** Players specifically call out casual party banter during exploration and side activities as a reason companions feel alive. r/JRPG recommendations frequently surface Tales, Persona, Trails and NieR examples for this reason.
- r/JRPG, “JRPGs with excellent party banter” (2025): https://www.reddit.com/r/JRPG/comments/1kw5uw0/jrpgs_with_excellent_party_banter/
- r/JRPG, “JRPGs with a great sense of adventure + focus on the characters in the party” (2022): https://www.reddit.com/r/JRPG/comments/tiiitn/jrpgs_with_a_great_sense_of_adventure_focus_on/

**Aetherwake implication:** Do not make Ionia's first contribution only a quest instruction. Give her one optional observation before the choice and one short reaction after the payoff. Later party members should react to places and each other in small, skippable moments rather than relying entirely on long cutscenes.

## 3. Turn-based combat must earn the player's attention
**Developer evidence:** Atlus' GDC 2025 session on *Metaphor: ReFantazio* explicitly frames the problem as updating command-battle RPG design and describes test play used to gather balance data more reliably and cost-effectively.
- GDC Vault, “Developing 'Metaphor: ReFantazio' and the Potential of RPG Command Battle Systems”: https://www.gdcvault.com/play/1035147

A Game Developer postmortem for *Inkbound* reports that pacing was initially too slow, describes a hybrid design change, and emphasizes iterative player feedback and testing before 1.0.
- Game Developer, “Postmortem: The journey of Inkbound through Early Access”: https://www.gamedeveloper.com/production/postmortem-inkbound-s-journey-in-early-access

**Aetherwake implication:** The new guard→echo→quiet-strike loop is a reasonable prototype because the telegraph changes the best action instead of being decoration. Keep it short and test whether an uncoached player understands *why* guard matters. If the answer is no, improve feedback before adding status systems, elemental charts or combo depth.

## 4. Accessibility is part of game feel, not cleanup
**Guideline evidence:** Game Accessibility Guidelines recommends remappable controls, adjustable font size, clear language, high text/background contrast, interactive tutorials, player-paced text, and avoiding essential information conveyed by color alone. It also recommends options to reduce motion-related effects.
- Remappable controls: https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped-reconfigured/
- Adjustable font size: https://gameaccessibilityguidelines.com/allow-the-font-size-to-be-adjusted/
- Clear language: https://gameaccessibilityguidelines.com/use-simple-clear-language/
- Basic guidelines: https://gameaccessibilityguidelines.com/basic/
- Motion differences: https://gameaccessibilityguidelines.com/avoid-or-provide-option-to-disable-any-difference-between-controller-movement-and-camera-movement/

**Aetherwake implication:** Current text-size control, reduced-motion default and text labels are directionally correct. Next implementation priority should be configurable input actions/controller support and prompts that display the active binding, not hard-coded “E/1/2” forever.

## 5. World identity should be specific and revisitable
**Community evidence / anecdotal:** Recent r/JRPG threads praise worlds that feel pleasant to spend time in and towns whose identities remain memorable through music, layout, culture and recurring change.
- r/JRPG, “What JRPG world(s) do you love spending time in and why?” (2024): https://www.reddit.com/r/JRPG/comments/1fumw4h
- r/JRPG, “What game has the best towns?” (2025): https://www.reddit.com/r/JRPG/comments/1psevxt/what_game_has_the_best_towns/

**Aetherwake implication:** Treat each Aetherwake location as a small emotional identity system: a visual silhouette, a local sound, one social ritual, one practical resource and one evolving detail. The First Wake dock should become recognizable from a screenshot or a few seconds of audio before expanding geography.

## Low-cost / high-impact queue from this interim pass
1. **P0 — Context prompt clarity:** implemented in PR #330 as a stage-aware prompt policy; pure native prompt-model test passes locally at current head.
2. **P0 — Combat attention:** implemented as guard→echo→quiet-strike counterplay; pure native encounter test passes locally at current head. External comprehension not yet tested.
3. **P0 — One reactive NPC beat:** add an optional Ionia line before the decision and a distinct post-payoff reaction; keep it noncanonical until creator approval.
4. **P0 — Active-binding prompts:** replace hard-coded interaction/choice labels with named InputMap actions and keyboard/controller bindings.
5. **P1 — Dialogue history:** let players reread the current short conversation.
6. **P1 — Dock micro-secret:** one optional observation that rewards curiosity but never blocks progression.
7. **P1 — Original signal sound:** a simple original two-note call/answer motif with equivalent visual cue and mute-safe comprehension.
8. **P1 — Cold playtest:** five de-identified sessions using the existing protocol; preserve confusion and negative feedback.
9. **P2 — Additional town/airship content only after the first ten minutes survive playtesting.**

## Current verification boundary
At PR #330 head `720fc910b2cdba0edcb4ff187e6f715988339531`, hosted GitHub Actions jobs are not starting because check annotations report account payment/spending-limit blocking. On authorized Windows host `neontic`, the official Godot 4.7.2 Windows archive was verified against the release SHA-512 manifest, and asset-independent tests pass for choice state, echo counterplay and contextual prompts. A fresh full-scene run on that checkout is blocked by a local imported-texture cache problem; current-head full-scene rendering is therefore not re-established by this pass. Keep the PR draft, do not merge, and retain earlier passing renderer evidence only as historical evidence.

## Research integration gate
The exhaustive research run remains in progress. When it returns, reconcile this note rather than stacking contradictory recommendations. Tag each material recommendation as **developer evidence**, **community anecdote**, **accessibility guideline**, **design inference**, or **Aetherwake playtest evidence**; surface counterexamples; and reprioritize by expected player impact, implementation cost and reversibility.
