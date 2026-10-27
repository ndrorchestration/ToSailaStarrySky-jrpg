> **OCTOBER 27 ENGINE/ART HANDOFF:** Read the [cinematic production + orphan/stale audit](2026-10-27_CINEMATIC_PRODUCTION_ORPHAN_AUDIT.md) for current drafts #402–#411, the independent equipment/weapon-tree branches, still-empty resonance branch, current ship distinction, and reviewer gates. Existing older links below are provenance rather than permission to merge code or overwrite canon.

---

# Agent handoff — documentation routing

**Status:** Public-safe cross-agent reference; created 2026-10-25 from current creator direction, GitHub contracts, and selected Notion records. This is a **navigation and reconciliation layer**, not an approval to integrate, publish or expose restricted story material.

## Required reading by task

| Agent work | Read before implementation |
|---|---|
| Any game change | [../AGENTS.md](../AGENTS.md), [Godot coordination](GODOT_MIGRATION_COORDINATION.md), [../SPEC.md](../SPEC.md) (legacy baseline) |
| Story, character dialog, reveals | [Canon and reveal](CANON_AND_REVEAL_POLICY.md), [Notion source index](NOTION_SOURCE_INDEX.md), [../SPEC.md](../SPEC.md) |
| Character models, sprites, portraits, animations | [Character and art authority](CHARACTER_AND_ART_AUTHORITY.md), [CHARACTER_ART_DIRECTION.md](CHARACTER_ART_DIRECTION.md), [VISUAL_BIBLE.md](VISUAL_BIBLE.md) |
| Ships, world map, terrain, sky, aurora, flight | [World / ship](WORLD_SHIP_VISUAL_DIRECTION.md), [VISUAL_BENCHMARK_SCENE.md](VISUAL_BENCHMARK_SCENE.md), [VISUAL_BIBLE.md](VISUAL_BIBLE.md) |
| Magic, battle, skills, class progression | [MAGIC_SYSTEM.md](MAGIC_SYSTEM.md), [../SPEC.md](../SPEC.md); port semantics before rewriting balance |
| Cinematics | [CINEMATIC_CLIP_CONTRACT.md](CINEMATIC_CLIP_CONTRACT.md) and benchmark scene |
| Builds / validation / release | [DEVELOPMENT.md](DEVELOPMENT.md), [PREVIEW_0_1_ACCEPTANCE.md](PREVIEW_0_1_ACCEPTANCE.md), [Godot coordination](GODOT_MIGRATION_COORDINATION.md) |

## Cross-agent collaboration protocol

**Hermes / Hyperagent Spellcraft / Muse Herald:** do not rely on your own chat memory or a private Notion connection to discover canon. Read this GitHub handoff and follow source links if authorized. A file linked in a draft PR is not in `main` until merged.

- Identify exact branch/commit and whether the task changes *story canon*, *visual direction*, *runtime behavior*, *tests*, or *documentation only*.
- For new content, state the content authority and conflict check (especially character likeness, family relationships, the Dragonfly, map geography and late-game routes).
- Implement GDScript/Godot for new runtime work. Existing JS behavior can serve as a bounded test oracle, not a new gameplay destination.
- Keep chapter-one native work, planetary Godot PR #364, and JS planetary prototypes #349/#363 distinct until deliberate integration.
- Provide proof as **observed facts**, never substitute source static checks for rendered graphics or native Windows acceptance.
- Do not merge drafts or publish binaries based solely on this document.

## Highest-value shared gaps (not accomplishments)

1. Ender and Ionia creator-quality source art / directional animation and grounded First Wake scene, including actual settled native visual evidence.
2. Chapter I complete native scene/quest/party/combat/save parity, not just technical unit contracts.
3. Planetary Godot scene with production-credible ocean/clouds/atmosphere, scale and terrain LOD; global navigation and local horizon must remain distinct.
4. Dragonfly original silhouette, in-engine material and rig, five-character shipboard context.
5. Creator visual/player review, representative performance and Windows export/installed-launch verification.

The existing canonical repository is public: https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg. Review actual branch states before making status claims.
