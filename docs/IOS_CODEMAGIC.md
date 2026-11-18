# Unsigned iOS build check on Codemagic

This workflow uses a Codemagic Mac; a local Mac or Apple signing credentials
are not needed for this compilation check. It does **not** produce an app
that can be installed directly on an iPhone.

## Start the build

1. Open the existing NL-Prayer-Times-App application in Codemagic.
2. Choose configuration from `codemagic.yaml` (switch from Workflow Editor
   to YAML configuration if needed).
3. Scan branch `main` using **Check for configuration file**.
4. Choose workflow **iOS unsigned build check** (`ios-unsigned`).
5. Start a build from the newest `main` commit. No signing certificates,
   provisioning profiles, App Store integration, or publishing are configured.
6. Check the build result. On success download
   `NL-Prayer-Times-iOS-unsigned.app.zip` from Artifacts. On failure, open the
   failing step and share its error log, without credentials.

Builds use the account's available Mac build minutes. No automatic trigger
is configured; starting another build is a manual decision.

## What this checks

Flutter 3.44.4 / Dart 3.12.2, Dart analysis, Flutter tests, and native release
compilation for iPhone. The iOS deployment target is 14.0, as required by the
current file picker. The existing Swift Package Manager setup is preserved;
CocoaPods fallback is configured for plugins such as `flutter_compass`.

## What is not ready

The ZIP contains an unsigned device `Runner.app`, not an installable IPA and
not a Simulator app. It needs Apple signing/provisioning for installation.
TestFlight requires the appropriate paid Apple Developer membership.
Prayer notification scheduling and importing custom notification audio are
currently Android-only; compiling the iOS UI does not add these features.
A Mac build must complete successfully before claiming iOS build readiness.

Sources: [Codemagic Flutter configuration](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
and [Flutter SwiftPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).
