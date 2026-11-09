import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/fire_alarm.dart';
import '../attendance/attendance_overview_screen.dart';
import '../auth/login_screen.dart';
import '../incident/incident_detail_screen.dart';
import '../incident/incident_list_screen.dart';
import '../leave/leave_approval_screen.dart';
import '../management/checkpoints_screen.dart';
import '../management/equipment_screen.dart';
import '../management/patrol_monitor_screen.dart';
import '../management/personnel_screen.dart';
import '../management/roster_screen.dart';
import '../management/route_list_screen.dart';
import '../management/site_map_scan_screen.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pendingLeaves = ref
        .watch(leavesProvider)
        .where((l) => l.status == LeaveStatus.pending)
        .length;
    final pendingIncidents =
        ref.watch(incidentsProvider).where((i) => !i.isResolved).length;

    final tabs = [
      _OpsTab(onOpenRoster: () => setState(() => _tab = 1)),
      const RosterScreen(),
      const _PeopleTab(),
      const _SetupTab(),
    ];

    return Scaffold(
      body: tabs[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: pendingIncidents > 0,
                  label: Text('$pendingIncidents'),
                  child: const Icon(Icons.shield_outlined)),
              selectedIcon: const Icon(Icons.shield),
              label: 'Trực ban'),
          const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Lịch trực'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: pendingLeaves > 0,
                  label: Text('$pendingLeaves'),
                  child: const Icon(Icons.groups_outlined)),
              selectedIcon: const Icon(Icons.groups),
              label: 'Nhân sự'),
          const NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Thiết lập'),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

void _logout(BuildContext context) => Navigator.pushReplacement(
    context, MaterialPageRoute(builder: (_) => const LoginScreen()));

