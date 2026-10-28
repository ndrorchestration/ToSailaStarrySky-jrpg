# Chapter 1 Beta Roadmap — solo development planning baseline

**Planning date:** 2026-10-28  
**Alpha target:** 2027-03-31  
**Beta target:** 2027-05-31  
**Contingency window:** June–August 2027  
**Status:** planning proposal, not release commitment or proof of completion.

## Evidence boundary
The repository contains a historical browser/p5.js preservation runtime and active native Godot/GDScript development. Current Godot Chapter 1 art, ships, story transitions, JRPG system cohesion and Windows packaging work include multiple **draft, unmerged pull requests**. Passing tests on a draft branch do not establish main-branch behavior, artistic acceptance, shipped Windows artifacts, or a complete Chapter 1. Preserve established Five Lights/celestial canon and the current Ionia-first native opening; treat older Lyra-first browser documents as historical until reconciled.

## Monthly gates
| Deadline | Phase | Evidence required |
|---|---|---|
| 2026-11-30 | Integration foundation | One canonical playable Godot route, consistent opening sequence, verified build, save contract, reproducible capture and smoke checks; Windows install candidate |
| 2026-12-31 | Narrative and JRPG | Core quest progression and playable representative battle, deterministic rules for stats/skills/magic/leveling, save/resume |
| 2027-01-31 | Cinematic environments | Chapter 1-critical locations, ocean, berth, Aureate Wake, coherent materials, lighting, sky/weather and camera; side-by-side native render review |
| 2027-02-28 | Characters and battle | Creator-correct Five Lights visuals, real gameplay animations, enemy/effects/UI integration, encounter balance review |
| 2027-03-31 | Feature-complete alpha | Fresh-save start-to-end unassisted Chapter 1 completion with no debug shortcuts or hard blockers; freeze major feature scope |
| 2027-04-30 | Beta candidate | Independent playtest, visual review, profiling, accessibility, major defect triage |
| 2027-05-31 | Beta decision | No known critical blockers, tested Windows installer/launch/uninstall, compatible saves, verified artifact/commit hashes and creator approval |
| 2027-06-01 through 2027-08-31 | Contingency | Extend only on evidence of unmet gates; do not silently lower beta quality bar |

## Scope and effort assumptions
Baseline 15–25 focused solo hours weekly, with a 20-hour planning scenario, approximately 70% effective productive capacity after coordination, investigation and rework. These are assumptions, not observed velocity. Scope prioritizes the complete Chapter 1 hero route, not production completion of the entire planetary globe, Moon Bridge or submersible traversal. Preserve underlying data/contracts for later expansion. AI-generated code and art studies do not count as accepted playable production until integrated and tested.

## Beta acceptance checklist
- [ ] Complete Chapter 1 narrative start-to-finish without developer commands
- [ ] Character, ship, environments, lighting and effects pass creator-directed cinematic review
- [ ] Combat, stats, leveling, equipment, magic, skill availability and costs agree with documented mechanics
- [ ] Save/resume, scene transitions and story/party state preserve progress
- [ ] No known critical blockers; performance targets defined and measured on Windows test hardware
- [ ] Dialogue presentation, sound, music, UI and accessibility reviewed
- [ ] Fresh-machine download, installer, launch, save, uninstall/reinstall and hashes verified
- [ ] At least five external tester sessions attempted, blockers captured and triaged

## Governance
Every Friday review: exact commit + PR state, playable path, latest native screenshots, passing/failed tests, defects, scope, owner visual approval and date forecast. Keep **verified merged behavior**, **draft candidates**, **historical compatibility runtime**, **planned work**, and **human artistic acceptance** separate. If integration slips, move dependent milestones instead of declaring incomplete work complete. No automatic merge, canon change or public release is authorized by this plan.

## Immediate work (November P0)
1. Audit and deduplicate recent Chapter 1 draft PR stacks; identify exact-head dependencies, conflicts and actual main state.
2. Reconcile Ionia-first Godot opening against legacy Lyra-first README/JS narrative.
3. Promote one native continuous First Wake → berth → story/quest scene path behind tests.
4. Establish one authoritative save version and clean Windows install candidate.
5. Measure a full native capture and first 30-minute unassisted player path before increasing scope.

Related anchors: [GitHub repository](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg), [3D/JRPG cohesion draft PR #582](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/582), [art draft PR #583](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/583), [Windows packaging draft PR #565](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/565).
