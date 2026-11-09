import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/json_mappers.dart';

class LocalStore {
  static const keyIncidents = 'incidents';
  static const keyRoutes = 'routes';
  static const keySchedules = 'schedules';
  static const keyPersonnel = 'personnel';
  static const keyEquipment = 'equipment';
  static const keyRoster = 'roster';
  static const keyAttendance = 'attendance';
  static const keyLeaves = 'leaves';
  static const keySiteTracks = 'site_tracks';
  static const keyLastGuardId = 'last_guard_id';
  static const keyDataVersion = 'data_version';
  static const dataVersion = 7;

  static const _dataKeys = [
    keyIncidents,
    keyRoutes,
    keySchedules,
    keyPersonnel,
    keyEquipment,
    keyRoster,
    keyAttendance,
    keyLeaves,
    keySiteTracks
  ];

  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  List<T>? readList<T>(String key, T Function(Json) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).map((e) => fromJson(e as Json)).toList();
    } catch (e) {
      debugPrint('LocalStore: bỏ qua dữ liệu hỏng ở "$key": $e');
      return null;
    }
  }

  Future<void> writeList<T>(
      String key, List<T> items, Json Function(T) toJson) {
    return _prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }

  Future<void> migrate() async {
    if (_prefs.getInt(keyDataVersion) == dataVersion) return;
    await clearData();
    await _prefs.setInt(keyDataVersion, dataVersion);
  }

  String? get lastGuardId => _prefs.getString(keyLastGuardId);
  Future<void> setLastGuardId(String id) =>
      _prefs.setString(keyLastGuardId, id);

  Future<void> clearData() async {
    for (final key in _dataKeys) {
      await _prefs.remove(key);
    }
  }
}
