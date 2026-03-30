import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/db_service.dart';
import '../models/session.dart';
import '../providers/db_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State notifier
// ─────────────────────────────────────────────────────────────────────────────

class ActiveSessionNotifier extends AutoDisposeAsyncNotifier<Session?> {
  @override
  Future<Session?> build() =>
      ref.read(dbProvider).getInProgressSession();

  DatabaseService get _db => ref.read(dbProvider);

  Future<void> logLiftingSet(
      int exIdx, int setIdx, double weight, int reps) async {
    final session = state.valueOrNull;
    if (session == null) return;
    final set = session.exercises[exIdx].liftingSets[setIdx];
    set.weight = weight;
    set.reps = reps;
    set.completedAtMs = DateTime.now().millisecondsSinceEpoch;
    await _db.updateSession(session);
    state = AsyncData(session);
  }

  Future<void> addLiftingSet(int exIdx) async {
    final session = state.valueOrNull;
    if (session == null) return;
    final sets = session.exercises[exIdx].liftingSets;
    final last = sets.isNotEmpty ? sets.last : null;
    sets.add(LiftingSet(
      reps: last?.reps ?? 0,
      weight: last?.weight ?? 0,
      unit: last?.unit ?? 'kg',
    ));
    await _db.updateSession(session);
    state = AsyncData(session);
  }

  Future<void> logCardioSet(int exIdx, int durationSeconds) async {
    final session = state.valueOrNull;
    if (session == null) return;
    final exercise = session.exercises[exIdx];
    if (exercise.cardioSets.isEmpty) {
      exercise.cardioSets.add(CardioSet(durationSeconds: durationSeconds));
    } else {
      exercise.cardioSets.first.durationSeconds = durationSeconds;
    }
    exercise.cardioSets.first.completedAtMs =
        DateTime.now().millisecondsSinceEpoch;
    await _db.updateSession(session);
    state = AsyncData(session);
  }

  Future<void> finishSession() async {
    final session = state.valueOrNull;
    if (session == null) return;
    session.completedAt = DateTime.now();
    await _db.updateSession(session);
    state = const AsyncData(null);
  }
}

final activeSessionProvider =
    AsyncNotifierProvider.autoDispose<ActiveSessionNotifier, Session?>(
  ActiveSessionNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  int _exIdx = 0;
  LiftingSet? _prevBest;
  bool _bestLoaded = false;

  void _loadPrevBest(String exerciseName) {
    _bestLoaded = true;
    ref
        .read(dbProvider)
        .getPreviousBestLift(exerciseName)
        .then((best) {
      if (mounted) setState(() => _prevBest = best);
    });
  }

  void _goNext(int total) {
    if (_exIdx >= total - 1) return;
    setState(() {
      _exIdx++;
      _prevBest = null;
      _bestLoaded = false;
    });
  }

  void _showFinishDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('FINISH SESSION', style: AppTextStyles.headingMd),
        content: Text('Save and end this workout?', style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeSessionProvider.notifier).finishSession();
            },
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeSessionProvider, (_, next) {
      if (next.hasValue && next.valueOrNull == null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    final sessionAsync = ref.watch(activeSessionProvider);

    return Scaffold(
      body: sessionAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (session) {
          if (session == null || session.exercises.isEmpty) {
            return const _NoSessionView();
          }

          if (!_bestLoaded) {
            final ex = session.exercises[_exIdx];
            if (ex.type == 'lifting') _loadPrevBest(ex.name);
          }

          final exercise = session.exercises[_exIdx];
          final isLast = _exIdx == session.exercises.length - 1;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SessionBar(
                  dayName: session.workoutDayName ?? 'WORKOUT',
                  onFinish: () => _showFinishDialog(context),
                ),
                _ExerciseHeader(
                  exercise: exercise,
                  index: _exIdx,
                  total: session.exercises.length,
                  prevBest: _prevBest,
                ),
                const _SetColumnHeader(),
                Expanded(
                  child: _SetsBody(
                    key: ValueKey('exercise_$_exIdx'),
                    exercise: exercise,
                    exerciseIndex: _exIdx,
                    prevBest: _prevBest,
                  ),
                ),
                _Footer(
                  isLast: isLast,
                  nextExerciseName:
                      isLast ? null : session.exercises[_exIdx + 1].name,
                  onAddSet: () => ref
                      .read(activeSessionProvider.notifier)
                      .addLiftingSet(_exIdx),
                  onNext: () => _goNext(session.exercises.length),
                  onFinish: () => _showFinishDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session bar
// ─────────────────────────────────────────────────────────────────────────────

class _SessionBar extends StatelessWidget {
  const _SessionBar({required this.dayName, required this.onFinish});

  final String dayName;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('←  ', style: AppTextStyles.body),
          ),
          Expanded(child: Text(dayName, style: AppTextStyles.appTitle)),
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'FINISH',
              style: AppTextStyles.buttonLabel.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise header
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.exercise,
    required this.index,
    required this.total,
    required this.prevBest,
  });

  final SessionExercise exercise;
  final int index;
  final int total;
  final LiftingSet? prevBest;

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_pad(index + 1)} / ${_pad(total)}',
            style: AppTextStyles.screenLabel,
          ),
          const SizedBox(height: 6),
          Text(exercise.name, style: AppTextStyles.headingLg),
          const SizedBox(height: 8),
          _PrevBestRow(prevBest: prevBest, isLifting: exercise.type == 'lifting'),
        ],
      ),
    );
  }
}

