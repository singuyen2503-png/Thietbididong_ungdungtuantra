import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/core/utils/geo_utils.dart';
import 'package:demo_app/core/utils/qr_utils.dart';
import 'package:demo_app/data/datasources/local_store.dart';
import 'package:demo_app/domain/entities/models.dart';
import 'package:demo_app/presentation/state/manager_state.dart';
import 'package:demo_app/presentation/state/patrol_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    container.read(currentGuardIdProvider.notifier).state = 'p1';
  });
  tearDown(() => container.dispose());

  group('Lịch tuần tra', () {
    test('Bảo vệ p1 có ca trực mẫu chưa bắt đầu với 3 điểm', () {
      final schedule = container.read(currentGuardScheduleProvider);
      expect(schedule, isNotNull);
      expect(schedule!.status, ScheduleStatus.pending);
      expect(schedule.checkpoints.map((c) => c.expectedQrCode).toList(),
          ['nhà kho', 'nhà xe', 'hành lang']);
      expect(formatShiftTime(schedule), '06:00 - 14:00');
    });

    test('Quét đủ điểm thì ca trực chuyển HOÀN THÀNH', () async {
      final sub = container.listen(patrolCheckpointsProvider, (_, __) {});
      await Future.delayed(const Duration(milliseconds: 600));

      final checkpoints = container.read(patrolCheckpointsProvider).value!;
      final notifier = container.read(patrolCheckpointsProvider.notifier);

      await notifier.scanCheckpoint(checkpoints[0]);
      expect(container.read(schedulesProvider).first.status,
          ScheduleStatus.inProgress);

      await notifier.scanCheckpoint(checkpoints[1]);
      await notifier.scanCheckpoint(checkpoints[2]);
      final schedule = container.read(schedulesProvider).first;
      expect(schedule.actualPath.length, 3);
      expect(schedule.status, ScheduleStatus.completed);
      expect(
          schedule.checkpoints.every((c) => c.isScanned && c.isSynced), isTrue);
      expect(
          container
              .read(equipmentProvider)
              .firstWhere((e) => e.id == 'e1')
              .status,
          EquipmentStatus.available);
      sub.close();
    });

    test('Tên ca theo giờ bắt đầu', () {
      final s = container.read(schedulesProvider);
      expect(shiftName(s[0]), 'CA SÁNG');
      expect(shiftName(s[1]), 'CA CHIỀU');
    });

    test('Mỗi bảo vệ chỉ thấy ca của mình', () {
      container.read(currentGuardIdProvider.notifier).state = 'p3';
      expect(
          container.read(currentGuardScheduleProvider)!.guardName, 'Lê Văn C');
      container.read(currentGuardIdProvider.notifier).state = 'p2';
      expect(container.read(currentGuardScheduleProvider), isNull);
    });

    test('Thống kê bảo vệ đang đi tuần lấy từ lịch', () {
      expect(container.read(patrollingGuardIdsProvider), {'p3'});
    });
  });

  group('Sự cố', () {
    test('Thêm sự cố mới được đưa lên đầu danh sách', () {
      container.read(incidentsProvider.notifier).addIncident(Incident(
          id: 'x',
          title: 'Cháy',
          description: 'Kho B',
          reportedBy: 'Nguyễn Văn A',
          createdAt: DateTime.now()));
      expect(container.read(incidentsProvider).first.id, 'x');
    });

    test('Chỉ huy đóng sự cố kèm ghi chú chỉ đạo', () {
      container
          .read(incidentsProvider.notifier)
          .resolveByCommander('i1', 'Đã xử lý');
      final incident =
          container.read(incidentsProvider).firstWhere((i) => i.id == 'i1');
      expect(incident.isResolved, isTrue);
      expect(incident.commanderNote, 'Đã xử lý');
      expect(incident.resolvedBy, 'Chỉ huy');
    });

    test('Điều động chi viện thêm tên bảo vệ vào sự cố', () {
      container
          .read(incidentsProvider.notifier)
          .assignBackups('i1', ['Lê Văn C']);
      expect(container.read(incidentsProvider).first.assignedBackupNames,
          contains('Lê Văn C'));
    });
  });

  group('Nhân sự & Thiết bị', () {
    test('Thêm, sửa, xóa nhân sự', () {
      final notifier = container.read(personnelProvider.notifier);
      final p = Personnel(
          id: 'p9',
          username: 'guard_z',
          name: 'Phạm Văn Z',
          phone: '0900000000',
          role: 'Bảo vệ',
          gender: 'Nam',
          age: 30,
          pin: '9999');
      notifier.addPersonnel(p);
      expect(container.read(personnelProvider).length, 4);

      notifier.updatePersonnel(Personnel(
          id: 'p9',
          username: 'guard_z',
          name: 'Phạm Văn Zet',
          phone: '0900000000',
          role: 'Bảo vệ',
          gender: 'Nam',
          age: 31,
          pin: '9999'));
      expect(container.read(personnelProvider).last.name, 'Phạm Văn Zet');

      expect(notifier.findByPin('9999')?.id, 'p9');
      notifier.deletePersonnel('p9');
      expect(
          container.read(personnelProvider).any((e) => e.id == 'p9'), isFalse);
    });

    test('Cấp phát thiết bị chuyển trạng thái ĐANG CẤP', () {
      container.read(equipmentProvider.notifier).markEquipmentsAsInUse(['e3']);
      expect(
          container
              .read(equipmentProvider)
              .firstWhere((e) => e.id == 'e3')
              .status,
          EquipmentStatus.inUse);
      container.read(equipmentProvider.notifier).releaseEquipments(['e3']);
      expect(
          container
              .read(equipmentProvider)
              .firstWhere((e) => e.id == 'e3')
              .status,
          EquipmentStatus.available);
    });
  });

  test('So khớp mã QR không phân biệt hoa thường và khoảng trắng', () {
    expect(qrMatches(' Nhà  Kho ', 'nhà kho'), isTrue);
    expect(qrMatches('HÀNH LANG', 'hành lang'), isTrue);
    expect(qrMatches('nhà xe', 'nhà kho'), isFalse);
  });

  test('Haversine: 0.001 độ vĩ ~ 111m', () {
    final d = GeoUtils.calculateDistance(10.761, 106.656, 10.762, 106.656);
    expect(d, closeTo(111, 2));
  });

  group('Lưu trữ cục bộ', () {
    test('Dữ liệu còn nguyên sau khi khởi động lại', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());

      final first = ProviderContainer(
          overrides: [localStoreProvider.overrideWithValue(store)]);
      first.read(incidentsProvider.notifier).addIncident(Incident(
          id: 'x',
          title: 'Cháy kho',
          description: 'Kho B',
          reportedBy: 'Lê Văn C',
          createdAt: DateTime(2026, 11, 1, 9, 5),
          imageBase64: 'AAAA',
          severity: IncidentSeverity.critical));
      first.read(routeConfigsProvider.notifier).deleteRoute('r1');
      first
          .read(schedulesProvider.notifier)
          .deleteSchedule('r${DateTime.now().weekday - 1}-p3');
      first.dispose();
      await Future<void>.delayed(Duration.zero);

      final second = ProviderContainer(
          overrides: [localStoreProvider.overrideWithValue(store)]);
      final saved = second.read(incidentsProvider).first;
      expect(saved.title, 'Cháy kho');
      expect(saved.severity, IncidentSeverity.critical);
      expect(saved.imageBase64, 'AAAA');
      expect(saved.createdAt, DateTime(2026, 11, 1, 9, 5));
      expect(second.read(routeConfigsProvider), isEmpty);
      expect(second.read(schedulesProvider).map((s) => s.id),
          ['r${DateTime.now().weekday - 1}-p1']);
      expect(
          second
              .read(schedulesProvider)
              .first
              .checkpoints
              .first
              .location
              .latitude,
          10.777394);
      second.dispose();
    });

    test('Dữ liệu hỏng thì dùng lại dữ liệu mẫu', () async {
      SharedPreferences.setMockInitialValues(
          {LocalStore.keyPersonnel: '{không phải json'});
      final store = LocalStore(await SharedPreferences.getInstance());
      final c = ProviderContainer(
          overrides: [localStoreProvider.overrideWithValue(store)]);
      expect(c.read(personnelProvider).length, 3);
      c.dispose();
    });
  });
}
