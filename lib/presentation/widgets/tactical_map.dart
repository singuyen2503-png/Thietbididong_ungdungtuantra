import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/theme/app_theme.dart';
import '../../core/utils/lat_lng.dart';
import '../../domain/entities/models.dart';

const defaultMapCenter = LatLng(10.776900, 106.700900);

ll.LatLng _ll(LatLng p) => ll.LatLng(p.latitude, p.longitude);

class TacticalMap extends StatelessWidget {
  final List<LatLng> plannedPath;
  final List<LatLng> actualPath;
  final List<Checkpoint> checkpoints;
  final List<List<LatLng>> siteTracks;
  final LatLng? currentLocation;
  final ValueChanged<LatLng>? onTap;
  final bool fitToContent;

  const TacticalMap({
    super.key,
    this.plannedPath = const [],
    this.actualPath = const [],
    this.checkpoints = const [],
    this.siteTracks = const [],
    this.currentLocation,
    this.onTap,
    this.fitToContent = true,
  });

  List<ll.LatLng> get _allPoints => [
        ...plannedPath.map(_ll),
        ...actualPath.map(_ll),
        ...checkpoints.map((c) => _ll(c.location)),
        for (final t in siteTracks) ...t.map(_ll),
        if (currentLocation != null) _ll(currentLocation!),
      ];

  @override
  Widget build(BuildContext context) {
    final points = _allPoints;
    final fit = fitToContent && points.length > 1;

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            points.length == 1 ? points.first : _ll(defaultMapCenter),
        initialZoom: 17,
        minZoom: 4,
        maxZoom: 19,
        backgroundColor: AppColors.mapBackground,
        initialCameraFit: fit
            ? CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(40),
                maxZoom: 18)
            : null,
        onTap: onTap == null
            ? null
            : (_, point) => onTap!(LatLng(point.latitude, point.longitude)),
      ),
      children: [
        const _GridLayer(),
        PolylineLayer(polylines: [
          for (final t in siteTracks)
            if (t.length > 1)
              Polyline(
                  points: t.map(_ll).toList(),
                  strokeWidth: 7,
                  color: AppColors.info.withValues(alpha: 0.7)),
          if (plannedPath.length > 1)
            Polyline(
                points: plannedPath.map(_ll).toList(),
                strokeWidth: 4,
                color: Colors.white70,
                pattern: StrokePattern.dashed(segments: const [12, 8])),
          if (actualPath.length > 1)
            Polyline(
                points: actualPath.map(_ll).toList(),
                strokeWidth: 5,
                color: AppColors.primary),
        ]),
        CircleLayer(circles: [
          for (final c in checkpoints)
            CircleMarker(
                point: _ll(c.location),
                radius: c.radiusMeters,
                useRadiusInMeter: true,
                color: (c.isScanned ? AppColors.primary : AppColors.warning)
                    .withValues(alpha: 0.18),
                borderColor:
                    c.isScanned ? AppColors.primary : AppColors.warning,
                borderStrokeWidth: 1.5),
        ]),
        MarkerLayer(markers: [
          for (final c in checkpoints)
            Marker(
              point: _ll(c.location),
              width: 120,
              height: 54,
              alignment: Alignment.center,
              child: _CheckpointPin(name: c.name, scanned: c.isScanned),
            ),
          if (currentLocation != null)
            Marker(
              point: _ll(currentLocation!),
              width: 26,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppColors.info, blurRadius: 14)
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

class _CheckpointPin extends StatelessWidget {
  final String name;
  final bool scanned;
  const _CheckpointPin({required this.name, required this.scanned});

  @override
  Widget build(BuildContext context) {
    final color = scanned ? AppColors.primary : AppColors.warning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(scanned ? Icons.verified : Icons.location_on,
            color: color, size: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.85),
              border: Border.all(color: color.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4)),
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _GridLayer extends StatelessWidget {
  const _GridLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(MapCamera.of(context).pixelOrigin));
  }
}

class _GridPainter extends CustomPainter {
  final Offset origin;
  const _GridPainter(this.origin);

  static const _step = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 1;
    for (var x = -(origin.dx % _step); x < size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = -(origin.dy % _step); y < size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.origin != origin;
}
