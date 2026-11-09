import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/tactical_map.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';

class PatrolMonitorScreen extends ConsumerStatefulWidget {
  const PatrolMonitorScreen({super.key});

  @override
  ConsumerState<PatrolMonitorScreen> createState() =>
      _PatrolMonitorScreenState();
}

class _PatrolMonitorScreenState extends ConsumerState<PatrolMonitorScreen> {
  static const _accent = AppColors.primary;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final active = ref
        .watch(schedulesProvider)
        .where((s) => s.status == ScheduleStatus.inProgress)
        .toList();
    final selected = active.where((s) => s.id == _selectedId).firstOrNull ??
        active.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('GIÁM SÁT TUẦN TRA',
            style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
      ),
      body: selected == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Hiện không có ca tuần tra nào đang diễn ra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            )
          : Column(
              children: [
                Container(
                  height: 260,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.mapCanvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.5))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TacticalMap(
                        key: ValueKey(selected.id),
                        siteTracks: ref.watch(siteTrackPointsProvider),
                        plannedPath: selected.plannedPath,
                        actualPath: selected.actualPath,
                        checkpoints: selected.checkpoints,
                        currentLocation: selected.actualPath.lastOrNull),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final s in active)
                        _ScheduleCard(
                          schedule: s,
                          selected: s.id == selected.id,
                          onTap: () => setState(() => _selectedId = s.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final bool selected;
  final VoidCallback onTap;
  const _ScheduleCard(
      {required this.schedule, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = schedule.checkpoints.length;
    final scanned = schedule.checkpoints.where((c) => c.isScanned).toList();
    final next = schedule.checkpoints.where((c) => !c.isScanned).firstOrNull;
    final lastScan = scanned
        .map((c) => c.scannedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: selected ? AppColors.primary : Colors.white12,
              width: selected ? 2 : 1)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(schedule.guardName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  Text(formatShiftTime(schedule),
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Tuyến: ${schedule.routeName}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : scanned.length / total,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                  'Đã quét ${scanned.length}/$total điểm'
                  '${lastScan == null ? '' : ' • Lần cuối ${formatHourMinute(lastScan)}'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (next != null)
                Text('Điểm kế tiếp: ${next.name}',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
