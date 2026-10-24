# To Sail the Starry Sky — title and repository migration contract

**Decision date:** 2026-10-23  
**Decision authority:** creator's direct instruction  
**Public-facing game title:** **To Sail the Starry Sky**  
**Previous development title:** **Aetherwake**  
**Scope:** verified source-repository rename, public-visibility dependency hygiene and staged branding/documentation. Public source visibility does **not** authorize installer release or alter the known-gameplay/canon acceptance gates.

## Naming boundaries

| Surface | Direction |
|---|---|
| New game title, copy, brand pages, eventual title/menu art | **To Sail the Starry Sky** |
| Internal history, SHA-bound proofs, old PRs/issues, source filenames, shipped preview artifacts | Keep historical **Aetherwake** references verbatim |
| The in-world aetherwake phenomenon, First Wake, Five Lights, Auroral Ladder/Rings, existing ship and crew names | **Do not rename** as an automatic consequence of rebranding |
| Verified repository slug | **ndrorchestration/ToSailtheStarrySky-jrpg** — public source, stable GitHub repository ID `1372641872` (verified 2026-10-23) |
| Long-term lore | Keep unreleased creator mysteries in access-controlled narrative records, not public branding or README |
| Preview 0.1 / Windows package identity | Preserve until installer/update/uninstall/save backward compatibility and SHA-bound acceptance can be demonstrated |

## Repo-rename checklist

- [x] Owner renamed the repo; current canonical slug verified as `ToSailtheStarrySky-jrpg`. The change also made source visibility **PUBLIC**; this is NOT permission to publish an accepted game build.
- [x] GitHub ID `1372641872` unchanged and base `main` recorded at `7364d43c202b2186e2d4eb3c752367afe61ee408`; draft PR #358 remains open/unmerged. Do not embed a moving PR head SHA as the supposed current identity in this checklist; verify head live for each review.
- [x] Old `aetherwake-jrpg` GitHub metadata resolves to the same stable repository ID (redirect/alias). Do not recreate the old slug.
- [ ] On **each existing clone**, run `git remote set-url origin https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg.git`, then `git remote -v`. Host access and local clone verification are still pending.
- [ ] Audit Actions references, Pages/project-site URLs, app/webhook integrations, branch protections/rulesets, hardcoded repository paths, checkouts, README badges, CI logs and external distribution links.
- [ ] Merge only after independent review/CI the isolated [draft PR #359](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/359) which corrects the hardcoded repository field in `scripts/capture-player-evidence.js` and adds a regression contract. Historical receipts are immutable.
- [ ] Confirm the existing GitHub issue/PR redirect links and update active central documentation, leaving historical evidence links intact.

## Future source/packaging adoption — **not** an immediate bulk rename

- [ ] Design and approve logo/title screen and title fonts under visual bible.
- [ ] Migrate browser HTML title, visible UI, NW.js window title, package metadata and the Godot native scene title in a dedicated source PR. Keep platform-specific branding coherent.
- [ ] Inventory package scripts, source references, environment variables, stable JS exports, save identifiers, storage keys, installer filename, setup shortcuts, AppData directory and uninstall upgrade behavior *before* renaming.
- [ ] Maintain save migration and old-preview discoverability; prove that previously shipped Preview 0.1 can save/load after update.
- [ ] Run the exact candidate's canonical current smoke/targeted contract commands (current `main` does **not** define `npm run test:all`), plus browser/packaging/static and exact-head Godot/Windows checks where required, with independently reviewed receipts.
- [ ] Do **not** sync deployment copies or rebuild/publish an executable until independent inspection and explicit deployment authorization.
- [ ] Perform comprehensive title/trademark/storefront clearance before public commercialization. Preliminary searches are not legal clearance.

## Story and marketing discipline

The new title is aspirational in Act I. Keep unreleased late-campaign, postgame and astronomical mysteries out of public README, issue titles, PR bodies, metadata and promotional documents. Full creative canon details belong in the project's access-controlled narrative workspace.

## Public source exposure review

- [ ] Audit full commit history, issues, attachments, workflows and artifacts for leaked tokens, sensitive records, unpublished licensed assets and unintended story spoilers. A surface-only current-branch scan is insufficient.
- [ ] Check GitHub security settings, secret scanning, dependency alerts, push protection, pages, releases, permissions and webhooks on the renamed repo through an authorized admin surface. Do not presume settings migrated unchanged.
- [ ] Review and correct external metadata, badges and published URLs from the *verified* canonical slug; retain exact historical URLs as provenance where appropriate.
- [ ] Do not add game spoilers or internal Notion canon links to public PR and README content.

## Existing holds

Respect the existing Preview 0.1 release controls, Chapter I/native and Defender QA requirements, independent code review, player visual acceptance and existing PR stack. A title change is **not** a green light for feature expansion, CI bypass, unverified binaries, or deployment.


## Current documentation authority — 2026-10-24

- Active central documentation should use **To Sail the Starry Sky** and the canonical repository `ndrorchestration/ToSailtheStarrySky-jrpg`.
- Historical package names, executable names, source filenames, hashes, receipts, issue/PR text and old repository URLs remain immutable evidence and may continue to say **Aetherwake**.
- Repository visibility is **PUBLIC**, but game release status remains **NOT AUTHORIZED**.
- Current release/native blockers remain separate: PR #347 exact Windows verification, issue #293 Defender disposition, issue #106 hosted runner allocation, creator visual review, and uncoached player acceptance.
- Current collaboration drafts #354 and #357 are test/CI hardening only and do not supersede game or release authority.
