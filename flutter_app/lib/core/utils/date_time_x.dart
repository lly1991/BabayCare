extension DateTimeX on DateTime {
  String toLocalIsoString() {
    final local = toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final millis = local.millisecond.toString().padLeft(3, '0');
    return '${local.year}-$month-$day'
        'T$hour:$minute:$second.$millis';
  }
}
