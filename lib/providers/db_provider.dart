import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/db_service.dart';

/// Overridden in main() with the initialised DatabaseService instance.
final dbProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('dbProvider must be overridden in ProviderScope');
});
