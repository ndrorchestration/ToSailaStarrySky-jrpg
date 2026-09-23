# M0 accessibility visual-review protocol

Status: **MANUAL BLOCKING EVIDENCE / HUMAN JUDGMENT REQUIRED**

This protocol owns human acceptance of the generated 58-frame accessibility visual matrix. Automated capture proves that the required surfaces render without registered runtime/HTTP errors; it does **not** prove readability, clipping quality, focus clarity, contrast quality, or acceptable composition.

## Candidate binding

Before review, record:
- exact Git commit SHA;
- `artifacts/accessibility-visual-matrix/manifest.json` identity;
- SHA-256 of that manifest;
- capture count;
- reviewer identity or stable reviewer label;
- review date.

Do not reuse a review from another commit or regenerated matrix.

## Required review set

The current matrix contains exactly **58 captures**:
- 48 text-scale captures: 12 representative surfaces at 100%, 125%, 150%, and 175%;
- 6 high-contrast captures at 150%;
- 4 subtitle/speaker-label presentation captures.

Every file listed in the manifest must be reviewed. A missing or extra capture invalidates the review record.

## Review criteria

For each capture, inspect at minimum:
- no clipped, overlapping, off-canvas, or unreadable required text;
- focus/selection state remains identifiable without relying on color alone where focus is shown;
- text remains legible against its immediate background;
- enlarged text preserves usable hierarchy and does not hide required controls/objectives;
- high-contrast mode improves or preserves distinction rather than collapsing information;
- subtitle background/size combinations remain readable and do not obscure critical interaction information;
- speaker-label behavior matches the selected setting;
- no obvious placeholder/debug/error surface is visible;
- no composition defect makes a required M0 action materially harder to understand.

Record defects by capture filename. Do not silently waive a defect because another scale or surface looks correct.

## Result semantics

The review record begins as `NOT_RUN`.

Valid terminal results:
- `PASS` — every capture reviewed; no blocking visual/accessibility defect remains.
- `FAIL` — one or more blocking defects exist.
- `INVALIDATED` — candidate/manifest mismatch, incomplete capture set, regenerated evidence after review, or other provenance failure.

A passing automated visual-matrix capture **cannot** set this result to `PASS`.

## Evidence record

Copy `docs/m0-accessibility-visual-review.template.json` for each exact candidate review.

The human review and the uncoached external-player gate answer different questions and neither substitutes for the other.


## Evidence validation

The generated matrix manifest uses provenance schema v2 and binds:
- exact Git HEAD;
- exactly 58 capture records;
- each capture filename, byte count, and SHA-256.

After completing the human review record, validate it against the exact matrix before treating the review as admissible evidence:

```powershell
npm run validate:accessibility-review -- --record ".\path\to\completed-review.json" --matrix-dir ".\artifacts\accessibility-visual-matrix"
```

The validator fails closed if the review commit does not match the matrix Git HEAD, the manifest bytes changed, any capture was replaced/regenerated, review coverage is incomplete, any criterion is not explicitly true, blocking defects remain, reviewer identity/date is missing, or the result is not `PASS`.

A validator PASS confirms integrity and completeness of the human record; it does not replace the human judgment that produced that record.

## Deterministic review packet

After the 58-frame matrix is generated, create the review packet with:

```powershell
npm run prepare:accessibility-review
```

This produces, inside `artifacts/accessibility-visual-matrix/`:
- `review-index.html` — a local contact sheet containing all 58 manifest-bound captures, grouped by text scale, high-contrast, and subtitle cases;
- `human-review.json` — a copy of the review template pre-bound to the exact matrix Git HEAD, manifest SHA-256, and capture count.

The generated record remains `NOT_RUN`; all coverage flags remain false and all review criteria remain unset. The packet generator verifies the manifest and every screenshot hash before writing either output. It does **not** perform or imply human acceptance.

Open `review-index.html`, review every capture, then complete `human-review.json` manually. Validate the completed record using the evidence-validation command above.
