# To Sail the Starry Sky — title and repository migration contract

**Decision date:** 2026-10-23  
**Decision authority:** creator's direct instruction  
**Public-facing game title:** **To Sail the Starry Sky**  
**Previous development title:** **Aetherwake**  
**Scope:** branding/documentation and cautious repository-slug transition. This document does not authorize installer release or alter the known-gameplay/canon acceptance gates.

## Naming boundaries

| Surface | Direction |
|---|---|
| New game title, copy, brand pages, eventual title/menu art | **To Sail the Starry Sky** |
| Internal history, SHA-bound proofs, old PRs/issues, source filenames, shipped preview artifacts | Keep historical **Aetherwake** references verbatim |
| The in-world aetherwake phenomenon, First Wake, Five Lights, Auroral Ladder/Rings, existing ship and crew names | **Do not rename** as an automatic consequence of rebranding |
| Repository slug | **ndrorchestration/to-sail-the-starry-sky** when verified by GitHub admin action |
| Moon Bridge | Creator-favored **working name**, deep postgame mystery, not a main-campaign marketing spoiler |
| Preview 0.1 / Windows package identity | Preserve until installer/update/uninstall/save backward compatibility and SHA-bound acceptance can be demonstrated |

## Repo-rename checklist

- [ ] Use an authorized GitHub repo-admin surface to rename the private repo to `to-sail-the-starry-sky`.
- [ ] Verify new `owner/name`, stable repository ID, `main` SHA, and draft PR numbers/heads before and after; do not merge those PRs as part of a branding change.
- [ ] Check old URL redirect; do not recreate the old repository slug because that would invalidate redirects.
- [ ] Update every local clone using `git remote set-url origin https://github.com/ndrorchestration/to-sail-the-starry-sky.git`; verify `git remote -v`.
- [ ] Audit Actions references, Pages/project-site URLs, app/webhook integrations, branch protections/rulesets, hardcoded repository paths, checkouts, README badges, CI logs and external distribution links.
- [ ] Repair the hardcoded repository field in `scripts/capture-player-evidence.js` after ensuring capture-contract fixtures are updated/tested. Historical receipts are immutable.
- [ ] Confirm the existing GitHub issue/PR redirect links and update active central documentation, leaving historical evidence links intact.

## Future source/packaging adoption — **not** an immediate bulk rename

- [ ] Design and approve logo/title screen and title fonts under visual bible.
- [ ] Migrate browser HTML title, visible UI, NW.js window title, package metadata and the Godot native scene title in a dedicated source PR. Keep platform-specific branding coherent.
- [ ] Inventory package scripts, source references, environment variables, stable JS exports, save identifiers, storage keys, installer filename, setup shortcuts, AppData directory and uninstall upgrade behavior *before* renaming.
- [ ] Maintain save migration and old-preview discoverability; prove that previously shipped Preview 0.1 can save/load after update.
- [ ] Run existing `npm run test:all`, browser/packaging/static contracts and exact-head Godot/Windows checks where required, with independently reviewed receipts.
- [ ] Do **not** sync deployment copies or rebuild/publish an executable until independent inspection and explicit deployment authorization.
- [ ] Perform comprehensive title/trademark/storefront clearance before public commercialization. Preliminary searches are not legal clearance.

## Story and marketing discipline

The new title is aspirational in Act I. Later celestial implications may be revealed through exploration, but public first-chapter materials should not spoil the ancient diagram's full-moon clue, the concealed lunar Auroral route, or the life-bearing moon's postgame mystery.

Full moon/auroral creator notes are maintained in Notion rather than reproduced in public-facing README:
- [Title Canon and Lunar Clue](https://app.notion.com/p/403f5bad238b81428c5ec7dc1a8f54ee)
- [Cosmology: Five Lights](https://app.notion.com/p/3ebf5bad238b81e5bb5bda1cc1867b5b)
- [Auroral Rings](https://app.notion.com/p/3ebf5bad238b81f588e5fd008739662f)

## Existing holds

Respect the existing Preview 0.1 release controls, Chapter I/native and Defender QA requirements, independent code review, player visual acceptance and existing PR stack. A title change is **not** a green light for feature expansion, CI bypass, unverified binaries, or deployment.
