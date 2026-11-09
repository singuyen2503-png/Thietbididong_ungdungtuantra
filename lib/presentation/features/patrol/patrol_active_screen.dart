import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../state/patrol_state.dart';
import '../../widgets/tactical_radar_widget.dart';
import '../../../core/utils/geo_utils.dart';
import 'mock_qr_scanner_screen.dart';
import 'real_qr_scanner_screen.dart';
import '../../../core/theme/app_theme.dart';

class PatrolActiveScreen extends ConsumerWidget {
  const PatrolActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkpointsAsync = ref.watch(patrolCheckpointsProvider);
    final currentGuardLocAsync = ref.watch(currentGuardLocationProvider);
    final schedule = ref.watch(currentGuardScheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
            schedule == null ? 'OPS: TUẦN TRA' : 'OPS: ${shiftName(schedule)}',
            style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: checkpointsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, s) => Center(
              child: Text('Lỗi hệ thống: $e',
                  style: const TextStyle(color: Colors.red))),
          data: (checkpoints) {
            final scannedCount = checkpoints.where((c) => c.isScanned).length;
            final progress =
                checkpoints.isEmpty ? 0.0 : scannedCount / checkpoints.length;

            final targets = checkpoints.map((c) => c.location).toList();

            return Column(
              children: [
                currentGuardLocAsync.when(
                  data: (loc) => TacticalRadarWidget(
                    progress: progress,
                    currentGuardLocation: loc,
                    targets: targets,
                  ),
                  loading: () {
                    return Column(
                      children: [
                        TacticalRadarWidget(progress: progress),
                        _buildBanner(
                            'ĐANG KẾT NỐI VỆ TINH GPS...', Colors.orange),
                      ],
                    );
                  },
                  error: (e, s) {
                    return Column(
                      children: [
                        TacticalRadarWidget(progress: progress),
                        _buildBanner('LỖI GPS: ${e.toString()}', Colors.red),
                      ],
                    );
                  },
                ),
                if (checkpoints.isNotEmpty &&
                    scannedCount == checkpoints.length)
                  _buildBanner(
                      'HOÀN THÀNH TUẦN TRA: $scannedCount/${checkpoints.length} ĐIỂM',
                      AppColors.primary),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: checkpoints.length,
                    itemBuilder: (context, index) {
                      final cp = checkpoints[index];
                      return _buildTacticalCheckpointCard(
                          context, ref, cp, currentGuardLocAsync.value);
                    },
                  ),
                )
              ],
            );
          }),
    );
  }

  Widget _buildBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
          child: Text(text,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: color))),
    );
  }

  Widget _buildTacticalCheckpointCard(BuildContext context, WidgetRef ref,
      Checkpoint cp, Map<String, double>? guardLoc) {
    final isDone = cp.isScanned;

    final bool hasGps = guardLoc != null;
    final double distanceMeters = hasGps
        ? GeoUtils.calculateDistance(guardLoc['lat']!, guardLoc['lng']!,
            cp.location.latitude, cp.location.longitude)
        : 99999.0;

    final bool isInRange = hasGps && distanceMeters <= cp.radiusMeters;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDone
                ? AppColors.primary
                : (isInRange ? Colors.blueAccent : Colors.white12),
            width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    isDone
                        ? Icons.gps_fixed
                        : (isInRange ? Icons.radar : Icons.gps_off),
                    color: isDone
                        ? AppColors.primary
                        : (isInRange ? Colors.blueAccent : Colors.grey),
                    size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cp.name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDone
                                  ? Colors.white
                                  : Colors.grey.shade400)),
                      Text(
                          'Tọa độ: ${cp.location.latitude}, ${cp.location.longitude}',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.blue.shade200)),
                      const SizedBox(height: 4),
                      if (!isDone && hasGps)
                        Text(
                          'Khoảng cách: ${distanceMeters.toStringAsFixed(1)}m (Bán kính: ${cp.radiusMeters}m)',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isInRange
                                  ? AppColors.primary
                                  : Colors.redAccent),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isDone) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isInRange
                      ? () async {
                          HapticFeedback.heavyImpact();

                          if (kIsWeb) {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MockQrScannerScreen(
                                        expectedQr: cp.expectedQrCode)));
                            if (result == true && context.mounted) {
                              ref
                                  .read(patrolCheckpointsProvider.notifier)
                                  .scanCheckpoint(cp);
                            }
                            return;
                          }

                          final status = await Permission.camera.request();
                          if (!status.isGranted) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Cần cấp quyền Camera để quét QR!'),
                                      backgroundColor: Colors.red));
                            }
                            return;
                          }

                          if (context.mounted) {
                            final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RealQrScannerScreen(
                                        expectedQr: cp.expectedQrCode)));
                            if (result == true && context.mounted) {
                              ref
                                  .read(patrolCheckpointsProvider.notifier)
                                  .scanCheckpoint(cp);
                            }
                          }
                        }
                      : () {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'BẠN ĐANG Ở QUÁ XA MỤC TIÊU! KHÔNG THỂ QUÉT.'),
                              backgroundColor: Colors.red));
                        },
                  icon: Icon(isInRange ? Icons.camera_alt : Icons.block,
                      color: isInRange ? Colors.black : Colors.white70),
                  label: Text(
                      isInRange ? 'MỞ CAMERA QUÉT QR' : 'QUÁ XA ĐỂ QUÉT',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: isInRange ? Colors.black : Colors.white70,
                          letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isInRange ? AppColors.primary : Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                ),
              )
            ] else ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(cp.isSynced ? Icons.cloud_done : Icons.cloud_off,
                      color:
                          cp.isSynced ? Colors.blueAccent : Colors.orangeAccent,
                      size: 16),
                  const SizedBox(width: 8),
                  Text(cp.isSynced ? 'ĐÃ ĐỒNG BỘ MÁY CHỦ' : 'ĐANG CHỜ MẠNG...',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: cp.isSynced
                              ? Colors.blueAccent
                              : Colors.orangeAccent,
                          fontWeight: FontWeight.bold)),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
