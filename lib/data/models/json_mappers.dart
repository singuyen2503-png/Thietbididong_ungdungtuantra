import '../../core/utils/lat_lng.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/models.dart';
import '../../domain/entities/workforce.dart';

typedef Json = Map<String, dynamic>;

Json latLngToJson(LatLng p) => {'lat': p.latitude, 'lng': p.longitude};
LatLng latLngFromJson(Json j) =>
    LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

List<LatLng> _path(dynamic list) =>
    (list as List).map((e) => latLngFromJson(e as Json)).toList();
DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);

Json incidentToJson(Incident i) => {
      'id': i.id,
      'title': i.title,
      'description': i.description,
      'reportedBy': i.reportedBy,
      'createdAt': i.createdAt.toIso8601String(),
      'isResolved': i.isResolved,
      'imageBase64': i.imageBase64,
      'audioPath': i.audioPath,
      'commanderNote': i.commanderNote,
      'severity': i.severity.name,
      'assignedBackupNames': i.assignedBackupNames,
      'resolutionReport': i.resolutionReport,
      'resolvedBy': i.resolvedBy,
      'isFireAlarm': i.isFireAlarm,
    };

Incident incidentFromJson(Json j) => Incident(
      id: j['id'],
      title: j['title'],
      description: j['description'],
      reportedBy: j['reportedBy'],
      createdAt: DateTime.parse(j['createdAt']),
      isResolved: j['isResolved'] ?? false,
      imageBase64: j['imageBase64'],
      audioPath: j['audioPath'],
      commanderNote: j['commanderNote'],
      severity: IncidentSeverity.values.byName(j['severity'] ?? 'medium'),
      assignedBackupNames:
          List<String>.from(j['assignedBackupNames'] ?? const []),
      resolutionReport: j['resolutionReport'],
      resolvedBy: j['resolvedBy'],
      isFireAlarm: j['isFireAlarm'] ?? false,
    );

Json checkpointConfigToJson(CheckpointConfig c) => {
      'id': c.id,
      'name': c.name,
      'expectedQrCode': c.expectedQrCode,
      'location': latLngToJson(c.location),
      'radiusMeters': c.radiusMeters,
    };

CheckpointConfig checkpointConfigFromJson(Json j) => CheckpointConfig(
      id: j['id'],
      name: j['name'],
      expectedQrCode: j['expectedQrCode'],
      location: latLngFromJson(j['location']),
      radiusMeters: (j['radiusMeters'] as num).toDouble(),
    );

Json routeToJson(RouteConfig r) => {
      'id': r.id,
      'name': r.name,
      'plannedPath': r.plannedPath.map(latLngToJson).toList(),
      'checkpoints': r.checkpoints.map(checkpointConfigToJson).toList(),
    };

RouteConfig routeFromJson(Json j) => RouteConfig(
      id: j['id'],
      name: j['name'],
      plannedPath: _path(j['plannedPath']),
      checkpoints: (j['checkpoints'] as List)
          .map((e) => checkpointConfigFromJson(e as Json))
          .toList(),
    );

Json checkpointToJson(Checkpoint c) => {
      'id': c.id,
      'name': c.name,
      'expectedQrCode': c.expectedQrCode,
      'location': latLngToJson(c.location),
      'radiusMeters': c.radiusMeters,
      'isScanned': c.isScanned,
      'scannedAt': c.scannedAt?.toIso8601String(),
      'isSynced': c.isSynced,
    };

Checkpoint checkpointFromJson(Json j) => Checkpoint(
      id: j['id'],
      name: j['name'],
      expectedQrCode: j['expectedQrCode'],
      location: latLngFromJson(j['location']),
      radiusMeters: (j['radiusMeters'] as num).toDouble(),
      isScanned: j['isScanned'] ?? false,
      scannedAt: _date(j['scannedAt']),
      isSynced: j['isSynced'] ?? false,
    );

Json scheduleToJson(Schedule s) => {
      'id': s.id,
      'routeId': s.routeId,
      'routeName': s.routeName,
      'guardId': s.guardId,
      'guardName': s.guardName,
      'startTime': s.startTime.toIso8601String(),
      'endTime': s.endTime.toIso8601String(),
      'checkpoints': s.checkpoints.map(checkpointToJson).toList(),
      'plannedPath': s.plannedPath.map(latLngToJson).toList(),
      'actualPath': s.actualPath.map(latLngToJson).toList(),
      'equipmentIds': s.equipmentIds,
      'status': s.status,
    };

