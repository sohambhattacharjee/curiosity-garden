# Validation

Run from the repository root on a Mac with Xcode 16+ and Swift 6:

```sh
python3 -m unittest discover -s scripts/tests
python3 scripts/check_question_bank.py
bash scripts/test_coverage.sh
xcodebuild -project CuriosityGarden.xcodeproj -scheme CuriosityGarden -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project CuriosityGarden.xcodeproj -scheme CuriosityGarden -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

These build commands compile the app. Launch it with Xcode Run as described in [README](../README.md#run).

CI requires Core tests and both iOS builds. The coverage gate enforces **at least 95% executable-line coverage overall and per production logic Swift file**, including new files. The declarative SwiftUI file is the sole exclusion; business logic belongs in tested targets. The bank audit checks the JSON directly.

Before a device release, verify:

- Offline setup, mixed rounds, explanations, recap, and parent PIN/settings/reports.
- iPhone/iPad portrait, landscape, window sizes, largest text, complete answer controls, contrast, and VoiceOver.
- Session limits across rounds, backgrounding, relaunch and restart; the full 30-minute break; clock changes and grade changes.
- Keychain persistence/cooldown, 90-day retention, and graceful failure for corrupt or unwritable storage.
- Forgotten-PIN recovery with real Face ID/Touch ID and passcode fallback; cancellation, no device passcode, backgrounding, and relaunch. Verify reports remain locked and learning/session limits/breaks survive. Unit tests substitute system authentication replies.

Use synthetic data. Automated tests do not replace these device checks or content validation. Draft questions remain ineligible for Release.
