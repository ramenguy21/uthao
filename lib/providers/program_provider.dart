import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program.dart';
import '../models/workout_day.dart';
import 'db_provider.dart';

final activeProgramProvider = FutureProvider<Program?>((ref) {
  final db = ref.watch(dbProvider);
  return db.getActiveProgram();
});

final workoutDaysProvider = FutureProvider<List<WorkoutDay>>((ref) async {
  final program = await ref.watch(activeProgramProvider.future);
  if (program == null) return [];
  final db = ref.watch(dbProvider);
  return db.getWorkoutDays(program.id);
});
