import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cupertino_date_picker_sheet.dart';
import '../../../session/application/session_providers.dart';
import '../../domain/entities/sleep_record.dart';
import '../providers/sleep_providers.dart';

class SleepPage extends ConsumerWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingAsync = ref.watch(ongoingSleepProvider);
    final recordsAsync = ref.watch(sleepRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠记录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          ongoingAsync.when(
            data: (ongoing) {
              if (ongoing == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Text('😴', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text(
                          '宝宝准备睡觉了吗？',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _startSleep(ref),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('开始计时'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _manualAdd(context, ref),
                          child: const Text('手动补录'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Card(
                color: const Color(0xFFFFF0F3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '正在睡眠中',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '开始时间：${_fmt(ongoing.startTime)}',
                        style: const TextStyle(color: Color(0xFF6C6C70)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _wakeUp(ref, ongoing),
                        child: const Text('醒了'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(e.toString()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '历史记录',
            style: TextStyle(
              color: Color(0xFF6C6C70),
              fontSize: 13,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          recordsAsync.when(
            data: (records) => records.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('暂无睡眠记录'),
                    ),
                  )
                : Column(
                    children: records
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _SleepTile(record: r),
                            ))
                        .toList(),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(e.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSleep(WidgetRef ref) async {
    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) return;
    await ref.read(sleepRepositoryProvider).create(
          SleepRecord(
            babyId: babyId,
            userId: userId,
            startTime: DateTime.now(),
            isOngoing: true,
            createdAt: DateTime.now(),
          ),
        );
    ref.invalidate(ongoingSleepProvider);
    ref.invalidate(sleepRecordsProvider);
  }

  Future<void> _wakeUp(WidgetRef ref, SleepRecord ongoing) async {
    if (ongoing.id == null) return;
    await ref
        .read(sleepRepositoryProvider)
        .endSleep(ongoing.id!, DateTime.now());
    ref.invalidate(ongoingSleepProvider);
    ref.invalidate(sleepRecordsProvider);
  }

  Future<void> _manualAdd(BuildContext context, WidgetRef ref) async {
    final start = await _pickDateTime(
      context,
      DateTime.now().subtract(const Duration(hours: 1)),
    );
    if (start == null || !context.mounted) return;
    final end = await _pickDateTime(context, DateTime.now());
    if (end == null || !context.mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间必须晚于开始时间')),
      );
      return;
    }

    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) return;

    await ref.read(sleepRepositoryProvider).create(
          SleepRecord(
            babyId: babyId,
            userId: userId,
            startTime: start,
            endTime: end,
            isOngoing: false,
            createdAt: DateTime.now(),
          ),
        );
    ref.invalidate(ongoingSleepProvider);
    ref.invalidate(sleepRecordsProvider);
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final picked = await showCupertinoDatePickerSheet(
      context: context,
      mode: CupertinoDatePickerMode.dateAndTime,
      minimumDate: DateTime(2010),
      maximumDate: DateTime.now().add(const Duration(days: 1)),
      initialDateTime: initial,
    );
    return picked;
  }

  String _fmt(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SleepTile extends ConsumerWidget {
  const _SleepTile({required this.record});

  final SleepRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = record.endTime?.difference(record.startTime).inMinutes;
    return Card(
      child: ListTile(
        leading: const Text('😴', style: TextStyle(fontSize: 23)),
        title: Text(
          record.isOngoing ? '进行中' : '${duration ?? 0} 分钟',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${record.startTime.month}/${record.startTime.day} ${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')}'
          '${record.endTime == null ? '' : ' - ${record.endTime!.hour.toString().padLeft(2, '0')}:${record.endTime!.minute.toString().padLeft(2, '0')}'}',
        ),
        trailing: record.id == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(sleepRepositoryProvider).delete(record.id!);
                  ref.invalidate(ongoingSleepProvider);
                  ref.invalidate(sleepRecordsProvider);
                },
              ),
      ),
    );
  }
}
