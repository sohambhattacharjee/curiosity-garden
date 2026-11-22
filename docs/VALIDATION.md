# Validation

Automated core tests exercise independent subject streaks and persistence, exactly-ten promotion, wrong/unsure handling, level bounds, mixed groups, selected-grade reading filtering, reviewed-content selection, approved calibration and round bounds, all six caps, foreground accounting across rounds, short/long absence, serialized relaunch, conservative killed-process/restart handling, wall-clock changes, grade-change break bypass, ninety-day retention, and bundled fixture validity.

```sh
swift test
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
