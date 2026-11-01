import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/month_switcher.dart';

class PersonalAttendanceScreen extends ConsumerStatefulWidget {
  final String personnelId;
  final DateTime? initialMonth;
  const PersonalAttendanceScreen(
      {super.key, required this.personnelId, this.initialMonth});

  @override
  ConsumerState<PersonalAttendanceScreen> createState() =>
      _PersonalAttendanceScreenState();
}

class _PersonalAttendanceScreenState
    extends ConsumerState<PersonalAttendanceScreen> {
  static const _accent = Color(0xFF38BDF8);
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final start = widget.initialMonth ?? ref.read(clockProvider)();
    _month = DateTime(start.year, start.month);
  }

  @override
  Widget build(BuildContext context) {
    final person = ref
        .watch(personnelProvider)
        .where((p) => p.id == widget.personnelId)
        .firstOrNull;
    final attendance = ref.watch(attendanceProvider);
    final roster = ref.watch(rosterProvider);
    final leaves = ref.watch(leavesProvider);
    final now = ref.watch(clockProvider)();
    final summary = summarize(
        personnelId: widget.personnelId,
        month: _month,
        attendance: attendance,
        roster: roster,
        leaves: leaves,
        now: now);
    final records = attendance
        .where((a) =>
            a.personnelId == widget.personnelId &&
            a.date.year == _month.year &&
            a.date.month == _month.month)
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        iconTheme: const IconThemeData(color: _accent),
        title: Text('CÔNG: ${person?.name ?? 'Nhân viên'}',
            style:
                const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          MonthSwitcher(
              month: _month, onChanged: (m) => setState(() => _month = m)),
          const SizedBox(height: 8),
          Row(children: [
            StatTile(
                label: 'Ca đã làm',
                value: '${summary.shiftsWorked}',
                color: const Color(0xFF00FF9D)),
            StatTile(
                label: 'Tổng giờ',
                value: summary.hours.toStringAsFixed(1),
                color: _accent),
            StatTile(
                label: 'Đi trễ',
                value: '${summary.lateCount}',
                color: Colors.orangeAccent),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            StatTile(
                label: 'Phút trễ',
                value: '${summary.lateMinutes}',
                color: Colors.orange),
            StatTile(
                label: 'Ngày nghỉ phép',
                value: '${summary.leaveDays}',
                color: Colors.pinkAccent),
            StatTile(
                label: 'Ca vắng',
                value: '${summary.absentShifts}',
                color: Colors.redAccent),
          ]),
          const SizedBox(height: 20),
          const Text('CHI TIẾT CHẤM CÔNG',
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('Chưa có dữ liệu chấm công trong tháng này.',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ...records.map((a) => _RecordTile(record: a)),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final a = record;
    return Card(
      color: const Color(0xFF151E2E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(a.isComplete ? Icons.check_circle : Icons.timelapse,
            color: a.isComplete ? const Color(0xFF00FF9D) : Colors.orange),
        title: Text(
            '${weekdayShort(a.date)} ${formatDate(a.date)} • ${a.shift.label}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Vào ${formatHourMinute(a.checkIn)} • '
            'Ra ${a.checkOut == null ? '--:--' : formatHourMinute(a.checkOut!)}'
            '${a.isComplete ? ' • ${a.workedHours.toStringAsFixed(1)} giờ' : ''}',
            style: const TextStyle(color: Colors.grey)),
        trailing: a.isLate
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Trễ ${a.lateMinutes}p',
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            : null,
      ),
    );
  }
}
