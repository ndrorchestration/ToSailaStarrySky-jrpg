# Aetherwake Chapter 1 Visual Strike Program

Status: **OPERATOR-READY / GATED**
Parent authority: `docs/VISUAL_BIBLE.md`
Machine-readable contract: `docs/visual-style-contract.json`
Current implementation frontier: `068792a49c38b0d3ba236de5fafa84c9e295c45a` / PR #154

## Program rule
Every visual lane must answer exactly five questions before merge:
1. What exists now? ? baseline evidence, files, screenshots, measured constraints.
2. What exact artifact will be produced? ? named files/specs/sheets/runtime modules.
3. What are the hard specs? ? dimensions, counts, palette, scale, budgets, states.
4. How do we know it is done? ? automated contract + exact-head screenshots + human acceptance evidence.
5. What does it depend on / what does it block? ? explicit gate and downstream lanes.

No visual PR is accepted on intent language such as ?improve,? ?refine,? or ?make more elegant? without the artifact/spec/evidence tuple above.

## Integrator and expert panel
The **Art Director / Integrator** is a merge gate, not a parallel art lane. It resolves conflicts among these specialist lenses:
- Character Design + Animation
- Environment / World Presentation
- Dragonfly / Vehicle Design
- UI / HUD / UX
- Cinematic / Narrative Presentation
- Technical Art / Performance
- Player Acceptance / QA

Each specialist reviews the same exact-head screenshot set. The integrator records one disposition: `ACCEPT`, `REVISE`, or `BLOCKED_BY_DEPENDENCY`.

## Gate graph
`G0 BASELINE_AUDITED` ? `G1 STYLE_CONTRACT_LOCKED` ? `G2 CHARACTER_DRAGONFLY_IDENTITY_LOCKED` ? `G3 WORLD_UI_SYSTEM_LOCKED` ? `G4 POLISH_QA_ACCEPTED`.

A downstream lane may prototype before its dependency closes, but it may not be promoted as visual authority.

## Lane A ? Art Direction / Style Authority
**Exists now:** `VISUAL_BIBLE.md`, seven-frame evidence capture, painted world/battle/interior assets, current 2.5D runtime pass.

**Produces:**
- `docs/visual-style-contract.json`
- `docs/VISUAL_BASELINE_068792A.md`
- `docs/VISUAL_STRIKE_PROGRAM.md`
- later: `docs/art/style-tile.png` and annotated do/don't board.

**Hard specs:** 16-role palette; 960?640 logical canvas; 1440?960 evidence viewport; exact line, camera, scale, UI, performance and acceptance constants in the JSON contract.

**Done when:** contract validator passes; exact-head baseline is complete; no unresolved contradiction with Visual Bible or character canon; Art Director signs `G1`.

**Depends / blocks:** depends on G0; blocks all authoritative asset production.

## Lane B ? Character Design + Animation
**Exists now:** articulated runtime renderer, current character-art library in Drive, creator-canon appearance authority in Notion, legacy pixel fallback.

**Produces:**
- 5 canonical turnaround sheets: front / 3/4 / side / back
- 30 portraits: 512?512, six emotions per protagonist
- 5 gameplay animation sheets and manifests
- `docs/art/characters/character-scale-chart.png`
- updated `modules/character-renderer.js` or replacement atlas-backed renderer

**Hard specs:** idle 8f@8fps; walk 6f@10fps; talk 4f@6fps; focus 6f@12fps; attack 8f@15fps. Relative height order: Reson > Aepex > Ender > Ionia/Lyra. Ender copper/auburn buzz cut + brass goggles + freckles; Lyra long red hair; Ionia shoulder-length curly blond; Reson backwards red cap + light mustache; Aepex dirty-blond undercut + eyebrow notch/tattoos. Portrait/body/sprite identity must match.

**Done when:** 8/10 silhouette identification per protagonist; no canon drift; all animation states run without fallback in benchmark scenes; weighted character-quality score ?3.5 and cohesion ?4.0.

**Depends / blocks:** depends on G1; jointly blocks G2 and final dialogue/combat polish.

## Lane C ? Dragonfly / Vehicle Design
**Exists now:** shared procedural renderer in `modules/dragonfly-visual.js`; current title/background contains a separate painted airship language; scale drift remains.

**Produces:**
- orthographic blueprint: side/top/front/3-4
- silhouette sheet at title/dock/flight/combat scales
- dock, flight, bank, brake, shield, damage states
- runtime authority replacing conflicting ship depictions
- `docs/art/dragonfly/scale-chart.png`

**Hard specs:** body length ?3 adult heights; wingspan ?2.4? body length; ?28% screen width in normal flight; ?25% in combat; paired insect-like wing membranes; readable helm glazing; aether core; warm inhabited cabin detail; four shield-node language preserved.

**Done when:** 9/10 blind silhouette recognition; no scene uses an independent conflicting hull; dock/flight/title/combat scales pass the scale chart; ship-quality score ?4.0.

**Depends / blocks:** depends on G1; jointly blocks G2, flight and title authority.

