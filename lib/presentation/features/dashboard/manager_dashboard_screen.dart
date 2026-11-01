import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/login_screen.dart';
import '../patrol/schedule_management_screen.dart';
import '../incident/incident_list_screen.dart';
import '../management/personnel_screen.dart';
import '../management/equipment_screen.dart';
import '../management/patrol_monitor_screen.dart';
import '../management/roster_screen.dart';
import '../management/site_map_scan_screen.dart';
import '../attendance/attendance_overview_screen.dart';
import '../incident/incident_detail_screen.dart';
import '../leave/leave_approval_screen.dart';
import '../../../domain/entities/workforce.dart';
import '../../widgets/fire_alarm.dart';
import '../../state/workforce_state.dart';
import '../management/route_list_screen.dart';
import '../../state/manager_state.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF0A0E17);
    const accentColor = Color(0xFF00FF9D);

    final incidents = ref.watch(incidentsProvider);
    final pendingIncidents = incidents.where((i) => !i.isResolved).length;
    final activePersonnel = ref.watch(patrollingGuardIdsProvider).length;
    final activeSchedules = ref
        .watch(schedulesProvider)
        .where((s) => s.status == ScheduleStatus.inProgress)
        .length;
    final pendingLeaves = ref
        .watch(leavesProvider)
        .where((l) => l.status == LeaveStatus.pending)
        .length;
    final hasSiteMap = ref.watch(siteTracksProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        elevation: 0,
        centerTitle: true,
        title: const Text('TRUNG TÂM CHỈ HUY',
            style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'Roboto')),
        actions: [
          IconButton(
              tooltip: 'Khôi phục dữ liệu mẫu',
              icon: const Icon(Icons.restore, color: accentColor),
              onPressed: () => _confirmReset(context, ref)),
          IconButton(
              icon: const Icon(Icons.logout, color: accentColor),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FireAlarmBanner(
                  onOpen: (inc) => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              IncidentDetailScreen(incident: inc)))),
            ),
          ),
          if (!hasSiteMap)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _buildDashboardCard(
                    context,
                    'QUÉT BẢN ĐỒ LẦN ĐẦU',
                    'Khu vực chưa có bản đồ nền – đi một vòng để tạo',
                    Icons.travel_explore,
                    Colors.tealAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SiteMapScanScreen()))),
              ),
            ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('TUYẾN ĐANG TRỰC', activeSchedules.toString(),
                      Icons.route, Colors.blueAccent),
                  _buildStatItem('NHÂN SỰ ĐI TUẦN', activePersonnel.toString(),
                      Icons.directions_walk, accentColor),
                  _buildStatItem(
                      'SỰ CỐ KHẨN',
                      pendingIncidents.toString(),
                      Icons.warning_amber,
                      pendingIncidents > 0 ? Colors.redAccent : Colors.grey),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildDashboardCard(
                  context,
                  'QUẢN LÝ SỰ CỐ',
                  pendingIncidents > 0
                      ? 'Có $pendingIncidents sự cố cần duyệt ngay!'
                      : 'Tình hình ổn định',
                  Icons.report_problem,
                  pendingIncidents > 0 ? Colors.redAccent : Colors.grey,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IncidentListScreen())),
                  isAlert: pendingIncidents > 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDashboardCard(
                  context,
                  'LỊCH TUẦN TRA',
                  'Phân công Lộ trình & Thiết bị',
                  Icons.calendar_month,
                  Colors.greenAccent,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScheduleManagementScreen()))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5),
              delegate: SliverChildListDelegate([
                _buildSmallCard(
                    context,
                    'NHÂN SỰ',
                    Icons.people,
                    Colors.blueAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonnelScreen()))),
                _buildSmallCard(
                    context,
                    'THIẾT BỊ',
                    Icons.inventory,
                    Colors.orangeAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EquipmentScreen()))),
                _buildSmallCard(
                    context,
                    'LỘ TRÌNH & QR',
                    Icons.map,
                    Colors.purpleAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RouteListScreen()))),
                _buildSmallCard(
                    context,
                    'LỊCH TRỰC TUẦN',
                    Icons.view_week,
                    const Color(0xFF38BDF8),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RosterScreen()))),
                _buildSmallCard(
                    context,
                    'CHẤM CÔNG',
                    Icons.fact_check,
                    Colors.lightGreenAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendanceOverviewScreen()))),
                _buildSmallCard(
                    context,
                    pendingLeaves > 0
                        ? 'NGHỈ PHÉP ($pendingLeaves)'
                        : 'NGHỈ PHÉP',
                    Icons.beach_access,
                    Colors.pinkAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LeaveApprovalScreen()))),
                _buildSmallCard(
                    context,
                    'BẢN ĐỒ',
                    Icons.travel_explore,
                    Colors.tealAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SiteMapScanScreen()))),
                _buildSmallCard(
                    context,
                    'GIÁM SÁT',
                    Icons.radar,
                    Colors.cyanAccent,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatrolMonitorScreen()))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu mẫu?'),
        content: const Text(
            'Toàn bộ sự cố, lịch, lộ trình, nhân sự và thiết bị đã lưu sẽ bị xóa và thay bằng dữ liệu mẫu ban đầu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('KHÔI PHỤC',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    await resetAllData(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã khôi phục dữ liệu mẫu'),
          backgroundColor: Colors.green));
    }
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto')),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, VoidCallback onTap,
      {bool isAlert = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: isAlert
                ? Colors.redAccent.withValues(alpha: 0.1)
                : const Color(0xFF151E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isAlert ? Colors.redAccent : Colors.white12, width: 2)),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isAlert ? Colors.redAccent : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF151E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
