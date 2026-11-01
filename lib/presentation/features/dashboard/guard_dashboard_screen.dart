import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shift_detail_screen.dart';
import '../incident/incident_report_screen.dart';
import '../incident/guard_incident_detail_screen.dart';
import '../auth/login_screen.dart';
import '../attendance/attendance_card.dart';
import '../attendance/personal_attendance_screen.dart';
import '../leave/leave_request_screen.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../widgets/fire_alarm.dart';
import '../../widgets/slide_to_act_widget.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';

class GuardDashboardScreen extends ConsumerWidget {
  const GuardDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF00FF9D);

    final String myName = ref.watch(currentGuardProvider)?.name ?? 'Bảo vệ';

    final schedule = ref.watch(currentGuardScheduleProvider);
    final myIncidents = ref
        .watch(incidentsProvider)
        .where((i) =>
            i.reportedBy == myName || i.assignedBackupNames.contains(myName))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ĐIỀU HÀNH TÁC CHIẾN',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Roboto')),
                Text(myName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                ref.read(currentGuardIdProvider.notifier).state = null;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FireAlarmBanner(
                onOpen: (inc) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            GuardIncidentDetailScreen(incident: inc)))),
            const AttendanceCard(),
            const SizedBox(height: 12),
            const _MyWeekStrip(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    icon: Icons.fact_check,
                    label: 'CÔNG CỦA TÔI',
                    color: const Color(0xFF38BDF8),
                    onTap: () {
                      final id = ref.read(currentGuardIdProvider);
                      if (id == null) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PersonalAttendanceScreen(personnelId: id)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickButton(
                    icon: Icons.beach_access,
                    label: 'XIN NGHỈ PHÉP',
                    color: Colors.pinkAccent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaveRequestScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('CA TUẦN TRA',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            if (schedule == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: const Color(0xFF151E2E),
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(
                    child: Text('Bạn chưa được phân công ca trực nào.',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ShiftDetailScreen())),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF151E2E),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3), width: 1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(formatShiftTime(schedule),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto')))),
                          const SizedBox(width: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: scheduleStatusColor(schedule.status),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(schedule.status,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Tuyến: ${schedule.routeName}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                          'Đã quét ${schedule.checkpoints.where((c) => c.isScanned).length}/${schedule.checkpoints.length} điểm',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      const Text('Nhấn để xem lộ trình & bản đồ...',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            const Text('BẢNG THEO DÕI SỰ CỐ',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            if (myIncidents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: const Color(0xFF151E2E),
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(
                    child: Text('Khu vực an toàn. Không có sự cố.',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              ...myIncidents.map((inc) {
                final isMyReport = inc.reportedBy == myName;
                return Card(
                  color: const Color(0xFF151E2E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color:
                              inc.isResolved ? Colors.green : Colors.redAccent),
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                        isMyReport ? Icons.record_voice_over : Icons.group_add,
                        color: isMyReport
                            ? Colors.blueAccent
                            : Colors.orangeAccent),
                    title: Text(inc.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        isMyReport ? 'Do tôi báo cáo' : 'Yêu cầu tôi chi viện',
                        style: const TextStyle(color: Colors.grey)),
                    trailing: inc.isResolved
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.warning, color: Colors.redAccent),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                GuardIncidentDetailScreen(incident: inc))),
                  ),
                );
              }),
            const SizedBox(height: 48),
            const Center(
                child: Text('TÌNH HUỐNG KHẨN CẤP?',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            const FireAlarmButton(),
            const SizedBox(height: 16),
            SlideToActWidget(
              text: 'VUỐT ĐỂ BÁO CÁO',
              onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IncidentReportScreen())),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.6))),
      icon: Icon(icon, color: color),
      label: FittedBox(
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      onPressed: onTap,
    );
  }
}

class _MyWeekStrip extends ConsumerWidget {
  const _MyWeekStrip();

  static const _short = {
    ShiftType.morning: 'S',
    ShiftType.afternoon: 'C',
    ShiftType.night: 'T',
  };

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
        const Text('LỊCH TRỰC TUẦN NÀY (S: sáng • C: chiều • T: tối • P: phép)',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
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
            final label = onLeave
                ? 'P'
                : entry == null
                    ? '-'
                    : _short[entry.shift]!;
            final color = onLeave
                ? Colors.pinkAccent
                : entry == null
                    ? Colors.white38
                    : const Color(0xFF38BDF8);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: entry != null
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                        : const Color(0xFF151E2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isToday
                            ? const Color(0xFF38BDF8)
                            : Colors.white12)),
                child: Column(
                  children: [
                    Text(weekdayShort(day),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
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
      ],
    );
  }
}
