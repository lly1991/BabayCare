import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/application/session_providers.dart';
import '../../domain/entities/growth_record.dart';
import '../providers/growth_providers.dart';

class GrowthPage extends ConsumerWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(growthRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('生长记录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: ListTile(
              leading: const Text('📈', style: TextStyle(fontSize: 24)),
              title: const Text('新增生长记录'),
              subtitle: const Text('记录体重、身高、头围'),
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
                                title: Text(
                                  '${r.weightKg} kg · ${r.heightCm} cm${r.headCircCm == null ? '' : ' · ${r.headCircCm} cm'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${r.measureTime.year}-${r.measureTime.month.toString().padLeft(2, '0')}-${r.measureTime.day.toString().padLeft(2, '0')}',
                                ),
                                trailing: IconButton(
                                  onPressed: () async {
                                    if (r.id == null) return;
                                    await ref
                                        .read(growthRepositoryProvider)
                                        .delete(r.id!);
                                    ref.invalidate(growthRecordsProvider);
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
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final headCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增生长记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '体重 (kg)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '身高 (cm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: headCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '头围 (cm，可选)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final weight = double.tryParse(weightCtrl.text.trim());
    final height = double.tryParse(heightCtrl.text.trim());
    final head = double.tryParse(headCtrl.text.trim());
    if (weight == null || height == null) return;

    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) return;
    await ref.read(growthRepositoryProvider).create(
          GrowthRecord(
            babyId: babyId,
            userId: userId,
            weightKg: weight,
            heightCm: height,
            headCircCm: head,
            measureTime: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
    ref.invalidate(growthRecordsProvider);
  }
}
