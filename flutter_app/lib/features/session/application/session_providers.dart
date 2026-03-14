import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

class SessionState {
  const SessionState({this.userId, this.babyId});

  final int? userId;
  final int? babyId;

  bool get isAuthenticated => userId != null;
  bool get hasBaby => babyId != null;

  SessionState copyWith({int? userId, int? babyId}) {
    return SessionState(
      userId: userId ?? this.userId,
      babyId: babyId ?? this.babyId,
    );
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(sessionControllerProvider).valueOrNull?.userId,
);

final currentBabyIdProvider = Provider<int?>(
  (ref) => ref.watch(sessionControllerProvider).valueOrNull?.babyId,
);

class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final db = await AppDatabase.instance.database;
    final userRows = await db.query('users', orderBy: 'id DESC', limit: 1);
    if (userRows.isEmpty) {
      return const SessionState();
    }

    final userId = userRows.first['id'] as int;
    final babyRows = await db.query(
      'babies',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    final babyId = babyRows.isEmpty ? null : babyRows.first['id'] as int;
    return SessionState(userId: userId, babyId: babyId);
  }

  void setAuthenticatedUser(int userId, {int? babyId}) {
    state = AsyncData(SessionState(userId: userId, babyId: babyId));
  }

  Future<void> setCurrentBaby(int babyId) async {
    final current = state.valueOrNull;
    if (current == null || current.userId == null) return;
    state = AsyncData(current.copyWith(babyId: babyId));
  }

  Future<void> signOut() async {
    state = const AsyncData(SessionState());
  }
}
