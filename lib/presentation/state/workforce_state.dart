import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/lat_lng.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/json_mappers.dart';
import '../../domain/entities/models.dart';
import '../../domain/entities/workforce.dart';
import 'manager_state.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

final rosterProvider = StateNotifierProvider<RosterNotifier, List<RosterEntry>>(
    (ref) => RosterNotifier(ref.watch(localStoreProvider)));

class RosterNotifier extends PersistedListNotifier<RosterEntry> {
  RosterNotifier([LocalStore? store])
      : super(
            store, LocalStore.keyRoster, _seed(), rosterToJson, rosterFromJson);

  static List<RosterEntry> _seed() {
    final monday = startOfWeek(DateTime.now());
    final entries = <RosterEntry>[];
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      entries.add(RosterEntry(
          id: 'r$i-p1',
          personnelId: 'p1',
          date: day,
          shift: ShiftType.morning));
      if (i < 6) {
        entries.add(RosterEntry(
            id: 'r$i-p3',
            personnelId: 'p3',
            date: day,
            shift: ShiftType.afternoon));
      }
      if (i < 5) {
        entries.add(RosterEntry(
            id: 'r$i-p2',
            personnelId: 'p2',
            date: day,
            shift: ShiftType.night));
      }
    }
    return entries;
  }

  String? assign(String personnelId, DateTime day, ShiftType shift,
      {required List<Personnel> personnel,
      required List<LeaveRequest> leaves}) {
    final date = dateOnly(day);
    final person = personnel.where((p) => p.id == personnelId).firstOrNull;
    if (person == null || !person.isActive) {
      return 'Nhân viên không còn làm việc!';
    }
    final onLeave = leaves.any((l) =>
        l.personnelId == personnelId &&
        l.status == LeaveStatus.approved &&
        l.covers(date));
    if (onLeave) return '${person.name} đang nghỉ phép ngày này!';
    final busy = state
        .where((e) => e.personnelId == personnelId && sameDay(e.date, date));
    if (busy.any((e) => e.shift == shift)) {
      return '${person.name} đã có trong ${shift.label}!';
    }
    if (busy.isNotEmpty) {
      return '${person.name} đã được phân ${busy.first.shift.label} ngày này!';
    }
    state = [
      ...state,
      RosterEntry(
          id: _newId(), personnelId: personnelId, date: date, shift: shift)
    ];
    return null;
  }

  void remove(String id) => state = state.where((e) => e.id != id).toList();

  int removeFor(String personnelId,
      {DateTime? from, DateTime? to, bool Function(RosterEntry)? where}) {
    final before = state.length;
    state = state.where((e) {
      if (e.personnelId != personnelId) return true;
      if (from != null && e.date.isBefore(dateOnly(from))) return true;
      if (to != null && e.date.isAfter(dateOnly(to))) return true;
      if (where != null && !where(e)) return true;
      return false;
    }).toList();
    return before - state.length;
  }

  int copyWeek(DateTime fromMonday, DateTime toMonday,
      {required List<Personnel> personnel,
      required List<LeaveRequest> leaves}) {
    final source = state.where((e) =>
        !e.date.isBefore(fromMonday) &&
        e.date.isBefore(fromMonday.add(const Duration(days: 7))));
    final offset = toMonday.difference(fromMonday).inDays;
    int added = 0;
    for (final e in source.toList()) {
      final error = assign(
          e.personnelId, e.date.add(Duration(days: offset)), e.shift,
          personnel: personnel, leaves: leaves);
      if (error == null) added++;
    }
    return added;
  }
}

List<RosterEntry> rosterForDay(List<RosterEntry> roster, DateTime day,
        [ShiftType? shift]) =>
    roster
        .where(
            (e) => sameDay(e.date, day) && (shift == null || e.shift == shift))
        .toList();

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(
        (ref) => AttendanceNotifier(ref.watch(localStoreProvider)));

class AttendanceNotifier extends PersistedListNotifier<AttendanceRecord> {
  AttendanceNotifier([LocalStore? store])
      : super(store, LocalStore.keyAttendance, _seed(), attendanceToJson,
            attendanceFromJson);

