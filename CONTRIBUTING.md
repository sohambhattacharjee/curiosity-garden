# Contributing to Curiosity Garden

Start with the [MVP requirements](docs/MVP_REQUIREMENTS.md), [open product decisions](docs/OPEN_DECISIONS.md), and [implementation choices](docs/IMPLEMENTATION_DECISIONS.md). Discuss substantial product changes in an issue; small fixes can go straight to a PR.

For setup and signing, see [family builds](docs/FAMILY_BUILDS.md).

## Workflow

1. Fork if needed, then create a branch from `main`. Keep each PR focused; separate unrelated content and app changes.
2. Update affected tests and docs. Preserve offline operation, fixed breaks, parent privacy, and calm, score-free play.
3. Before pushing, run the [coverage and Debug/Release build checks](docs/VALIDATION.md), plus `python3 -m unittest discover -s scripts/tests`. Production logic must retain **at least 95% line coverage overall and per file**. Keep it in tested targets; do not lower thresholds or add exclusions to pass.
4. Use the [PR template](.github/pull_request_template.md): explain the change, review starting point, and check results. UI changes need synthetic screenshots and relevant iPhone/iPad accessibility checks. Merge through a PR after all required CI checks pass.

## Questions and visuals

Follow [content review](docs/CONTENT_REVIEW.md) for sources, licensing, difficulty/reading targets, choices, keys, and explanations. Keep IDs stable for corrections; use new IDs for materially different questions. Drafts, including AI-assisted content, need actual human approval before becoming `reviewed`. Marking a PR ready does not approve its questions.

Check ambiguity, cultural assumptions, and time-sensitive claims.

Keep visuals educational and provide equivalent accessible descriptions. Retain required third-party notices.

## Privacy and attribution

Use fictional examples and synthetic progress. Never commit child histories, parent PINs, credentials, or signing materials. Use your own Git identity and credit co-authors; disclose AI assistance in content provenance.

Contribute under [MIT](LICENSE), preserving applicable notices. See the [distribution policy](README.md#adapting-and-publishing) for family builds and permitted adaptations.
