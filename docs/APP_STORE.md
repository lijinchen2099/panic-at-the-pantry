# Mac App Store release

The first store release is **1.0**, build **2**, free, for macOS. App Store
Connect record: `6829105510`. Bundle ID: `com.breakfastclub.panicatthepantry`.
The game interface is English. Store metadata is tracked in
`release/app-store/en-US.json`.

## Public pages

- Website: https://lijinchen2099.github.io/panic-at-the-pantry/
- Support: https://lijinchen2099.github.io/panic-at-the-pantry/support.html
- Privacy: https://lijinchen2099.github.io/panic-at-the-pantry/privacy.html

The buildless website is in `website/`. `.github/workflows/pages.yml` deploys
only that directory; signing material and build artifacts are not published.
The support channel is GitHub Issues. The game has no advertising, tracking,
analytics, online account, network requirement, or in-app purchases. Preferences
and progress are saved locally. The website policy separately describes GitHub
hosting and public support requests.

## Signing and packaging

The **macOS** preset continues to produce the original local ad-hoc build.
The separate **Mac App Store** preset enables App Sandbox and disables network
access, debugger access, and library-validation exceptions. It uses Apple's
distribution signing tools and a game-specific App Store provisioning profile.
macOS 13 is the store minimum for the native Metal renderer. Apple Silicon was
tested; Intel compatibility still needs device testing despite the universal
binary's x86_64 slice.

Keep certificates, private keys, profiles, and upload credentials out of Git.
Private signing identities belong in the local login keychain. The helper takes
local configuration from environment variables and exports from a temporary
project copy so it does not insert machine-specific identities or profile paths
into the tracked export preset:

```sh
PANTRY_APP_IDENTITY='3rd Party Mac Developer Application: Zhenyu Li (9A2S27Y6C4)' \
PANTRY_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Zhenyu Li (9A2S27Y6C4)' \
PANTRY_PROFILE='/absolute/path/to/Pantry_App_Store.provisionprofile' \
python3 tools/build_app_store.py
```

The result is `build/app-store/Panic at the Pantry.pkg`. The helper verifies the
profile's team, App ID, expiry and distribution type, package signature, app
signature, embedded profile, and required sandbox/team/application entitlements.
The store preset also declares a global `LSMinimumSystemVersion` in addition to
Godot's per-architecture minimum versions, as required by Apple's uploader.
It rejects debugger, networking and disabled-library-validation entitlements.
Move an existing package aside before rebuilding. Set `PANTRY_BUILD_NUMBER` to
a new numeric build number before replacing a build already uploaded to Apple.
This helper prepares the package; it does not upload, submit, or release it.

App Store packages use App Store signing and Apple's upload/review workflow.
Developer ID notarization is a separate distribution route.

## Store screenshots

```sh
.tools/Godot.app/Contents/MacOS/Godot --audio-driver Dummy --path game \
  --script ../tools/capture_store_screenshots.gd -- --self-test
```

Five actual native-rendered boss screens are written to
`output/app-store/screenshots/`. Each is a 1440 × 900 RGB PNG without alpha.
The 16:9 gameplay image is preserved inside a plain 16:10 store canvas, without
stretching the artwork. Capture mode does not save changes to player progress.

## Submission status

Version **1.0 (2)** was submitted to Apple on **October 31, 2026 at 11:40 AM
(GMT+8)**. App Store Connect confirmed **Waiting for Review**. Submission ID:
`0d210fec-0c57-457a-a4e6-824bdbf65495`.

The signed universal package passed local signature, provisioning profile and
sandbox checks, then Apple's upload processing. The submission includes the
description, support/marketing links, five screenshots, review contact, age
rating and confirmed encryption declaration. The **Data Not Collected** privacy
declaration is published. The calculated global age rating is **13+**, with
regional variations assigned by Apple.

The account holder authorized submission and **automatic release after Apple
approval**. Pricing is **free**, with public availability in all **175** selected
countries and regions. The game is awaiting review and is not yet available on
the store; the website continues to say "Coming soon". Check
[App Store Connect](https://appstoreconnect.apple.com/apps/6829105510/distribution/reviewsubmissions/details/0d210fec-0c57-457a-a4e6-824bdbf65495)
for the authoritative current status.

## Official references

- [Godot macOS export and App Sandbox](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
- [Godot macOS export settings](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformmacos.html)
- [Apple build uploads](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
