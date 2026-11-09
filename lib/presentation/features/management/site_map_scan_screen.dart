import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/lat_lng.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/tactical_map.dart';
import '../../../core/theme/app_theme.dart';

class SiteMapScanScreen extends ConsumerStatefulWidget {
  const SiteMapScanScreen({super.key});

  @override
  ConsumerState<SiteMapScanScreen> createState() => _SiteMapScanScreenState();
}

class _SiteMapScanScreenState extends ConsumerState<SiteMapScanScreen> {
  static const _accent = AppColors.primary;
  static const _useRealGps = bool.fromEnvironment('USE_REAL_GPS');
  static const _stepMeters = 4.0;

  LatLng _walker = defaultMapCenter;
  LatLng? _target;
  bool _recording = false;
  final List<LatLng> _track = [];
  Timer? _timer;
  StreamSubscription<Position>? _gps;

  @override
  void dispose() {
    _timer?.cancel();
    _gps?.cancel();
    super.dispose();
  }

  double _distance(LatLng a, LatLng b) => GeoUtils.calculateDistance(
      a.latitude, a.longitude, b.latitude, b.longitude);

  double get _trackLength {
    double total = 0;
    for (int i = 1; i < _track.length; i++) {
      total += _distance(_track[i - 1], _track[i]);
    }
    return total;
  }

  void _record(LatLng point) {
    if (_track.isEmpty || _distance(_track.last, point) >= 2) {
      _track.add(point);
    }
  }

  void _tick(Timer _) {
    final target = _target;
    if (target == null) return;
    final d = _distance(_walker, target);
    setState(() {
      if (d <= _stepMeters) {
        _walker = target;
        _target = null;
      } else {
        final f = _stepMeters / d;
        _walker = LatLng(
            _walker.latitude + (target.latitude - _walker.latitude) * f,
            _walker.longitude + (target.longitude - _walker.longitude) * f);
      }
      if (_recording) _record(_walker);
    });
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _track
        ..clear()
        ..add(_walker);
    });
    if (!_useRealGps) {
      _timer ??= Timer.periodic(const Duration(milliseconds: 100), _tick);
      return;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Chưa cấp quyền vị trí');
      }
      _gps = Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high, distanceFilter: 2))
          .listen((p) => setState(() {
                _walker = LatLng(p.latitude, p.longitude);
                if (_recording) _record(_walker);
              }));
    } catch (e) {
      if (!mounted) return;
      setState(() => _recording = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không lấy được GPS: $e'),
          backgroundColor: Colors.red));
    }
  }

  void _stopAndSave() {
    _gps?.cancel();
    _gps = null;
    final points = List<LatLng>.from(_track);
    setState(() {
      _recording = false;
      _track.clear();
    });
    if (points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đường đi quá ngắn, chưa lưu.'),
          backgroundColor: Colors.orange));
      return;
    }
    ref.read(siteTracksProvider.notifier).addTrack(points);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã lưu đường đi vào bản đồ nền.'),
        backgroundColor: Colors.green));
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bản đồ nền?'),
        content: const Text('Toàn bộ đường đi đã quét sẽ bị xóa để quét lại.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('XÓA', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) ref.read(siteTracksProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(siteTrackPointsProvider);
    final checkpoints = {
      for (final r in ref.watch(routeConfigsProvider))
        for (final c in r.checkpoints)
          c.id: Checkpoint(
              id: c.id,
              name: c.name,
              expectedQrCode: c.expectedQrCode,
              location: c.location,
              radiusMeters: c.radiusMeters)
    };
    final firstTime = tracks.isEmpty && !_recording;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('QUÉT BẢN ĐỒ KHU VỰC',
            style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
        actions: [
          if (tracks.isNotEmpty && !_recording)
            IconButton(
                tooltip: 'Xóa bản đồ để quét lại',
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                onPressed: _clear),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Text(
              firstTime
                  ? 'Khu vực chưa có bản đồ. Bấm "BẮT ĐẦU QUÉT" rồi đi một vòng '
                      'các lối đi nội bộ để tạo bản đồ nền lần đầu.'
                  : _recording
                      ? (_useRealGps
                          ? 'Đang ghi theo GPS thật... hãy đi dọc lối đi.'
                          : 'Chạm vào bản đồ để đi tới điểm đó (giả lập bước đi).')
                      : 'Đã có ${tracks.length} đoạn đường. Có thể quét thêm đoạn mới.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: TacticalMap(
              siteTracks: [...tracks, if (_track.length > 1) _track],
              checkpoints: checkpoints.values.toList(),
              currentLocation: _walker,
              onTap: _recording && !_useRealGps
                  ? (point) => setState(() => _target = point)
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                if (_recording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Đã ghi ${_track.length} điểm • ${_trackLength.toStringAsFixed(0)} m',
                        style: const TextStyle(
                            color: _accent, fontWeight: FontWeight.bold)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _recording ? Colors.redAccent : _accent),
                    icon: Icon(_recording ? Icons.stop : Icons.radar,
                        color: Colors.black),
                    label: Text(
                        _recording ? 'DỪNG & LƯU ĐƯỜNG ĐI' : 'BẮT ĐẦU QUÉT',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    onPressed: _recording ? _stopAndSave : _start,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
