import 'package:flutter_test/flutter_test.dart';
import 'package:my_ios_app/app/app.dart';

void main() {
  testWidgets(
    'Application starts successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const NLPrayerTimesApp(),
      );

      expect(find.text('Home'), findsOneWidget);
    },
  );
}
