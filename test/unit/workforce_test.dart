import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/utils/date_utils.dart';
import 'package:demo_app/core/utils/lat_lng.dart';
import 'package:demo_app/domain/entities/workforce.dart';
import 'package:demo_app/presentation/state/manager_state.dart';
import 'package:demo_app/presentation/state/workforce_state.dart';

void main() {
  late ProviderContainer c;
  final today = dateOnly(DateTime.now());

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  String? assign(String id, DateTime day, ShiftType shift) =>
      c.read(rosterProvider.notifier).assign(id, day, shift,
          personnel: c.read(personnelProvider), leaves: c.read(leavesProvider));

  group('Gộp lịch trực với ca tuần tra', () {
    test('Ca mẫu hôm nay liên kết với ca tuần tra', () {
      c.read(currentGuardIdProvider.notifier).state = 'p1';
      final shift = c.read(currentShiftProvider);
      expect(shift.entry, isNotNull);
      expect(shift.schedule?.id, shift.entry!.id);
      expect(shift.routeName, 'Tuyến tuần tra mẫu');
    });

    test('Gỡ ca chưa tuần tra thì xóa luôn ca tuần tra', () {
      final p1 = c
          .read(rosterProvider)
          .firstWhere((e) => e.personnelId == 'p1' && sameDay(e.date, today));
      final p3 = c
          .read(rosterProvider)
          .where((e) => e.personnelId == 'p3' && sameDay(e.date, today));
      expect(
          shiftStateOf(p1, c.read(attendanceProvider),
              c.read(schedulesProvider), DateTime.now()),
          isNot(ShiftState.patrolling));
      final schedules = c.read(schedulesProvider);
      final p3Schedule = schedules.where((s) => s.guardId == 'p3').first;
      expect(p3Schedule.status, ScheduleStatus.inProgress);
      if (p3.isNotEmpty) {
        expect(
            shiftStateOf(p3.first, c.read(attendanceProvider), schedules,
                DateTime.now()),
            ShiftState.patrolling);
      }
    });
  });

  group('Phân ca & lịch trực tuần', () {
    test('Lịch mẫu có đủ 3 ca cho tuần hiện tại', () {
      final roster = c.read(rosterProvider);
      final monday = startOfWeek(today);
      expect(rosterForDay(roster, monday, ShiftType.morning).length, 1);
      expect(rosterForDay(roster, monday, ShiftType.afternoon).length, 1);
      expect(rosterForDay(roster, monday, ShiftType.night).length, 1);
    });

    test('Không phân 2 ca cùng ngày cho một người', () {
      final nextMonday = startOfWeek(today).add(const Duration(days: 7));
      expect(assign('p2', nextMonday, ShiftType.morning), isNull);
      expect(assign('p2', nextMonday, ShiftType.night),
          contains('đã được phân Ca Sáng'));
      expect(assign('p2', nextMonday, ShiftType.morning),
          contains('đã có trong Ca Sáng'));
    });

    test('Sao chép lịch tuần trước sang tuần sau', () {
      final monday = startOfWeek(today);
      final added = c.read(rosterProvider.notifier).copyWeek(
          monday, monday.add(const Duration(days: 7)),
          personnel: c.read(personnelProvider), leaves: c.read(leavesProvider));
      expect(added, 18);
    });
  });

  group('Chấm công', () {
    test('Vào ca trễ quá 10 phút bị tính đi trễ', () {
      final entry = RosterEntry(
          id: 'x', personnelId: 'p1', date: today, shift: ShiftType.morning);
      final notifier = c.read(attendanceProvider.notifier);
      expect(
          notifier.checkIn(
              'p1', entry, entry.start.subtract(const Duration(hours: 1))),
          contains('Chưa đến giờ'));
      expect(
          notifier.checkIn(
              'p1', entry, entry.start.add(const Duration(minutes: 25))),
          isNull);
      expect(
          notifier.checkIn(
              'p1', entry, entry.start.add(const Duration(minutes: 30))),
          contains('đã chấm công'));
      final record = c.read(attendanceProvider).first;
      expect(record.lateMinutes, 25);
      notifier.checkOut(record.id, entry.end);
      expect(c.read(attendanceProvider).first.workedHours, closeTo(7.58, 0.01));
    });

    test('Tổng hợp công tháng theo nhân viên', () {
      final summary = summarize(
          personnelId: 'p1',
          month: today,
          attendance: [
            AttendanceRecord(
                id: '1',
                personnelId: 'p1',
                date: today,
                shift: ShiftType.morning,
                checkIn: ShiftType.morning.startOn(today),
                checkOut: ShiftType.morning.endOn(today)),
            AttendanceRecord(
                id: '2',
                personnelId: 'p1',
                date: today,
                shift: ShiftType.afternoon,
                checkIn: ShiftType.afternoon
                    .startOn(today)
                    .add(const Duration(minutes: 20))),
          ],
          roster: const [],
          leaves: const [],
          now: today.add(const Duration(hours: 23)));
      expect(summary.shiftsWorked, 1);
      expect(summary.hours, 8);
      expect(summary.lateCount, 1);
      expect(summary.lateMinutes, 20);
    });
  });

  group('Nghỉ phép', () {
    test('Kiểm tra đơn xin nghỉ không hợp lệ', () {
      final me = c.read(personnelProvider).first;
      final notifier = c.read(leavesProvider.notifier);
      expect(notifier.submit(me, today, today, ' ', today), contains('lý do'));
      expect(
          notifier.submit(
              me, today.subtract(const Duration(days: 1)), today, 'Ốm', today),
          contains('đã qua'));
      expect(
          notifier.submit(
              me, today.add(const Duration(days: 2)), today, 'Ốm', today),
          contains('sau ngày bắt đầu'));
      expect(notifier.submit(me, today, today, 'Ốm', today), isNull);
      expect(notifier.submit(me, today, today, 'Ốm', today), contains('trùng'));
    });

    test('Phân ca cho người đang nghỉ phép bị từ chối', () {
      final leave = c.read(leavesProvider).first;
      c.read(leavesProvider.notifier).review(leave.id, LeaveStatus.approved);
      expect(assign('p2', leave.fromDate, ShiftType.morning),
          contains('đang nghỉ phép'));
    });

    test('Duyệt nghỉ thì xóa ca trực trong những ngày nghỉ', () {
      final notifier = c.read(rosterProvider.notifier);
      expect(notifier.removeFor('p1', from: today, to: today), 1);
      expect(
          rosterForDay(c.read(rosterProvider), today)
              .where((e) => e.personnelId == 'p1'),
          isEmpty);
    });
  });

  group('Nhân viên nghỉ việc', () {
    test('Nhân viên đã nghỉ không đăng nhập được', () {
      final p1 = c.read(personnelProvider).first;
      c
          .read(personnelProvider.notifier)
          .updatePersonnel(p1.copyWith(isActive: false));
      expect(c.read(personnelProvider.notifier).findByPin('1234'), isNull);
      expect(c.read(personnelProvider.notifier).findByPin('2345'), isNotNull);
    });
  });

  test('Lưu đường đi khi quét bản đồ', () {
    c
        .read(siteTracksProvider.notifier)
        .addTrack(const [LatLng(10.761, 106.656), LatLng(10.762, 106.657)]);
    expect(c.read(siteTracksProvider).single.points.length, 2);
    c.read(siteTracksProvider.notifier).clearAll();
    expect(c.read(siteTracksProvider), isEmpty);
  });
}
