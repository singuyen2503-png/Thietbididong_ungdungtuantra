import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/models.dart';
import '../../core/utils/lat_lng.dart';
import 'manager_state.dart';

final currentGuardLocationProvider =
    StreamProvider.autoDispose<Map<String, double>>((ref) async* {
  const bool useMockGps = !bool.fromEnvironment('USE_REAL_GPS');

  if (useMockGps) {
    double currentLat = 10.989120;
    double currentLng = 106.578710;

    LatLng? activeTarget;

    ref.listen(patrolCheckpointsProvider, (previous, next) {
      if (next is AsyncData<List<Checkpoint>>) {
        final checkpoints = next.value;
        final target = checkpoints
            .cast<Checkpoint?>()
            .firstWhere((c) => c != null && !c.isScanned, orElse: () => null);
        if (target != null) {
          activeTarget = target.location;
        } else {
          activeTarget = null;
        }
      }
    }, fireImmediately: true);

    while (true) {
      await Future.delayed(const Duration(seconds: 1));

      if (activeTarget != null) {
        final dLat = activeTarget!.latitude - currentLat;
        final dLng = activeTarget!.longitude - currentLng;

        currentLat += dLat * 0.25;
        currentLng += dLng * 0.25;
      }

      yield {'lat': currentLat, 'lng': currentLng};
    }
  } else {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí bị tắt. Vui lòng bật GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt.');
    }

    const LocationSettings locationSettings =
        LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2);

    yield* Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((Position position) {
      return {'lat': position.latitude, 'lng': position.longitude};
    });
  }
});

final patrolCheckpointsProvider = StateNotifierProvider.autoDispose<
    PatrolCheckpointsNotifier, AsyncValue<List<Checkpoint>>>((ref) {
  return PatrolCheckpointsNotifier(ref);
});

class PatrolCheckpointsNotifier
    extends StateNotifier<AsyncValue<List<Checkpoint>>> {
  final Ref _ref;
  String? _scheduleId;

  PatrolCheckpointsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCheckpoints();
  }

  Future<void> loadCheckpoints() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final schedule = _ref.read(currentGuardScheduleProvider);
    _scheduleId = schedule?.id;
    final fromSchedule = schedule?.checkpoints ?? const <Checkpoint>[];
    state = AsyncValue.data(
        fromSchedule.isNotEmpty ? fromSchedule : seedCheckpoints);
  }

  Future<void> scanCheckpoint(Checkpoint checkpoint) async {
    if (state is AsyncData) {
      final List<Checkpoint> currentList = List<Checkpoint>.from(state.value!);
      final int index = currentList.indexWhere((c) => c.id == checkpoint.id);

      if (index != -1) {
        currentList[index] = checkpoint.copyWith(
            isScanned: true, scannedAt: DateTime.now(), isSynced: false);
        state = AsyncValue.data(currentList);
        final gps = _ref.read(currentGuardLocationProvider).valueOrNull;
        _saveToSchedule(currentList,
            visited: gps == null
                ? checkpoint.location
                : LatLng(gps['lat']!, gps['lng']!));

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        final List<Checkpoint> updatedList =
            List<Checkpoint>.from(state.value!);
        updatedList[index] = updatedList[index].copyWith(isSynced: true);
        state = AsyncValue.data(updatedList);
        _saveToSchedule(updatedList);
      }
    }
  }

  void _saveToSchedule(List<Checkpoint> checkpoints, {LatLng? visited}) {
    final schedule = _ref
        .read(schedulesProvider)
        .where((s) => s.id == _scheduleId)
        .firstOrNull;
    if (schedule == null || schedule.checkpoints.isEmpty) return;
    final allDone = checkpoints.every((c) => c.isScanned);
    if (allDone && schedule.status != ScheduleStatus.completed) {
      _ref
          .read(equipmentProvider.notifier)
          .releaseEquipments(schedule.equipmentIds);
    }
    _ref.read(schedulesProvider.notifier).updateSchedule(schedule.copyWith(
          checkpoints: checkpoints,
          actualPath:
              visited == null ? null : [...schedule.actualPath, visited],
          status:
              allDone ? ScheduleStatus.completed : ScheduleStatus.inProgress,
        ));
  }
}
