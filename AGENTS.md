# Repository working rules

Preserve the README, docs/MVP_REQUIREMENTS.md, and docs/OPEN_DECISIONS.md as product sources of truth. Keep child data and signing credentials out of git. Preserve MIT and the maintainer's family-build/no-monetization policy.

Before pushing changes, run `bash scripts/test_coverage.sh` and relevant iOS build checks. Maintain **95% executable-line unit coverage overall and for each production logic Swift file**. New production Swift files must be included in the package's tested targets; missing coverage is a failure. Never lower the threshold, remove tests, or add exclusions to silence a coverage failure. Keep business logic out of the sole declarative SwiftUI presentation exclusion. Add regression tests for behavior changes and defects.

Work on a branch, pass the required Core tests (including the coverage gate), Debug, and Release checks, then merge through a PR. Preserve the owner's commit identity and Codex co-author credit when applicable.
