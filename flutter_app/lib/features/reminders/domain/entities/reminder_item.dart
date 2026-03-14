class ReminderItem {
  const ReminderItem({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final DateTime createdAt;

  String get displayTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
