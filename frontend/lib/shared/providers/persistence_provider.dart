import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/persistence_service.dart';

final persistenceProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
