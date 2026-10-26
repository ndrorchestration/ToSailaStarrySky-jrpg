# Legacy Windows NW.js / NSIS release: fail-closed hold

**2026-10-26 security response — proposed in isolated draft, NOT merged.**

## Risk and observed source

At public `main=79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09`, the historical `.github/workflows/desktop-package.yml` (original Git blob `0a5479ff5ed551d205444e4b90fc1cc754f8c032`) had:

- `workflow_dispatch` **and** `push` on `main` / `v*` tags.
- `permissions: contents: write`.
- A Windows `NW.js` + `NSIS` packaging/install/launch recipe.
- A final `softprops/action-gh-release@v2` step whose condition allowed publication on **manual dispatch or version tag**.

**Important:** This establishes a *reachable legacy release path*, not proof a release was issued, that the old artifact is presently malicious, or that the latest Godot candidate is infected. The original workflow predates the [active release security hold #293](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293). It does **not** include the later Defender-real-time fail-closed gate. Main [AGENTS.md](../../AGENTS.md) specifies forward **Godot 4.7.2 / GDScript** gameplay, not new JS/NW.js desktop releases.

## Containment in this proposed PR

The live workflow is changed into a minimal, explicitly blocked entrypoint:

1. Remove every `push` and tag trigger; keep manual execution only to fail with an explanatory error.
2. Reduce GitHub token permission to `contents: read`.
3. Remove all Node, NSIS, installer, executable launch and release-upload steps.
4. On PRs that change this workflow, show a harmless status notice so reviewers can see the retirement change without running a historical package.
5. Preserve the complete old release recipe and hashes in immutable Git history; **no flagged binary is fetched, run, restored or whitelisted**.

This protects **this particular legacy workflow only if the draft is reviewed and merged**. It does not attest that every other job, branch, scheduled tool, artifact or historical Git tag is safe; nor does it resolve [branch protection issue #303](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/303) or [source-rights audit #360](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/360).

## Windows Chapter I — separate track

At the observed current source SHA for [draft PR #347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347), `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`, native First Wake and Ionia CI passed. [Windows QA run #40065451838](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40065451838) includes a **successful Windows functional prerequisites** job (Godot export, package, install/launch/uninstall), but its **Defender security verifier failed closed** at `WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED`. This is a runner capability limitation, **not an antivirus clearance or release approval**. A Defender-real-time-enabled authorized QA host, exact-source candidate verification, human/player acceptance and creator approval are still required.

### Required future review

- Confirm this workflow is a legacy release path only and that no shipping-dependent workflow relies upon it.
- Verify the diff contains **no release-writing action, executable launch, dynamic package building, writable token or tag trigger**.
- Keep [issue #293](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293) open pending independent security review. Do not replace the Godot Windows QA gate with Linux-only tests.
- Recheck the current default branch, check states and required review rules before an authorized merge. A green PR CI check is **not merge authorization**.

Maintainer/creator permission is required for merge or any future redistribution. This is not a new build or user-downloadable Chapter I package.
