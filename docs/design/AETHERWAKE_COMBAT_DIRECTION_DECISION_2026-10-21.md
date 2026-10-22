# Aetherwake Combat Direction Decision — Vertical Slice
**Date:** 2026-10-21  
**Status:** review-only design decision for PR #330; not full-game canon or release authorization

## Decision
Adopt **Direction A: Strategic Prediction** for the First Wake vertical slice, while keeping the interface and encounter model compatible with a later Direction B timing experiment.

For this slice, **Guard is a deliberate turn choice, not a reflex/timing test**. A clearly telegraphed warned pulse makes Guard the strategically correct preparation; a successful Guard earns Echo; the following quiet state makes Strike the high-value answer. The player wins by reading and predicting the encounter state, not by pressing a button within a narrow timing window.

## Why this direction
The completed 69-source JRPG research converges on:
- combat consequence legibility as a fairness prerequisite;
- prediction/knowledge as a strong source of turn-based depth;
- accessibility risk when telegraphs become reflex tests;
- lower onboarding and implementation cost for pure menu-driven prediction;
- scope discipline for a ten-minute vertical slice.

This also matches the implementation already verified in PR #330: `vertical_slice_encounter.gd` is deterministic and turn-based, with no real-time guard window.

## Direction B compatibility
Do **not** implement reaction timing now. Preserve:
- named input actions rather than raw key checks;
- encounter states that distinguish warning and quiet windows;
- visual/audio telegraphs independent of damage resolution;
- Echo as a follow-up state/resource rather than an animation-side effect.

If external playtesting later indicates that pure prediction feels inert, Direction B may be evaluated as a separate reversible experiment with generous timing and accessibility alternatives.

## Direction C deferral
Tactical positioning is explicitly deferred. Spatial combat adds UI, navigation, encounter-design, AI and onboarding costs that would confound the current question: *is the discovery→choice→prediction→payoff loop understandable and satisfying?*

No positioning layer should enter First Wake until the simpler loop has player evidence.

## Current acceptance questions
The current encounter is ready for cold-playtest only when distribution/security gates permit it. A new player should be able to answer:
1. What is the enemy signaling?
2. Why is Guard useful while the pulse is gathering?
3. What changed when Echo appeared?
4. Why is Strike stronger after the guarded warning?
5. Did the pattern feel strategic rather than arbitrary?
6. Would another encounter with a different pattern sound interesting, or repetitive?

## Held decisions
- Echo resource cost is **not automatically adopted**. The research rates the anti-spam recommendation as moderate; add a cost only if playtest shows a dominant repeat loop.
- Three enemy/telegraph families are deferred until the one-family tutorial is understood uncoached.
- Normal-fight time targets are playtest hypotheses, not production law.
- No creator art/canon, production migration, installer, or release authority changes.
