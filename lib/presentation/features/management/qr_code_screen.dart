import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../state/manager_state.dart';
import 'checkpoint_editor_screen.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  final String routeId;
  final String checkpointId;

  const QrCodeScreen(
      {super.key, required this.routeId, required this.checkpointId});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  static const _accent = AppColors.setup;
  final _cardKey = GlobalKey();
  bool _sharing = false;

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green));
  }

  Future<void> _share(String name, String code) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final safe = code.replaceAll(RegExp(r'[^\w]+'), '_');
      final file = File('${dir.path}/ma_qr_$safe.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Mã QR điểm tuần tra: $name ($code)'));
    } catch (_) {
      if (mounted) _toast('Không tạo được ảnh mã QR!', error: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa điểm?'),
        content: Text(
            'Xóa "$name" khỏi lộ trình? Mã QR đã in tại điểm này sẽ không còn hiệu lực.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('XÓA', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error =
        deleteCheckpoint(ref.read, widget.routeId, widget.checkpointId);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    HapticFeedback.heavyImpact();
    _toast('Đã xóa địa điểm "$name"');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final route = ref
        .watch(routeConfigsProvider)
        .where((r) => r.id == widget.routeId)
        .firstOrNull;
    final cp = route?.checkpoints
        .where((c) => c.id == widget.checkpointId)
        .firstOrNull;
    final index = route?.checkpoints.indexWhere((c) => c.id == cp?.id) ?? -1;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('MÃ QR ĐỊA ĐIỂM', style: TextStyle(color: _accent)),
        actions: [
          if (cp != null) ...[
            IconButton(
                tooltip: 'Sửa địa điểm',
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CheckpointEditorScreen(
                            routeId: widget.routeId, checkpoint: cp)))),
            IconButton(
                tooltip: 'Xóa địa điểm',
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _delete(cp.name)),
          ],
        ],
      ),
      body: cp == null
          ? const Center(
              child: Text('Địa điểm không còn tồn tại.',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text(
                              'ĐIỂM ${index + 1} • ${route!.name.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          QrImageView(
                              data: cp.expectedQrCode,
                              size: 230,
                              backgroundColor: Colors.white),
                          const SizedBox(height: 10),
                          Text(cp.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900)),
                          Text('Nội dung mã: ${cp.expectedQrCode}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.route, color: _accent),
                        title: Text(route.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: const Text('Lộ trình',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.gps_fixed, color: _accent),
                        title: Text(
                            '${cp.location.latitude.toStringAsFixed(6)}, '
                            '${cp.location.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            'Bán kính quét ${cp.radiusMeters.toStringAsFixed(0)} m',
                            style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _accent),
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share),
                    label: const Text('CHIA SẺ / IN MÃ QR'),
                    onPressed: _sharing
                        ? null
                        : () => _share(cp.name, cp.expectedQrCode),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                    'Gửi ảnh mã QR qua Zalo, Drive, email hoặc máy in, rồi dán đúng tại địa điểm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
    );
  }
}
