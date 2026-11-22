# Install on a device

1. Open `CuriosityGarden.xcodeproj` in Xcode 16+ on a Mac.
2. Select the CuriosityGarden scheme and Debug configuration. In Signing & Capabilities, choose your team and a unique bundle identifier.
3. Connect an iPhone or iPad running iOS/iPadOS 17+, select it, and Run. Follow Xcode's signing and Developer Mode prompts.

Use the same bundle identifier and signing identity for updates. Development signing may expire; rebuild from Xcode when needed. The bundled questions work offline in Debug and Release.

Each device has independent local progress. There is no account, synchronization, backup recovery, or PIN recovery service. Keep signing credentials outside git.

A forgotten PIN requires an intentional development reset of app data and the `org.curiositygarden.parent-pin` Keychain entry. Uninstalling alone may leave the PIN in Keychain. Resetting removes local learning and timing records.
