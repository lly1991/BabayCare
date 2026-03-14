import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/reminder_repository_impl.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepositoryImpl(AppDatabase.instance),
);

final remindersProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.read(reminderRepositoryProvider).getByUserId(userId);
});
