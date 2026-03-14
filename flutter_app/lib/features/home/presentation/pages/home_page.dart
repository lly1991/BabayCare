import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/local_date.dart';
import '../../../baby/presentation/providers/baby_providers.dart';
import '../../../feeding/domain/entities/feeding_record.dart';
import '../../../feeding/presentation/providers/feeding_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = localDateString();
    final babyAsync = ref.watch(currentBabyProvider);
    final dayStatAsync = ref.watch(dailyStatProvider(today));
    final recentAsync = ref.watch(recentFeedingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentBabyProvider);
          ref.invalidate(dailyStatProvider(today));
          ref.invalidate(recentFeedingsProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            babyAsync.when(
              data: (baby) => _HeroHeader(
                name: baby?.name,
                gender: baby?.gender,
                birthDate: baby?.birthDate,
              ),
              loading: () => const _HeroHeader(name: null),
              error: (_, __) => const _HeroHeader(name: null),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: dayStatAsync.when(
                data: (s) => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: '今日次数',
                        value: '${s.totalCount}',
                        unit: '次',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: '奶粉',
                        value: '${s.formulaCount}',
                        unit: '${s.formulaAmount}ml',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: '母乳',
                        value: '${s.breastCount}',
                        unit: '${s.breastDuration}分钟',
                      ),
                    ),
                  ],
                ),
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(text: e.toString()),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('快捷入口'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ShortcutCard(
                    emoji: '😴',
                    title: '睡眠记录',
                    subtitle: '开始计时、手动补录与历史查看',
                    onTap: () => context.push('/sleep'),
                  ),
                  const SizedBox(height: 8),
                  _ShortcutCard(
                    emoji: '💩',
                    title: '排泄记录',
                    subtitle: '快速记录尿布更换情况',
                    onTap: () => context.push('/diaper'),
                  ),
                  const SizedBox(height: 8),
                  _ShortcutCard(
                    emoji: '📈',
                    title: '生长记录',
                    subtitle: '记录身高体重并管理历史',
                    onTap: () => context.push('/growth'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('最近喂养记录'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: recentAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const _EmptyCard(text: '还没有喂养记录，点击底部 + 号开始添加');
                  }
                  return Column(
                    children: records
                        .take(20)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FeedingTile(
                                record: e,
                                onDelete: e.id == null
                                    ? null
                                    : () => _deleteFeeding(context, ref, e),
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(text: e.toString()),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFeeding(
    BuildContext context,
    WidgetRef ref,
    FeedingRecord record,
  ) async {
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
    ref.invalidate(recentFeedingsProvider);
    ref.invalidate(dailyStatProvider(localDateString()));
    ref.invalidate(dailyStatProvider(localDateString(record.feedTime)));
    ref.invalidate(feedingsByDateProvider(localDateString(record.feedTime)));
    ref.invalidate(weeklyStatsProvider);
    ref.invalidate(monthlyStatsProvider);
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.name,
    this.gender,
    this.birthDate,
  });

  final String? name;
  final String? gender;
  final DateTime? birthDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFE5E5), Color(0xFFF2F2F7)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            gender == 'female' ? '👧' : '👦',
            style: const TextStyle(fontSize: 52),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: name == null
                ? const Text(
                    'BabyCare',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ageText(birthDate),
                        style: const TextStyle(
                          color: Color(0xFF6C6C70),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _ageText(DateTime? birth) {
    if (birth == null) return '记录宝宝成长每一刻';
    final now = DateTime.now();
    final days =
        now.difference(DateTime(birth.year, birth.month, birth.day)).inDays;
    if (days < 30) return '🎂 $days 天';
    final months = days ~/ 30;
    if (months < 12) return '🎂 $months 月 ${days % 30} 天';
    return '🎂 ${months ~/ 12} 岁 ${months % 12} 月';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C6C70)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C6C70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6C6C70),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedingTile extends StatelessWidget {
  const _FeedingTile({
    required this.record,
    required this.onDelete,
  });

  final FeedingRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        '${record.feedTime.hour.toString().padLeft(2, '0')}:${record.feedTime.minute.toString().padLeft(2, '0')}';
    final title = record.feedType == FeedType.breast
        ? '母乳 · ${record.durationMin ?? 0} 分钟'
        : '奶粉${record.brand == null ? '' : ' · ${record.brand}'} · ${record.amountMl ?? 0} ml';
    return Card(
      child: ListTile(
        leading: Text(
          record.feedType == FeedType.breast ? '🤱' : '🍼',
          style: const TextStyle(fontSize: 22),
        ),
        title: Text(
          title,
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
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF6C6C70)),
              onPressed: onDelete,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6C6C70),
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
