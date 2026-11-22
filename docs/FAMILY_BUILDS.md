# Family builds

Use Xcode 16+ with Swift 6 and the iOS 17+ SDK on a Mac. Open `CuriosityGarden.xcodeproj`, select the shared CuriosityGarden scheme, choose your own signing team and unique bundle identifier, and Run on an iPhone or iPad. Keep the same bundle identifier and signing identity for updates so local data is preserved. iPhone and iPad remain independent.

Debug builds are development previews with draft questions. Release builds require a reviewed bank and deliberately cannot use draft content. No maintainer App Store release, monetization, paid tier, subscriptions, analytics, or advertising is planned. This distribution policy adds no restrictions to the MIT license; others can adapt and publish their own builds.

For personal-device installation, follow Xcode's current signing prompts, enable Developer Mode where requested, and trust your own development profile. Signing expiration depends on your Apple account; rebuild and reinstall from Xcode as needed. Never commit a team identifier, signing certificate, private key, provisioning profile, or child's data.

Keep the parent PIN somewhere safe. There is no in-app bypass. Resetting forgotten credentials requires the family build owner to remove both the app data and its `org.curiositygarden.parent-pin` Keychain entry using development/device-management tooling. Keychain items can survive uninstall. Removing data loses local learning and timing records; do this only as an intentional device reset, not a way around a break.

Progress is local and excluded from backups. Device loss or data removal loses progress. No synchronization, report export, or recovery service exists.