class _OpsTab extends ConsumerWidget {
  final VoidCallback onOpenRoster;
  const _OpsTab({required this.onOpenRoster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);
    final pendingIncidents = incidents.where((i) => !i.isResolved).length;
    final schedules = ref.watch(schedulesProvider);
    final patrolling =
        schedules.where((s) => s.status == ScheduleStatus.inProgress).toList();
    final hasSiteMap = ref.watch(siteTracksProvider).isNotEmpty;
    final now = ref.watch(clockProvider)();
    final todayRoster = rosterForDay(ref.watch(rosterProvider), now);
    final attendance = ref.watch(attendanceProvider);
    final names = {for (final p in ref.watch(personnelProvider)) p.id: p.name};
    final onDuty = todayRoster
        .map((e) => shiftStateOf(e, attendance, schedules, now))
        .where((s) => s == ShiftState.checkedIn || s == ShiftState.patrolling)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRUNG TÂM CHỈ HUY'),
        actions: [
          IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FireAlarmBanner(
              onOpen: (inc) =>
                  _open(context, IncidentDetailScreen(incident: inc))),
          if (!hasSiteMap)
            HubTile(
                icon: Icons.travel_explore,
                color: Colors.tealAccent,
                title: 'QUÉT BẢN ĐỒ LẦN ĐẦU',
                subtitle: 'Khu vực chưa có bản đồ – đi một vòng để tạo',
                onTap: () => _open(context, const SiteMapScanScreen())),
          Row(
            children: [
              _Stat('${todayRoster.length}', 'CA HÔM NAY',
                  Icons.event_available, AppColors.roster),
              const SizedBox(width: 10),
              _Stat('$onDuty', 'ĐANG TRỰC', Icons.directions_walk,
                  AppColors.primary),
              const SizedBox(width: 10),
              _Stat(
                  '$pendingIncidents',
                  'SỰ CỐ MỞ',
                  Icons.warning_amber,
                  pendingIncidents > 0
                      ? AppColors.danger
                      : AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('ĐIỀU HÀNH'),
          HubTile(
              icon: Icons.report_problem,
              color: pendingIncidents > 0 ? AppColors.danger : Colors.grey,
              title: 'Sự cố',
              subtitle: pendingIncidents > 0
                  ? 'Có $pendingIncidents sự cố cần xử lý'
                  : 'Tình hình ổn định',
              badge: pendingIncidents > 0 ? '$pendingIncidents' : null,
              onTap: () => _open(context, const IncidentListScreen())),
          HubTile(
              icon: Icons.radar,
              color: AppColors.primary,
              title: 'Giám sát tuần tra',
              subtitle: patrolling.isEmpty
                  ? 'Không có ca nào đang đi tuần'
                  : '${patrolling.length} ca đang đi tuần • '
                      '${patrolling.map((s) => s.guardName).join(', ')}',
              onTap: () => _open(context, const PatrolMonitorScreen())),
          const SizedBox(height: 8),
          SectionTitle('CA TRỰC HÔM NAY • ${formatDate(now)}',
              trailing: TextButton(
                  onPressed: onOpenRoster, child: const Text('Xem lịch'))),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final shift in ShiftType.values)
                    _TodayShiftRow(
                      shift: shift,
                      entries: todayRoster
                          .where((e) => e.shift == shift)
                          .map((e) => (
                                names[e.personnelId] ?? 'Đã xóa',
                                shiftStateOf(e, attendance, schedules, now)
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            FittedBox(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayShiftRow extends StatelessWidget {
  final ShiftType shift;
  final List<(String, ShiftState)> entries;
  const _TodayShiftRow({required this.shift, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shift.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(shift.timeRange,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Text('Chưa phân ca',
                    style: TextStyle(
                        color: Colors.white38, fontStyle: FontStyle.italic))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (name, state) in entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(name,
                                      style: const TextStyle(
                                          color: Colors.white70))),
                              Icon(Icons.circle,
                                  size: 8, color: shiftStateColor(state)),
                              const SizedBox(width: 4),
                              Text(state.label,
                                  style: TextStyle(
                                      color: shiftStateColor(state),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeopleTab extends ConsumerWidget {
  const _PeopleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(personnelProvider);
    final active = personnel.where((p) => p.isActive).length;
    final now = ref.watch(clockProvider)();
    final monthRecords = ref
        .watch(attendanceProvider)
        .where((a) =>
            a.date.year == now.year &&
            a.date.month == now.month &&
            a.isComplete)
        .toList();
    final hours = monthRecords.fold<double>(0, (s, a) => s + a.workedHours);
    final pending = ref
        .watch(leavesProvider)
        .where((l) => l.status == LeaveStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
          title:
              const Text('NHÂN SỰ', style: TextStyle(color: AppColors.people)),
          iconTheme: const IconThemeData(color: AppColors.people)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HubTile(
              icon: Icons.badge,
              color: AppColors.people,
              title: 'Nhân viên',
              subtitle: '$active đang làm việc'
                  '${personnel.length > active ? ' • ${personnel.length - active} đã nghỉ' : ''}',
              onTap: () => _open(context, const PersonnelScreen())),
          HubTile(
              icon: Icons.fact_check,
              color: Colors.lightGreenAccent,
              title: 'Chấm công',
              subtitle: 'Tháng ${now.month}: ${monthRecords.length} ca • '
                  '${hours.toStringAsFixed(0)} giờ công',
              onTap: () => _open(context, const AttendanceOverviewScreen())),
          HubTile(
              icon: Icons.beach_access,
              color: AppColors.leave,
              title: 'Nghỉ phép',
              subtitle: pending > 0
                  ? '$pending đơn đang chờ duyệt'
                  : 'Không có đơn chờ duyệt',
              badge: pending > 0 ? '$pending' : null,
              onTap: () => _open(context, const LeaveApprovalScreen())),
        ],
      ),
    );
  }
}

class _SetupTab extends ConsumerWidget {
  const _SetupTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(siteTracksProvider).length;
    final routes = ref.watch(routeConfigsProvider);
    final points = routes.fold<int>(0, (s, r) => s + r.checkpoints.length);
    final equipment = ref.watch(equipmentProvider);
    final ready =
        equipment.where((e) => e.status == EquipmentStatus.available).length;

    return Scaffold(
      appBar: AppBar(
          title:
              const Text('THIẾT LẬP', style: TextStyle(color: AppColors.setup)),
          iconTheme: const IconThemeData(color: AppColors.setup)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('KHU VỰC TUẦN TRA'),
          HubTile(
              icon: Icons.travel_explore,
              color: Colors.tealAccent,
              title: 'Bản đồ khu vực',
              subtitle: tracks == 0
                  ? 'Chưa quét – đi một vòng để tạo bản đồ'
                  : '$tracks đoạn đường đã quét',
              onTap: () => _open(context, const SiteMapScanScreen())),
          HubTile(
              icon: Icons.qr_code_2,
              color: AppColors.setup,
              title: 'Lộ trình & mã QR',
              subtitle: '${routes.length} lộ trình • $points điểm tuần tra',
              onTap: () => _open(context, const RouteListScreen())),
          HubTile(
              icon: Icons.add_location_alt,
              color: Colors.purpleAccent,
              title: 'Địa điểm & mã QR',
              subtitle: '$points địa điểm • thêm địa điểm, tạo và in mã QR',
              onTap: () => _open(context, const CheckpointsScreen())),
          const SizedBox(height: 8),
          const SectionTitle('TRANG BỊ'),
          HubTile(
              icon: Icons.inventory_2,
              color: AppColors.warning,
              title: 'Thiết bị',
              subtitle: '${equipment.length} thiết bị • $ready sẵn sàng',
              onTap: () => _open(context, const EquipmentScreen())),
          const SizedBox(height: 8),
          const SectionTitle('HỆ THỐNG'),
          HubTile(
              icon: Icons.restore,
              color: AppColors.textMuted,
              title: 'Khôi phục dữ liệu mẫu',
              subtitle: 'Xóa dữ liệu đã lưu, nạp lại dữ liệu ban đầu',
              onTap: () => _confirmReset(context, ref)),
          HubTile(
              icon: Icons.logout,
              color: AppColors.danger,
              title: 'Đăng xuất',
              subtitle: 'Quay lại màn hình xác thực',
              onTap: () => _logout(context)),
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
            'Toàn bộ sự cố, lịch trực, lộ trình, nhân sự, thiết bị và bản đồ đã lưu sẽ bị xóa và thay bằng dữ liệu mẫu ban đầu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('KHÔI PHỤC',
                  style: TextStyle(color: AppColors.danger))),
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
}
