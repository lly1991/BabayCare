import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cupertino_date_picker_sheet.dart';
import '../../../../core/utils/local_date.dart';
import '../../../session/application/session_providers.dart';
import '../../domain/entities/feeding_record.dart';
import '../providers/feeding_providers.dart';

class AddFeedingPage extends ConsumerStatefulWidget {
  const AddFeedingPage({super.key});

  @override
  ConsumerState<AddFeedingPage> createState() => _AddFeedingPageState();
}

class _AddFeedingPageState extends ConsumerState<AddFeedingPage> {
  FeedType _type = FeedType.breast;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(minutes: 1));
  String _breastSide = 'left';
  final _amountController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加喂养记录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const _SectionTitle('喂养类型'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      selected: _type == FeedType.breast,
                      emoji: '🤱',
                      title: '母乳',
                      onTap: () => setState(() => _type = FeedType.breast),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeButton(
                      selected: _type == FeedType.formula,
                      emoji: '🍼',
                      title: '奶粉',
                      onTap: () => setState(() => _type = FeedType.formula),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle('喂养时间'),
          const SizedBox(height: 8),
          _DateTimeCard(
            label: '开始时间',
            value: _start,
            onChanged: (d) => setState(() {
              _start = d;
              if (!_end.isAfter(_start)) {
                _end = _start.add(const Duration(minutes: 1));
              }
            }),
          ),
          if (_type == FeedType.breast) ...[
            const SizedBox(height: 8),
            _DateTimeCard(
              label: '结束时间',
              value: _end,
              onChanged: (d) => setState(() => _end = d),
            ),
            const SizedBox(height: 14),
            const _SectionTitle('母乳类型'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SideButton(
                        label: '左侧',
                        selected: _breastSide == 'left',
                        onTap: () => setState(() => _breastSide = 'left'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SideButton(
                        label: '双侧',
                        selected: _breastSide == 'both',
                        onTap: () => setState(() => _breastSide = 'both'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SideButton(
                        label: '右侧',
                        selected: _breastSide == 'right',
                        onTap: () => setState(() => _breastSide = 'right'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前时长：${_end.difference(_start).inMinutes.clamp(0, 24 * 60)} 分钟',
              style: const TextStyle(color: Color(0xFF6C6C70), fontSize: 13),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const _SectionTitle('奶粉信息'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '奶量 (ml)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: '奶粉品牌（可选）',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const _SectionTitle('备注'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存记录'),
          ),
          const SizedBox(height: 10),
          Text(
            '记录日期：${localDateString(_start)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C6C70),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) return;

    if (_type == FeedType.breast && !_end.isAfter(_start)) {
      _showSnack('结束时间必须晚于开始时间');
      return;
    }

    final amount = int.tryParse(_amountController.text.trim());
    if (_type == FeedType.formula && (amount == null || amount <= 0)) {
      _showSnack('请输入正确奶量');
      return;
    }

    final duration = _type == FeedType.breast
        ? _end.difference(_start).inMinutes.clamp(0, 24 * 60)
        : null;

    int? leftDuration;
    int? rightDuration;
    if (_type == FeedType.breast && duration != null) {
      if (_breastSide == 'left') {
        leftDuration = duration;
        rightDuration = 0;
      } else if (_breastSide == 'right') {
        leftDuration = 0;
        rightDuration = duration;
      } else {
        leftDuration = duration ~/ 2;
        rightDuration = duration - leftDuration;
      }
    }

    setState(() => _saving = true);
    try {
      await ref.read(feedingRepositoryProvider).addRecord(
            FeedingRecord(
              babyId: babyId,
              userId: userId,
              feedTime: _start,
              feedType: _type,
              amountMl: _type == FeedType.formula ? amount : null,
              durationMin: duration,
              leftDuration: leftDuration,
              rightDuration: rightDuration,
              endTime: _type == FeedType.breast ? _end : null,
              brand: _type == FeedType.formula
                  ? _brandController.text.trim().isEmpty
                      ? null
                      : _brandController.text.trim()
                  : null,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
      ref.invalidate(recentFeedingsProvider);
      ref.invalidate(feedingsByDateProvider(localDateString(_start)));
      ref.invalidate(dailyStatProvider(localDateString(_start)));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6C6C70),
        fontSize: 13,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.selected,
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String emoji;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFFFFF0F3) : const Color(0xFFF2F2F7),
        side: BorderSide(
          color: selected ? const Color(0xFFFF8FAB) : const Color(0xFFE5E5EA),
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Color(0xFF1C1C1E))),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFFFFF0F3) : const Color(0xFFF2F2F7),
        side: BorderSide(
          color: selected ? const Color(0xFFFF8FAB) : const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF1C1C1E))),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  const _DateTimeCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          final picked = await showCupertinoDatePickerSheet(
            context: context,
            mode: CupertinoDatePickerMode.dateAndTime,
            minimumDate: DateTime(2010),
            maximumDate: DateTime.now().add(const Duration(days: 30)),
            initialDateTime: value,
          );
          if (picked == null) return;
          onChanged(picked);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6C6C70),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
                      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.access_time, color: Color(0xFFFF6B6B)),
            ],
          ),
        ),
      ),
    );
  }
}
