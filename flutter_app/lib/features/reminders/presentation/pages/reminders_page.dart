import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cupertino_date_picker_sheet.dart';
import '../../../session/application/session_providers.dart';
import '../../domain/entities/reminder_item.dart';
import '../providers/reminder_providers.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('提醒设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          FilledButton.icon(
            onPressed: _creating ? null : _showCreateSheet,
            icon: const Icon(Icons.add),
            label: Text(_creating ? '保存中...' : '添加提醒'),
          ),
          const SizedBox(height: 16),
          const Text(
            '提醒列表',
            style: TextStyle(
              color: Color(0xFF6C6C70),
              fontSize: 13,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          remindersAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '暂无提醒',
                      style: TextStyle(color: Color(0xFF6C6C70)),
                    ),
                  ),
                );
              }
              return Column(
                children: list
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReminderTile(
                          item: item,
                          onDelete: () => _delete(item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(e.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSheet() async {
    final draft = await showModalBottomSheet<_ReminderDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReminderEditorSheet(),
    );
    if (draft == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _creating = true);
    try {
      await ref.read(reminderRepositoryProvider).create(
            ReminderItem(
              userId: userId,
              title: draft.title,
              body: draft.body,
              hour: draft.hour,
              minute: draft.minute,
              createdAt: DateTime.now(),
            ),
          );
      ref.invalidate(remindersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提醒已添加')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _delete(ReminderItem item) async {
    if (item.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除提醒'),
        content: const Text('确定删除这条提醒吗？'),
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

    await ref.read(reminderRepositoryProvider).delete(item.id!);
    ref.invalidate(remindersProvider);
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.item, required this.onDelete});

  final ReminderItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF0F3),
          child: Icon(Icons.notifications_none, color: Color(0xFFFF6B6B)),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${item.body}\n⏰ ${item.displayTime}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet();

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late DateTime _time;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: '喂养提醒');
    _bodyController = TextEditingController(text: '记得记录宝宝喂养情况');
    final now = DateTime.now();
    _time = DateTime(now.year, now.month, now.day, 8, 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final timeText =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '添加提醒',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '提醒标题'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: '提醒内容'),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '提醒时间',
                suffixIcon: Icon(Icons.access_time),
              ),
              child: Text(timeText),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text('保存提醒'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final min = DateTime(2010, 1, 1, 0, 0);
    final max = DateTime(2100, 12, 31, 23, 59);
    final picked = await showCupertinoDatePickerSheet(
      context: context,
      mode: CupertinoDatePickerMode.time,
      initialDateTime: _time,
      minimumDate: min,
      maximumDate: max,
    );
    if (picked == null) return;
    setState(() {
      _time = DateTime(
        _time.year,
        _time.month,
        _time.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入提醒标题')),
      );
      return;
    }
    Navigator.of(context).pop(
      _ReminderDraft(
        title: title,
        body: _bodyController.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
      ),
    );
  }
}

class _ReminderDraft {
  const _ReminderDraft({
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  final String title;
  final String body;
  final int hour;
  final int minute;
}