class _PrevBestRow extends StatelessWidget {
  const _PrevBestRow({required this.prevBest, required this.isLifting});

  final LiftingSet? prevBest;
  final bool isLifting;

  static String _fmt(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  @override
  Widget build(BuildContext context) {
    if (!isLifting) return const SizedBox.shrink();
    return Row(
      children: [
        Text('PREV BEST  ', style: AppTextStyles.meta),
        prevBest == null
            ? Text('—', style: AppTextStyles.meta)
            : Text(
                '${_fmt(prevBest!.weight)} ${prevBest!.unit.toUpperCase()}  ×  ${prevBest!.reps}',
                style: AppTextStyles.bodyMuted,
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Column header
// ─────────────────────────────────────────────────────────────────────────────

class _SetColumnHeader extends StatelessWidget {
  const _SetColumnHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('SET', style: AppTextStyles.meta)),
          const SizedBox(width: 12),
          Expanded(child: Text('WEIGHT', style: AppTextStyles.meta)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text('REPS', style: AppTextStyles.meta,
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sets body
// ─────────────────────────────────────────────────────────────────────────────

class _SetsBody extends ConsumerWidget {
  const _SetsBody({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.prevBest,
  });

  final SessionExercise exercise;
  final int exerciseIndex;
  final LiftingSet? prevBest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (exercise.type == 'cardio') {
      return _CardioBody(exercise: exercise, exerciseIndex: exerciseIndex);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: exercise.liftingSets.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: AppColors.ghostBorder),
      itemBuilder: (context, i) => _LiftingSetRow(
        key: ValueKey('set_${exerciseIndex}_$i'),
        setNumber: i + 1,
        set: exercise.liftingSets[i],
        prefillWeight: prevBest?.weight,
        onLog: (weight, reps) => ref
            .read(activeSessionProvider.notifier)
            .logLiftingSet(exerciseIndex, i, weight, reps),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lifting set row — owns its TextEditingControllers
// ─────────────────────────────────────────────────────────────────────────────

class _LiftingSetRow extends StatefulWidget {
  const _LiftingSetRow({
    super.key,
    required this.setNumber,
    required this.set,
    required this.prefillWeight,
    required this.onLog,
  });

  final int setNumber;
  final LiftingSet set;
  final double? prefillWeight;
  final void Function(double weight, int reps) onLog;

  @override
  State<_LiftingSetRow> createState() => _LiftingSetRowState();
}

class _LiftingSetRowState extends State<_LiftingSetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  static String _fmt(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  @override
  void initState() {
    super.initState();
    final w = widget.set.weight > 0
        ? _fmt(widget.set.weight)
        : (widget.prefillWeight != null && widget.prefillWeight! > 0)
            ? _fmt(widget.prefillWeight!)
            : '';
    _weightCtrl = TextEditingController(text: w);
    _repsCtrl = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_LiftingSetRow old) {
    super.didUpdateWidget(old);
    // Backfill when prevBest arrives after row is first built
    if (old.prefillWeight == null &&
        widget.prefillWeight != null &&
        widget.set.weight == 0 &&
        _weightCtrl.text.isEmpty) {
      _weightCtrl.text = _fmt(widget.prefillWeight!);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _handleLog() {
    final weight = double.tryParse(_weightCtrl.text.trim());
    final reps = int.tryParse(_repsCtrl.text.trim());
    if (weight == null || reps == null || reps <= 0) return;
    widget.onLog(weight, reps);
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.set.completedAtMs != null;

    return Container(
      color: done ? AppColors.surface : AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              widget.setNumber.toString(),
              style: AppTextStyles.setNumber.copyWith(
                color: done ? AppColors.textMuted : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumberField(
              controller: _weightCtrl,
              hint: '0',
              suffix: ' ${widget.set.unit}',
              enabled: !done,
              decimal: true,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: _NumberField(
              controller: _repsCtrl,
              hint: '0',
              enabled: !done,
              decimal: false,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: done
                ? Center(
                    child: Text('✓',
                        style: AppTextStyles.headingMd
                            .copyWith(color: AppColors.accent)),
                  )
                : TextButton(
                    onPressed: _handleLog,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: AppTextStyles.buttonLabel,
                    ),
                    child: const Text('LOG'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cardio body
// ─────────────────────────────────────────────────────────────────────────────

class _CardioBody extends ConsumerStatefulWidget {
  const _CardioBody({required this.exercise, required this.exerciseIndex});

  final SessionExercise exercise;
  final int exerciseIndex;

  @override
  ConsumerState<_CardioBody> createState() => _CardioBodyState();
}

class _CardioBodyState extends ConsumerState<_CardioBody> {
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    final secs = widget.exercise.cardioSets.isNotEmpty
        ? widget.exercise.cardioSets.first.durationSeconds
        : 0;
    _durationCtrl =
        TextEditingController(text: secs > 0 ? (secs ~/ 60).toString() : '');
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  void _handleLog() {
    final mins = int.tryParse(_durationCtrl.text.trim());
    if (mins == null || mins <= 0) return;
    ref
        .read(activeSessionProvider.notifier)
        .logCardioSet(widget.exerciseIndex, mins * 60);
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.exercise.cardioSets.isNotEmpty &&
        widget.exercise.cardioSets.first.completedAtMs != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DURATION', style: AppTextStyles.screenLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: _NumberField(
                  controller: _durationCtrl,
                  hint: '0',
                  suffix: ' min',
                  enabled: !done,
                  decimal: false,
                ),
              ),
              const SizedBox(width: 16),
              done
                  ? Text('✓  DONE',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.accent))
                  : TextButton(
                      onPressed: _handleLog,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        textStyle: AppTextStyles.buttonLabel,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        side: const BorderSide(
                            color: AppColors.accent, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: const Text('LOG'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number input — terminal style (bottom border only)
// ─────────────────────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    this.suffix,
    this.enabled = true,
    required this.decimal,
  });

  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final bool enabled;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        color: enabled ? AppColors.white : AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMuted,
        suffixText: suffix,
        suffixStyle: AppTextStyles.meta,
        filled: true,
        fillColor: enabled ? AppColors.cardHigh : AppColors.surface,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ghostBorder, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isLast,
    required this.nextExerciseName,
    required this.onAddSet,
    required this.onNext,
    required this.onFinish,
  });

  final bool isLast;
  final String? nextExerciseName;
  final VoidCallback onAddSet;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: onAddSet,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTextStyles.meta,
                ),
                child: const Text('+ ADD SET'),
              ),
              const Spacer(),
              if (!isLast && nextExerciseName != null)
                Flexible(
                  child: Text(
                    'NEXT: $nextExerciseName',
                    style: AppTextStyles.meta,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: isLast ? onFinish : onNext,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: AppTextStyles.buttonLabel,
            ),
            child: Text(isLast ? 'FINISH WORKOUT' : 'NEXT EXERCISE'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility state widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 2),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, style: AppTextStyles.bodyMuted),
        ),
      );
}

class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NO ACTIVE SESSION', style: AppTextStyles.headingLg),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('BACK TO PICKER'),
            ),
          ],
        ),
      );
}
