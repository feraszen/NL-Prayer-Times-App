import 'package:flutter_test/flutter_test.dart';
import 'package:nl_prayer_times_app/app/app.dart';

void main() {
  testWidgets(
    'Application starts successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const NLPrayerTimesApp(),
      );

      expect(
        find.byType(NLPrayerTimesApp),
        findsOneWidget,
      );
    },
  );
}