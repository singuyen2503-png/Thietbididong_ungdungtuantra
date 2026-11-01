import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/json_mappers.dart';
import '../../domain/entities/models.dart';
import '../../domain/entities/equipment.dart';
import '../../core/utils/lat_lng.dart';
import 'workforce_state.dart';

final localStoreProvider = Provider<LocalStore?>((ref) => null);

abstract class PersistedListNotifier<T> extends StateNotifier<List<T>> {
  final LocalStore? _store;
  final String _key;
  final Json Function(T) _toJson;

  PersistedListNotifier(LocalStore? store, String key, List<T> seed,
      this._toJson, T Function(Json) fromJson)
      : _store = store,
        _key = key,
        super(store?.readList(key, fromJson) ?? seed);

  @override
  set state(List<T> value) {
    super.state = value;
    _store?.writeList(_key, value, _toJson);
  }
}

const String kCommanderPin = '5678';

final incidentsProvider =
    StateNotifierProvider<IncidentsNotifier, List<Incident>>(
        (ref) => IncidentsNotifier(ref.watch(localStoreProvider)));

class IncidentsNotifier extends PersistedListNotifier<Incident> {
  IncidentsNotifier([LocalStore? store])
      : super(
            store,
            LocalStore.keyIncidents,
            [
              Incident(
                id: 'i1',
                title: 'Phát hiện đối tượng khả nghi',
                description: 'Có tiếng động lạ ở Kho Hóa Chất.',
                reportedBy: 'Nguyễn Văn A',
                createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
                severity: IncidentSeverity.high,
              ),
            ],
            incidentToJson,
            incidentFromJson);
  void addIncident(Incident incident) => state = [incident, ...state];
  void resolveByCommander(String id, String note) => state = state
      .map((i) => i.id == id
          ? i.copyWith(
              isResolved: true, commanderNote: note, resolvedBy: 'Chỉ huy')
          : i)
      .toList();
  void resolveByGuard(String id, String report) => state = state
      .map((i) => i.id == id
          ? i.copyWith(
              isResolved: true, resolutionReport: report, resolvedBy: 'Bảo vệ')
          : i)
      .toList();
  void assignBackups(String id, List<String> guardNames) => state = state
      .map((i) => i.id == id
          ? i.copyWith(
              assignedBackupNames:
                  {...i.assignedBackupNames, ...guardNames}.toList())
          : i)
      .toList();
}

const _seedPath = [
  LatLng(10.989686, 106.579488),
  LatLng(10.989219, 106.580083),
  LatLng(10.989443, 106.579763)
];

final seedCheckpoints = [
  Checkpoint(
      id: 'cp1',
      name: 'Nhà Kho',
      expectedQrCode: 'nhà kho',
      location: _seedPath[0],
      radiusMeters: 15.0),
  Checkpoint(
      id: 'cp2',
      name: 'Nhà Xe',
      expectedQrCode: 'nhà xe',
      location: _seedPath[1],
      radiusMeters: 15.0),
  Checkpoint(
      id: 'cp3',
      name: 'Hành Lang',
      expectedQrCode: 'hành lang',
      location: _seedPath[2],
      radiusMeters: 15.0),
];

final routeConfigsProvider =
    StateNotifierProvider<RouteConfigsNotifier, List<RouteConfig>>(
        (ref) => RouteConfigsNotifier(ref.watch(localStoreProvider)));

class RouteConfigsNotifier extends PersistedListNotifier<RouteConfig> {
  RouteConfigsNotifier([LocalStore? store])
      : super(
            store,
            LocalStore.keyRoutes,
            [
              RouteConfig(
                  id: 'r1',
                  name: 'Tuyến Trung tâm 59',
                  plannedPath: _seedPath,
                  checkpoints: [
                    for (final c in seedCheckpoints)
                      CheckpointConfig(
                          id: c.id,
                          name: c.name,
                          expectedQrCode: c.expectedQrCode,
                          location: c.location),
                  ])
            ],
            routeToJson,
            routeFromJson);
  void addRoute(RouteConfig route) => state = [...state, route];
  void deleteRoute(String id) =>
      state = state.where((r) => r.id != id).toList();
}

