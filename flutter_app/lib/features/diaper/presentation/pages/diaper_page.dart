import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/application/session_providers.dart';
import '../../domain/entities/diaper_record.dart';
import '../providers/diaper_providers.dart';

class DiaperPage extends ConsumerWidget {
  const DiaperPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(diaperRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('排泄记录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: ListTile(
              leading: const Text('+',
                  style: TextStyle(fontSize: 26, color: Color(0xFFFF6B6B))),
              title: const Text('添加记录'),
              subtitle: const Text('快速记录尿尿 / 便便'),
              onTap: () => _add(context, ref),
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
                      child: Text('暂无记录'),
                    ),
                  )
                : Column(
                    children: records
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                leading: Text(_icon(r.type),
                                    style: const TextStyle(fontSize: 24)),
                                title: Text(_label(r.type)),
                                subtitle: Text(
                                  '${r.recordTime.month}/${r.recordTime.day} ${r.recordTime.hour.toString().padLeft(2, '0')}:${r.recordTime.minute.toString().padLeft(2, '0')}'
                                  '${r.color == null ? '' : ' · ${r.color}'}'
                                  '${r.texture == null ? '' : ' · ${r.texture}'}',
                                ),
                                trailing: IconButton(
                                  onPressed: () async {
                                    if (r.id == null) return;
                                    await ref
                                        .read(diaperRepositoryProvider)
                                        .delete(r.id!);
                                    ref.invalidate(diaperRecordsProvider);
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Text('💧', style: TextStyle(fontSize: 20)),
              title: const Text('尿尿'),
              onTap: () => Navigator.pop(context, 'pee'),
            ),
            ListTile(
              leading: const Text('💩', style: TextStyle(fontSize: 20)),
              title: const Text('便便'),
              onTap: () => Navigator.pop(context, 'poop'),
            ),
            ListTile(
              leading: const Text('🌟', style: TextStyle(fontSize: 20)),
              title: const Text('都有'),
              onTap: () => Navigator.pop(context, 'both'),
            ),
          ],
        ),
      ),
    );
    if (type == null) return;
    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) return;

    await ref.read(diaperRepositoryProvider).create(
          DiaperRecord(
            babyId: babyId,
            userId: userId,
            recordTime: DateTime.now(),
            type: type,
            createdAt: DateTime.now(),
          ),
        );
    ref.invalidate(diaperRecordsProvider);
  }

  String _label(String t) {
    switch (t) {
      case 'pee':
        return '尿尿';
      case 'poop':
        return '便便';
      case 'both':
        return '都有';
      default:
        return t;
    }
  }

  String _icon(String t) {
    switch (t) {
      case 'pee':
        return '💧';
      case 'poop':
        return '💩';
      case 'both':
        return '🌟';
      default:
        return '❓';
    }
  }
}
