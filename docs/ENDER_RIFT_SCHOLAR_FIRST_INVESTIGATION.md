# Ender — First Rift Scholar Investigation (V46)
**Status:** bounded playable candidate / visual review pending / creator acceptance NOT ESTABLISHED

## Authority and story intent
- Creator-approved rift model C: subtle spatial abnormalities first; traversable portals are rarer, more advanced manifestations.
- Ender's Rift Scholarship combines natural observational aptitude with scientific instruments. He notices an anomaly before using goggles to test it.
- Approved character appearance and realistic cinematic portrait direction unchanged; V46 provisional field art is not promoted into an admitted 64 x 96 production sprite pack.
- The opening plants an Act I observation whose broader significance is investigated across Acts II–V. Do not display an Auroral map, portal, Ring geometry or final cause in this scene.
- Reference canon: Notion Ender Character Dossier; Act-by-Act Campaign Beat Sheet; Auroral Rings & Hemispheric Transit; Campaign Reveal Ledger.

## Player interaction
Location: opening dock walk beside existing closed-route marker (positions 2–5).
1. **Natural perception:** as Ender approaches, a restrained offset-line highlight appears. He observes the distant beacon and dock markers disagree. This happens without equipment and costs nothing.
2. **Press E — field goggles:** optics compare chart and observed reference lines. Instrument error remains possible; no magical detection spell is assumed.
3. **Press E — field notes:** record a repeating discrepancy, mark its cause unknown, and plan to ask Captain Ionia to check navigation charts.
4. Player can continue walking/board normally. The investigation is optional for existing route compatibility; it is independently exercised by the browser smoke test.
5. **Ionia at navigation:** if Ender recorded the observation, Ionia independently checks her route charts and confirms the beacon's recorded location, without asserting what caused the mismatch. Otherwise, her original Core-load response remains unchanged. The browser smoke test covers the conditional corroboration.
6. Notes and Ionia's response remain only in bounded opening session state; they are not persistent save entries.

## Implementation files
- modules/first-wake-opening.js: deterministic discovery, inspect, record, conditional Ionia cross-check and read-only view
- aetherwake.js: E input and player feedback; no new global/world-state writes
- modules/first-wake-visual-stage.js: drawn scene highlight, instrument panel and focused Ender action using existing V46 assets
- tests/ender-rift-investigation.test.js: noticed-before-goggles, range, no automatic permission, repeat idempotence, optional skip and scene-bound containment
- tests/smoke-playwright.js: actual in-browser walkthrough plus optional screenshots using AETHERWAKE_ENDER_CAPTURE_DIR
- .github/workflows/smoke.yml: focused test in hosted validation

## Non-effects / boundaries
- No new school, mastery, magic spell, portal action, job, weapon, equipment bonus or Rift Step admission.
- No changed party join order: Lyra still joins first, Ionia command remains separately authored.
- No Auroral/High Sky unlocking; access remains barred until all five party members and the ship meet full harmonic/stability requirements.
- No save migration, route-knowledge entry, quest permanence, scene-count change or published lore explanation. Ionia's conditional dialogue is an observational cross-check, not a new guaranteed quest step.
- A bounded local field note and Ionia's in-session chart cross-check are not durable campaign evidence. Any persistence, expanded investigation quest, or permanent canon revelation requires its own reviewed story/save contract.
- No production field-art acceptance or final likeness approval. V46 visual candidate remains a draft stack.

## Acceptance gates
- Run npm run test:ender-rift-investigation and npm run test:first-wake-opening.
- Run npm run test:smoke from a clean checkout with Chromium; optionally capture three screenshots by setting AETHERWAKE_ENDER_CAPTURE_DIR.
- Inspect captured image composition, legibility, portrait/sprite relationship and scene continuity before claiming visual PASS.
- Keep feature PR draft until exact-head hosted checks, player review and upstream V46 integration are reconciled.
