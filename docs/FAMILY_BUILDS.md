# Install on a device

1. Open `CuriosityGarden.xcodeproj` in Xcode 16+ on a Mac.
2. Select the CuriosityGarden scheme and Debug configuration. In Signing & Capabilities, choose your team and a unique bundle identifier.
3. Connect an iPhone or iPad running iOS/iPadOS 17+, select it, and Run. Follow Xcode's signing and Developer Mode prompts.

Use the same bundle identifier and signing identity for updates. Development signing may expire; rebuild from Xcode when needed. The bundled questions work offline in Debug and Release.

Each device has independent local progress. There is no account, synchronization, or backup recovery. Keep signing credentials outside git.

Forgot the PIN? Open **Parents → Forgot PIN?**, enter a matching new six-digit PIN, then authenticate with Face ID, Touch ID, or the device passcode. Enter the new PIN to open reports. This preserves learning, session limits, and breaks. Anyone able to unlock the device can reset the PIN; a device passcode must be configured in Settings.
