# Curiosity Garden

<img src="App/Assets.xcassets/GardenFox.imageset/GardenFox.png" width="140" alt="A laughing fox holding a magnifying glass among garden leaves and flowers" />

An offline SwiftUI trivia app for iPhone and iPad, covering kindergarten through grade 5. Progress, parent settings, and reports stay on the device.

## Run

Requires a Mac with Xcode 16+, Swift 6, and an iOS/iPadOS 17+ simulator or device.

```sh
git clone https://github.com/sohambhattacharjee/curiosity-garden.git
cd curiosity-garden
open CuriosityGarden.xcodeproj
```

1. Select the **CuriosityGarden** scheme, **Debug** configuration, and an iPhone or iPad simulator. Press **Run** (⌘R).
2. Choose a starting grade and create a six-digit parent PIN, then start a round.

For a physical device, select your signing team and a unique bundle identifier. See [device installation](docs/FAMILY_BUILDS.md).

## Questions

`App/questions.json` bundles **1,440 AI-assisted questions**: 40 per subject at each K–5 difficulty level. Each contains choices, a key, an explanation, and source references. Early readers may need adult help.

The approved bank works offline in Debug and Release. See [question format](docs/CONTENT_REVIEW.md).

## Screenshots

Earlier development builds with synthetic progress.

<img src="docs/screenshots/iphone-reading-maximum.png" width="260" alt="iPhone question, choices, explanation, I'm not sure, and Next" />

<img src="docs/screenshots/ipad-landscape.png" width="640" alt="iPad landscape question and answer controls" />

## Development

- [Checks and device validation](docs/VALIDATION.md)
- [Contributing](CONTRIBUTING.md)
- [MVP requirements](docs/MVP_REQUIREMENTS.md), [implementation details](docs/IMPLEMENTATION_DECISIONS.md), and [remaining decisions](docs/OPEN_DECISIONS.md)

## Adapting and publishing

[MIT licensed](LICENSE). Maintainer builds are for family use, with no monetization or maintainer App Store release. Others may adapt and publish their own versions, including on the App Store, under MIT.
