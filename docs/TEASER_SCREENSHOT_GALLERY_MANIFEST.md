# Trailer screenshots — review gallery manifest

**Source of frames:** owner-supplied 70-second `To_Sail_The_Starry_Sky_Trailer_V2_CorrectCast_70s.mp4`, distinct from the previously linked Explain narrated slideshow. Nine JPG stills were extracted and packaged locally for optional GitHub publication. **The binary stills are not in this PR.** Do not add image Markdown referring to files that are not committed or hosted.

| Second | Proposed image | Gallery caption |
|---:|---|---|
| 16 | `01_planetary_reveal.jpg` | Planetary reveal, with polar aurora |
| 22 | `02_above_the_clouds.jpg` | Atmospheric clouds at sunrise |
| 28 | `03_airship_concept.jpg` | Airship concept art (ship identity not approved) |
| 34 | `04_character_concept.jpg` | Character concept; check against approved cast references |
| 40 | `05_coastal_world.jpg` | Coastal environment concept |
| 46 | `06_forest_biome.jpg` | Forest biome concept |
| 52 | `07_five_lights_concept.jpg` | Fellowship and Five Lights motif |
| 58 | `08_celestial_mystery.jpg` | Celestial phenomenon (not proof of unlock mechanics) |
| 64 | `09_moonward_horizon.jpg` | Moonward mystery |

**Provenance and truth in marketing:** Every still comes from generated concept footage, not Godot rendering. These images do not establish canonical ship appearance or geography, nor production visuals. The **Aureate Wake** is the protagonists' smaller, dragonfly-inspired home; **the Dragonfly** is a distinct, much larger Frigate-class ship. Do not assign an unlabeled concept vessel to either without creator review.

**Pending upload:** Attach approved, rights-cleared stills through a GitHub interface that accepts binary assets, then update the page with verified repository-relative or hosted image URLs. The current connected GitHub contents tool supports UTF-8 text; binary still upload has not been verified. Review visual fidelity, AI-output labels, character identities, accessibility captions, and hidden-story clues first.

## Screenshot package integrity — 2026-10-27

The owner-side `starry_sky_github_teaser_gallery.zip` was inspected locally: ZIP CRC/readability PASS, 9 JPEG stills plus `manifest.json` present, each image decodes at **1280 × 720 (16:9)**, and all nine JPEG SHA-256 hashes match the manifest. These checks validate file integrity and dimensions, **not** artistic approval, likeness continuity, copyright clearance, or on-engine rendering. Exact evidence is maintained with the owner-side ZIP; the GitHub repository does not currently host the binaries.

**Promotion gate:** Publish actual binary media only after verifying the final stills against approved art/ship names. Once uploaded, replace this pending state with actual verified repository links and accessible alt text. Do not point Markdown image tags at absent paths.

## Reproducible binary import (not yet executed on GitHub)

Download the creator-review gallery ZIP, place it in a trusted local checkout of this draft branch, and run the following **after art/rights approval**:

```bash
python tools/import_concept_teaser_stills.py starry_sky_github_teaser_gallery.zip
python tools/import_concept_teaser_stills.py starry_sky_github_teaser_gallery.zip --write
```

The first command is a read-only verification; the second copies nine JPEG files and their manifest into `docs/media/concept-teaser-2026-10-27/`. The tool checks ZIP integrity, filenames and exact SHA-256 digests, refuses to overwrite conflicting images, and **never commits/pushes**. Review stills before staging and linking. No image-hosting claim is made until the committed files are independently visible through GitHub.
