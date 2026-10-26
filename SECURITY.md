# Security policy — To Sail the Starry Sky

**Status: pre-alpha game source, public repository, not an approved public game release.** This policy is guidance for responsible reporting and repository handling; it does not assert a formal security response SLA, independent audit, or certification.

## Report a vulnerability privately

Do **not** post tokens, credentials, personal data, exploit details, or unredacted diagnostic artifacts in public issues, pull requests, Discussions, or CI logs.

1. Use GitHub's **Report a vulnerability** / private vulnerability reporting entry on this repository's **Security** tab **if it is enabled**.
2. If private reporting is not available, use an already established private communication channel with the repository owner. The [owner's GitHub profile](https://github.com/ndrorchestration) is an entry point for finding a contact method; this file does not invent or promise a private inbox.
3. Report the affected file/commit or component, minimally reproducible steps, impact, and safe-to-share evidence. Redact any sensitive material before sending.

Never include actual compromised credentials in a public report. If exposed credentials are discovered, notify the owner privately so the corresponding provider credentials can be revoked and rotated, and affected access logs inspected. Removing a file or changing `.gitignore` does **not** revoke a secret already committed to history.

## Executable and artifact safety

A [QA-only Windows NSIS uninstaller triggered Microsoft Defender](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293). Its security disposition is unresolved. **Do not execute, restore, whitelist, or distribute that specifically detected file.** A positive detection is not by itself proof of malicious source or of a false positive. Preserve exact hashes and evidence when investigating.

Public GitHub source, build draft releases, and previously published prerelease artifacts are not synonymous with independently accepted player builds. Installation and distribution require the project's separate Windows, security, licensing, visual and human player acceptance gates.

## Public-source disclosure boundaries

- This repository currently has **no repository-wide root `LICENSE` grant**. Publicly readable code or assets are not automatically available for redistribution or commercial reuse. Respect applicable third-party/per-file licenses, authorship and rights.
- Proposed upstream code or assets must carry their actual attribution and redistribution permissions; do not infer permission from a reference implementation or archived research note.
- Unreleased story and postgame lore should be handled through access-controlled project records instead of public issue and PR descriptions.
- The continuing [public-source admission audit](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/360) covers source/history secrets, rights, disclosures, GitHub admin settings and publication readiness.
- The [main branch protection gap](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/303) remains open. Passing CI or changing docs does not establish non-author review or release authorization.

## Supported versions

This project is pre-alpha. **No version is declared security-supported for production or general distribution.** Security findings should be linked to exact source commit, package identity and artifact SHA-256.
