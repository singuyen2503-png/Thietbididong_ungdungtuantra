import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import 'schedule_create_screen.dart';

class ScheduleManagementScreen extends ConsumerWidget {
  const ScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        title: const Text('LỊCH TUẦN TRA',
            style: TextStyle(
                color: Color(0xFF00FF9D), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF00FF9D)),
      ),
      body: schedules.isEmpty
          ? const Center(
              child: Text('Chưa có lịch tuần tra nào.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];

                final statusColor = scheduleStatusColor(schedule.status);

                return Dismissible(
                  key: Key(schedule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hủy lịch tuần tra?'),
                      content: Text(
                          'Hủy ca "${schedule.routeName}" của ${schedule.guardName}? Thiết bị đã cấp sẽ được thu hồi về kho.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('KHÔNG')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('HỦY LỊCH',
                                style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    if (schedule.status != ScheduleStatus.completed) {
                      ref
                          .read(equipmentProvider.notifier)
                          .releaseEquipments(schedule.equipmentIds);
                    }
                    ref
                        .read(schedulesProvider.notifier)
                        .deleteSchedule(schedule.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hủy lịch tuần tra')));
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFF151E2E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(schedule.routeName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(schedule.status,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const Divider(color: Colors.white12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.person, color: Colors.white)),
                            title: Text('Phụ trách: ${schedule.guardName}',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Ca: ${formatShiftTime(schedule)}\nĐã quét ${schedule.checkpoints.where((c) => c.isScanned).length}/${schedule.checkpoints.length} điểm kiểm tra\nĐược cấp ${schedule.equipmentIds.length} thiết bị',
                                style: const TextStyle(color: Colors.white70)),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScheduleCreateScreen())),
        backgroundColor: const Color(0xFF00FF9D),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('TẠO LỊCH MỚI',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
