import '../../core/utils/lat_lng.dart';

enum IncidentSeverity { low, medium, high, critical }

extension IncidentSeverityExtension on IncidentSeverity {
  String get vietnameseName {
    switch (this) {
      case IncidentSeverity.low:
        return 'THẤP';
      case IncidentSeverity.medium:
        return 'VỪA';
      case IncidentSeverity.high:
        return 'CAO';
      case IncidentSeverity.critical:
        return 'KHẨN CẤP';
    }
  }
}

class Incident {
  final String id;
  final String title;
  final String description;
  final String reportedBy;
  final DateTime createdAt;
  final bool isResolved;
  final String? imageBase64;
  final String? audioPath;
  final String? commanderNote;
  final IncidentSeverity severity;
  final List<String> assignedBackupNames;
  final String? resolutionReport;
  final String? resolvedBy;
  final bool isFireAlarm;

  Incident(
      {required this.id,
      required this.title,
      required this.description,
      required this.reportedBy,
      required this.createdAt,
      this.isResolved = false,
      this.imageBase64,
      this.audioPath,
      this.commanderNote,
      this.severity = IncidentSeverity.medium,
      this.assignedBackupNames = const [],
      this.resolutionReport,
      this.resolvedBy,
      this.isFireAlarm = false});
  Incident copyWith(
      {bool? isResolved,
      String? commanderNote,
      IncidentSeverity? severity,
      List<String>? assignedBackupNames,
      String? resolutionReport,
      String? resolvedBy}) {
    return Incident(
        id: id,
        title: title,
        description: description,
        reportedBy: reportedBy,
        createdAt: createdAt,
        imageBase64: imageBase64,
        audioPath: audioPath,
        isResolved: isResolved ?? this.isResolved,
        commanderNote: commanderNote ?? this.commanderNote,
        severity: severity ?? this.severity,
        assignedBackupNames: assignedBackupNames ?? this.assignedBackupNames,
        resolutionReport: resolutionReport ?? this.resolutionReport,
        resolvedBy: resolvedBy ?? this.resolvedBy,
        isFireAlarm: isFireAlarm);
  }
}

class RouteConfig {
  final String id;
  final String name;
  final List<LatLng> plannedPath;
  final List<CheckpointConfig> checkpoints;

  RouteConfig(
      {required this.id,
      required this.name,
      required this.plannedPath,
      required this.checkpoints});
}

class CheckpointConfig {
  final String id;
  final String name;
  final String expectedQrCode;
  final LatLng location;
  final double radiusMeters;

  CheckpointConfig(
      {required this.id,
      required this.name,
      required this.expectedQrCode,
      required this.location,
      this.radiusMeters = 15.0});
}

class Checkpoint {
  final String id;
  final String name;
  final String expectedQrCode;
  final LatLng location;
  final double radiusMeters;
  final bool isScanned;
  final DateTime? scannedAt;
  final bool isSynced;

  Checkpoint(
      {required this.id,
      required this.name,
      required this.expectedQrCode,
      required this.location,
      required this.radiusMeters,
      this.isScanned = false,
      this.scannedAt,
      this.isSynced = false});
  Checkpoint copyWith({bool? isScanned, DateTime? scannedAt, bool? isSynced}) {
    return Checkpoint(
        id: id,
        name: name,
        expectedQrCode: expectedQrCode,
        location: location,
        radiusMeters: radiusMeters,
        isScanned: isScanned ?? this.isScanned,
        scannedAt: scannedAt ?? this.scannedAt,
        isSynced: isSynced ?? this.isSynced);
  }
}

class Schedule {
  final String id;
  final String routeId;
  final String routeName;
  final String guardId;
  final String guardName;
  final DateTime startTime;
  final DateTime endTime;
  final List<Checkpoint> checkpoints;
  final List<LatLng> plannedPath;
  final List<LatLng> actualPath;
  final List<String> equipmentIds;
  final String status;

  Schedule(
      {required this.id,
      required this.routeId,
      required this.routeName,
      required this.guardId,
      required this.guardName,
      required this.startTime,
      required this.endTime,
      required this.checkpoints,
      required this.plannedPath,
      this.actualPath = const [],
      required this.equipmentIds,
      required this.status});
  Schedule copyWith(
      {List<LatLng>? actualPath,
      List<Checkpoint>? checkpoints,
      String? status}) {
    return Schedule(
        id: id,
        routeId: routeId,
        routeName: routeName,
        guardId: guardId,
        guardName: guardName,
        startTime: startTime,
        endTime: endTime,
        checkpoints: checkpoints ?? this.checkpoints,
        plannedPath: plannedPath,
        actualPath: actualPath ?? this.actualPath,
        equipmentIds: equipmentIds,
        status: status ?? this.status);
  }
}

class Personnel {
  final String id;
  final String username;
  final String name;
  final String phone;
  final String role;
  final String gender;
  final int age;
  final String notes;
  final String pin;
  final bool isActive;

  Personnel(
      {required this.id,
      required this.username,
      required this.name,
      required this.phone,
      required this.role,
      required this.gender,
      required this.age,
      this.notes = '',
      required this.pin,
      this.isActive = true});

  Personnel copyWith({bool? isActive}) => Personnel(
      id: id,
      username: username,
      name: name,
      phone: phone,
      role: role,
      gender: gender,
      age: age,
      notes: notes,
      pin: pin,
      isActive: isActive ?? this.isActive);
}

class SiteTrack {
  final String id;
  final List<LatLng> points;
  final DateTime recordedAt;

  SiteTrack({required this.id, required this.points, required this.recordedAt});
}
