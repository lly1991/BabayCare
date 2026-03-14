import '../entities/reminder_item.dart';

abstract class ReminderRepository {
  Future<List<ReminderItem>> getByUserId(int userId);
  Future<ReminderItem> create(ReminderItem item);
  Future<void> delete(int id);
}
