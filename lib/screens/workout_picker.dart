import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_day.dart';
import '../providers/db_provider.dart';
import 'active_session.dart';
import '../providers/program_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

final selectedDayProvider = StateProvider<WorkoutDay?>((ref) => null);

// Two-phase card state: idle → selected (horizontal sweep) → expanded (drop down)
enum _CardPhase { idle, selected, expanded }

class WorkoutPickerScreen extends ConsumerWidget {
  const WorkoutPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(workoutDaysProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            Expanded(
              child: daysAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(error: e.toString()),
                data: (days) =>
                    days.isEmpty ? const _EmptyState() : _DayList(days: days),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _StartButton(
                isActive: selectedDay != null,
                onPressed: () => _onStart(context, ref, selectedDay),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStart(
      BuildContext context, WidgetRef ref, WorkoutDay? day) async {
    if (day == null) return;
    final db = ref.read(dbProvider);
    await db.startSession(day);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UTHAO', style: AppTextStyles.appTitle),
          const SizedBox(height: 6),
          Text('SELECT WORKOUT', style: AppTextStyles.screenLabel),
        ],
      ),
    );
  }
}

// ── Workout day card ──────────────────────────────────────────────────────────

class _WorkoutDayCard extends ConsumerStatefulWidget {
  final WorkoutDay day;
  const _WorkoutDayCard({required this.day, super.key});

  @override
  ConsumerState<_WorkoutDayCard> createState() => _WorkoutDayCardState();
}

class _WorkoutDayCardState extends ConsumerState<_WorkoutDayCard>
    with TickerProviderStateMixin {
  _CardPhase _phase = _CardPhase.idle;

  // Phase 1: horizontal left-sweep (P5 snap)
  late final AnimationController _selectCtrl;
  late final Animation<double> _selectAnim;

  // Phase 2: vertical drop (exercise details)
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();

    _selectCtrl = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _selectAnim = CurvedAnimation(
      parent: _selectCtrl,
      curve: Curves.easeOutExpo,
    );

    _expandCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutExpo,
    );
  }

  @override
  void dispose() {
    _selectCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    final current = ref.read(selectedDayProvider);
    final isThisActive = current?.id == widget.day.id;

    if (!isThisActive) {
      // Select this card — phase 1: horizontal sweep
      ref.read(selectedDayProvider.notifier).state = widget.day;
      setState(() => _phase = _CardPhase.selected);
      _selectCtrl.forward();
      _expandCtrl.reverse();
    } else if (_phase == _CardPhase.selected) {
      // Phase 2: drop down exercises
      setState(() => _phase = _CardPhase.expanded);
      _expandCtrl.forward();
    } else {
      // Collapse back to selected (header only)
      setState(() => _phase = _CardPhase.selected);
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkoutDay?>(selectedDayProvider, (_, next) {
      if (next?.id != widget.day.id) {
        // Another card was activated — reset fully to idle
        setState(() => _phase = _CardPhase.idle);
        _selectCtrl.reverse();
        _expandCtrl.reverse();
      }
    });

    final selected = ref.watch(selectedDayProvider);
    final isActive = selected?.id == widget.day.id;
    final isExpanded = _phase == _CardPhase.expanded;

    final liftCount =
        widget.day.exercises.where((e) => e.type == 'lifting').length;
    final cardioCount =
        widget.day.exercises.where((e) => e.type == 'cardio').length;

    // Build the subtitle summary (e.g. "5 EXERCISES // 3 LIFT · 2 CARDIO")
    final parts = <String>[];
    if (liftCount > 0) parts.add('$liftCount LIFT');
    if (cardioCount > 0) parts.add('$cardioCount CARDIO');
    final subtitleRight = parts.join(' · ');
    final subtitle =
        '${widget.day.exercises.length} EXERCISES  //  $subtitleRight';

    return AnimatedBuilder(
      animation: _selectAnim,
      builder: (context, child) {
        // Right inset shrinks to 0 as the card expands on select
        final rightInset = (1 - _selectAnim.value) * 40.0;
        return Container(
          margin: EdgeInsets.only(right: rightInset),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _onTap,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Stack so the accent sweep sits behind content ────────
          Stack(
            children: [
              // Base card surface
              Positioned.fill(child: Container(color: AppColors.card)),

              // Accent sweep — slides in from the left on select (P5 snap)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizeTransition(
                    sizeFactor: _selectAnim,
                    axis: Axis.horizontal,
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ),

              // Header content — drives the Stack's intrinsic height
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left bar: white when active (inverted from normal red)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      width: isActive ? 3 : 0,
                      color: AppColors.white,
                    ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            isActive ? 13 : 16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.day.name,
                                    style: AppTextStyles.headingLg,
                                  ),
                                ),
                                // Chip / phase label
                                if (!isActive)
                                  _ExerciseCountChip(
                                    lifting: liftCount,
                                    cardio: cardioCount,
                                  )
                                else ...[
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 120),
                                    child: Text(
                                      isExpanded ? 'HIDE' : 'SEE DETAILS',
                                      key: ValueKey(isExpanded),
                                      style: AppTextStyles.meta.copyWith(
                                        color: AppColors.white
                                            .withValues(alpha: 0.55),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.25 : 0,
                                    duration:
                                        const Duration(milliseconds: 180),
                                    curve: Curves.easeOutExpo,
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.white
                                          .withValues(alpha: 0.6),
                                      size: 18,
                                    ),
                                  ),
                                ],
                                if (!isActive) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTextStyles.meta.copyWith(
                                color: isActive
                                    ? AppColors.white.withValues(alpha: 0.5)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Exercise detail panel: drops down on phase 2 ─────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1.0,
            child: Container(
              color: AppColors.cardHigh,
              child: widget.day.exercises.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: AppColors.accent.withValues(alpha: 0.4),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          child: _ExerciseList(
                              exercises: widget.day.exercises),
                        ),
                      ],
                    )
                  : const SizedBox(height: 12),
            ),
          ),
        ],
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 32),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _WorkoutDayCard(day: days[i]),
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
  const _StartButton({required this.isActive, required this.onPressed});

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isActive ? AppColors.accent : AppColors.buttonMuted,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor:
                isActive ? AppColors.white : AppColors.textMuted,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: AppTextStyles.buttonLabel,
          ),
          child: const Text('LETS GO !'),
        ),
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
