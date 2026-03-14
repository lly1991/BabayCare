import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../baby/presentation/providers/baby_providers.dart';
import '../../../session/application/session_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babiesAsync = ref.watch(babiesProvider);
    final currentBaby = ref.watch(currentBabyProvider).valueOrNull;
    final currentBabyId = ref.watch(currentBabyIdProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (currentBaby != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      currentBaby.gender == 'female' ? '👧' : '👦',
                      style: const TextStyle(fontSize: 54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBaby.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentBaby.birthDate.year}-${currentBaby.birthDate.month.toString().padLeft(2, '0')}-${currentBaby.birthDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C6C70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: Color(0xFFFF6B6B)),
                title: const Text('还没有宝宝档案'),
                trailing: TextButton(
                  onPressed: () => context.push('/baby/setup'),
                  child: const Text('去建档'),
                ),
              ),
            ),
          const SizedBox(height: 14),
          const _SectionTitle('账号信息'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE5E5),
                child: Icon(Icons.person, color: Color(0xFFFF6B6B)),
              ),
              title: Text('用户 ID: ${userId ?? '-'}'),
              subtitle: const Text('本地账号'),
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle('宝宝切换'),
          const SizedBox(height: 8),
          babiesAsync.when(
            data: (babies) {
              if (babies.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('暂无宝宝数据'),
                  ),
                );
              }
              return Column(
                children: babies
                    .map(
                      (baby) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            title: Text(baby.name),
                            subtitle: Text(
                              '出生 ${baby.birthDate.year}-${baby.birthDate.month.toString().padLeft(2, '0')}-${baby.birthDate.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: currentBabyId == baby.id
                                ? const Text(
                                    '当前',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B6B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () async {
                                      if (baby.id == null) return;
                                      await ref
                                          .read(sessionControllerProvider
                                              .notifier)
                                          .setCurrentBaby(baby.id!);
                                      ref.invalidate(currentBabyProvider);
                                    },
                                    child: const Text('切换'),
                                  ),
                          ),
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
                padding: const EdgeInsets.all(14),
                child: Text(e.toString()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => context.push('/baby/setup'),
            child: const Text('新增宝宝'),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('功能设置'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('育儿知识'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/knowledge'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('提醒设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于软件'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).signOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
              side: const BorderSide(color: Color(0xFFFFDAD6)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
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
        fontSize: 13,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6C6C70),
      ),
    );
  }
}