Schedule scheduleFromJson(Json j) => Schedule(
      id: j['id'],
      routeId: j['routeId'],
      routeName: j['routeName'],
      guardId: j['guardId'],
      guardName: j['guardName'],
      startTime: DateTime.parse(j['startTime']),
      endTime: DateTime.parse(j['endTime']),
      checkpoints: (j['checkpoints'] as List)
          .map((e) => checkpointFromJson(e as Json))
          .toList(),
      plannedPath: _path(j['plannedPath']),
      actualPath: _path(j['actualPath'] ?? const []),
      equipmentIds: List<String>.from(j['equipmentIds']),
      status: j['status'],
    );

Json personnelToJson(Personnel p) => {
      'id': p.id,
      'username': p.username,
      'name': p.name,
      'phone': p.phone,
      'role': p.role,
      'gender': p.gender,
      'age': p.age,
      'notes': p.notes,
      'pin': p.pin,
      'isActive': p.isActive,
    };

Personnel personnelFromJson(Json j) => Personnel(
      id: j['id'],
      username: j['username'],
      name: j['name'],
      phone: j['phone'],
      role: j['role'],
      gender: j['gender'],
      age: j['age'],
      notes: j['notes'] ?? '',
      pin: j['pin'],
      isActive: j['isActive'] ?? true,
    );

Json equipmentToJson(Equipment e) =>
    {'id': e.id, 'name': e.name, 'code': e.code, 'status': e.status};
Equipment equipmentFromJson(Json j) => Equipment(
    id: j['id'], name: j['name'], code: j['code'], status: j['status']);

Json rosterToJson(RosterEntry r) => {
      'id': r.id,
      'personnelId': r.personnelId,
      'date': r.date.toIso8601String(),
      'shift': r.shift.name,
      'routeId': r.routeId,
      'equipmentIds': r.equipmentIds,
    };

RosterEntry rosterFromJson(Json j) => RosterEntry(
    id: j['id'],
    personnelId: j['personnelId'],
    date: DateTime.parse(j['date']),
    shift: ShiftType.values.byName(j['shift']),
    routeId: j['routeId'],
    equipmentIds: List<String>.from(j['equipmentIds'] ?? const []));

Json attendanceToJson(AttendanceRecord a) => {
      'id': a.id,
      'personnelId': a.personnelId,
      'date': a.date.toIso8601String(),
      'shift': a.shift.name,
      'checkIn': a.checkIn.toIso8601String(),
      'checkOut': a.checkOut?.toIso8601String(),
    };

AttendanceRecord attendanceFromJson(Json j) => AttendanceRecord(
    id: j['id'],
    personnelId: j['personnelId'],
    date: DateTime.parse(j['date']),
    shift: ShiftType.values.byName(j['shift']),
    checkIn: DateTime.parse(j['checkIn']),
    checkOut: _date(j['checkOut']));

Json leaveToJson(LeaveRequest l) => {
      'id': l.id,
      'personnelId': l.personnelId,
      'personnelName': l.personnelName,
      'fromDate': l.fromDate.toIso8601String(),
      'toDate': l.toDate.toIso8601String(),
      'reason': l.reason,
      'status': l.status.name,
      'createdAt': l.createdAt.toIso8601String(),
      'reviewNote': l.reviewNote,
    };

LeaveRequest leaveFromJson(Json j) => LeaveRequest(
    id: j['id'],
    personnelId: j['personnelId'],
    personnelName: j['personnelName'],
    fromDate: DateTime.parse(j['fromDate']),
    toDate: DateTime.parse(j['toDate']),
    reason: j['reason'],
    status: LeaveStatus.values.byName(j['status']),
    createdAt: DateTime.parse(j['createdAt']),
    reviewNote: j['reviewNote']);

Json siteTrackToJson(SiteTrack t) => {
      'id': t.id,
      'points': t.points.map(latLngToJson).toList(),
      'recordedAt': t.recordedAt.toIso8601String(),
    };

SiteTrack siteTrackFromJson(Json j) => SiteTrack(
    id: j['id'],
    points: _path(j['points']),
    recordedAt: DateTime.parse(j['recordedAt']));
