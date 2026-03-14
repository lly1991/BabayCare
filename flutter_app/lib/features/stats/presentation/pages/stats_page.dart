import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cupertino_date_picker_sheet.dart';
import '../../../../core/utils/local_date.dart';
import '../../../feeding/domain/entities/daily_stat.dart';
import '../../../feeding/presentation/providers/feeding_providers.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  String _tab = 'day';
  DateTime _day = DateTime.now();
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'day', label: Text('日')),
                ButtonSegment(value: 'week', label: Text('周')),
                ButtonSegment(value: 'month', label: Text('月')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: 14),
          if (_tab == 'day') _buildDay(),
          if (_tab == 'week') _buildWeek(),
          if (_tab == 'month') _buildMonth(),
        ],
      ),
    );
  }

  Widget _buildDay() {
    final date = localDateString(_day);
    final async = ref.watch(dailyStatProvider(date));
    return async.when(
      data: (s) => Column(
        children: [
          _DateCard(
            label: '选择日期',
            value: date,
            onTap: _pickDay,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '总记录',
                    value: '${s.totalCount}',
                    unit: '次',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '奶粉奶量',
                    value: '${s.formulaAmount}',
                    unit: 'ml',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    color: const Color(0xFFEBF5FF),
                    emoji: '🍼',
                    title: '奶粉',
                    line1: '次数 ${s.formulaCount}',
                    line2: '奶量 ${s.formulaAmount}ml',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeCard(
                    color: const Color(0xFFFFF0F3),
                    emoji: '🤱',
                    title: '母乳',
                    line1: '次数 ${s.breastCount}',
                    line2: '时长 ${s.breastDuration}分钟',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const _LoadingBlock(),
      error: (e, _) => _ErrorBlock(text: e.toString()),
    );
  }

  Widget _buildWeek() {
    final start = DateTime.now().subtract(const Duration(days: 6));
    final startDate = localDateString(start);
    final async = ref.watch(weeklyStatsProvider(startDate));
    return async.when(
      data: (stats) {
        final sum = _sum(stats);
        final maxCount = stats.isEmpty
            ? 1
            : stats.map((e) => e.totalCount).reduce((a, b) => a > b ? a : b);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: '本周总记录',
                      value: '${sum.totalCount}',
                      unit: '次',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: '本周奶量',
                      value: '${sum.formulaAmount}',
                      unit: 'ml',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _HeaderLabel('每日详情'),
            const SizedBox(height: 8),
            if (stats.isEmpty)
              const _EmptyBlock(text: '本周暂无喂养数据')
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: stats.map((s) {
                    final ratio = maxCount == 0 ? 0.0 : s.totalCount / maxCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 54,
                                child: Text(
                                  s.date.substring(5),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE5E5EA),
                                    color: const Color(0xFFFF9F9F),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${s.totalCount}次',
                                style: const TextStyle(
                                  color: Color(0xFF6C6C70),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
      loading: () => const _LoadingBlock(),
      error: (e, _) => _ErrorBlock(text: e.toString()),
    );
  }

  Widget _buildMonth() {
    final ym = YearMonth(year: _month.year, month: _month.month);
    final async = ref.watch(monthlyStatsProvider(ym));
    return async.when(
      data: (stats) {
        final sum = _sum(stats);
        final breastCount = stats.fold(0, (p, e) => p + e.breastCount);
        final formulaCount = stats.fold(0, (p, e) => p + e.formulaCount);
        final totalType = breastCount + formulaCount;
        final breastPercent =
            totalType == 0 ? 0 : ((breastCount * 100) ~/ totalType);
        return Column(
          children: [
            _DateCard(
              label: '选择月份',
              value:
                  '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
              onTap: _pickMonth,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: '本月总记录',
                      value: '${sum.totalCount}',
                      unit: '次',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: '本月奶量',
                      value: '${sum.formulaAmount}',
                      unit: 'ml',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _HeaderLabel('母乳 / 奶粉 占比'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Row(
                          children: [
                            Expanded(
                              flex: breastCount == 0 ? 1 : breastCount,
                              child: Container(
                                height: 14,
                                color: const Color(0xFFFF8FAB),
                              ),
                            ),
                            Expanded(
                              flex: formulaCount == 0 ? 1 : formulaCount,
                              child: Container(
                                height: 14,
                                color: const Color(0xFF74B9FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '母乳 $breastPercent%（$breastCount 次）',
                              style: const TextStyle(
                                color: Color(0xFF6C6C70),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '奶粉 ${100 - breastPercent}%（$formulaCount 次）',
                              style: const TextStyle(
                                color: Color(0xFF6C6C70),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const _LoadingBlock(),
      error: (e, _) => _ErrorBlock(text: e.toString()),
    );
  }

  _StatSum _sum(List<DailyStat> list) {
    var totalCount = 0;
    var formulaCount = 0;
    var formulaAmount = 0;
    var breastCount = 0;
    var breastDuration = 0;
    for (final s in list) {
      totalCount += s.totalCount;
      formulaCount += s.formulaCount;
      formulaAmount += s.formulaAmount;
      breastCount += s.breastCount;
      breastDuration += s.breastDuration;
    }
    return _StatSum(
      totalCount: totalCount,
      formulaCount: formulaCount,
      formulaAmount: formulaAmount,
      breastCount: breastCount,
      breastDuration: breastDuration,
    );
  }

  Future<void> _pickDay() async {
    final picked = await showCupertinoDatePickerSheet(
      context: context,
      mode: CupertinoDatePickerMode.date,
      minimumDate: DateTime(2010),
      maximumDate: DateTime.now().add(const Duration(days: 30)),
      initialDateTime: _day,
    );
    if (picked == null) return;
    setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickMonth() async {
    final picked = await showCupertinoDatePickerSheet(
      context: context,
      mode: CupertinoDatePickerMode.monthYear,
      minimumDate: DateTime(2010, 1, 1),
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      initialDateTime: _month,
    );
    if (picked == null) return;
    setState(() => _month = DateTime(picked.year, picked.month, 1));
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        value,
                        style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.calendar_month_outlined,
                    color: Color(0xFFFF6B6B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Color(0xFF6C6C70), fontSize: 12)),
            const SizedBox(height: 2),
            Text(unit,
                style: const TextStyle(color: Color(0xFF6C6C70), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.color,
    required this.emoji,
    required this.title,
    required this.line1,
    required this.line2,
  });

  final Color color;
  final String emoji;
  final String title;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(line1,
                style: const TextStyle(color: Color(0xFF6C6C70), fontSize: 13)),
            const SizedBox(height: 6),
            Text(line2,
                style: const TextStyle(color: Color(0xFF6C6C70), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6C6C70),
            fontSize: 13,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6C6C70)),
          ),
        ),
      ),
    );
  }
}

class _StatSum {
  const _StatSum({
    required this.totalCount,
    required this.formulaCount,
    required this.formulaAmount,
    required this.breastCount,
    required this.breastDuration,
  });

  final int totalCount;
  final int formulaCount;
  final int formulaAmount;
  final int breastCount;
  final int breastDuration;
}
