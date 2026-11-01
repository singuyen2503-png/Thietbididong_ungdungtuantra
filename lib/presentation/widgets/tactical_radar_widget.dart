import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/lat_lng.dart';

class TacticalRadarWidget extends StatefulWidget {
  final double progress;
  final Map<String, double>? currentGuardLocation;
  final List<LatLng>? targets;

  const TacticalRadarWidget({
    super.key,
    required this.progress,
    this.currentGuardLocation,
    this.targets,
  });

  @override
  State<TacticalRadarWidget> createState() => _TacticalRadarWidgetState();
}

class _TacticalRadarWidgetState extends State<TacticalRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
          color: const Color(0xFF0A0E17),
          border: Border(
              bottom: BorderSide(
                  color: const Color(0xFF00FF9D).withValues(alpha: 0.3),
                  width: 2))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3), width: 1)),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5), width: 1)),
          ),
          Container(
              width: 250,
              height: 1,
              color: Colors.green.withValues(alpha: 0.3)),
          Container(
              width: 1,
              height: 250,
              color: Colors.green.withValues(alpha: 0.3)),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF00FF9D).withValues(alpha: 0.0),
                        const Color(0xFF00FF9D).withValues(alpha: 0.6)
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.currentGuardLocation != null && widget.targets != null)
            ..._buildDynamicTargets(),
          _buildBlip(const Color(0xFF00FF9D), size: 12),
          Positioned(
            bottom: 16,
            right: 16,
            child: Text('ĐÃ HOÀN TẤT ${(widget.progress * 100).toInt()}%',
                style: const TextStyle(
                    color: Color(0xFF00FF9D),
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const Positioned(
            top: 16,
            left: 16,
            child: Text('ĐỊNH VỊ GPS: SẴN SÀNG',
                style: TextStyle(
                    color: Colors.white70, fontFamily: 'Roboto', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlip(Color color, {double size = 8}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 2)]),
    );
  }

  List<Widget> _buildDynamicTargets() {
    final List<Widget> widgets = [];
    final guardLat = widget.currentGuardLocation!['lat']!;
    final guardLng = widget.currentGuardLocation!['lng']!;

    for (final target in widget.targets!) {
      final double latDiff = target.latitude - guardLat;
      final double lngDiff = target.longitude - guardLng;

      const double scaleFactor = 100 / 0.0005;

      final double dx = lngDiff * scaleFactor;
      final double dy = -latDiff * scaleFactor;

      if (dx * dx + dy * dy <= 10000) {
        widgets.add(Transform.translate(
          offset: Offset(dx, dy),
          child: _buildBlip(Colors.redAccent),
        ));
      }
    }
    return widgets;
  }
}
