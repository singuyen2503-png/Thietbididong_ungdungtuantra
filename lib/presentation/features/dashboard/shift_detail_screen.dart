import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../patrol/patrol_active_screen.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/tactical_map.dart';

class ShiftDetailScreen extends ConsumerWidget {
  const ShiftDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF00FF9D);
    final schedule = ref.watch(currentGuardScheduleProvider);
    final equipments = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CHI TIẾT CA TRỰC',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: schedule == null
          ? const Center(
              child: Text('Bạn chưa được phân công ca trực nào.',
                  style: TextStyle(color: Colors.grey)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LỘ TRÌNH ĐỊA LÝ',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                        color: const Color(0xFF05080D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TacticalMap(
                          siteTracks: ref.watch(siteTrackPointsProvider),
                          plannedPath: schedule.plannedPath,
                          actualPath: schedule.actualPath,
                          checkpoints: schedule.checkpoints),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF151E2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('THỜI GIAN',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${formatShiftTime(schedule)} (Hôm nay)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto')),
                        const Divider(color: Colors.white24, height: 32),
                        const Text('TUYẾN ĐƯỜNG',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(schedule.routeName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            schedule.checkpoints.map((c) => c.name).join(' → '),
                            style: const TextStyle(color: Colors.white70)),
                        const Divider(color: Colors.white24, height: 32),
                        const Text('THIẾT BỊ ĐƯỢC CẤP',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (schedule.equipmentIds.isEmpty)
                          const Text('Không có thiết bị',
                              style: TextStyle(color: Colors.white54)),
                        ...equipments
                            .where((e) => schedule.equipmentIds.contains(e.id))
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    const Icon(Icons.build,
                                        color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text('${e.name} (${e.code})',
                                        style: const TextStyle(
                                            color: Colors.white))
                                  ]),
                                )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: schedule.status == ScheduleStatus.completed
                          ? null
                          : () {
                              if (schedule.status == ScheduleStatus.pending) {
                                ref
                                    .read(schedulesProvider.notifier)
                                    .updateSchedule(schedule.copyWith(
                                        status: ScheduleStatus.inProgress));
                              }
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PatrolActiveScreen()));
                            },
                      icon: const Icon(Icons.play_arrow,
                          size: 28, color: Colors.black),
                      label: Text(
                        schedule.status == ScheduleStatus.completed
                            ? 'CA TRỰC ĐÃ HOÀN THÀNH'
                            : (schedule.status == ScheduleStatus.inProgress
                                ? 'TIẾP TỤC TUẦN TRA'
                                : 'BẮT ĐẦU TUẦN TRA NGAY'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
