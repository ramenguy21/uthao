import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/program.dart';
import '../models/session.dart';
import '../models/workout_day.dart';

class DatabaseService {
  DatabaseService._(this._db);

  final Database _db;

  static Future<DatabaseService> init() async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'uthao.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE programs (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            version      INTEGER NOT NULL,
            archived_at  INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_days (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            program_id      INTEGER NOT NULL,
            name            TEXT NOT NULL,
            display_order   INTEGER NOT NULL,
            exercises_json  TEXT NOT NULL DEFAULT '[]'
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            program_day_id    INTEGER,
            workout_day_name  TEXT,
            created_at        INTEGER NOT NULL,
            completed_at      INTEGER,
            exercises_json    TEXT NOT NULL DEFAULT '[]'
          )
        ''');
      },
    );

    return DatabaseService._(db);
  }

  // ── Programs ──────────────────────────────────────────────────────────────

  Future<Program?> getActiveProgram() async {
    final rows = await _db.query(
      'programs',
      where: 'archived_at IS NULL',
      limit: 1,
    );
    return rows.isEmpty ? null : Program.fromMap(rows.first);
  }

  Future<int> saveProgram(Program program) {
    return _db.insert('programs', program.toMap());
  }

  Future<void> archiveProgram(int id) {
    return _db.update(
      'programs',
      {'archived_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Workout Days ──────────────────────────────────────────────────────────

  Future<List<WorkoutDay>> getWorkoutDays(int programId) async {
    final rows = await _db.query(
      'workout_days',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'display_order ASC',
    );
    return rows.map(WorkoutDay.fromRow).toList();
  }

  Future<int> saveWorkoutDay(WorkoutDay day) {
    return _db.insert('workout_days', day.toRow());
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<Session?> getInProgressSession() async {
    final rows = await _db.query(
      'sessions',
      where: 'completed_at IS NULL',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Session.fromRow(rows.first);
  }

  Future<List<Session>> getCompletedSessions({int limit = 50}) async {
    final rows = await _db.query(
      'sessions',
      where: 'completed_at IS NOT NULL',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Session.fromRow).toList();
  }

  Future<int> insertSession(Session session) {
    return _db.insert('sessions', session.toRow());
  }

  Future<void> updateSession(Session session) {
    return _db.update(
      'sessions',
      session.toRow(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<Session> startSession(WorkoutDay day) async {
    final existing = await getInProgressSession();
    if (existing != null) {
      existing.completedAt = DateTime.now();
      await updateSession(existing);
    }

    final exercises = day.exercises.map((ref) {
      if (ref.type == 'lifting') {
        return SessionExercise(
          name: ref.name,
          type: ref.type,
          order: ref.order,
          liftingSets: List.generate(
            ref.targetSets,
            (_) => LiftingSet(reps: 0, weight: 0),
          ),
        );
      } else {
        return SessionExercise(
          name: ref.name,
          type: ref.type,
          order: ref.order,
          cardioSets: [CardioSet(durationSeconds: 0)],
        );
      }
    }).toList();

    final now = DateTime.now();
    final draft = Session(
      id: 0,
      programDayId: day.id,
      workoutDayName: day.name,
      createdAt: now,
      exercises: exercises,
    );

    final id = await insertSession(draft);
    return Session(
      id: id,
      programDayId: day.id,
      workoutDayName: day.name,
      createdAt: now,
      exercises: exercises,
    );
  }

  // ── Previous Best ─────────────────────────────────────────────────────────

  Future<LiftingSet?> getPreviousBestLift(String exerciseName) async {
    final sessions = await getCompletedSessions(limit: 200);
    LiftingSet? best;
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.type != 'lifting') continue;
        if (exercise.name.toLowerCase() != exerciseName.toLowerCase()) continue;
        for (final set in exercise.liftingSets) {
          if (set.completedAtMs == null) continue;
          if (best == null || set.weight > best.weight) best = set;
        }
      }
    }
    return best;
  }

  // ── Seed Data ─────────────────────────────────────────────────────────────

  Future<void> seedIfEmpty() async {
    final count = Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM programs'));
    if ((count ?? 0) > 0) return;

    final programId = await saveProgram(Program(id: 0, version: 1));

    final days = [
      _day(programId, 'PUSH A', 0, [
        _ex('Barbell Bench Press', 4, '4-6', 'lifting', 0),
        _ex('Incline DB Press', 3, '8-12', 'lifting', 1),
        _ex('Cable Lateral Raise', 3, '12-15', 'lifting', 2),
        _ex('Tricep Rope Pushdown', 3, '10-12', 'lifting', 3),
      ]),
      _day(programId, 'PULL A', 1, [
        _ex('Weighted Pull-Up', 4, '4-6', 'lifting', 0),
        _ex('Pendlay Row', 4, '6-8', 'lifting', 1),
        _ex('Incline DB Curl', 3, '10-12', 'lifting', 2),
        _ex('Face Pull', 3, '15-20', 'lifting', 3),
      ]),
      _day(programId, 'LEGS A', 2, [
        _ex('Back Squat', 4, '4-6', 'lifting', 0),
        _ex('Romanian Deadlift', 3, '8-10', 'lifting', 1),
        _ex('Leg Press', 3, '12-15', 'lifting', 2),
        _ex('Leg Curl', 3, '10-12', 'lifting', 3),
      ]),
      _day(programId, 'PUSH B', 3, [
        _ex('Overhead Press', 4, '4-6', 'lifting', 0),
        _ex('DB Shoulder Press', 3, '8-12', 'lifting', 1),
        _ex('Cable Fly', 3, '12-15', 'lifting', 2),
        _ex('Skull Crusher', 3, '8-10', 'lifting', 3),
      ]),
      _day(programId, 'PULL B', 4, [
        _ex('Deadlift', 3, '3-5', 'lifting', 0),
        _ex('Cable Row', 4, '8-12', 'lifting', 1),
        _ex('Hammer Curl', 3, '10-12', 'lifting', 2),
        _ex('Rear Delt Fly', 3, '15-20', 'lifting', 3),
      ]),
      _day(programId, 'CARDIO', 5, [
        _ex('Treadmill Run', 1, '30 min', 'cardio', 0),
      ]),
    ];

    for (final day in days) {
      await saveWorkoutDay(day);
    }
  }

  static WorkoutDay _day(
    int programId,
    String name,
    int order,
    List<RefExercise> exercises,
  ) =>
      WorkoutDay(
        id: 0,
        programId: programId,
        name: name,
        order: order,
        exercises: exercises,
      );

  static RefExercise _ex(
    String name,
    int sets,
    String reps,
    String type,
    int order,
  ) =>
      RefExercise(
        name: name,
        targetSets: sets,
        targetReps: reps,
        type: type,
        order: order,
      );
}
