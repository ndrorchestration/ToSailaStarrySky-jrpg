# Aetherwake Codex repository instructions (autonomy draft)

Official product name: **Aetherwake**. Chapter 1: **First Wake**. Former subtitle is retired from active branding; preserve historical quotes and evidence.

## Agent contract
- Read `docs/autonomy/README.md`, `docs/autonomy/QUEUE.json`, the Visual Bible, character art contract and relevant issues before modifying code.
- Use a named feature branch based on a verified exact SHA; never work on protected `main`. Do not merge or push without explicit authority.
- Work only on the single selected task. Do not modify canon, approved likeness, asset admission, releases, external services, privacy controls or security policy without explicit human approval.
- Validate changed source with the narrowest relevant tests, expand to Chapter 1 core/browser/visual when changes warrant, and report tests actually executed. Never claim visual quality from CI alone.
- Treat missing sources, broken tests, artifact-upload quota or stale heads as blockers, not permission to guess.
- Return concise findings: exact SHA, files changed, tests PASS/FAIL/NOT_RUN, screenshots/artifact paths, dependencies and unresolved gates.
- After task work, stop. The external controller chooses whether/when the next task runs. No self-recursive agents or background jobs.
