# Visual Internal Readiness Review ? V25 exact-head

Status: **DEVELOPER REVIEW / NON-G4 EVIDENCE**
Candidate branch: `docs/visual-v25-readiness-evidence-binding-2026-09-26`
Evidence: eight canonical rendered frames plus repeated-window performance samples. V25 additionally binds local captures to the concrete git HEAD and records working-tree cleanliness.

This review is diagnostic only. It does **not** close G4 and must not be copied into `visual-acceptance-results.json`.

## Internal weighted read

| Category | Weight | V18 | V25 internal read | G4 floor | Finding |
|---|---:|---:|---:|---:|---|
| Cohesion | 20% | 3.7 | 3.9 | 4.0 | Title, flight and combat cohere strongly; dock/world crown and procedural figures remain visibly flatter. |
| Readability | 20% | 4.2 | 4.3 | V21/V22 HUD compression improves hierarchy and art visibility. |
| Appeal | 15% | 3.9 | 4.1 | Painted vistas now carry title, flight and combat convincingly. |
| Identity | 15% | 4.0 | 4.1 | Five protagonist silhouettes and Dragonfly are distinguishable. |
| World depth | 10% | 3.6 | 3.8 | V19/V23 improve near-plane and edge depth; benchmark dock remains flatter. |
| Character quality | 10% | 3.1 | 3.4 | V24 portraits help, but procedural bodies/faces remain the principal finish gap. |
| Ship quality | 5% | 4.0 | 4.2 | Dragonfly has a recognizable silhouette and consistent material language. |
| Production credibility | 5% | 3.8 | 3.9 | Strong scenes are credible; finish consistency is not yet uniform. |

Diagnostic weighted read: **3.99 / 5**. This is not a player score.

## Gate finding

- **G1 style contract:** internally established.
- **G2 character + Dragonfly identity:** identity is internally strong enough to proceed, but character *fidelity* is still below the human acceptance floor.
- **G3 world + UI system:** architecture/readability is internally established; benchmark dock finish remains the weakest world scene.
- **G4 polish + QA:** **OPEN / HUMAN EVIDENCE NOT RUN**.

## Exact-head evidence finding

Previous local manifests could report `LOCAL_UNBOUND`. V25 removes that ambiguity when git is available by recording local `git rev-parse HEAD`, the binding mode, and whether the working tree is clean. CI continues to prefer the explicit PR-head SHA.

## Remaining debt order

1. **Canon-compliant authored protagonist assets** ? further procedural face/body detail now has diminishing returns.
2. **Benchmark dock finish** ? its broad projected crown still reads flatter than the painted world, but it is already at the ~33.4 ms p95 floor. Any improvement should replace cost rather than add cost.
3. **Cross-scene final consistency sweep** ? especially title/opening/world dialogue transitions and text contrast at native Windows scale.
4. **G4 human evidence** ? five-player weighted scoring, same-game grouping and Dragonfly recall on one packaged exact-head candidate.

## V25 decision

Do not declare visual acceptance. The package is close enough that broad code-only polishing is now lower value than targeted asset replacement. The next development tranche should establish a **canon-compliant authored character asset contract and integration path**, while protecting the current runtime and fallbacks.
