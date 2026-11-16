import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nl_prayer_times_app/core/services/custom_adhan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final audio = CustomAdhanService();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CustomAdhanService.channel, null),
  );

  test(
    'import persists durable URI and restores previous choice on rollback',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(CustomAdhanService.channel, (call) async {
            expect(call.method, 'importAudio');
            expect(call.arguments['path'], '/picker/cache/selected.mp3');
            return {
              'uri': 'content://media/audio/7',
              'token': 'seven',
              'path': '/app/files/notification_audio/seven.mp3',
            };
          });
      final previous = await audio.selection();
      final imported = await audio.importFile(
        '/picker/cache/selected.mp3',
        'My adhan.mp3',
      );
      await audio.save(imported);
      final saved = await CustomAdhanService().selection();
      expect(saved[CustomAdhanService.uriKey], 'content://media/audio/7');
      expect(
        saved[CustomAdhanService.pathKey],
        '/app/files/notification_audio/seven.mp3',
      );
      expect(saved[CustomAdhanService.nameKey], 'My adhan.mp3');
      await audio.save({});
      expect(await audio.selection(), isEmpty);
      await audio.restore(saved);
      expect(await audio.selection(), saved);
      await audio.restore(previous);
      expect(await audio.selection(), isEmpty);
    },
  );

  test('failed import leaves the saved notification audio unchanged', () async {
    await audio.save({
      'uri': 'content://media/audio/1',
      'token': 'one',
      'path': '/app/one.mp3',
      'name': 'Old.mp3',
    });
    final previous = await audio.selection();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CustomAdhanService.channel, (_) async {
          throw PlatformException(code: 'AUDIO_IMPORT_FAILED');
        });
    await expectLater(
      audio.importFile('/bad.mp3', 'bad.mp3'),
      throwsA(isA<PlatformException>()),
    );
    expect(await audio.selection(), previous);
  });
}