  static List<AttendanceRecord> _seed() {
    final today = dateOnly(DateTime.now());
    final records = <AttendanceRecord>[];
    const people = {
      'p1': ShiftType.morning,
      'p3': ShiftType.afternoon,
      'p2': ShiftType.night
    };
    for (int back = 1; back <= 6; back++) {
      final day = today.subtract(Duration(days: back));
      people.forEach((id, shift) {
        if (id == 'p2' && day.weekday >= 6) return;
        final late = (back + id.hashCode) % 3 == 0;
        final start = shift.startOn(day);
        final checkIn = start.add(Duration(minutes: late ? 18 : -5));
        records.add(AttendanceRecord(
            id: 'a$back-$id',
            personnelId: id,
            date: day,
            shift: shift,
            checkIn: checkIn,
            checkOut: shift.endOn(day).add(const Duration(minutes: 3))));
      });
    }
    return records;
  }

  String? checkIn(String personnelId, RosterEntry entry, DateTime now) {
    if (now.isBefore(entry.start.subtract(const Duration(minutes: 30)))) {
      return 'Chưa đến giờ vào ca (chỉ được chấm công trước 30 phút)!';
    }
    if (now.isAfter(entry.end)) return 'Ca trực đã kết thúc!';
    final exists = state.any((a) =>
        a.personnelId == personnelId &&
        sameDay(a.date, entry.date) &&
        a.shift == entry.shift);
    if (exists) return 'Bạn đã chấm công vào ca này rồi!';
    state = [
      AttendanceRecord(
          id: _newId(),
          personnelId: personnelId,
          date: dateOnly(entry.date),
          shift: entry.shift,
          checkIn: now),
      ...state
    ];
    return null;
  }

  void checkOut(String recordId, DateTime now) => state = state
      .map((a) => a.id == recordId ? a.copyWith(checkOut: now) : a)
      .toList();
}

class AttendanceSummary {
  final int shiftsWorked;
  final double hours;
  final int lateCount;
  final int lateMinutes;
  final int leaveDays;
  final int absentShifts;

  const AttendanceSummary(
      {this.shiftsWorked = 0,
      this.hours = 0,
      this.lateCount = 0,
      this.lateMinutes = 0,
      this.leaveDays = 0,
      this.absentShifts = 0});
}

AttendanceSummary summarize(
    {required String personnelId,
    required DateTime month,
    required List<AttendanceRecord> attendance,
    required List<RosterEntry> roster,
    required List<LeaveRequest> leaves,
    required DateTime now}) {
  bool inMonth(DateTime d) => d.year == month.year && d.month == month.month;
  final mine = attendance
      .where((a) => a.personnelId == personnelId && inMonth(a.date))
      .toList();
  final complete = mine.where((a) => a.isComplete).toList();
  final approved = leaves.where(
      (l) => l.personnelId == personnelId && l.status == LeaveStatus.approved);
  int leaveDays = 0;
  for (var d = DateTime(month.year, month.month);
      d.month == month.month;
      d = d.add(const Duration(days: 1))) {
    if (approved.any((l) => l.covers(d))) leaveDays++;
  }
  final absent = roster.where((e) =>
      e.personnelId == personnelId &&
      inMonth(e.date) &&
      e.end.isBefore(now) &&
      !mine.any((a) => sameDay(a.date, e.date) && a.shift == e.shift));
  return AttendanceSummary(
    shiftsWorked: complete.length,
    hours: complete.fold(0, (sum, a) => sum + a.workedHours),
    lateCount: mine.where((a) => a.isLate).length,
    lateMinutes: mine.fold(0, (sum, a) => sum + a.lateMinutes),
    leaveDays: leaveDays,
    absentShifts: absent.length,
  );
}

final leavesProvider =
    StateNotifierProvider<LeavesNotifier, List<LeaveRequest>>(
        (ref) => LeavesNotifier(ref.watch(localStoreProvider)));

class LeavesNotifier extends PersistedListNotifier<LeaveRequest> {
  LeavesNotifier([LocalStore? store])
      : super(store, LocalStore.keyLeaves, _seed(), leaveToJson, leaveFromJson);

