import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import 'shift_detail_screen.dart';

class ShiftCard extends ConsumerWidget {
  const ShiftCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentGuardProvider) == null) return const SizedBox.shrink();
    final shift = ref.watch(currentShiftProvider);
    final schedule = ref.watch(currentGuardScheduleProvider);
    final entry = shift.entry;
    final record = shift.record;
    final now = shift.now;

    String status;
    Color statusColor;
    if (entry == null) {
      status = 'Hôm nay bạn không có ca trực';
      statusColor = AppColors.textMuted;
    } else if (record == null) {
      final missed = entry.end.isBefore(now);
      status = missed ? 'Vắng – không chấm công' : 'Chưa vào ca';
      statusColor = missed ? AppColors.danger : AppColors.warning;
    } else if (!record.isComplete) {
      status = 'Đang trong ca từ ${formatHourMinute(record.checkIn)}'
          '${record.isLate ? ' (trễ ${record.lateMinutes} phút)' : ''}';
      statusColor = AppColors.primary;
    } else {
      status = 'Đã xong ca: ${formatHourMinute(record.checkIn)} - '
          '${formatHourMinute(record.checkOut!)} '
          '(${record.workedHours.toStringAsFixed(1)} giờ)';
      statusColor = AppColors.info;
    }

    final routeName = schedule?.routeName ?? shift.routeName;
    final total = schedule?.checkpoints.length ?? 0;
    final scanned = schedule?.checkpoints.where((c) => c.isScanned).length ?? 0;
    final patrolOpen =
        schedule != null && schedule.status != ScheduleStatus.completed;
    final canPatrol = patrolOpen && (shift.onDuty || entry == null);
    final accent = shift.onDuty ? AppColors.primary : AppColors.info;

    void openDetail() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ShiftDetailScreen()));

    void fail(String message) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.12), AppColors.surface]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, color: accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('CA TRỰC HÔM NAY',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ),
              if (schedule != null)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: scheduleStatusColor(schedule.status),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(schedule.status,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          if (entry != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${entry.shift.label} • ${entry.shift.timeRange}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            )
          else if (schedule != null)
            Text(formatShiftTime(schedule),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: statusColor)),
          if (routeName != null) ...[
            const SizedBox(height: 12),
            Text('Tuyến: $routeName',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
          if (schedule != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : scanned / total,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text('Đã quét $scanned/$total điểm',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          if (shift.canCheckIn)
            _ActionButton(
              icon: Icons.login,
              label: 'VÀO CA',
              color: AppColors.primary,
              onPressed: () {
                final error = startShift(ref);
                if (error != null) return fail(error);
                HapticFeedback.mediumImpact();
              },
            ),
          if (canPatrol)
            _ActionButton(
              icon: Icons.play_arrow,
              label: schedule.status == ScheduleStatus.inProgress
                  ? 'TIẾP TỤC TUẦN TRA'
                  : 'BẮT ĐẦU TUẦN TRA',
              color: AppColors.primary,
              onPressed: openDetail,
            ),
          if (shift.canCheckOut)
            _ActionButton(
              icon: Icons.logout,
              label: 'KẾT THÚC CA',
              color: AppColors.warning,
              outlined: canPatrol,
              onPressed: () {
                endShift(ref);
                HapticFeedback.mediumImpact();
              },
            ),
          if (schedule != null && !canPatrol)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: openDetail,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Xem lộ trình & bản đồ'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onPressed,
      this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final text =
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: outlined
            ? OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: color, side: BorderSide(color: color)),
                icon: Icon(icon),
                label: text,
                onPressed: onPressed)
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: color, foregroundColor: Colors.black),
                icon: Icon(icon),
                label: text,
                onPressed: onPressed),
      ),
    );
  }
}

extension on ShiftType {
  String get short => switch (this) {
        ShiftType.morning => 'S',
        ShiftType.afternoon => 'C',
        ShiftType.night => 'T',
      };
}

class MyWeekStrip extends ConsumerWidget {
  const MyWeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentGuardIdProvider);
    final today = dateOnly(ref.watch(clockProvider)());
    final monday = startOfWeek(today);
    final roster = ref.watch(rosterProvider);
    final leaves = ref.watch(leavesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i));
            final entry = roster
                .where((e) => e.personnelId == id && sameDay(e.date, day))
                .firstOrNull;
            final onLeave = leaves.any((l) =>
                l.personnelId == id &&
                l.status == LeaveStatus.approved &&
                l.covers(day));
            final isToday = sameDay(day, today);
            final label = onLeave ? 'P' : entry?.shift.short ?? '-';
            final color = onLeave
                ? AppColors.leave
                : entry == null
                    ? Colors.white38
                    : AppColors.roster;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: entry != null
                        ? AppColors.roster.withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isToday ? AppColors.roster : AppColors.border,
                        width: isToday ? 1.5 : 1)),
                child: Column(
                  children: [
                    Text(weekdayShort(day),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        const Text('S: sáng • C: chiều • T: tối • P: nghỉ phép',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
