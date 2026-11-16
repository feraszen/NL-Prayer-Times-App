import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../app/app_preferences.dart';
import '../../../core/presentation/islamic_decoration.dart';
import '../../location/data/providers/gps_location_provider.dart';
import '../domain/services/qibla_service.dart';
import 'widgets/qibla_compass.dart';

class QiblaRealScreen extends StatefulWidget {
  const QiblaRealScreen({super.key});
  @override
  State<QiblaRealScreen> createState() => _QiblaRealScreenState();
}

class _QiblaRealScreenState extends State<QiblaRealScreen> {
  StreamSubscription<CompassEvent>? _subscription;
  double? _latitude, _longitude, _bearing, _heading;
  double _unwrappedHeading = 0;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
    _subscription = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          if (event.heading != null) {
            _unwrappedHeading +=
                ((event.heading! - (_heading ?? event.heading!) + 540) % 360) -
                180;
            if (_heading == null) _unwrappedHeading = event.heading!;
          }
          _heading = event.heading;
        });
      },
      onError: (Object error) {
        debugPrint('Compass stream unavailable: $error');
        if (mounted) setState(() => _heading = null);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await const GpsLocationProvider().getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _bearing = const QiblaService().calculateQiblaDirection(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  double get _distance {
    final lat = _latitude! * math.pi / 180,
        target = QiblaService.kaabaLatitude * math.pi / 180;
    final dlat = target - lat,
        dlon = (QiblaService.kaabaLongitude - _longitude!) * math.pi / 180;
    final a =
        math.pow(math.sin(dlat / 2), 2) +
        math.cos(lat) * math.cos(target) * math.pow(math.sin(dlon / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context);
    final aligned =
        _heading != null &&
        _bearing != null &&
        ((_bearing! - _heading! + 540) % 360 - 180).abs() < 5;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: IslamicBackdrop(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _loading ? null : _load,
                            tooltip: p.text('تحديث الموقع', 'Refresh location'),
                            icon: const Icon(
                              CupertinoIcons.refresh,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.text('القبلة', 'Qibla'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _calibrate(p),
                            tooltip: p.text(
                              'معايرة البوصلة',
                              'Compass calibration',
                            ),
                            icon: const Icon(
                              CupertinoIcons.scope,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(70),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else if (_error != null) ...[
                        Text(
                          p.text(
                            'تعذر تحديد موقعك. فعّل الموقع وحاول مجددًا.',
                            'Could not get your location. Enable GPS and retry.',
                          ),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(p.text('إعادة المحاولة', 'Retry')),
                        ),
                      ] else ...[
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: _unwrappedHeading,
                              end: _unwrappedHeading,
                            ),
                            duration: const Duration(milliseconds: 180),
                            builder: (context, value, child) => QiblaCompass(
                              qiblaDirection: _bearing!,
                              heading: value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          aligned
                              ? p.text(
                                  'أنت باتجاه القبلة',
                                  'You are facing the Qibla',
                                )
                              : p.text(
                                  'وجّه السهم الذهبي إلى أعلى',
                                  'Turn until the gold arrow points up',
                                ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: aligned
                                ? const Color(0xFF73DC9F)
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _heading == null
                              ? p.text(
                                  'مستشعر البوصلة غير متاح؛ الاتجاه معروض نسبةً للشمال.',
                                  'Compass unavailable; bearing is shown relative to north.',
                                )
                              : p.text(
                                  'اتجاه الهاتف: ${_heading!.toStringAsFixed(0)}°',
                                  'Phone heading: ${_heading!.toStringAsFixed(0)}°',
                                ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          p.text(
                            'المسافة إلى مكة المكرمة',
                            'Distance to Makkah',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${_distance.toStringAsFixed(1)} ${p.text('كم', 'km')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SurfaceCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _coordinate(
                                p.text('خط العرض', 'Latitude'),
                                _coordinateText(_latitude!, true),
                                CupertinoIcons.globe,
                              ),
                              _coordinate(
                                p.text('خط الطول', 'Longitude'),
                                _coordinateText(_longitude!, false),
                                CupertinoIcons.globe,
                              ),
                              _coordinate(
                                p.text('المصدر', 'Source'),
                                'GPS',
                                CupertinoIcons.location,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: SurfaceCard(
                            padding: EdgeInsets.zero,
                            child: TextButton.icon(
                              onPressed: () => _calibrate(p),
                              icon: const Icon(CupertinoIcons.scope),
                              label: Text(
                                p.text('معايرة البوصلة', 'Calibrate compass'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _coordinateText(double value, bool latitude) =>
      '${value.abs().toStringAsFixed(4)}° ${latitude ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W')}';
  Widget _coordinate(String label, String value, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
  void _calibrate(AppPreferences p) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(p.text('معايرة البوصلة', 'Compass calibration')),
      content: Text(
        p.text(
          'حرّك الهاتف على شكل الرقم 8 عدة مرات، ثم ضعه بشكل أفقي بعيدًا عن المعادن والمغناطيس. دقة الاتجاه تعتمد على مستشعر الهاتف.',
          'Move your phone in a figure-eight several times, then hold it flat away from metal and magnets. Direction accuracy depends on the phone sensor.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(p.text('حسنًا', 'OK')),
        ),
      ],
    ),
  );
}
