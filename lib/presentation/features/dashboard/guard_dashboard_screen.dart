import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shift_card.dart';
import '../incident/incident_report_screen.dart';
import '../incident/guard_incident_detail_screen.dart';
import '../auth/login_screen.dart';
import '../attendance/personal_attendance_screen.dart';
import '../leave/leave_request_screen.dart';
import '../../widgets/fire_alarm.dart';
import '../../widgets/slide_to_act_widget.dart';
import '../../state/manager_state.dart';
import '../../../core/theme/app_theme.dart';

class GuardDashboardScreen extends ConsumerWidget {
  const GuardDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String myName = ref.watch(currentGuardProvider)?.name ?? 'Bảo vệ';

    final myIncidents = ref
        .watch(incidentsProvider)
        .where((i) =>
            i.reportedBy == myName || i.assignedBackupNames.contains(myName))
        .toList();

    return Scaffold(
      appBar: AppBar(
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
            const ShiftCard(),
            const SizedBox(height: 24),
            const SectionTitle('LỊCH & CÔNG CỦA TÔI'),
            const MyWeekStrip(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    icon: Icons.fact_check,
                    label: 'CÔNG CỦA TÔI',
                    color: AppColors.info,
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
                    color: AppColors.leave,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaveRequestScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionTitle('SỰ CỐ CỦA TÔI'),
            if (myIncidents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(
                    child: Text('Khu vực an toàn. Không có sự cố.',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              ...myIncidents.map((inc) {
                final isMyReport = inc.reportedBy == myName;
                return Card(
                  color: AppColors.surface,
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
