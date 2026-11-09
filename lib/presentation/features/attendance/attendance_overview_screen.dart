import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/month_switcher.dart';
import 'personal_attendance_screen.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceOverviewScreen extends ConsumerStatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  ConsumerState<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState
    extends ConsumerState<AttendanceOverviewScreen> {
  static const _accent = AppColors.info;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final personnel = ref.watch(personnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final roster = ref.watch(rosterProvider);
    final leaves = ref.watch(leavesProvider);
    final now = ref.watch(clockProvider)();
    final rows = [
      for (final p in personnel)
        (
          person: p,
          summary: summarize(
              personnelId: p.id,
              month: _month,
              attendance: attendance,
              roster: roster,
              leaves: leaves,
              now: now)
        )
    ];
    final totalShifts = rows.fold(0, (s, r) => s + r.summary.shiftsWorked);
    final totalHours = rows.fold(0.0, (s, r) => s + r.summary.hours);
    final totalLate = rows.fold(0, (s, r) => s + r.summary.lateCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('BẢNG CHẤM CÔNG',
            style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          MonthSwitcher(
              month: _month, onChanged: (m) => setState(() => _month = m)),
          const SizedBox(height: 8),
          Row(children: [
            StatTile(
                label: 'Tổng ca',
                value: '$totalShifts',
                color: AppColors.primary),
            StatTile(
                label: 'Tổng giờ công',
                value: totalHours.toStringAsFixed(1),
                color: _accent),
            StatTile(
                label: 'Lượt đi trễ',
                value: '$totalLate',
                color: Colors.orangeAccent),
          ]),
          const SizedBox(height: 20),
          const Text('THEO NHÂN VIÊN (chạm để xem chi tiết)',
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Chưa có nhân viên.',
                      style: TextStyle(color: Colors.grey))),
            ),
          for (final r in rows)
            Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      r.person.isActive ? Colors.blueAccent : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                    '${r.person.name}${r.person.isActive ? '' : ' (đã nghỉ)'}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${r.summary.shiftsWorked} ca • '
                    '${r.summary.hours.toStringAsFixed(1)} giờ • '
                    'trễ ${r.summary.lateCount} • '
                    'phép ${r.summary.leaveDays} • '
                    'vắng ${r.summary.absentShifts}',
                    style: const TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PersonalAttendanceScreen(
                            personnelId: r.person.id, initialMonth: _month))),
              ),
            ),
        ],
      ),
    );
  }
}
