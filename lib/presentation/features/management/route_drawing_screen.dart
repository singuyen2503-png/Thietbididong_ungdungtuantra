import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../../domain/entities/models.dart';
import '../../../core/utils/lat_lng.dart';
import '../../widgets/tactical_map.dart';

class RouteDrawingScreen extends ConsumerStatefulWidget {
  const RouteDrawingScreen({super.key});

  @override
  ConsumerState<RouteDrawingScreen> createState() => _RouteDrawingScreenState();
}

class _RouteDrawingScreenState extends ConsumerState<RouteDrawingScreen> {
  final List<LatLng> _plannedPath = [];
  final List<CheckpointConfig> _checkpoints = [];
  bool _isDrawMode = true;
  final _nameCtrl = TextEditingController();
  final String _qrPrefix =
      'PTR${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _undo() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isDrawMode && _plannedPath.isNotEmpty) {
        _plannedPath.removeLast();
      } else if (!_isDrawMode && _checkpoints.isNotEmpty) {
        _checkpoints.removeLast();
      }
    });
  }

  Future<void> _renameCheckpoint(int index) async {
    final ctrl = TextEditingController(text: _checkpoints[index].name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên điểm tuần tra'),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'Tên điểm (VD: Cổng sau)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('LƯU')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    final old = _checkpoints[index];
    setState(() => _checkpoints[index] = CheckpointConfig(
        id: old.id,
        name: name,
        expectedQrCode: old.expectedQrCode,
        location: old.location,
        radiusMeters: old.radiusMeters));
  }

  void _onMapTap(LatLng tapGps) {
    HapticFeedback.selectionClick();

    setState(() {
      if (_isDrawMode) {
        _plannedPath.add(tapGps);
      } else {
        _checkpoints.add(CheckpointConfig(
          id: '${_qrPrefix}_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Điểm ${_checkpoints.length + 1}',
          expectedQrCode: '$_qrPrefix-${_checkpoints.length + 1}',
          location: tapGps,
        ));
      }
    });
  }

  void _saveRoute() {
    if (_nameCtrl.text.trim().isEmpty ||
        _plannedPath.length < 2 ||
        _checkpoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Vui lòng nhập tên, vẽ đường (ít nhất 2 nét) và chọn ít nhất 1 điểm!',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red));
      return;
    }

    final newRoute = RouteConfig(
      id: DateTime.now().toString(),
      name: _nameCtrl.text.trim(),
      plannedPath: List.of(_plannedPath),
      checkpoints: List.of(_checkpoints),
    );

    ref.read(routeConfigsProvider.notifier).addRoute(newRoute);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã lưu Lộ trình thành công!'),
        backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text('CẤU HÌNH LỘ TRÌNH',
            style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF00FF9D),
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Tên Lộ Trình',
                            filled: true,
                            fillColor: Color(0xFF151E2E)))),
                const SizedBox(width: 16),
                ElevatedButton(
                    onPressed: _saveRoute,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF9D)),
                    child: const Text('LƯU LẠI',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)))
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              ChoiceChip(
                label: const Text('VẼ ĐƯỜNG ĐI'),
                selected: _isDrawMode,
                selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                onSelected: (val) => setState(() => _isDrawMode = true),
              ),
              ChoiceChip(
                label: const Text('CHẤM ĐIỂM'),
                selected: !_isDrawMode,
                selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
                onSelected: (val) => setState(() => _isDrawMode = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TacticalMap(
              siteTracks: ref.watch(siteTrackPointsProvider),
              plannedPath: _plannedPath,
              checkpoints: _checkpoints
                  .map((c) => Checkpoint(
                      id: c.id,
                      name: c.name,
                      expectedQrCode: c.expectedQrCode,
                      location: c.location,
                      radiusMeters: c.radiusMeters))
                  .toList(),
              onTap: _onMapTap,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF151E2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                            'Đường: ${_plannedPath.length} nét · Điểm: ${_checkpoints.length}. Chạm bản đồ để vẽ, kéo / chụm 2 ngón để di chuyển, phóng to.',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                                fontSize: 12))),
                    TextButton.icon(
                        onPressed: _undo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('HOÀN TÁC')),
                  ],
                ),
                if (_checkpoints.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < _checkpoints.length; i++)
                        ActionChip(
                            avatar: const Icon(Icons.edit, size: 16),
                            label: Text(_checkpoints[i].name),
                            onPressed: () => _renameCheckpoint(i)),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
