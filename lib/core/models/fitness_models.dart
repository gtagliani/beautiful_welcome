import 'dart:convert';

class WorkoutExercise {
  final String id;
  final String name;
  final String youtubeLink;
  final String description;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.youtubeLink,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'youtubeLink': youtubeLink,
      'description': description,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      youtubeLink: map['youtubeLink'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class RoutineDay {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;

  RoutineDay({
    required this.id,
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((x) => x.toMap()).toList(),
    };
  }

  factory RoutineDay.fromMap(Map<String, dynamic> map) {
    return RoutineDay(
      id: map['id'] ?? '',
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
  final String description;
  final List<RoutineDay> days;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'days': days.map((x) => x.toMap()).toList(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      days: List<RoutineDay>.from(
        (map['days'] ?? []).map((x) => RoutineDay.fromMap(x)),
      ),
    );
  }

  String toJson() => json.encode(toMap());
  factory Routine.fromJson(String source) => Routine.fromMap(json.decode(source));
}

class WorkoutLog {
  final String id;
  final DateTime date;
  final String routineId;
  final String notes;

  WorkoutLog({
    required this.id,
    required this.date,
    required this.routineId,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'routineId': routineId,
      'notes': notes,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] ?? '',
      date: DateTime.tryParse(map['date']) ?? DateTime.now(),
      routineId: map['routineId'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory WorkoutLog.fromJson(String source) => WorkoutLog.fromMap(json.decode(source));
}
