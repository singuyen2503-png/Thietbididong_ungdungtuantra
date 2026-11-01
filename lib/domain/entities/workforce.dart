enum ShiftType { morning, afternoon, night }

extension ShiftTypeInfo on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.morning:
        return 'Ca Sáng';
      case ShiftType.afternoon:
        return 'Ca Chiều';
      case ShiftType.night:
        return 'Ca Tối';
    }
  }

  int get startHour {
    switch (this) {
      case ShiftType.morning:
        return 6;
      case ShiftType.afternoon:
        return 14;
      case ShiftType.night:
        return 22;
    }
  }

  String get timeRange {
    final end = (startHour + 8) % 24;
    String two(int h) => h.toString().padLeft(2, '0');
    return '${two(startHour)}:00 - ${two(end)}:00';
  }

  DateTime startOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour);

  DateTime endOn(DateTime day) => startOn(day).add(const Duration(hours: 8));
}

class RosterEntry {
  final String id;
  final String personnelId;
  final DateTime date;
  final ShiftType shift;

  RosterEntry(
      {required this.id,
      required this.personnelId,
      required this.date,
      required this.shift});

  DateTime get start => shift.startOn(date);
  DateTime get end => shift.endOn(date);
}

class AttendanceRecord {
  final String id;
  final String personnelId;
  final DateTime date;
  final ShiftType shift;
  final DateTime checkIn;
  final DateTime? checkOut;

  AttendanceRecord(
      {required this.id,
      required this.personnelId,
      required this.date,
      required this.shift,
      required this.checkIn,
      this.checkOut});

  static const lateToleranceMinutes = 10;

  int get lateMinutes {
    final late = checkIn.difference(shift.startOn(date)).inMinutes;
    return late > lateToleranceMinutes ? late : 0;
  }

  bool get isLate => lateMinutes > 0;
  bool get isComplete => checkOut != null;

  double get workedHours => checkOut == null
      ? 0
      : checkOut!.difference(checkIn).inMinutes.clamp(0, 24 * 60) / 60;

  AttendanceRecord copyWith({DateTime? checkOut}) => AttendanceRecord(
      id: id,
      personnelId: personnelId,
      date: date,
      shift: shift,
      checkIn: checkIn,
      checkOut: checkOut ?? this.checkOut);
}

enum LeaveStatus { pending, approved, rejected }

extension LeaveStatusInfo on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'CHỜ DUYỆT';
      case LeaveStatus.approved:
        return 'ĐÃ DUYỆT';
      case LeaveStatus.rejected:
        return 'TỪ CHỐI';
    }
  }
}

class LeaveRequest {
  final String id;
  final String personnelId;
  final String personnelName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;
  final String? reviewNote;

  LeaveRequest(
      {required this.id,
      required this.personnelId,
      required this.personnelName,
      required this.fromDate,
      required this.toDate,
      required this.reason,
      required this.createdAt,
      this.status = LeaveStatus.pending,
      this.reviewNote});

  int get days => toDate.difference(fromDate).inDays + 1;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(fromDate) && !d.isAfter(toDate);
  }

  LeaveRequest copyWith({LeaveStatus? status, String? reviewNote}) =>
      LeaveRequest(
          id: id,
          personnelId: personnelId,
          personnelName: personnelName,
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
          createdAt: createdAt,
          status: status ?? this.status,
          reviewNote: reviewNote ?? this.reviewNote);
}
