import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/workout_picker.dart';
import 'theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'uthao',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WorkoutPickerScreen(),
    );
  }
}
