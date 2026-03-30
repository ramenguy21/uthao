import 'dart:convert';

class LiftingSet {
  int reps;
  double weight;
  String unit; // 'kg' | 'lbs'
  int? completedAtMs;

  LiftingSet({
    required this.reps,
    required this.weight,
    this.unit = 'kg',
    this.completedAtMs,
  });

  DateTime? get completedAt => completedAtMs != null
      ? DateTime.fromMillisecondsSinceEpoch(completedAtMs!)
      : null;

  Map<String, Object?> toMap() => {
        'reps': reps,
        'weight': weight,
        'unit': unit,
        'completedAtMs': completedAtMs,
      };

  factory LiftingSet.fromMap(Map<String, Object?> m) => LiftingSet(
        reps: m['reps'] as int,
        weight: (m['weight'] as num).toDouble(),
        unit: m['unit'] as String? ?? 'kg',
        completedAtMs: m['completedAtMs'] as int?,
      );
}

class CardioSet {
  int durationSeconds;
  double? distance;
  String? distanceUnit; // 'km' | 'mi'
  int? completedAtMs;

  CardioSet({
    required this.durationSeconds,
    this.distance,
    this.distanceUnit,
    this.completedAtMs,
  });

  DateTime? get completedAt => completedAtMs != null
      ? DateTime.fromMillisecondsSinceEpoch(completedAtMs!)
      : null;

  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, Object?> toMap() => {
        'durationSeconds': durationSeconds,
        'distance': distance,
        'distanceUnit': distanceUnit,
        'completedAtMs': completedAtMs,
      };

  factory CardioSet.fromMap(Map<String, Object?> m) => CardioSet(
        durationSeconds: m['durationSeconds'] as int,
        distance: (m['distance'] as num?)?.toDouble(),
        distanceUnit: m['distanceUnit'] as String?,
        completedAtMs: m['completedAtMs'] as int?,
      );
}

/// A fully-owned copy of an exercise within a Session.
class SessionExercise {
  String name;
  String type; // 'lifting' | 'cardio'
  int order;
  List<LiftingSet> liftingSets;
  List<CardioSet> cardioSets;

  SessionExercise({
    required this.name,
    required this.type,
    required this.order,
    List<LiftingSet>? liftingSets,
    List<CardioSet>? cardioSets,
  })  : liftingSets = liftingSets ?? [],
        cardioSets = cardioSets ?? [];

  double get totalVolume =>
      liftingSets.fold(0, (sum, s) => sum + (s.weight * s.reps));

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type,
        'order': order,
        'liftingSets': liftingSets.map((s) => s.toMap()).toList(),
        'cardioSets': cardioSets.map((s) => s.toMap()).toList(),
      };

  factory SessionExercise.fromMap(Map<String, Object?> m) => SessionExercise(
        name: m['name'] as String,
        type: m['type'] as String,
        order: m['order'] as int,
        liftingSets: (m['liftingSets'] as List)
            .map((e) => LiftingSet.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
        cardioSets: (m['cardioSets'] as List)
            .map((e) => CardioSet.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}

class Session {
  final int id;
  final int? programDayId;
  final String? workoutDayName;
  final DateTime createdAt;
  DateTime? completedAt;
  List<SessionExercise> exercises;

  Session({
    required this.id,
    this.programDayId,
    this.workoutDayName,
    required this.createdAt,
    this.completedAt,
    List<SessionExercise>? exercises,
  }) : exercises = exercises ?? [];

  bool get isInProgress => completedAt == null;

  double get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  Map<String, Object?> toRow() => {
        'program_day_id': programDayId,
        'workout_day_name': workoutDayName,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'exercises_json':
            jsonEncode(exercises.map((e) => e.toMap()).toList()),
      };

  factory Session.fromRow(Map<String, Object?> row) => Session(
        id: row['id'] as int,
        programDayId: row['program_day_id'] as int?,
        workoutDayName: row['workout_day_name'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        completedAt: row['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['completed_at'] as int)
            : null,
        exercises: (jsonDecode(row['exercises_json'] as String) as List)
            .map((e) =>
                SessionExercise.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}
