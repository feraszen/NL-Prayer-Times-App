#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "An unsigned iOS device build still requires macOS and Xcode." >&2
  exit 1
fi

# Flutter resolves Swift packages and installs fallback CocoaPods plugins.
# The IPA below is a packaging convenience only. It still needs Apple signing.
flutter build ios --release --no-codesign --no-pub
app_path="build/ios/iphoneos/Runner.app"
test -d "$app_path"
output_dir="build/ios/unsigned"
mkdir -p "$output_dir"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent \
  "$app_path" "$output_dir/NL-Prayer-Times-iOS-unsigned.app.zip"
# A Payload IPA saves Windows testers the manual ZIP/repack step.
mkdir -p "$output_dir/Payload"
/usr/bin/ditto "$app_path" "$output_dir/Payload/Runner.app"
/usr/bin/ditto -c -k --keepParent "$output_dir/Payload" \
  "$output_dir/NL-Prayer-Times-iOS-unsigned.ipa"
cat > "$output_dir/README.txt" <<'NOTES'
NL Prayer Times - unsigned iOS device build

Both the IPA and Runner.app ZIP are UNSIGNED and unprovisioned.
They cannot be installed directly or uploaded to TestFlight as-is.
Use Apple signing, or re-sign the IPA for your test device as before.

Version 1.1.0 adds iOS prayer notifications, audio import, a 29-second
notification sound, explicit full playback, and optional AlarmKit alarms
on iOS 26+. AlarmKit full sound and delivery still need physical-device tests.
Open the app at least weekly to renew its seven-day schedule.
NOTES
