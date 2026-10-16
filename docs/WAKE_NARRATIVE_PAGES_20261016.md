# Complete authored Wake narrative before exploration

This draft follows #283 exact `9c7a27c6c400066b07e1c5b97e494a1ce5867eec`. In production New Game, the current `lyra_join` scene has four authored lines, but the renderer displayed only the first three and confirmation immediately entered exploration. Its fourth existing line, `A shield-frequency echo and a displaced spatial relation overlap.`, never reached the narrative canvas.

Exploration-enabled sequences 5–8 now page narrative three lines at a time before enabling exploration. The controller supplies a read-only view of the current page and whether more text remains. Confirmation shows the next page with the scene clock intact; only confirmation on the last page enters exploration. The cue reads ENTER NEXT while another page remains, then ENTER CONTINUE. Movement/E remain inactive while reading. The offset resets on scene exit.

No authored text, scene record, party rule, artwork, font or panel geometry changes. Reading all pages does not recruit Lyra or satisfy her acknowledgement gate. Default narrative-only construction and controllers without the paging API retain their existing renderer fallback. States lacking the new offset begin at zero instead of producing an invalid offset.

## Verification

- RED regression reproduced confirmation starting exploration before the remaining authored line. GREEN now observes that line in the real renderer function while the scene remains narrative; rendering does not mutate state and page changes preserve presentationTicks.
- A missing-offset state fixture exposed a second RED invalid-offset case; initialization fallback repaired it. Next-scene first page and the unchanged Lyra acknowledgement/recruitment gate are covered.
- Nine selected Node checks PASS: pagination, motion, controller/input, inspection projection, opening contract, narrative fallback, visual contract, HUD bounds and presentation clock. Syntax checks PASS.
- Same-system reviewer independently passed the pagination, controller/input and motion checks and found no important issue; this is not independent/player acceptance.
- Linux Chromium153 at 960×640 drove actual keyboard input from New Game through the Core and world handoff. Per-page canvas observations confirm all thirteen authored lines across scenes5–8, including Lyra pages of3+1 lines. The collector resets its page observations before waiting for each expected text/cue, preventing earlier pages from satisfying a later-page assertion. The full script retained motion observations, interaction/duplicate-clue/threshold gates, Ender+Lyra party and empty pageErrors. No direct scene/state assignment drives this browser route.
- The new Node check is explicitly smoke-wired. The existing standalone browser route now checks every narrative page; full existing smoke consumes pages through the shared keyboard helper. Final hosted outcome must be read at the candidate tree.

This is a technical story-presentation correction in a scripted route. It does not establish line-delivery quality, creator visual approval, an uncoached player session, Windows packaging, complete Chapter1 acceptance, merge or release. VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING; PROMOTION=NOT_AUTHORIZED.
