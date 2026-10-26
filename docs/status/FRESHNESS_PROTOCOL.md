# Documentation freshness policy — To Sail the Starry Sky

**Status: proposed operational maintenance policy, draft, 2026-10-26.** This file is public safe and does not supersede the creator's canon or grant a release. The [dated program register](PROGRAM_FRESHNESS_2026-10-26.md) supplies initial evidence.

## Source-of-truth order

1. **Creator-approved story/art/engine decisions** in current creator sources govern content. If public `main` says GDScript for forward gameplay, a passing *isolated* .NET engine study does not overturn that decision.
2. **Observed immutable GitHub commits, exact-head Actions jobs, native logs and signed package hashes** establish implementation and technical testing only, not art or player acceptance.
3. **Current branch/PR refs** establish where code is *now*, not whether an older commit is wrong; never describe a historical head as current after it moves.
4. **Notion project domain ledgers** retain context and decisions; newer evidence is appended in dated supersession notes, not retroactively rewritten.
5. **Concept/proposal/renders/engine-neutral math** must never substitute for native gameplay, target-platform performance or final creator/user acceptance.

## Update protocol

Whenever a development handoff crosses repos or updates a major PR, audit **at least**:
- current public/private repository visibility, default branch SHA, protection and ruleset status (report unavailable endpoints rather than inventing protection);
- major active draft PRs by branch, target base, exact head and same-SHA CI evidence;
- Chapter I native/Windows package/playtest readiness and active Defender/security hold;
- cinematic planet/aurora/native visual studies and visual acceptance separately;
- public and restricted Celestial Arc progress, artifact/source import parity and current disclosure rules;
- source rights/licensing, private secrets/history scan, save-compatibility and creator canon;
- per-source new title and migration decisions, and stale links (Aetherwake legacy pointers);
- actual remote local runner availability vs connected device presence and exhausted quotas.

## Required evidence card fields

`checked_at_utc`; `repo`; `PR_number`; `ref+SHA`; `source_visibility`; `implementation_scope`; `workflow_run_id`; `run_status`; `run_conclusion`; `native_vs_static`; `hardware`; `image_origin`; `human_acceptance`; `known_limits`; `authorized_next_action`.

**Gate status vocabulary:**
- **VERIFIED:** the precise claim was exercised at an identified SHA with a completed successful run.
- **PROPOSED:** design/implementation has not been executed in the target environment.
- **DRAFT-UNMERGED:** source may have passed its own CI but is not admitted to main/production.
- **BLOCKED:** a required condition/security/privacy or host tool prevents advancement.
- **UNKNOWN:** cannot reach exact proof; do not infer success.
- **SUPERSEDED POINTER:** older historical evidence remains valid for its old commit only.
- **ACCEPTED:** requires the appropriate creator/human acceptance evidence, not just CI.

Do not make a single “green” checkbox for all of a game workstream. Engineering, visual acceptance, narrative canon, packaging/Windows, external review and release are **independent gates**.

## Active routing

| Primary area | Correct active issue/ledger |
|---|---|
| Godot native gameplay and Chapter I | [Agent handoff](../AGENT_HANDOFF_INDEX.md), [Chapter I native PR lineage](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pulls), [Chapter I Player Acceptance](https://app.notion.com/p/3e6f5bad238b810d9af7f2abc30efbc5) |
| C# mathematical/numerical globe lab | [#368](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/368) + [#375](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/375) (draft/isolated) |
| Visual fidelity / Creator Ender–Ionia | [#297](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/297), [#350](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/350), [Visual Bible](https://app.notion.com/p/3e3f5bad238b81579019c70c72778e1f) |
| Celestial exploration complete playable journey | [#372](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/372), restricted [private working plan](https://app.notion.com/p/405f5bad238b810999a1ddf012162e72) |
| Public-source/secret rights audit | [#360](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/360), [#373](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/373) boundary-only tests |
| Branch governance and Windows release | [#303](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/303), [#293](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293), [Windows closure runbook](https://app.notion.com/p/3e6f5bad238b81c5af29e8aac6731145) |
| Cross-workstream routing | [Notion Operational Control Center](https://app.notion.com/p/3e0f5bad238b81f1be63d6f8e961612c), [Notion Documentation Authority](https://app.notion.com/p/3e2f5bad238b813cae95ee61e4b517cc) |

## Anti-staleness safeguards

- Keep a **current-as-of** date on summaries. Historical headings remain unchanged. Don't treat “last edited” as “source checked.”
- Append a **freshness delta** and link to this register after source branch heads change. Correct an obsolete “latest/current” claim with a supersession note, not an invented historical rewrite.
- Do not copy restricted lunar/canon material into public documentation. Private GitHub repo visibility is a necessary but insufficient permission check for confidential story files.
- Do not relabel an experimental Godot C# scene as *the* complete JRPG; the user expects a visually exceptional, playable world and Chapter I parity.
- Re-check exact link destinations and moved public repo slug before publication.

**Lifecycle:** This draft is deliberately **not auto-promoted** to main. Creator/reviewer authorization is required for merge; no scheduled status crawler or background task is currently created by this document.