## Lane D ? Environment / World Presentation
**Exists now:** painted world/battle/interior assets; projected world renderer; dock benchmark; procedural depth layers and props.

**Produces:**
- Chapter 1 environment kit: sky, cloud, island, dock, settlement, ruin, foliage, machinery and prop families
- parallax/depth manifest
- environment scale chart
- exact-head benchmark replacements for title/opening/world/flight/combat backgrounds

**Hard specs:** ?3 immediately perceptible depth planes in every major exterior; 1 foreground occlusion family; 1 playable plane; ?2 mid/far layers; door=1.35 adult heights; crate=0.38 adult heights; atlas ?2048?; no repeated tile pattern may dominate >25% of a hero screenshot.

**Done when:** world-depth ?3.5 and cohesion ?4.0 on all seven evidence frames; no obvious placeholder geometry in benchmark set; runtime stays inside technical budget.

**Depends / blocks:** begins after G1; authoritative propagation waits on G2; blocks G3.

## Lane E ? UI / HUD / UX
**Exists now:** functional dialogue/combat/flight panels with inconsistent density and overlap behavior.

**Produces:**
- 8pt-grid component sheet
- 9-slice panel kit
- typography tokens
- title/dialogue/quest/combat/flight/chapter-card layouts
- 16:9 and 16:10 safe-area diagrams
- runtime UI token module

**Hard specs:** 8px grid; 24px safe margin; 8px radius; 2px stroke; panel opacity 0.78?0.90; body text ?16px logical presentation equivalent; contrast ?4.5:1; max two primary panels simultaneously; UI may obscure ?10% of an enemy tell region.

**Done when:** representative combat HP/status can be located/read in <2s in moderated test; no panel covers critical enemy tell; readability ?4.0; no collision in evidence set.

**Depends / blocks:** depends on G2 plus stable world composition; blocks G3.

## Lane F ? Cinematic / Narrative Presentation
**Exists now:** First Wake staged opening, transition cards, authored path, title and scene-music routing.

**Produces:** shot list + timing sheet for New Game ? world; camera bible; transition spec; selected high-value animatics only where runtime presentation cannot carry the moment.

**Hard specs:** every shot has focal subject, duration band, camera motion rule, entry/exit state and fallback; story-bearing screens never auto-advance only by timer; camera movement must preserve gameplay orientation at handoff.

**Done when:** first-time player can identify protagonist, Dragonfly, immediate objective and next interaction without coaching; opening visual continuity scores ?4.0.

**Depends / blocks:** depends on G2 and core UI tokens; blocks G4.

## Lane G ? Technical Art / Performance
**Exists now:** ~29.85 MB staged desktop runtime; ~26.99 MB assets; 44 runtime module files; exact-head screenshot harness; package and release evidence gates.

**Produces:** performance capture script/report; texture/asset inventory; visual-runtime size delta report; fallback matrix.

**Hard specs:** target 60fps, hard minimum 30fps; target p95 frame 16.7ms, p95 hard limit 33.4ms; isolated single-frame spike hard limit 50ms; GPU memory soft/hard 512MiB/2GiB; ?200 active particles soft limit; scene load target <5s; staged desktop runtime soft limit 50 MB; each visual tranche soft growth limit 5 MB unless documented exception.

**Done when:** every benchmark scene meets hard frame/load limits on the operator Windows machine; no missing-asset fallback breaks play; runtime/package tests remain green.

**Depends / blocks:** continuous lane; can block every merge.

## Lane H ? Player Acceptance / QA
**Exists now:** technical candidate acceptance procedure; seven-frame visual evidence harness; no current blind visual study.

**Produces:** five-player 20-minute visual acceptance record; blind screenshot same-game test; character/ship recognition sheet; confusion log.

**Hard specs:** five players; same-game identification ?80%; Dragonfly recall ?80%; weighted visual score ?4.0; no category below its contract minimum.

**Done when:** G4 evidence is attached to exact candidate; no unresolved visual-blocking defect; technical release evidence is still valid.

**Depends / blocks:** depends on G3 and release candidate; blocks visual acceptance/promotion.

## PR tranches
1. **PR-V1: Baseline + style lock** ? this program, machine contract, baseline scorecard, validator. Closes G0; prepares G1.
2. **PR-V2: Character identity package** ? canonical sheets/portraits/runtime bindings.
3. **PR-V3: Dragonfly identity package** ? blueprint, states, scale and single ship authority. V2+V3 close G2.
4. **PR-V4: World depth kit** ? environment/parallax/prop propagation.
5. **PR-V5: UI design system** ? tokens, components, HUD layouts. V4+V5 close G3.
6. **PR-V6: Opening/flight/combat cinematic polish** ? shot timing, effects, transition and final scene staging.
7. **PR-V7: Performance + blind acceptance closure** ? exact-head benchmarks and human evidence. Closes G4.

## Per-PR required evidence
Every visual PR must contain: exact files changed; before/after screenshots; source commit; visual-contract diff if any; asset/runtime-size delta; relevant automated visual/core/browser tests; performance delta when rendering changes; specialist review notes; integrator disposition; dependency/gate state.
