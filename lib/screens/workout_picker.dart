import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_day.dart';
import '../providers/db_provider.dart';
import 'active_session.dart';
import '../providers/program_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WorkoutPickerScreen extends ConsumerWidget {
  const WorkoutPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(workoutDaysProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            Expanded(
              child: daysAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(error: e.toString()),
                data: (days) =>
                    days.isEmpty ? const _EmptyState() : _DayList(days: days),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('uthao', style: AppTextStyles.appTitle),
          const SizedBox(height: 6),
          Text('SELECT WORKOUT', style: AppTextStyles.screenLabel),
        ],
      ),
    );
  }
}

// ── Day list ──────────────────────────────────────────────────────────────────

class _DayList extends StatelessWidget {
  const _DayList({required this.days});

  final List<WorkoutDay> days;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _WorkoutDayCard(day: days[i]),
    );
  }
}

// ── Workout day card ──────────────────────────────────────────────────────────

class _WorkoutDayCard extends ConsumerWidget {
  const _WorkoutDayCard({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liftingExercises =
        day.exercises.where((e) => e.type == 'lifting').toList();
    final cardioExercises =
        day.exercises.where((e) => e.type == 'cardio').toList();

    return Container(
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(day.name, style: AppTextStyles.headingLg),
                ),
                _ExerciseCountChip(
                  lifting: liftingExercises.length,
                  cardio: cardioExercises.length,
                ),
              ],
            ),
          ),
          if (day.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ExerciseList(exercises: day.exercises),
            ),
          ],
          const SizedBox(height: 16),
          _StartButton(
            onPressed: () => _onStart(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _onStart(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    await db.startSession(day);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
    );
  }
}

// ── Exercise list ─────────────────────────────────────────────────────────────

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.exercises});

  final List<RefExercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.map((e) => _ExerciseRow(exercise: e)).toList(),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final RefExercise exercise;

  @override
  Widget build(BuildContext context) {
    final isCardio = exercise.type == 'cardio';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Type indicator — thin left bar
          Container(
            width: 2,
            height: 14,
            color: isCardio ? AppColors.accentBright : AppColors.textMuted,
            margin: const EdgeInsets.only(right: 10),
          ),
          Expanded(
            child: Text(exercise.name, style: AppTextStyles.bodyMuted),
          ),
          Text(
            '${exercise.targetSets}×${exercise.targetReps}',
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }
}

// ── Exercise count chip ───────────────────────────────────────────────────────

class _ExerciseCountChip extends StatelessWidget {
  const _ExerciseCountChip({required this.lifting, required this.cardio});

  final int lifting;
  final int cardio;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (lifting > 0) parts.add('$lifting LIFT');
    if (cardio > 0) parts.add('$cardio CARDIO');
    final label = parts.join(' · ');

    return Container(
      color: AppColors.cardHigh,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label, style: AppTextStyles.meta),
    );
  }
}

// ── Start button ──────────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: AppTextStyles.buttonLabel,
        ),
        child: const Text('START WORKOUT'),
      ),
    );
  }
}

// ── State widgets ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text('LOADING', style: AppTextStyles.screenLabel),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ERROR', style: AppTextStyles.screenLabel),
          const SizedBox(height: 8),
          Text(error, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NO PROGRAM', style: AppTextStyles.headingLg),
          const SizedBox(height: 8),
          Text(
            'No workout program is configured.\nAdd a program to get started.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}
