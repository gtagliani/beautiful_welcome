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
    final newState = List<WorkoutLog>.from(state);
    final index = newState.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      newState[index] = log;
    } else {
      newState.add(log);
    }
    state = newState;
    await _saveToStorage();
  }

  Future<void> deleteLogsForRoutine(String routineId) async {
    final newState = state.where((log) => log.routineId != routineId).toList();
    state = newState;
    await _saveToStorage();
  }

  WorkoutLog? getActiveSessionForRoutine(String routineId) {
    try {
      return state.firstWhere((log) => log.routineId == routineId && log.status == WorkoutLogStatus.started);
    } catch (e) {
      return null;
    }
  }

  Future<void> finishSession(String id) async {
    final newState = List<WorkoutLog>.from(state);
    final index = newState.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final old = newState[index];
      newState[index] = WorkoutLog(
        id: old.id,
        date: old.date,
        routineId: old.routineId,
        routineDayId: old.routineDayId,
        exerciseLogs: old.exerciseLogs,
        status: WorkoutLogStatus.finished,
        percentage: old.percentage,
      );
      state = newState;
      await _saveToStorage();
    }
  }

  bool hasTrackedExercise(String exerciseId) {
    return state.any((log) => log.exerciseLogs.any((el) => el.exerciseId == exerciseId));
  }

  bool hasTrackedDay(String routineDayId) {
    return state.any((log) => log.routineDayId == routineDayId);
  }

  Future<void> cascadeDeleteExercise(String exerciseId) async {
    final newState = <WorkoutLog>[];
    for (var log in state) {
      final updatedExercises = log.exerciseLogs.where((el) => el.exerciseId != exerciseId).toList();
      if (updatedExercises.isNotEmpty) {
        newState.add(WorkoutLog(
          id: log.id,
          date: log.date,
          routineId: log.routineId,
          routineDayId: log.routineDayId,
          exerciseLogs: updatedExercises,
          status: log.status,
          percentage: log.percentage,
        ));
      }
    }
    state = newState;
    await _saveToStorage();
  }

  Future<void> cascadeDeleteDay(String routineDayId) async {
    final newState = state.where((log) => log.routineDayId != routineDayId).toList();
    state = newState;
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, List<WorkoutLog>>(() {
  return TrackingNotifier();
});
