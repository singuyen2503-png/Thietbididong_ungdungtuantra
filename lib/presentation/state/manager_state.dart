import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/lat_lng.dart';
import '../../core/utils/qr_utils.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/json_mappers.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/models.dart';
import 'workforce_state.dart';

final localStoreProvider = Provider<LocalStore?>((ref) => null);

abstract class PersistedListNotifier<T> extends StateNotifier<List<T>> {
  final LocalStore? _store;
  final String _key;
  final Json Function(T) _toJson;
  final T Function(Json) _fromJson;
  final Comparator<T>? _remoteOrder;
  CollectionReference<Json>? _remote;
  StreamSubscription<QuerySnapshot<Json>>? _subscription;
  bool _resetting = false;

  PersistedListNotifier(LocalStore? store, String key, List<T> seed,
      this._toJson, this._fromJson,
      {Comparator<T>? remoteOrder})
      : _store = store,
        _key = key,
        _remoteOrder = remoteOrder,
        super(store?.readList(key, _fromJson) ?? seed) {
    _remote = _openCollection(key);
    _subscription = _remote?.snapshots().listen(_onRemote,
        onError: (Object e) => debugPrint('Firestore "$_key": $e'));
  }

  static CollectionReference<Json>? _openCollection(String key) {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance.collection(key);
    } catch (_) {
      return null;
    }
  }

  void _onRemote(QuerySnapshot<Json> snapshot) {
    if (!mounted || _resetting || snapshot.metadata.hasPendingWrites) return;
    if (snapshot.docs.isEmpty) {
      if (!snapshot.metadata.isFromCache) _push(const [], state);
      return;
    }
    final remote = <String, T>{};
    for (final doc in snapshot.docs) {
      try {
        remote[doc.id] = _fromJson({...doc.data(), 'id': doc.id});
      } catch (e) {
        debugPrint('Firestore "$_key/${doc.id}": bỏ qua dữ liệu hỏng: $e');
      }
    }
    final merged = [
      for (final item in state)
        if (remote.remove(_idOf(item)) case final updated?) updated,
      ...remote.values,
    ];
    if (_remoteOrder != null) merged.sort(_remoteOrder);
    super.state = merged;
    _store?.writeList(_key, merged, _toJson);
  }

  String _idOf(T item) => _toJson(item)['id'] as String;

  @override
  set state(List<T> value) {
    final previous = state;
    super.state = value;
    _store?.writeList(_key, value, _toJson);
    _push(previous, value);
  }

  void _push(List<T> previous, List<T> next) {
    final remote = _remote;
    if (remote == null) return;
    final removed = {for (final item in previous) _idOf(item): item};
    final batch = remote.firestore.batch();
    var writes = 0;
    for (final item in next) {
      final json = _toJson(item);
      final id = json['id'] as String;
      if (identical(removed.remove(id), item)) continue;
      batch.set(remote.doc(id), json);
      writes++;
    }
    for (final id in removed.keys) {
      batch.delete(remote.doc(id));
      writes++;
    }
    if (writes == 0) return;
    batch.commit().catchError(
        (Object e) => debugPrint('Firestore "$_key": ghi thất bại: $e'));
  }

  Future<void> resetRemote() async {
    final remote = _remote;
    if (remote == null) return;
    _resetting = true;
    try {
      final batch = remote.firestore.batch();
      for (final doc in (await remote.get()).docs) {
        batch.delete(doc.reference);
      }
      for (final item in state) {
        final json = _toJson(item);
        batch.set(remote.doc(json['id'] as String), json);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore "$_key": khôi phục thất bại: $e');
    } finally {
      _resetting = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
            incidentFromJson,
            remoteOrder: (a, b) => b.createdAt.compareTo(a.createdAt));
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
  LatLng(10.777394, 106.700579),
  LatLng(10.776927, 106.701174),
  LatLng(10.777151, 106.700854)
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
                  name: 'Tuyến tuần tra mẫu',
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
  void replaceRoute(RouteConfig route) =>
      state = state.map((r) => r.id == route.id ? route : r).toList();
}

typedef Read = T Function<T>(ProviderListenable<T> provider);

String? validateCheckpoint(
    List<RouteConfig> routes, String routeId, CheckpointConfig cp) {
  if (cp.name.trim().isEmpty) return 'Vui lòng nhập tên địa điểm!';
  if (normalizeQr(cp.expectedQrCode).isEmpty) {
    return 'Vui lòng nhập nội dung mã QR!';
  }
  if (cp.radiusMeters < 5 || cp.radiusMeters > 100) {
    return 'Bán kính phải từ 5 đến 100 m!';
  }
  for (final r in routes) {
    for (final c in r.checkpoints) {
      if (c.id == cp.id) continue;
      if (qrMatches(c.expectedQrCode, cp.expectedQrCode)) {
        return 'Mã QR "${normalizeQr(cp.expectedQrCode)}" đã dùng cho '
            '${c.name} (${r.name})!';
      }
      if (r.id == routeId && normalizeQr(c.name) == normalizeQr(cp.name)) {
        return 'Lộ trình đã có địa điểm "${cp.name.trim()}"!';
      }
    }
  }
  return null;
}

String? saveCheckpoint(Read read, String routeId, CheckpointConfig cp) {
  final routes = read(routeConfigsProvider);
  final route = routes.where((r) => r.id == routeId).firstOrNull;
  if (route == null) return 'Không tìm thấy lộ trình!';
  final error = validateCheckpoint(routes, routeId, cp);
  if (error != null) return error;
  final clean = CheckpointConfig(
      id: cp.id,
      name: cp.name.trim(),
      expectedQrCode: normalizeQr(cp.expectedQrCode),
      location: cp.location,
      radiusMeters: cp.radiusMeters);
  final exists = route.checkpoints.any((c) => c.id == cp.id);
  _updateRoute(
      read,
      route,
      exists
          ? [for (final c in route.checkpoints) c.id == cp.id ? clean : c]
          : [...route.checkpoints, clean]);
  return null;
}

String? deleteCheckpoint(Read read, String routeId, String checkpointId) {
  final route =
      read(routeConfigsProvider).where((r) => r.id == routeId).firstOrNull;
  if (route == null) return 'Không tìm thấy lộ trình!';
  if (route.checkpoints.length <= 1) {
    return 'Lộ trình phải còn ít nhất 1 địa điểm!';
  }
  _updateRoute(read, route,
      route.checkpoints.where((c) => c.id != checkpointId).toList());
  return null;
}

void _updateRoute(
    Read read, RouteConfig route, List<CheckpointConfig> checkpoints) {
  final updated = RouteConfig(
      id: route.id,
      name: route.name,
      plannedPath: route.plannedPath,
      checkpoints: checkpoints);
  read(routeConfigsProvider.notifier).replaceRoute(updated);
  final schedules = read(schedulesProvider.notifier);
  for (final s in read(schedulesProvider)) {
    if (s.routeId != route.id || s.status != ScheduleStatus.pending) continue;
    schedules.updateSchedule(s.copyWith(checkpoints: [
      for (final c in checkpoints)
        Checkpoint(
            id: c.id,
            name: c.name,
            expectedQrCode: c.expectedQrCode,
            location: c.location,
            radiusMeters: c.radiusMeters)
    ]));
  }
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
    final day = now.weekday - 1;
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
          id: 'r$day-p1',
          routeId: 'r1',
          routeName: 'Tuyến tuần tra mẫu',
          guardId: 'p1',
          guardName: 'Nguyễn Văn A',
          startTime: at(6),
          endTime: at(14),
          checkpoints: checkpoints(),
          plannedPath: _seedPath,
          equipmentIds: ['e1'],
          status: ScheduleStatus.pending),
      Schedule(
          id: 'r$day-p3',
          routeId: 'r1',
          routeName: 'Tuyến tuần tra mẫu',
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
  final linked = ref.watch(currentShiftProvider).schedule;
  if (linked != null) return linked;
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
  ref.invalidate(silencedAlarmIdsProvider);
  final lists = <StateNotifierProvider<PersistedListNotifier<dynamic>, Object>>[
    incidentsProvider,
    routeConfigsProvider,
    schedulesProvider,
    personnelProvider,
    equipmentProvider,
    rosterProvider,
    attendanceProvider,
    leavesProvider,
    siteTracksProvider,
  ];
  for (final provider in lists) {
    ref.invalidate(provider);
  }
  await Future.wait(
      [for (final provider in lists) ref.read(provider.notifier).resetRemote()]);
}

String shiftName(Schedule s) {
  final h = s.startTime.hour;
  if (h < 12) return 'CA SÁNG';
  if (h < 18) return 'CA CHIỀU';
  return 'CA TỐI';
}

String formatShiftTime(Schedule s) =>
    '${formatHourMinute(s.startTime)} - ${formatHourMinute(s.endTime)}';

Color scheduleStatusColor(String status) {
  switch (status) {
    case ScheduleStatus.inProgress:
      return AppColors.primary;
    case ScheduleStatus.completed:
      return Colors.lightBlueAccent;
    default:
      return Colors.orange;
  }
}
