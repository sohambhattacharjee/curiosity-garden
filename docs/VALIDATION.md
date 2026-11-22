# Validation

Automated core tests exercise independent subject streaks and persistence, exactly-ten promotion, wrong/unsure handling, level bounds, mixed groups, selected-grade reading filtering, reviewed-content selection, approved calibration and round bounds, all six caps, foreground accounting across rounds, short/long absence, serialized relaunch, conservative killed-process/restart handling, wall-clock changes, grade-change break bypass, ninety-day retention, and bundled fixture validity.

```sh
bash scripts/test_coverage.sh
xcodebuild -project CuriosityGarden.xcodeproj -scheme CuriosityGarden -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project CuriosityGarden.xcodeproj -scheme CuriosityGarden -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Device release checklist

Before a family-ready release, check on physical iPhone and iPad: airplane-mode setup and full rounds; portrait/landscape and iPad window sizes; largest accessibility text; VoiceOver reading/focus order; contrast and answer state labels; Keychain persistence, cooldown, and forgotten-PIN workflow; background/foreground and force-quit at question, feedback, recap, parent gate and reports; foreground cap mid-question; mandatory 30-minute break across a real restart; short-interruption pending question; full inactivity refresh; ninety-day deletion; protected-data unavailability and low-storage/corrupt-file failures. Simulated clock tests do not replace a real-device timing test.

Content release is blocked until a human-reviewed question bank has adequate subject/level/reading coverage. Release builds currently contain no eligible reviewed questions. Draft-fixture testing and screenshots are development evidence only.

## Local preview checks — 2026-11-21

- Xcode 27.2: built and ran on iPhone 18 Pro and iPad Pro 11-inch (M5), iOS/iPadOS 27.2 simulators. Verified independent first-run setup, correct/wrong/unsure feedback, school/general alternation, ten-question recap with two facts and no score, parent PIN rejection, successful unlock, report relocking, and question-level history with draft labels. Verified iPad portrait and landscape layout. Captured screenshots contain only synthetic test activity.
- `swift test`: 14 tests passed with zero failures.
- Debug and Release generic simulator builds succeeded locally. Running in Xcode exposed and fixed a Debug active-architecture mismatch. CI on Xcode 16.4 exposed an oversized SwiftUI expression; the report was split into smaller views and its subject type was qualified for compatibility. All three CI jobs then passed on Xcode 16.4.
- Screenshot review exposed dark primary-button labels; corrected to white and recaptured. Completed-round recap now restores after relaunch.
- No physical-device, full VoiceOver/Dynamic Type, ninety-day real-time aging, or full thirty-minute real-time break audit has been completed. These remain release checks above.

## Pre-merge review corrections — 2026-11-21

A fresh review found that six-question review slots always selected the general-knowledge group, saved Debug rounds could bypass the Release draft gate, and recap completion was not persisted separately from final-answer feedback. Fixed the review cadence to alternate groups, revalidate all resumed round content, and persist explicit completion/session-limit/content-unavailable reasons. Empty or malformed PIN submissions are rejected before password derivation; missing question resources now fail gracefully.

The expanded core suite passes 17 tests, including regression coverage for school/general missed-question review despite subject balancing, draft-question and draft-recap rejection after persistence, and separate restoration of final explanations and ended recaps. Existing adaptation and timing tests remain passing.

## Required unit coverage

`bash scripts/test_coverage.sh` runs Swift tests with fresh LLVM counters, then enforces at least **95% executable-line coverage both overall and for every production logic file**. It fails for missing instrumentation, zero-line summaries, duplicate file entries, or any undercovered file. It discovers new Swift files automatically. `App/CuriosityGardenApp.swift` is the sole exclusion because it contains declarative presentation; business logic must stay in tested sources. Layout/accessibility remain covered by the device checklist, not by the unit metric.

The Swift package compiles the exact app-state and PIN source files used by the Xcode app into a testable target. Tests exercise offline rounds, persisted feedback and recap, foreground/background/parent-area timing, hard caps, persisted breaks, grade changes, corrupt/unsavable storage, Release upgrades, and actual Keychain verification/cooldown in isolated disposable service namespaces. No tests touch the family's PIN namespace.

Local measured production logic coverage: 375/388 executable lines (**96.65%**). Per file: GardenStore 95.70%, ParentPIN 96.49%, Learning 96.30%, Reports 100%, SessionClock 97.33%. The suite has 26 Swift tests and six Python tests for the coverage guard itself. The guard tests prove that missing files and a low-coverage file cannot be hidden by a high aggregate. The already-required Core tests CI check runs the gate on every branch push and PR, so main cannot merge below the threshold.
