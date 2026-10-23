# Aetherwake — ChatGPT / Hermes collaboration contract

**Status:** proposed, read-only handshake pending. **Owner:** Aetherwake creator. **Source of truth:** current `main` and `docs/DEVELOPMENT.md`; existing Aetherwake Notion Operational Control Center for narrative/decision context. This document is a collaboration protocol, **not** authorization to run, merge, deploy, expose secrets, change canon, or override the game's established release process.

## 1. What is connected — and what is not

GitHub issues and reviewable draft pull requests can serve as a durable message queue between ChatGPT and a user-configured Hermes execution agent, **if Hermes has independently demonstrated read and comment access**. A message pasted into a ChatGPT conversation confirms what the user has presented, not the identity, run state, permissions or automatic polling of a third-party agent. The initial capability challenge is [issue #351](https://github.com/ndrorchestration/aetherwake-jrpg/issues/351), `AETHERWAKE-HERMES-20261023-01`. Until a concrete reply can be inspected, `HERMES_CONNECTION=UNVERIFIED` and `AUTOMATED_DISPATCH=NOT_CONFIGURED`.

The Zeta-Pell Autonomous Lattice ([separate research repository](https://github.com/ndrorchestration/AHG-Zeta-Pell-Autonomous-Lattice)) is experimental. Its PID/Kalman/Pell simulations and historic benchmark claims are **not** game-build attestation, runtime agent coordination, a production scheduler, or authorizing governance. A possible future adapter needs a separate reviewed design and empirical admission test; no such adapter is established by this collaboration contract.

## 2. Hard boundaries

- `main` is the authoritative game source and **must be treated as protected by policy**. GitHub's branch metadata inspected 2026-10-23 reports `protected: false`; do **not** assume a server-side protection rule currently enforces reviews or blocks direct pushes. Until GitHub branch rules are independently confirmed/enabled, all agents must refrain from direct `main` writes or merges. `dev/progression-build` is historical, not automatically an up-to-date executable game. Reconcile Hermes' local checkout to the exact source SHA **before** making a patch.
- **First priority** is playable First Wake / Chapter I Preview 0.1 and its honest Windows installation, save/close/relaunch/Continue, native scene evidence, first-frame readiness and uncoached human acceptance. Do not divert the release lane with new world/globe features.
- The native Godot Chapter I track and the isolated cinematic/planetary globe experiment are different product/evidence scopes; scripts, manifests, source SHA and renderer tests do not cross-certify.
- No agent may modify game saves, migration contracts, game canon, character art approvals, CI protection, desktop deploy copies, published installers, credentials, or production configuration without separate explicit creator approval and verified relevant tests.
- Canonical authored cast: Ender, Lyra, Ionia, Reson and Aepex. Any unresolved action, combat authority, reveal, or likeness must remain unresolved rather than invented.
- Protect the existing `docs/PREVIEW_0_1_ACCEPTANCE.md` exact-candidate binding and any later authoritative verified supersession. Do not automatically declare player acceptance based on a smoke test, simulated render, or agent summary.
- No writing to the Zeta-Pell research repo is required for Aetherwake task routing.

## 3. Responsibility split

| Participant | Provisional responsibility | Not permitted by this document |
| --- | --- | --- |
| Creator | Goals, final canon/art decisions, permission grants, release acceptance | Delegation does not itself prove QA passed |
| ChatGPT | Decompose tasks, reconcile Notion and GitHub authority, write bounded issue specs, independently review evidence and draft PRs where possible | Cannot attest it operated the Hermes host or measured a real GPU without evidence |
| Hermes (only once connected/authorized) | Read assigned issues, claim a distinct branch, make scoped changes, run actually available tools, post reproducible evidence and a draft PR | Cannot merge, release, promote canon, access secrets or change save formats |
| GitHub | Issues as mailbox; source history/PRs/CI as immutable links with commit/hash context | Issue comment alone is not agent identity attestation |
| Notion | Decisions, acceptance gates, links and ongoing context | Not an executable code or test authority |

## 4. Handoff protocol (one task, one writer)

1. Create or reuse one issue for one bounded objective. Include `task_id`, exact repository/base SHA, branch owner, allowed files, forbidden files, verification commands, evidence outputs, rollback strategy and checkable definition of done. Do **not** assign or launch an agent merely because the issue exists.
2. Confirm receipt. The actual Hermes instance posts `RECEIVED` with issue number and an **observed** local checkout SHA/branch, tool availability and declared blockers. An unverified pasted message is a useful hint, **not** this GitHub receipt.
3. Post a claim: `CLAIMED by Hermes; branch=agent/hermes/<issue>-<slug>; base_sha=<sha>` or `CLAIMED by ChatGPT; branch=agent/chatgpt/<issue>-<slug>; base_sha=<sha>`. Claims are advisory, **not atomic locks**. Conflicting writers stop and coordinate.
4. Implement on a *distinct* branch, ideally from current `main`, with the minimal necessary files. The owner posts commits, commands, executed test results and any screenshot/log hashes. Avoid edits to deploy copies or source-of-truth docs without explicit scope.
5. Open a **draft** pull request. Reviewer independently inspects diff/base/head SHA, tests and the evidence's provenance, checks the issue's exclusions and surfaces unknowns. Use `TESTED` only for commands actually run on stated platform/commit. Separate `STATIC_PASS`, `SYNTHETIC_PASS`, `NATIVE_PASS`, `ART_REVIEW`, `PLAYER_ACCEPTANCE` and `RELEASE_APPROVAL` — no implied promotion.
6. Await creator/reviewer authority for merge/release. If a task is blocked, record `BLOCKED` plus exact missing capability instead of publishing substitute evidence.
7. Record resolution in the existing Aetherwake Notion Operational Control Center with issue/PR links; do not duplicate the canon or release tracker.

**Suggested task states:** `PROPOSED → ASSIGNED → RECEIVED → CLAIMED → IMPLEMENTED → TESTED → REVIEWED → ACCEPTED`, with `BLOCKED` and `CANCELED` as explicit branches. State advancement requires an issue/PR comment recording owner and observed evidence. This is a human-readable workflow, not an installed state machine.

## 5. Minimum verifiable receipt

```yaml
task_id: AW-HERMES-<issue>
actor: Hermes # a self-reported label, not proof of identity
transport: GitHub issue comment
source_repository: ndrorchestration/aetherwake-jrpg
observed_branch: <branch>
observed_head_sha: <full sha>
work_branch: <branch-or-none>
files_changed: [] # read-only handshake: empty
operations_executed: [] # list exact commands that actually ran
test_results: [] # command, platform, exit code and evidence location
artifacts: [] # exact filenames and sha256, when applicable
not_run: [] # e.g. native Godot 4.7.2, actual Windows install
blockers: []
requested_next_action: <review | permission | clarification | none>
status: OBSERVED # otherwise PARTIAL or BLOCKED
```

Avoid posting API tokens, SSH material, environment dumps, personal machine metadata, credentials or private user data. Minimize log content and sanitize artifact paths. Recheck all claims against the remote repository where possible.

## 6. Current baseline / first handshake

- As inspected through GitHub on 2026-10-23: `main=7364d43c202b2186e2d4eb3c752367afe61ee408`.
- A user-provided Hermes handoff states `dev/progression-build=46b4d73e699fdc4d4c02408753b25c4c06408505`, `npm run test:all` passing, and deploy/build intentionally unsynced. That commit exists, **but those local tests and permissions were not independently observed**. Current `main`'s `package.json` does not define `test:all`. The branch history is divergent; do **not** merge the historical branch or treat its test report as current-main verification.
- First **read-only** assignment: [#351](https://github.com/ndrorchestration/aetherwake-jrpg/issues/351) — verify whether the real Hermes instance can read the issue, post a minimal capability receipt, state exact local and remote SHAs and distinguish historical from authoritative build/test lanes. No code edit, deploy, build or install is requested.
- If handshake succeeds, use one small current-main **tests-only** issue as the first write exercise, with explicit non-release scope. Only then consider machine-side Godot native verification of the isolated cinematic prototype as a separately approved task; never treat it as First Wake release proof.

## 7. Cross-repository coordination and future automation gate

- **Aetherwake queue:** #351 is its read-only handshake, #353 the first tests-only task; use Aetherwake issues and **draft** PRs for Aetherwake implementation.
- **AHG/Zeta-Pell research queue:** [AHG issue #6](https://github.com/ndrorchestration/AHG-Zeta-Pell-Autonomous-Lattice/issues/6) is the active Hermes ↔ ChatGPT coordination record for AHG research. [AHG issue #7](https://github.com/ndrorchestration/AHG-Zeta-Pell-Autonomous-Lattice/issues/7) is closed and reference-only. They are **not** alternate Aetherwake assignment channels. Shared process vocabulary does not transfer scientific evidence or execution authority across repositories.
- **Recommended issue comment tokens:** `HANDOFF/ASSIGN`, `HANDOFF/CLAIM`, `HANDOFF/RESULT`, `HANDOFF/REVIEW`, `HANDOFF/BLOCKED`. A task comment cannot spawn Hermes unless an external, explicitly authorized agent actually reads it.
- **Manual activation today:** The user can invoke their already configured Hermes session with the GitHub issue URL, or—if their runtime is the [Nous Research Hermes Agent](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron)—ask Hermes to schedule a **single** self-contained run. The agent must first read #353, compare its live base SHA, post `HANDOFF/CLAIM`, and stop if it cannot satisfy the tool/auth/repo contract. The assignment comment alone does **not** cause that invocation.
- **Hermes native scheduling is a capability, not a verified connection:** The documented `hermes cron create` command supports one-shot and recurring jobs, and Hermes documents event-triggered cron. This repo has **not** demonstrated any installed cron entry, a running Hermes gateway, authenticated notification receiver, webhook, or automatic GitHub-to-agent delivery. Do not represent it as an operational ChatGPT↔Hermes bridge.
- **No unattended bridge confirmed:** Before automatic GitHub→Hermes→ChatGPT dispatch is advertised or enabled, verify authenticated least-privilege agent invocation, GitHub webhook-signature checking, idempotency/replay prevention, exact task/repository allowlisting, source-SHA checks, secrets isolation, event/receipt logging, user stop controls and a witnessed end-to-end dry run. Do not create a public unauthenticated agent endpoint, poll continuously without permission, or let a scheduler merge/release.
- **Platform policy:** [Aetherwake issue #303](https://github.com/ndrorchestration/aetherwake-jrpg/issues/303) already owns the private-repo `main` branch-protection governance gap. GitHub returned `protected=false`; `GET /rulesets` returned a plan-access 403, not proof of active protection. Do not create a duplicate control-policy issue; do not make the private repo public to access branch rules. Until enforcement is independently demonstrated, manual no-direct-main-write holds remain mandatory.

## 8. Revocation and recovery

Creator can revoke an agent's repository permissions or pause tasks at any time. On ambiguous commands, missing rights, unexpected dirty working tree, changed source SHA, conflicting claim, test failures or potentially sensitive data, agents **stop**, report an exact blocker and leave release/merge untouched. Work remains reviewable in draft PRs, not a hidden local edit.
