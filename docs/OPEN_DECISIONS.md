# Remaining decisions and validation

The implemented defaults are recorded in [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md); the product requirements remain in [MVP_REQUIREMENTS.md](MVP_REQUIREMENTS.md).

Outstanding work before a device release:

- Validate question facts, distractors, difficulty, reading targets, and sufficient reviewed content across the supported levels.
- Complete physical-device installation/update, accessibility, layout, persistence, and timing checks in [VALIDATION.md](VALIDATION.md).

The approved calibration rule extends a round only after a subject changes difficulty, ending after two subsequent answers at the new level within the grade limit. Paired extensions preserve the even mix. This is implemented, rather than an open decision.
