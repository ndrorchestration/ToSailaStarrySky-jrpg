# Aetherwake autonomous development control

## Authority
This is a draft, reversible development executor, not release authority. Protected `main`, immutable releases, approved character appearances, narrative canon, production asset manifests and formal visual/player acceptance are **human-gated**. Never merge, deploy, publish, release, modify Notion canon, or mark visual/player approval automatically.

## Source of truth
- GitHub repo `ndrorchestration/aetherwake-jrpg`, exact working commit and protected main.
- Notion Aetherwake Operational Control Center, Visual Bible, Narrative & Canon, Character Art Direction; verify latest, do not overwrite historical evidence.
- The queue in `docs/autonomy/QUEUE.json` is an ordered proposal; dependencies checked per task.
- Local runtime checkpoints are in `.autonomy/state.json` (gitignored); upload evidence or use a review PR for durability, never commit secrets.

## Installation
From an isolated cloned checkout of this draft branch on authorized NeonPC/neontic: `node scripts/autonomy/runner.js --dry-run` then `node scripts/autonomy/runner.js --once`. Requires `codex` CLI authenticated on the machine, `git`, Node, and repository tests. Run under standard Windows account with no admin privileges. Only one controller per checkout.

## Behavior
The runner selects the earliest eligible READY task whose dependencies are checkpointed PASS. It first verifies a clean worktree and non-main branch; it then invokes `codex exec` for one bounded task. It writes a local checkpoint with command exit state; nonzero exit is BLOCKED, not success. Completed *implementation* must still be independently tested and recorded before marking PASS; controller records REVIEW_REQUIRED after successful Codex, not PASS.

## Recovery
Inspect `.autonomy/state.json` and generated Codex notes; review changed files. Each attempt now retains bounded stdout/stderr tails, duration, signal and timeout state. For approved exact-head PASS, edit the local checkpoint to PASS after required tests. A BLOCKED attempt remains preserved and is excluded from normal scheduling. After explicit operator review, exactly that task may be retried once per invocation with `--retry-blocked=<TASK_ID>`; the prior BLOCKED record is never deleted and the retry still obeys dependencies, approval gates, lock and 45-minute timeout. No automatic retry loops or recursion. Recommended scheduling: Windows Task Scheduler uses the normal one-task runner only; explicit retry flags are manual recovery actions and must not be placed in the recurring scheduler.

## Dependencies and release gates
Character acceptance via issue #207; Ender art via PRs #261/#262; Chapter 1 rootline and persistence issues #210/#214/#216; preview human acceptance issue #249; artifact quota #222; title branding draft PR #263. No synthetic green labels or unreviewed asset admission.
