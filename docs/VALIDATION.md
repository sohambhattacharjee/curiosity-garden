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
