# NL Prayer Times

Flutter prayer times and Qibla app using GPS, ISNA (15° Fajr/Isha), and Shafi Asr.
The active home screen includes the blue header, sunrise, prayer cards, current
prayer highlight, countdown, and calculation information.

## Run and verify

Use Flutter with Dart 3.12.2 or later:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Android prayer notifications

- Scheduled and immediate prayer tests use `prayer_channel_v2` and the bundled
  `android/app/src/main/res/raw/adhan.mp3` (copied from `adhan_makkah.mp3`).
- The manifest declares the scheduled notification receiver and boot receiver.
  Pending alarms can be restored after reboot or an app update.
- Exact scheduling is used when allowed; otherwise Android's inexact scheduling
  is used, which may deliver late. Allow alarms/reminders in Android settings
  for timely prayer alerts.
- The master switch and each prayer switch update pending alarms immediately.
  Disabling alerts cancels prayer alarms without cancelling diagnostic tests.
- Each refresh calculates seven calendar days separately. Reopen the app at
  least weekly to renew the schedule. Home refreshes at a date change and when
  the app resumes. Sunrise does not produce an adhan notification.
- Local audio selection is a **preview only**. Scheduled alerts use the bundled
  adhan. Android notification channel sound can be changed in system settings.
- Notification support in this version is Android only. Other platforms can
  open the app without initializing Android notification services.

### Physical device acceptance check

1. Install the updated app and allow notifications, location, and exact alarms.
2. Enable prayer notifications in Settings.
3. Tap **Test Adhan After 30 Seconds**, put the app in the background, and lock
   the phone. Confirm a visible notification and audible adhan after 30 seconds.
4. Repeat with the app removed from Recents (do not use Android Force stop).
5. Disable one prayer and confirm its IDs are absent from pending diagnostics;
   disable the master switch and confirm all prayer IDs are removed.
6. Re-enable alerts, reboot, and check a future prayer alarm is delivered.
7. Check an actual prayer time on the target Samsung device.

Channel settings, silent mode, Do Not Disturb, and manufacturer restrictions
can affect sound. A notification sound is controlled by Android; this does not
implement a foreground service guaranteeing uninterrupted full-length adhan.
Automated tests check scheduling calls, preferences, IDs, timezone, and sound
configuration; they cannot prove audible delivery on a physical device.

## Three-screen Islamic design

Home, Qibla, and Settings follow a royal blue / white / soft gold design with
vector Islamic patterns, a mosque silhouette, rounded cards, and Cupertino
icons. Calendar is intentionally absent from the navigation.

- Arabic and English can be selected in Settings; layout direction changes
  immediately. Theme and 12/24-hour time format are applied and persisted.
- Apple platforms use the system font; Android uses the bundled IBM Plex Sans
  Arabic font (OFL license included). No network font download is required.
- Home uses the current GPS city when reverse geocoding is available. Offline
  or unavailable city lookup falls back to a GPS label without inventing a city.
- Qibla displays a live sensor heading, a rotating compass, great-circle distance
  to the Kaaba, and signed hemisphere coordinates. If there is no sensor, the
  screen explicitly shows the bearing relative to north. Calibration provides
  figure-eight instructions; it does not pretend to calibrate the sensor itself.
- The adhan switch selects a separate silent notification channel when disabled,
  keeping visible prayer reminders. Audio volume in Settings affects the preview
  only; Android controls notification channel volume and sound.

To capture rendered previews while running the design flow test:

```sh
flutter test --dart-define=CAPTURE_UI=true test/design_flow_test.dart
```

Images are written to `build/design-previews`. Test fixtures supply location and
sensor data for these previews; production screens use the device GPS and sensor.

## Al-Falah prayer start times (1.0.1)

Settings → Prayer time source offers **GPS ISNA** (the existing default) and
**Al-Falah — St. John's**. The latter uses the exact daily calculation endpoint
currently called by `https://alfalahnl.ca/`:

`https://api.aladhan.com/v1/timingsByCity/DD-MM-YYYY?country=canada&city=st%20johns&method=2&school=0`

It loads prayer **start** times, not mosque iqama times. Dates and the
`America/St_Johns` timezone are validated, fetched dates are cached, and duplicate
requests for a date share one fetch. Online data is refreshed on a subsequent
calendar day; if unavailable, a valid cache for that same requested date is used.
Missing dates are never silently replaced by GPS calculations.

Home and the seven-day notification scheduler use one loading/adjustment path.
Five optional minute adjustments (-30…+30, initially zero) apply exactly once to
both displayed times and alarms. Sunrise is not adjusted or notified. Home uses
the selected source's actual next-day Fajr after Isha. All seven daily schedules
must load before existing alarms are cancelled, so a failed source refresh leaves
previously scheduled alarms intact. Switching a source or adjustment in Settings
rolls back that preference if rescheduling fails.

The November 16, 2026 screenshot matches the checked daily endpoint:
05:38 / 07:07 / 11:46 / 14:03 / 16:23 / 17:53. The older screenshots supplied for
November 12–15 show Asr one minute later than the endpoint returns when checked
now. Their historical discrepancy is recorded in the delivery comparison file;
no permanent global +1/+2 minute shift or daily hardcoded prayer time is applied.
The app follows the calculation source currently used by the website; this is
not an official historical timetable archive or an iqama synchronization service.

The source requires Internet access when a requested date has not been saved.
After selecting Al-Falah, leave manual adjustments at zero to follow it directly.
