#!/usr/bin/env bash
set -euo pipefail
# This tests actual AVFoundation conversion on a Mac Simulator, not a Dart mock.
flutter build ios --simulator --debug --no-codesign --no-pub
simulator_id=$(xcrun simctl list devices available --json | python3 -c '
import json,sys
runtimes=json.load(sys.stdin)["devices"]
phones=[d for runtime, devices in runtimes.items() if "iOS" in runtime
        for d in devices if d.get("isAvailable") and "iPhone" in d.get("name", "")]
if not phones: raise SystemExit("No available iPhone Simulator runtime on this Mac")
print(phones[0]["udid"])
')
mkdir -p build/ios/native-tests
xcodebuild test \
  -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath build/ios-test-derived \
  CODE_SIGNING_ALLOWED=NO \
  | tee build/ios/native-tests/xcodebuild-test.log
