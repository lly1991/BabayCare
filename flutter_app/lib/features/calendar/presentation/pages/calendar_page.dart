import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/local_date.dart';
import '../../../feeding/domain/entities/feeding_record.dart';
import '../../../feeding/presentation/providers/feeding_providers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _selected;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = localDateString(_selected);
    final recordsAsync = ref.watch(feedingsByDateProvider(dateStr));
    final ym = YearMonth(year: _focusedMonth.year, month: _focusedMonth.month);
    final monthStatsAsync = ref.watch(monthlyStatsProvider(ym));

    return Scaffold(
      appBar: AppBar(title: const Text('喂养日历')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goPrevMonth,
                      icon: const Icon(Icons.chevron_left, size: 28),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_focusedMonth.year}年${_focusedMonth.month}月',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _goNextMonth,
                      icon: const Icon(Icons.chevron_right, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: monthStatsAsync.when(
                  data: (monthStats) {
                    final recordDates = monthStats.map((e) => e.date).toSet();
                    return Column(
                      children: [
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          child: Row(
                            children: [
                              _WeekDayCell('日'),
                              _WeekDayCell('一'),
                              _WeekDayCell('二'),
                              _WeekDayCell('三'),
                              _WeekDayCell('四'),
                              _WeekDayCell('五'),
                              _WeekDayCell('六'),
                            ],
                          ),
                        ),
                        ..._buildWeekRows(recordDates),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.toString()),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '当日记录：$dateStr',
              style: const TextStyle(
                color: Color(0xFF6C6C70),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: recordsAsync.when(
              data: (records) => records.isEmpty
                  ? const _EmptyCard(text: '当天没有记录')
                  : Column(
                      children: records
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RecordCard(
                                  record: e,
                                  onDelete: e.id == null
                                      ? null
                                      : () => _deleteFeeding(e),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(text: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekRows(Set<String> recordDates) {
    final cells = _buildMonthCells(recordDates);
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(children: cells.sublist(i, i + 7)),
        ),
      );
    }
    return rows;
  }

  List<Widget> _buildMonthCells(Set<String> recordDates) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDayWeek = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final cells = <Widget>[];
    for (var i = 0; i < firstDayWeek; i++) {
      cells.add(const _DayCell.empty());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateStr = localDateString(date);
      final isSelected = dateStr == localDateString(_selected);
      final isToday = dateStr == localDateString();
      final hasRecord = recordDates.contains(dateStr);
      cells.add(
        _DayCell(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          hasRecord: hasRecord,
          onTap: () => setState(() => _selected = date),
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(const _DayCell.empty());
    }
    return cells;
  }

  void _goPrevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selected = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  void _goNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selected = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  Future<void> _deleteFeeding(FeedingRecord record) async {
    if (record.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条喂养记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(feedingRepositoryProvider).deleteRecord(record.id!);
    final selectedDate = localDateString(_selected);
    final recordDate = localDateString(record.feedTime);
    final ym = YearMonth(year: _focusedMonth.year, month: _focusedMonth.month);
    ref.invalidate(feedingsByDateProvider(selectedDate));
    ref.invalidate(feedingsByDateProvider(recordDate));
    ref.invalidate(dailyStatProvider(recordDate));
    ref.invalidate(monthlyStatsProvider(ym));
    ref.invalidate(recentFeedingsProvider);
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6C6C70),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    this.day,
    this.isSelected = false,
    this.isToday = false,
    this.hasRecord = false,
    this.onTap,
  });

  const _DayCell.empty()
      : day = null,
        isSelected = false,
        isToday = false,
        hasRecord = false,
        onTap = null;

  final int? day;
  final bool isSelected;
  final bool isToday;
  final bool hasRecord;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const Expanded(child: SizedBox(height: 42));
    }
    return Expanded(
      child: SizedBox(
        height: 42,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFFF9F9F) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF1C1C1E),
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (hasRecord)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white70
                            : const Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onDelete,
  });

  final FeedingRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        '${record.feedTime.hour.toString().padLeft(2, '0')}:${record.feedTime.minute.toString().padLeft(2, '0')}';
    final text = record.feedType == FeedType.formula
        ? '奶粉 ${record.amountMl ?? 0} ml'
        : '母乳 ${record.durationMin ?? 0} 分钟';
    return Card(
      child: ListTile(
        leading: Text(
          record.feedType == FeedType.breast ? '🤱' : '🍼',
          style: const TextStyle(fontSize: 22),
        ),
        title: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: record.notes == null
            ? null
            : Text(
                record.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: const TextStyle(color: Color(0xFF6C6C70)),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFF6C6C70)),
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF6C6C70)),
        ),
      ),
    );
  }
}
