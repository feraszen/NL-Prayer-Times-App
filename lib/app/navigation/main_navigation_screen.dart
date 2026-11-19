import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_preferences.dart';
import '../../core/services/adhan_playback_service.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/home_screen_real.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/qibla/presentation/qibla_real_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  void select(int index) => setState(() => currentIndex = index);
  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context);
    final labels = [
      p.text('الرئيسية', 'Home'),
      p.text('القبلة', 'Qibla'),
      p.text('الإعدادات', 'Settings'),
    ];
    const icons = [
      CupertinoIcons.house,
      CupertinoIcons.compass,
      CupertinoIcons.gear_alt,
    ];
    return Scaffold(
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: AdhanPlaybackService.instance.playing,
            builder: (context, playing, _) => playing
                ? SafeArea(
                    bottom: false,
                    child: ListTile(
                      title: Text(
                        p.text('الأذان قيد التشغيل', 'Adhan is playing'),
                      ),
                      trailing: IconButton(
                        tooltip: p.text('إيقاف', 'Stop'),
                        icon: const Icon(CupertinoIcons.stop_circle),
                        onPressed: AdhanPlaybackService.instance.stop,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: AdhanPlaybackService.instance.error,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : SafeArea(
                    bottom: false,
                    child: ListTile(
                      title: Text(
                        p.text(
                          'تعذر تشغيل الصوت. اختر ملفًا متاحًا من الإعدادات.',
                          'Audio unavailable. Choose a local file in Settings.',
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.xmark),
                        onPressed: () =>
                            AdhanPlaybackService.instance.error.value = null,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: switch (currentIndex) {
              0 => HomeScreenReal(onSettings: () => select(2)),
              1 => const QiblaRealScreen(),
              _ => const SettingsScreen(),
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Semantics(
                  selected: currentIndex == i,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => select(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: currentIndex == i
                            ? const LinearGradient(
                                colors: [
                                  AppColors.royalBlue,
                                  AppColors.deepSkyBlue,
                                ],
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[i],
                            color: currentIndex == i
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            size: 25,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: currentIndex == i
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
