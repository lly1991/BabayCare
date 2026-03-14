import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cupertino_date_picker_sheet.dart';
import '../../../session/application/session_providers.dart';
import '../../domain/entities/baby.dart';
import '../providers/baby_providers.dart';

class BabySetupPage extends ConsumerStatefulWidget {
  const BabySetupPage({super.key});

  @override
  ConsumerState<BabySetupPage> createState() => _BabySetupPageState();
}

class _BabySetupPageState extends ConsumerState<BabySetupPage> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'unknown';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
          children: [
            const Center(child: Text('👶', style: TextStyle(fontSize: 70))),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '宝宝建档',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '填写宝宝信息，开始记录成长',
                style: TextStyle(color: Color(0xFF6C6C70), fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '宝宝姓名',
                        hintText: '请输入宝宝昵称',
                        prefixIcon:
                            Icon(Icons.face_retouching_natural_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '出生日期',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _birthDate == null
                              ? '请选择出生日期'
                              : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _birthDate == null
                                ? const Color(0xFFAEAEB2)
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderButton(
                            label: '男孩 👦',
                            selected: _gender == 'male',
                            onTap: () => setState(() => _gender = 'male'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GenderButton(
                            label: '女孩 👧',
                            selected: _gender == 'female',
                            onTap: () => setState(() => _gender = 'female'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GenderButton(
                            label: '未知',
                            selected: _gender == 'unknown',
                            onTap: () => setState(() => _gender = 'unknown'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: (_saving || userId == null) ? null : _save,
              child: Text(_saving ? '保存中...' : '开始使用'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showCupertinoDatePickerSheet(
      context: context,
      mode: CupertinoDatePickerMode.date,
      minimumDate: DateTime(2010),
      maximumDate: now,
      initialDateTime: _birthDate ?? now,
    );
    if (picked == null) return;
    setState(
        () => _birthDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || _birthDate == null) {
      _showSnack('请填写完整宝宝信息');
      return;
    }

    setState(() => _saving = true);
    try {
      final created = await ref.read(babyRepositoryProvider).create(
            Baby(
              userId: userId,
              name: name,
              birthDate: _birthDate!,
              gender: _gender,
              createdAt: DateTime.now(),
            ),
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .setCurrentBaby(created.id!);
      ref.invalidate(currentBabyProvider);
      ref.invalidate(babiesProvider);
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

class _GenderButton extends StatelessWidget {
  const _GenderButton({
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
        side: BorderSide(
          color: selected ? const Color(0xFFFF9F9F) : const Color(0xFFE5E5EA),
          width: 1.4,
        ),
        backgroundColor: selected ? const Color(0xFFFFF0F3) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
      ),
    );
  }
}
