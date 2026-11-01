import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/utils/lat_lng.dart';
import '../../domain/entities/models.dart';

const defaultMapCenter = LatLng(10.9891919, 106.5798086);

final bool _isTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

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
        backgroundColor: const Color(0xFFE5E3DF),
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
        if (!_isTest)
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
            fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.demo_app',
            maxZoom: 19,
          ),
        PolylineLayer(polylines: [
          for (final t in siteTracks)
            if (t.length > 1)
              Polyline(
                  points: t.map(_ll).toList(),
                  strokeWidth: 7,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.6)),
          if (plannedPath.length > 1)
            Polyline(
                points: plannedPath.map(_ll).toList(),
                strokeWidth: 4,
                color: const Color(0xFF1E3A8A),
                pattern: StrokePattern.dashed(segments: const [12, 8])),
          if (actualPath.length > 1)
            Polyline(
                points: actualPath.map(_ll).toList(),
                strokeWidth: 5,
                color: const Color(0xFF00A86B)),
        ]),
        CircleLayer(circles: [
          for (final c in checkpoints)
            CircleMarker(
                point: _ll(c.location),
                radius: c.radiusMeters,
                useRadiusInMeter: true,
                color:
                    (c.isScanned ? const Color(0xFF00A86B) : Colors.deepOrange)
                        .withValues(alpha: 0.2),
                borderColor:
                    c.isScanned ? const Color(0xFF00A86B) : Colors.deepOrange,
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
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF2563EB), blurRadius: 12)
                  ],
                ),
              ),
            ),
        ]),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: Colors.white70,
            child: const Text('© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black87)),
          ),
        ),
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
    final color = scanned ? const Color(0xFF00A86B) : Colors.deepOrange;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(scanned ? Icons.verified : Icons.location_on,
            color: color, size: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
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