  static List<LeaveRequest> _seed() {
    final today = dateOnly(DateTime.now());
    return [
      LeaveRequest(
          id: 'l1',
          personnelId: 'p2',
          personnelName: 'Trần Thị B',
          fromDate: today.add(const Duration(days: 3)),
          toDate: today.add(const Duration(days: 4)),
          reason: 'Về quê có việc gia đình',
          createdAt: today.subtract(const Duration(hours: 5))),
    ];
  }

  String? submit(Personnel person, DateTime from, DateTime to, String reason,
      DateTime now) {
    final f = dateOnly(from), t = dateOnly(to);
    if (reason.trim().isEmpty) return 'Vui lòng nhập lý do nghỉ!';
    if (f.isBefore(dateOnly(now))) return 'Không thể xin nghỉ cho ngày đã qua!';
    if (t.isBefore(f)) return 'Ngày kết thúc phải sau ngày bắt đầu!';
    final overlap = state.any((l) =>
        l.personnelId == person.id &&
        l.status != LeaveStatus.rejected &&
        !(t.isBefore(l.fromDate) || f.isAfter(l.toDate)));
    if (overlap) return 'Bạn đã có đơn nghỉ trùng khoảng thời gian này!';
    state = [
      LeaveRequest(
          id: _newId(),
          personnelId: person.id,
          personnelName: person.name,
          fromDate: f,
          toDate: t,
          reason: reason.trim(),
          createdAt: now),
      ...state
    ];
    return null;
  }

  void review(String id, LeaveStatus status, [String? note]) => state = state
      .map((l) => l.id == id
          ? l.copyWith(
              status: status,
              reviewNote:
                  note == null || note.trim().isEmpty ? null : note.trim())
          : l)
      .toList();
}

int approveLeave(WidgetRef ref, LeaveRequest leave, [String? note]) {
  ref
      .read(leavesProvider.notifier)
      .review(leave.id, LeaveStatus.approved, note);
  return ref
      .read(rosterProvider.notifier)
      .removeFor(leave.personnelId, from: leave.fromDate, to: leave.toDate);
}

int removeResignedStaff(WidgetRef ref) {
  final resigned =
      ref.read(personnelProvider).where((p) => !p.isActive).toList();
  for (final p in resigned) {
    ref.read(rosterProvider.notifier).removeFor(p.id);
    ref.read(personnelProvider.notifier).deletePersonnel(p.id);
  }
  return resigned.length;
}

final siteTracksProvider =
    StateNotifierProvider<SiteTracksNotifier, List<SiteTrack>>(
        (ref) => SiteTracksNotifier(ref.watch(localStoreProvider)));

class SiteTracksNotifier extends PersistedListNotifier<SiteTrack> {
  SiteTracksNotifier([LocalStore? store])
      : super(store, LocalStore.keySiteTracks, const [], siteTrackToJson,
            siteTrackFromJson);

  void addTrack(List<LatLng> points) => state = [
        ...state,
        SiteTrack(id: _newId(), points: points, recordedAt: DateTime.now())
      ];

  void clearAll() => state = const [];
}

final siteTrackPointsProvider = Provider<List<List<LatLng>>>(
    (ref) => ref.watch(siteTracksProvider).map((t) => t.points).toList());

final activeFireAlarmsProvider = Provider<List<Incident>>((ref) => ref
    .watch(incidentsProvider)
    .where((i) => i.isFireAlarm && !i.isResolved)
    .toList());

final silencedAlarmIdsProvider = StateProvider<Set<String>>((ref) => {});

void raiseFireAlarm(WidgetRef ref, String location, String reporter) {
  ref.read(incidentsProvider.notifier).addIncident(Incident(
      id: _newId(),
      title: 'BÁO CHÁY: $location',
      description: 'Phát hiện cháy tại $location. Yêu cầu chi viện và gọi '
          'cứu hỏa 114 ngay!',
      reportedBy: reporter,
      createdAt: DateTime.now(),
      severity: IncidentSeverity.critical,
      isFireAlarm: true));
}
