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

The app record, description, support/marketing links and five screenshots were
prepared in App Store Connect. Distribution signing identities and the app's
profile were created with the account holder's authorization. The local signed
package passed verification. Upload authentication, remaining app information,
age rating, pricing, privacy publication, review contact and final review/release
must be completed in App Store Connect before the game is available to customers.
Check App Store Connect for the authoritative current status.

## Official references

- [Godot macOS export and App Sandbox](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
- [Godot macOS export settings](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformmacos.html)
- [Apple build uploads](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
