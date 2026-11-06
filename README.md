# Tonkeeper iOS

Modified 5.1.1 fork (`com.jbig.tonkeeper`). Source is kept as provided.

## GitHub Actions IPA

Workflow: `.github/workflows/ipa.yml`

- Runs on `macos-15` after every push to `main`/`master`, or via **Actions → Build IPA → Run workflow**.
- Builds scheme `Tonkeeper` / configuration `TonkeeperRelease` without Apple signing.
- Uploads `Tonkeeper-5.1.1.ipa` as an artifact and as a GitHub Release (`ipa-5.1.1-<run>`).
- Sideload with your own certificate (AltStore, Sideloadly, or a development profile). The CI IPA is unsigned.

If the build needs real Firebase files, put `GoogleService-Info.plist` under `Tonkeeper/Resources/Firebase/` (see `setup_keys.sh`). CI writes placeholders automatically.

## Setup

### Tonkeeper team

#### Build

- run `setup_keys.sh` script. it downloads Debug/Release GoogleService-Info.plist from [https://github.com/tonkeeper/ios_keys](https://github.com/tonkeeper/ios_keys)

#### Device debug

- download certificates and provisioning profiles from Apple Developer Portal.

### Contest

#### Build
- create you own GoogleService-Info.plist ([Steps 1-3](https://firebase.google.com/docs/ios/setup))
- put created GoogleService-Info.plist `/Tonkeeper/Resources/Firebase/Debug/` and `/Tonkeeper/Resources/Firebase/Release/`

#### Device debug

all signing related stuff located in xcconfig files.

- PRODUCT_BUNDLE_IDENTIFIER in Debug.xcconfig, WidgetDebug.xcconfig and IntentsDebug.xcconfig
- DEVELOPMENT_TEAM, CODE_SIGN_IDENTITY, PROVISIONING_PROFILE_SPECIFIER, WIDGET_CODE_SIGN_IDENTITY, WIDGET_PROVISIONING_PROFILE_SPECIFIER, INTENTS_CODE_SIGN_IDENTITY and INTENTS_CODE_SIGN_IDENTITY in SignDebug.xcconfig
