import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/utils/date_utils.dart';
import 'package:demo_app/domain/entities/workforce.dart';
import 'package:demo_app/presentation/features/attendance/attendance_card.dart';
import 'package:demo_app/presentation/features/attendance/attendance_overview_screen.dart';
import 'package:demo_app/presentation/features/dashboard/guard_dashboard_screen.dart';
import 'package:demo_app/presentation/features/leave/leave_approval_screen.dart';
import 'package:demo_app/presentation/features/leave/leave_request_screen.dart';
import 'package:demo_app/presentation/features/management/personnel_screen.dart';
import 'package:demo_app/presentation/features/management/roster_screen.dart';
import 'package:demo_app/presentation/features/management/site_map_scan_screen.dart';
import 'package:demo_app/presentation/state/manager_state.dart';
import 'package:demo_app/presentation/state/workforce_state.dart';
import 'package:demo_app/presentation/widgets/fire_alarm.dart';

void main() {
  final today = dateOnly(DateTime.now());
  final morning = ShiftType.morning.startOn(today);

  Future<ProviderContainer> pump(WidgetTester tester, Widget home,
      {String? guard, DateTime? now}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final c = ProviderContainer(overrides: [
      alarmSoundProvider.overrideWithValue(false),
      if (now != null) clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    if (guard != null) c.read(currentGuardIdProvider.notifier).state = guard;
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp(home: Scaffold(body: home))));
    return c;
  }

  testWidgets('Lịch trực tuần hiển thị 7 ngày và phân ca', (tester) async {
    final c = await pump(tester, const RosterScreen());
    expect(find.text('LỊCH TRỰC TUẦN'), findsOneWidget);
    expect(find.textContaining('ca đã phân'), findsOneWidget);
    expect(find.text('Ca Sáng'), findsWidgets);

    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pump();
    expect(find.text('0 ca đã phân'), findsOneWidget);

    await tester.tap(find.byTooltip('Phân Ca Sáng').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trần Thị B'));
    await tester.pumpAndSettle();
    expect(find.text('1 ca đã phân'), findsOneWidget);
    expect(c.read(rosterProvider).last.personnelId, 'p2');
  });

  testWidgets('Bảo vệ chấm công vào ca và kết thúc ca', (tester) async {
    final c = await pump(tester, const AttendanceCard(),
        guard: 'p1', now: morning.add(const Duration(minutes: 20)));
    expect(find.text('Chưa vào ca'), findsOneWidget);
    await tester.tap(find.text('VÀO CA'));
    await tester.pump();
    expect(find.textContaining('trễ 20 phút'), findsOneWidget);
    await tester.tap(find.text('KẾT THÚC CA'));
    await tester.pump();
    expect(find.textContaining('Đã xong ca'), findsOneWidget);
    expect(c.read(attendanceProvider).first.isComplete, isTrue);
  });

  testWidgets('Bảng chấm công tổng hiển thị từng nhân viên', (tester) async {
    await pump(tester, const AttendanceOverviewScreen());
    expect(find.text('BẢNG CHẤM CÔNG'), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Lê Văn C'), findsOneWidget);
  });

  testWidgets('Xin nghỉ phép rồi Chỉ huy duyệt', (tester) async {
    final c = await pump(tester, const LeaveRequestScreen(), guard: 'p1');
    await tester.enterText(find.byType(TextField), 'Đi khám bệnh');
    await tester.tap(find.text('GỬI ĐƠN'));
    await tester.pump();
    expect(
        find.text('Đã gửi đơn xin nghỉ, chờ Chỉ huy duyệt.'), findsOneWidget);
    expect(find.text('Lý do: Đi khám bệnh'), findsOneWidget);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: const MaterialApp(home: LeaveApprovalScreen())));
    expect(find.text('CHỜ DUYỆT (2)'), findsOneWidget);
    await tester.tap(find.text('DUYỆT').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DUYỆT').last);
    await tester.pumpAndSettle();
    expect(find.text('CHỜ DUYỆT (1)'), findsOneWidget);
    expect(c.read(leavesProvider).first.status, LeaveStatus.approved);
  });

  testWidgets('Đánh dấu nghỉ việc rồi xóa nhân viên đã nghỉ', (tester) async {
    final c = await pump(tester, const PersonnelScreen());
    final p2 = c.read(personnelProvider)[1];
    c
        .read(personnelProvider.notifier)
        .updatePersonnel(p2.copyWith(isActive: false));
    await tester.pump();
    expect(find.text('ĐÃ NGHỈ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-resigned')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XÓA'));
    await tester.pumpAndSettle();
    expect(find.text('Trần Thị B'), findsNothing);
    expect(c.read(rosterProvider).any((e) => e.personnelId == 'p2'), isFalse);
  });

  testWidgets('Bảo vệ báo cháy hiện cảnh báo trên dashboard', (tester) async {
    final c = await pump(tester, const GuardDashboardScreen(), guard: 'p1');
    await tester.scrollUntilVisible(find.text('BÁO CHÁY'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('BÁO CHÁY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhà Xe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BÁO CHÁY').last);
    await tester.pump();
    final alarms = c.read(activeFireAlarmsProvider);
    expect(alarms.single.title, 'BÁO CHÁY: Nhà Xe');
    await tester.scrollUntilVisible(find.text('TẮT CÒI'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('TẮT CÒI'), findsOneWidget);
    await tester.tap(find.text('TẮT CÒI'));
    await tester.pump();
    expect(find.text('ĐÃ TẮT CÒI'), findsOneWidget);
  });

  testWidgets('Quét bản đồ lần đầu lưu đường đi giả lập', (tester) async {
    final c = await pump(tester, const SiteMapScanScreen());
    expect(find.textContaining('Khu vực chưa có bản đồ'), findsOneWidget);
    await tester.tap(find.text('BẮT ĐẦU QUÉT'));
    await tester.pump();
    await tester.tapAt(const Offset(60, 300));
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('Đã ghi'), findsOneWidget);
    await tester.tap(find.text('DỪNG & LƯU ĐƯỜNG ĐI'));
    await tester.pump();
    expect(c.read(siteTracksProvider).single.points.length, greaterThan(5));
    expect(find.textContaining('Đã có 1 đoạn đường'), findsOneWidget);
  });
}
