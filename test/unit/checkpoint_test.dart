import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/utils/lat_lng.dart';
import 'package:demo_app/domain/entities/models.dart';
import 'package:demo_app/presentation/state/manager_state.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  CheckpointConfig point(String name, String code, {String id = 'new'}) =>
      CheckpointConfig(
          id: id,
          name: name,
          expectedQrCode: code,
          location: const LatLng(10.7770, 106.7010));

  List<CheckpointConfig> routePoints() =>
      c.read(routeConfigsProvider).first.checkpoints;

  group('Thêm địa điểm & mã QR', () {
    test('Thêm địa điểm mới, mã QR được chuẩn hóa', () {
      expect(saveCheckpoint(c.read, 'r1', point(' Cổng sau ', 'Cổng  SAU ')),
          isNull);
      expect(routePoints().length, 4);
      expect(routePoints().last.name, 'Cổng sau');
      expect(routePoints().last.expectedQrCode, 'cổng sau');
    });

    test('Ca chưa bắt đầu nhận thêm địa điểm, ca đang tuần tra giữ nguyên', () {
      saveCheckpoint(c.read, 'r1', point('Cổng sau', 'cổng sau'));
      final schedules = c.read(schedulesProvider);
      final pending =
          schedules.firstWhere((s) => s.status == ScheduleStatus.pending);
      final active =
          schedules.firstWhere((s) => s.status == ScheduleStatus.inProgress);
      expect(pending.checkpoints.length, 4);
      expect(active.checkpoints.length, 3);
    });

    test('Không cho trùng mã QR, trùng tên hoặc để trống', () {
      expect(saveCheckpoint(c.read, 'r1', point('Kho 2', 'NHÀ KHO')),
          contains('đã dùng'));
      expect(saveCheckpoint(c.read, 'r1', point('nhà xe', 'nha xe 2')),
          contains('đã có địa điểm'));
      expect(saveCheckpoint(c.read, 'r1', point('  ', 'abc')),
          'Vui lòng nhập tên địa điểm!');
      expect(saveCheckpoint(c.read, 'r1', point('Cổng', ' ')),
          'Vui lòng nhập nội dung mã QR!');
      expect(routePoints().length, 3);
    });

    test('Sửa địa điểm giữ nguyên mã của chính nó', () {
      final kho = routePoints().first;
      expect(
          saveCheckpoint(
              c.read, 'r1', point('Kho chính', kho.expectedQrCode, id: kho.id)),
          isNull);
      expect(routePoints().first.name, 'Kho chính');
      expect(routePoints().length, 3);
    });

    test('Xóa địa điểm nhưng phải còn ít nhất 1 điểm', () {
      final ids = routePoints().map((p) => p.id).toList();
      expect(deleteCheckpoint(c.read, 'r1', ids[0]), isNull);
      expect(deleteCheckpoint(c.read, 'r1', ids[1]), isNull);
      expect(deleteCheckpoint(c.read, 'r1', ids[2]),
          'Lộ trình phải còn ít nhất 1 địa điểm!');
      expect(routePoints().single.id, ids[2]);
    });
  });
}
