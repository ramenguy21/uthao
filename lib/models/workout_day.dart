import 'dart:convert';

class RefExercise {
  final String name;
  final int targetSets;
  final String targetReps; // e.g. "4-6", "8-12", "30 min"
  final String type;       // 'lifting' | 'cardio'
  final int order;

  const RefExercise({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.type,
    required this.order,
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'type': type,
        'order': order,
      };

  factory RefExercise.fromMap(Map<String, Object?> m) => RefExercise(
        name: m['name'] as String,
        targetSets: m['targetSets'] as int,
        targetReps: m['targetReps'] as String,
        type: m['type'] as String,
        order: m['order'] as int,
      );
}

/// A named day within a Program. Reference template only — sessions copy
/// exercises at start time and are never linked back to this.
class WorkoutDay {
  final int id;
  final int programId;
  final String name;
  final int order;
  final List<RefExercise> exercises;

  const WorkoutDay({
    required this.id,
    required this.programId,
    required this.name,
    required this.order,
    required this.exercises,
  });

  /// Map for DB insert/update — excludes id (auto-assigned).
  Map<String, Object?> toRow() => {
        'program_id': programId,
        'name': name,
        'display_order': order,
        'exercises_json':
            jsonEncode(exercises.map((e) => e.toMap()).toList()),
      };

  factory WorkoutDay.fromRow(Map<String, Object?> row) => WorkoutDay(
        id: row['id'] as int,
        programId: row['program_id'] as int,
        name: row['name'] as String,
        order: row['display_order'] as int,
        exercises: (jsonDecode(row['exercises_json'] as String) as List)
            .map((e) => RefExercise.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}
