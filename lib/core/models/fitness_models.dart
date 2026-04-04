import 'dart:convert';

enum WorkoutLogStatus {
  started,
  finished,
}
class WorkoutExercise {
  final String id;
  final int sequence;
  final String name; // maps to Title in prompt
  final String description;
  final List<String> pictures;
  final String youtubeLink;
  final int sets;
  final double restTime;

  WorkoutExercise({
    required this.id,
    required this.sequence,
    required this.name,
    required this.description,
    this.pictures = const [],
    this.youtubeLink = '',
    this.sets = 3,
    required this.restTime,
  }) : assert(sets >= 1);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sequence': sequence,
      'name': name,
      'description': description,
      'pictures': pictures,
      'youtubeLink': youtubeLink,
      'sets': sets,
      'restTime': restTime,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] ?? '',
      sequence: map['sequence']?.toInt() ?? 1,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pictures: List<String>.from(map['pictures'] ?? []),
      youtubeLink: map['youtubeLink'] ?? '',
      sets: map['sets']?.toInt() ?? 3,
      restTime: (map['restTime'] ?? 1.0).toDouble(),
    );
  }
}

class RoutineDay {
  final String id;
  final int day; // Automatic sequence for each day
  final String name;
  final List<WorkoutExercise> exercises;

  RoutineDay({
    required this.id,
    required this.day,
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'name': name,
      'exercises': exercises.map((x) => x.toMap()).toList(),
    };
  }

  factory RoutineDay.fromMap(Map<String, dynamic> map) {
    return RoutineDay(
      id: map['id'] ?? '',
      day: map['day']?.toInt() ?? 1,
      name: map['name'] ?? '',
      exercises: List<WorkoutExercise>.from(
        (map['exercises'] ?? []).map((x) => WorkoutExercise.fromMap(x)),
      ),
    );
  }
}

class Routine {
  final String id;
  final String name;
  final String mainObjective;
  final String description;
  final List<RoutineDay> days;

  Routine({
    required this.id,
    required this.name,
    required this.mainObjective,
    required this.description,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mainObjective': mainObjective,
      'description': description,
      'days': days.map((x) => x.toMap()).toList(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      mainObjective: map['mainObjective'] ?? '',
      description: map['description'] ?? '',
      days: List<RoutineDay>.from(
        (map['days'] ?? []).map((x) => RoutineDay.fromMap(x)),
      ),
    );
  }

  String toJson() => json.encode(toMap());
  factory Routine.fromJson(String source) => Routine.fromMap(json.decode(source));
}

class ExerciseLog {
  final String exerciseId;
  final double weight;
  final String notes;
  final bool finished;

  ExerciseLog({
    required this.exerciseId,
    required this.weight,
    this.notes = '',
    this.finished = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'weight': weight,
      'notes': notes,
      'finished': finished,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseId: map['exerciseId'] ?? '',
      weight: (map['weight'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      finished: map['finished'] ?? false,
    );
  }
}

class WorkoutLog {
  final String id;
  final DateTime date;
  final String routineId;
  final String routineDayId;
  final List<ExerciseLog> exerciseLogs;
  final WorkoutLogStatus status;
  final double percentage;

  WorkoutLog({
    required this.id,
    required this.date,
    required this.routineId,
    required this.routineDayId,
    required this.exerciseLogs,
    this.status = WorkoutLogStatus.started,
    this.percentage = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'routineId': routineId,
      'routineDayId': routineDayId,
      'exerciseLogs': exerciseLogs.map((x) => x.toMap()).toList(),
      'status': status.name,
      'percentage': percentage,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      routineId: map['routineId'] ?? '',
      routineDayId: map['routineDayId'] ?? '',
      exerciseLogs: List<ExerciseLog>.from(
        (map['exerciseLogs'] ?? []).map((x) => ExerciseLog.fromMap(x)),
      ),
      status: WorkoutLogStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WorkoutLogStatus.started,
      ),
      percentage: (map['percentage'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());
  factory WorkoutLog.fromJson(String source) => WorkoutLog.fromMap(json.decode(source));
}