final schedulesProvider =
    StateNotifierProvider<SchedulesNotifier, List<Schedule>>(
        (ref) => SchedulesNotifier(ref.watch(localStoreProvider)));

class SchedulesNotifier extends PersistedListNotifier<Schedule> {
  SchedulesNotifier([LocalStore? store])
      : super(store, LocalStore.keySchedules, _initialSchedules(),
            scheduleToJson, scheduleFromJson);

  static List<Schedule> _initialSchedules() {
    final now = DateTime.now();
    DateTime at(int h) => DateTime(now.year, now.month, now.day, h);
    List<Checkpoint> checkpoints({bool firstScanned = false}) => [
          for (final c in seedCheckpoints)
            c.id == 'cp1' && firstScanned
                ? c.copyWith(
                    isScanned: true,
                    scannedAt: now.subtract(const Duration(minutes: 20)),
                    isSynced: true)
                : c,
        ];
    return [
      Schedule(
          id: 's1',
          routeId: 'r1',
          routeName: 'Tuyến Trung tâm 59',
          guardId: 'p1',
          guardName: 'Nguyễn Văn A',
          startTime: at(6),
          endTime: at(14),
          checkpoints: checkpoints(),
          plannedPath: _seedPath,
          equipmentIds: ['e1'],
          status: ScheduleStatus.pending),
      Schedule(
          id: 's2',
          routeId: 'r1',
          routeName: 'Tuyến Trung tâm 59',
          guardId: 'p3',
          guardName: 'Lê Văn C',
          startTime: at(14),
          endTime: at(22),
          checkpoints: checkpoints(firstScanned: true),
          plannedPath: _seedPath,
          actualPath: [_seedPath[0]],
          equipmentIds: ['e2'],
          status: ScheduleStatus.inProgress),
    ];
  }

  void addSchedule(Schedule schedule) => state = [...state, schedule];
  void updateSchedule(Schedule schedule) =>
      state = state.map((s) => s.id == schedule.id ? schedule : s).toList();
  void deleteSchedule(String id) =>
      state = state.where((s) => s.id != id).toList();
}

class ScheduleStatus {
  ScheduleStatus._();
  static const pending = 'CHƯA BẮT ĐẦU';
  static const inProgress = 'ĐANG ĐI TUẦN';
  static const completed = 'HOÀN THÀNH';
}

class EquipmentStatus {
  EquipmentStatus._();
  static const available = 'SẴN SÀNG';
  static const inUse = 'ĐANG CẤP';
}

final currentGuardIdProvider = StateProvider<String?>((ref) => null);

final currentGuardProvider = Provider<Personnel?>((ref) {
  final id = ref.watch(currentGuardIdProvider);
  return ref.watch(personnelProvider).where((p) => p.id == id).firstOrNull;
});

final currentGuardScheduleProvider = Provider<Schedule?>((ref) {
  final id = ref.watch(currentGuardIdProvider);
  final mine =
      ref.watch(schedulesProvider).where((s) => s.guardId == id).toList();
  if (mine.isEmpty) return null;
  final open = mine.where((s) => s.status != ScheduleStatus.completed).toList();
  return open.isNotEmpty ? open.last : mine.last;
});

final patrollingGuardIdsProvider = Provider<Set<String>>((ref) {
  return ref
      .watch(schedulesProvider)
      .where((s) => s.status == ScheduleStatus.inProgress)
      .map((s) => s.guardId)
      .toSet();
});

final personnelProvider =
    StateNotifierProvider<PersonnelNotifier, List<Personnel>>(
        (ref) => PersonnelNotifier(ref.watch(localStoreProvider)));

