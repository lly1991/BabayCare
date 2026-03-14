import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/daily_moment.dart';
import '../providers/daily_moments_providers.dart';

class DailyMomentsPage extends ConsumerWidget {
  const DailyMomentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsState = ref.watch(dailyMomentsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('日常动态')),
      body: momentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(dailyMomentsNotifierProvider.notifier).refresh(),
        ),
        data: (moments) {
          if (moments.isEmpty) {
            return _EmptyView(
              onAdd: () => _showCreateSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dailyMomentsNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              children: [
                GridView.builder(
                  itemCount: moments.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final moment = moments[index];
                    return _MomentGridItem(
                      moment: moment,
                      onTap: () => _openPreview(context, moment),
                      onDelete: () => _confirmDelete(context, ref, moment),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar:
          momentsState.valueOrNull == null || momentsState.valueOrNull!.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 70),
                    child: FilledButton.icon(
                      onPressed: () => _showCreateSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('发布动态'),
                    ),
                  ),
                ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('拍照'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _runSafe(context, () async {
                    await ref
                        .read(dailyMomentsNotifierProvider.notifier)
                        .pickImage(ImageSource.camera);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择图片'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _runSafe(context, () async {
                    await ref
                        .read(dailyMomentsNotifierProvider.notifier)
                        .pickImage(ImageSource.gallery);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('录制视频'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _runSafe(context, () async {
                    await ref
                        .read(dailyMomentsNotifierProvider.notifier)
                        .pickVideo(ImageSource.camera);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('从相册选择视频'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _runSafe(context, () async {
                    await ref
                        .read(dailyMomentsNotifierProvider.notifier)
                        .pickVideo(ImageSource.gallery);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runSafe(
      BuildContext context, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DailyMoment moment,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定删除这条动态吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await ref.read(dailyMomentsNotifierProvider.notifier).deleteMoment(moment);
  }

  Future<void> _openPreview(BuildContext context, DailyMoment moment) async {
    if (moment.type == DailyMomentType.image) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Stack(
            children: [
              Center(
                  child: InteractiveViewer(
                      child: Image.file(File(moment.filePath)))),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _VideoPreviewPage(filePath: moment.filePath),
      ),
    );
  }
}

class _MomentGridItem extends StatelessWidget {
  const _MomentGridItem({
    required this.moment,
    required this.onTap,
    required this.onDelete,
  });

  final DailyMoment moment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (moment.type == DailyMomentType.video)
              Container(
                color: const Color(0xFF333333),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              )
            else
              Image.file(
                File(moment.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE5E5EA),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            if (moment.type == DailyMomentType.video)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '视频',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreviewPage extends StatefulWidget {
  const _VideoPreviewPage({required this.filePath});

  final String filePath;

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller?.play();
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('视频预览')),
      body: Center(
        child: controller != null && controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton:
          controller == null || !controller.value.isInitialized
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 52, color: Color(0xFFAEAEB2)),
            const SizedBox(height: 10),
            const Text(
              '还没有日常动态',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '拍照或上传视频，记录宝宝成长瞬间',
              style: TextStyle(color: Color(0xFF6C6C70)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('发布第一条动态'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '加载失败',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
