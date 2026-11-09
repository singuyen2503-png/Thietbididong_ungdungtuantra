import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import 'checkpoint_editor_screen.dart';
import 'qr_code_screen.dart';

Future<void> openAddCheckpoint(BuildContext context, WidgetRef ref,
    {String? routeId}) async {
  final routes = ref.read(routeConfigsProvider);
  if (routes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hãy vẽ lộ trình trước khi thêm địa điểm!'),
        backgroundColor: Colors.red));
    return;
  }
  final id = routeId ??
      (routes.length == 1
          ? routes.first.id
          : await showModalBottomSheet<String>(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('THÊM ĐỊA ĐIỂM VÀO LỘ TRÌNH',
                          style: TextStyle(
                              color: AppColors.setup,
                              fontWeight: FontWeight.bold)),
                    ),
                    for (final r in routes)
                      ListTile(
                        leading:
                            const Icon(Icons.route, color: AppColors.setup),
                        title: Text(r.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${r.checkpoints.length} địa điểm',
                            style: const TextStyle(color: AppColors.textMuted)),
                        onTap: () => Navigator.pop(ctx, r.id),
                      ),
                  ],
                ),
              ),
            ));
  if (id == null || !context.mounted) return;
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => CheckpointEditorScreen(routeId: id)));
}

class CheckpointsScreen extends ConsumerWidget {
  const CheckpointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routeConfigsProvider);
    final total = routes.fold<int>(0, (s, r) => s + r.checkpoints.length);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.setup),
        title: const Text('ĐỊA ĐIỂM & MÃ QR',
            style: TextStyle(color: AppColors.setup)),
      ),
      body: routes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                    'Chưa có lộ trình nào. Vào "Lộ trình & mã QR" để vẽ lộ trình trước.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                    '$total địa điểm tuần tra • chạm để xem, in hoặc sửa mã QR',
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                for (final r in routes) ...[
                  SectionTitle(r.name.toUpperCase(),
                      trailing: TextButton.icon(
                          onPressed: () =>
                              openAddCheckpoint(context, ref, routeId: r.id),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm'))),
                  for (final c in r.checkpoints)
                    _CheckpointTile(routeId: r.id, checkpoint: c),
                  const SizedBox(height: 12),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.setup,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('THÊM ĐỊA ĐIỂM',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => openAddCheckpoint(context, ref),
      ),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final String routeId;
  final CheckpointConfig checkpoint;
  const _CheckpointTile({required this.routeId, required this.checkpoint});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(3),
          child: QrImageView(
              data: checkpoint.expectedQrCode,
              size: 48,
              backgroundColor: Colors.white),
        ),
        title: Text(checkpoint.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Mã: ${checkpoint.expectedQrCode} • '
            '${checkpoint.radiusMeters.toStringAsFixed(0)} m',
            style: const TextStyle(color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => QrCodeScreen(
                    routeId: routeId, checkpointId: checkpoint.id))),
      ),
    );
  }
}
