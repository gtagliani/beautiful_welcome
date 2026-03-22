import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beautiful_welcome/core/models/fitness_models.dart';

class TrackingNotifier extends Notifier<List<WorkoutLog>> {
  static const _storageKey = 'saved_logs';

  @override
  List<WorkoutLog> build() {
    _loadLogs();
    return [];
  }

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        state = jsonList.map((e) => WorkoutLog.fromMap(e)).toList();
      } else {
        state = [];
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> saveLog(WorkoutLog log) async {
    final newState = [...state, log];
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = newState.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, List<WorkoutLog>>(() {
  return TrackingNotifier();
});