class PersonnelNotifier extends PersistedListNotifier<Personnel> {
  PersonnelNotifier([LocalStore? store])
      : super(
            store,
            LocalStore.keyPersonnel,
            [
              Personnel(
                  id: 'p1',
                  username: 'guard_a',
                  name: 'Nguyễn Văn A',
                  phone: '0901234567',
                  role: 'Bảo vệ',
                  gender: 'Nam',
                  age: 35,
                  pin: '1234'),
              Personnel(
                  id: 'p2',
                  username: 'guard_b',
                  name: 'Trần Thị B',
                  phone: '0909876543',
                  role: 'Bảo vệ',
                  gender: 'Nữ',
                  age: 42,
                  pin: '2345'),
              Personnel(
                  id: 'p3',
                  username: 'guard_c',
                  name: 'Lê Văn C',
                  phone: '0911223344',
                  role: 'Bảo vệ',
                  gender: 'Nam',
                  age: 28,
                  pin: '3456'),
            ],
            personnelToJson,
            personnelFromJson);
  void addPersonnel(Personnel p) => state = [...state, p];
  void updatePersonnel(Personnel p) =>
      state = state.map((e) => e.id == p.id ? p : e).toList();
  void deletePersonnel(String id) =>
      state = state.where((e) => e.id != id).toList();
  Personnel? findByPin(String pin) =>
      state.where((p) => p.isActive && p.pin == pin).firstOrNull;
}

final equipmentProvider =
    StateNotifierProvider<EquipmentNotifier, List<Equipment>>(
        (ref) => EquipmentNotifier(ref.watch(localStoreProvider)));

class EquipmentNotifier extends PersistedListNotifier<Equipment> {
  EquipmentNotifier([LocalStore? store])
      : super(
            store,
            LocalStore.keyEquipment,
            [
              Equipment(
                  id: 'e1',
                  name: 'Bộ đàm Motorola',
                  code: 'BD-01',
                  status: EquipmentStatus.inUse),
              Equipment(
                  id: 'e2',
                  name: 'Đèn pin',
                  code: 'DP-05',
                  status: EquipmentStatus.inUse),
              Equipment(
                  id: 'e3',
                  name: 'Gậy cao su',
                  code: 'GC-02',
                  status: EquipmentStatus.available),
            ],
            equipmentToJson,
            equipmentFromJson);
  void addEquipment(Equipment eq) => state = [...state, eq];
  void updateEquipment(Equipment eq) =>
      state = state.map((e) => e.id == eq.id ? eq : e).toList();
  void deleteEquipment(String id) =>
      state = state.where((e) => e.id != id).toList();
  void markEquipmentsAsInUse(List<String> eqIds) =>
      _setStatus(eqIds, EquipmentStatus.inUse);
  void releaseEquipments(List<String> eqIds) =>
      _setStatus(eqIds, EquipmentStatus.available);
  void _setStatus(List<String> eqIds, String status) => state = state
      .map((e) => eqIds.contains(e.id)
          ? Equipment(id: e.id, name: e.name, code: e.code, status: status)
          : e)
      .toList();
}

Future<void> resetAllData(WidgetRef ref) async {
  await ref.read(localStoreProvider)?.clearData();
  ref.invalidate(incidentsProvider);
  ref.invalidate(routeConfigsProvider);
  ref.invalidate(schedulesProvider);
  ref.invalidate(personnelProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(rosterProvider);
  ref.invalidate(attendanceProvider);
  ref.invalidate(leavesProvider);
  ref.invalidate(siteTracksProvider);
  ref.invalidate(silencedAlarmIdsProvider);
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String formatTime(DateTime t) => _hhmm(t);

String shiftName(Schedule s) {
  final h = s.startTime.hour;
  if (h < 12) return 'CA SÁNG';
  if (h < 18) return 'CA CHIỀU';
  return 'CA TỐI';
}

String formatShiftTime(Schedule s) =>
    '${_hhmm(s.startTime)} - ${_hhmm(s.endTime)}';

Color scheduleStatusColor(String status) {
  switch (status) {
    case ScheduleStatus.inProgress:
      return const Color(0xFF00FF9D);
    case ScheduleStatus.completed:
      return Colors.lightBlueAccent;
    default:
      return Colors.orange;
  }
}
