import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/daily_moment.dart';

class DailyMomentCard extends StatelessWidget {
  const DailyMomentCard({
    super.key,
    required this.moment,
    required this.onTap,
    required this.onDelete,
  });

  final DailyMoment moment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd HH:mm').format(moment.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _Thumb(moment: moment),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.type == DailyMomentType.video ? '视频动态' : '图片动态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.moment});

  final DailyMoment moment;

  @override
  Widget build(BuildContext context) {
    if (moment.type == DailyMomentType.video) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
        ),
      );
    }

    return Image.file(
      File(moment.filePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
