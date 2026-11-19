# iOS 1.1.x test build on Codemagic

Use the existing manual `ios-unsigned` workflow (**iOS unsigned build check**)
from the newest `main` commit. No automatic trigger, signing credentials or
store publishing are configured. Each build consumes the account's Mac minutes.

## Build and install

1. Start a new build from `main`, selecting **iOS unsigned build check**.
2. The workflow analyzes Dart, runs Flutter tests, builds an iPhone Simulator
   app, and runs RunnerTests using AVFoundation. Those native tests verify the
   29-second notification conversion, complete alarm sound, stable imported
   copy, reuse, invalid input and excessive-duration rejection.
3. It then builds a device release app without signing and exports both
   `NL-Prayer-Times-iOS-unsigned.ipa` and `NL-Prayer-Times-iOS-unsigned.app.zip`.
4. If any step fails, share its error log. Simulator/native test success cannot
   be claimed until this workflow actually runs successfully on the Mac.
5. After success, download the **IPA** directly (no Windows repacking needed),
   re-sign/install it with your existing Sideloadly setup, and confirm **1.1.1**
   in About. Neither artifact can be installed directly without Apple signing.
   TestFlight still requires appropriate Apple Developer membership/signing.

Flutter is pinned to 3.44.4. SwiftPM is enabled with CocoaPods fallback for
`flutter_compass`; the deployment target remains iOS 14.0. AlarmKit code is
conditionally compiled with a supported SDK and is available on iOS 26+.

## Notification behavior

- Enable **Prayer notifications** and allow alert/sound permission. The same
  shared prayer source/adjustments used on Home schedule the five prayers.
- Seven separate daily schedules are calculated (up to 35 pending notifications,
  below iOS's 64 pending-notification limit). Sunrise is never notified. Open the
  app at least weekly to renew the horizon, and whenever the location changes.
- A fresh source must resolve before existing scheduled reminders are cancelled.
  Permission denial and scheduling errors are shown in Settings. An unsuccessful
  preference change rolls back the choice; a partially failed native reschedule
  can require tapping **Scheduled prayers** to retry after resolving the error.
- The ordinary notification sound uses the first **29 seconds** of the default
  or chosen file. Files are decoded natively into 16-bit PCM WAV in `Library/Sounds`.
  Supported imports are MP3/M4A/WAV/CAF/AIFF, <=50 MB, <=10 minutes, mono/stereo.
  A durable copy of the original is kept for full playback and previews.
- Long-press a prayer notification and choose **Play full adhan** to open the app
  and explicitly start the full chosen file. Playback may continue when locked;
  a visible **Stop** control is provided in the app. Tapping the notification
  normally does not automatically start audio. No silent background audio loop,
  critical-alert entitlement, or remote-push service is used.
- Muting adhan preserves the visible reminder and removes its audio action.
  Disabling an individual prayer or the master switch cancels only owned IDs.
  The removed **Audio & testing options** section has not been restored.

## Optional iOS prayer alarms (AlarmKit, iOS 26+)

Settings exposes **Use iOS prayer alarms** only when the native API is available.
This requires a separate system authorization and explicit opt-in. A fixed,
one-shot alarm is scheduled at each enabled prayer instant; regular companion
notifications are silent to avoid two simultaneous audio sources. A full WAV
resource of the selected audio is provided to AlarmKit. AlarmKit controls the
ringing behavior and stopping UI and can bypass Focus/Silent mode.

Do not promise uninterrupted full-length playback, exact ringing duration or
identical custom-sound behavior on every OS release before testing the actual
phone. If alarms are denied or scheduling fails, the app reports it rather than
claiming they were scheduled. The user can disable alarm mode and use ordinary
notifications. Muting adhan disables sound-bearing alarms while keeping silent
notifications. The alert-only presentation does not need a countdown widget.

## Physical iPhone acceptance checklist before release

Use an actual upcoming prayer (or a temporary per-prayer adjustment within the
existing allowed range, then reset it). The device and source date/timezone
must match. Do not reintroduce diagnostics controls into the public UI.

1. Allow notifications and confirm **Scheduled prayers** is nonzero after enabling.
2. With alarm mode **off**, verify the visible alert and correct <=29-second sound
   with the app open, backgrounded and screen locked. Check system sound settings,
   Focus, Scheduled Summary and mute separately; ordinary alerts obey iOS settings.
3. Import a different MP3/M4A, confirm its displayed filename, preview it, and
   verify the next actual notification uses that sound after restarting the app.
4. Long-press the notification, select **Play full adhan**, lock the phone and
   verify complete playback; reopen and stop it using the in-app control.
5. Enable AlarmKit, grant its permission, and verify the next prayer with screen
   locked. Check whether the custom full file is played, its duration/repetition,
   Focus/Silent behavior and the system **Stop** action. Record the exact iOS
   version and results; do not infer sound playback from a successful API call.
6. Mute adhan and verify silent notification only. Disable a prayer, then the
   master switch; verify those future notification/alarm IDs are no longer pending.
7. Deny/revoke notification or alarm authorization. Check the warning, enable it
   in iPhone Settings, return and tap **Scheduled prayers** to retry if needed.
8. Test a reboot, date rollover, offline cached St. John's timetable, a location
   change and dark/RTL/large-text layouts on the target iPhone.
9. Confirm a failed audio import leaves the previous sound selected. Confirm
   the restored bundled sound works for both notification and alarm modes.

Passing these tests is required before describing 1.1.0 as release-ready. A
successful unsigned build alone does not demonstrate audible delivery, complete
background adhan, App Store acceptance, or production signing/privacy readiness.

Sources: [Apple notification sounds](https://developer.apple.com/documentation/usernotifications/unnotificationsound)
(less than 30 seconds), [Apple AlarmKit scheduling](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit),
[Apple custom alarm sound location](https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:)),
[Codemagic Flutter configuration](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/).
