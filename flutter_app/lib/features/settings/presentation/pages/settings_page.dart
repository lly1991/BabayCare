import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/backup_service.dart';
import '../../../baby/presentation/providers/baby_providers.dart';
import '../../../feeding/presentation/providers/feeding_providers.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../../session/application/session_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;
  bool _importing = false;

  BackupService get _backupService => BackupService(AppDatabase.instance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const _SectionTitle('数据管理'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('导出数据备份'),
                  subtitle: const Text('导出本地数据为 JSON 文件'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _exporting ? null : _exportBackup,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('导入数据备份'),
                  subtitle: const Text('从备份文件恢复数据'),
                  trailing: _importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _importing ? null : _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle('更多功能'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                '数据仅保存在本地设备，请定期导出备份。',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C6C70),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    try {
      final file = await _backupService.exportToJsonFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'BabyCare 数据备份',
        text: 'BabyCare 本地数据备份文件',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份已导出：${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入确认'),
        content: const Text('导入将覆盖当前本地数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (result == null) return;

      final file = result.files.single;
      String content;
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        final bytes = file.bytes;
        if (bytes == null) {
          throw const FormatException('无法读取备份文件');
        }
        content = utf8.decode(bytes);
      }

      await _backupService.importFromJsonString(content);
      _invalidateData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份导入成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _invalidateData() {
    ref.invalidate(sessionControllerProvider);
    ref.invalidate(currentBabyProvider);
    ref.invalidate(babiesProvider);
    ref.invalidate(recentFeedingsProvider);
    ref.invalidate(remindersProvider);
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
