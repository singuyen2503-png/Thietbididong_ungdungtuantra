import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';

class AttendanceCard extends ConsumerWidget {
  const AttendanceCard({super.key});

  static const _accent = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentGuardProvider);
    if (me == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final today = dateOnly(now);
    final roster = ref.watch(rosterProvider);
    final attendance = ref.watch(attendanceProvider);

    final candidates = roster
        .where((e) =>
            e.personnelId == me.id &&
            (sameDay(e.date, today) ||
                (sameDay(e.date, today.subtract(const Duration(days: 1))) &&
                    e.end.isAfter(now))))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final entry = candidates.where((e) => e.end.isAfter(now)).firstOrNull ??
        candidates.lastOrNull;

    AttendanceRecord? record;
    if (entry != null) {
      record = attendance
          .where((a) =>
              a.personnelId == me.id &&
              sameDay(a.date, entry.date) &&
              a.shift == entry.shift)
          .firstOrNull;
    }

    String status;
    Color statusColor;
    if (entry == null) {
      status = 'Hôm nay bạn không có ca trực';
      statusColor = Colors.grey;
    } else if (record == null) {
      status =
          entry.end.isBefore(now) ? 'Vắng – không chấm công' : 'Chưa vào ca';
      statusColor =
          entry.end.isBefore(now) ? Colors.redAccent : Colors.orangeAccent;
    } else if (!record.isComplete) {
      status = 'Đang trong ca từ ${formatHourMinute(record.checkIn)}'
          '${record.isLate ? ' (trễ ${record.lateMinutes} phút)' : ''}';
      statusColor = const Color(0xFF00FF9D);
    } else {
      status = 'Đã xong ca: ${formatHourMinute(record.checkIn)} - '
          '${formatHourMinute(record.checkOut!)} '
          '(${record.workedHours.toStringAsFixed(1)} giờ)';
      statusColor = Colors.lightBlueAccent;
    }

    final canCheckIn =
        entry != null && record == null && entry.end.isAfter(now);
    final canCheckOut = record != null && !record.isComplete;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF151E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    entry == null
                        ? 'CHẤM CÔNG'
                        : 'CHẤM CÔNG • ${entry.shift.label} ${entry.shift.timeRange}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(status, style: TextStyle(color: statusColor)),
          if (canCheckIn || canCheckOut) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canCheckIn ? const Color(0xFF00FF9D) : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: Icon(canCheckIn ? Icons.login : Icons.logout,
                    color: Colors.black),
                label: Text(canCheckIn ? 'VÀO CA' : 'KẾT THÚC CA',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final time = ref.read(clockProvider)();
                  if (canCheckIn) {
                    final error = ref
                        .read(attendanceProvider.notifier)
                        .checkIn(me.id, entry, time);
                    if (error != null) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error), backgroundColor: Colors.red));
                      return;
                    }
                  } else {
                    ref
                        .read(attendanceProvider.notifier)
                        .checkOut(record!.id, time);
                  }
                  HapticFeedback.mediumImpact();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
