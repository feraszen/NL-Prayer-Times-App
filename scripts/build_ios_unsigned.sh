#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "An unsigned iOS device build still requires macOS and Xcode." >&2
  exit 1
fi

# Flutter resolves Swift packages and installs fallback CocoaPods plugins.
# Do not export/relabel this as an installable IPA: it has no Apple signature.
flutter build ios --release --no-codesign --no-pub
app_path="build/ios/iphoneos/Runner.app"
test -d "$app_path"
output_dir="build/ios/unsigned"
mkdir -p "$output_dir"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent \
  "$app_path" "$output_dir/NL-Prayer-Times-iOS-unsigned.app.zip"
cat > "$output_dir/README.txt" <<'NOTES'
NL Prayer Times - unsigned iOS device build

Runner.app is compiled for an iPhone, but is NOT signed or provisioned.
It cannot be installed on an iPhone or uploaded to TestFlight as-is.
This is not an iOS Simulator build either.

This workflow checks iOS compilation only. It does not implement or verify
background prayer alerts or custom notification audio on iOS. Those features
are currently Android-only. Apple signing and iOS feature work remain.
NOTES
