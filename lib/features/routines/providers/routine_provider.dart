import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beautiful_welcome/core/models/fitness_models.dart';

class RoutineNotifier extends Notifier<List<Routine>> {
  static const _storageKey = 'saved_routines';

  @override
  List<Routine> build() {
    _loadRoutines();
    return [];
  }

  Future<void> _loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        state = jsonList.map((e) => Routine.fromMap(e)).toList();
      } else {
        // Initial setup with a demo routine for UI testing
        state = [
          Routine(
            id: 'demo1',
            name: 'Push Day - Hypertrophy',
            mainObjective: 'Hypertrophy',
            description: 'Intense chest, shoulders, and triceps focus.',
            days: [
              RoutineDay(
                id: 'd1',
                day: 1,
                name: 'Chest Focus',
                exercises: [
                  WorkoutExercise(
                    id: 'e1',
                    sequence: 1,
                    name: 'Bench Press',
                    youtubeLink: '',
                    description: '4 sets of 8-10 reps',
                    sets: 4,
                    restTime: 1.5,
                  )
                ]
              )
            ]
          )
        ];
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> saveRoutine(Routine routine) async {
    final newState = [...state];
    final index = newState.indexWhere((r) => r.id == routine.id);
    if (index >= 0) {
      newState[index] = routine;
    } else {
      newState.add(routine);
    }
    state = newState;
    await _saveToStorage();
  }

  Future<void> deleteRoutine(String routineId) async {
    final newState = state.where((r) => r.id != routineId).toList();
    state = newState;
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}

final routineProvider = NotifierProvider<RoutineNotifier, List<Routine>>(() {
  return RoutineNotifier();
});
