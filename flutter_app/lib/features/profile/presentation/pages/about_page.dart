import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于软件')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('👶', style: TextStyle(fontSize: 72)),
                  SizedBox(height: 8),
                  Text(
                    'BabyCare',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Version 1.5.0',
                    style: TextStyle(color: Color(0xFF6C6C70)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            '版本迭代记录',
            style: TextStyle(
              color: Color(0xFF6C6C70),
              fontSize: 13,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'v1.5.0\n'
                '• 首页提醒卡片：显示最近提醒。\n'
                '• 关于模块：展示版本与更新记录。\n'
                '• 统计与记录体验优化。\n\n'
                'v1.4.0\n'
                '• 喂养提醒能力升级。\n'
                '• iOS 风格组件样式优化。\n'
                '• 时间校验与滚动适配修复。\n\n'
                'v1.3.0\n'
                '• 母乳时长统计。\n'
                '• 记录项快捷操作。\n'
                '• 自动分侧计时优化。',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  height: 1.6,
                ),
              ),
            ),
          ),
          SizedBox(height: 22),
          Center(
            child: Text(
              'Copyright © 2026 BabyCare Team',
              style: TextStyle(fontSize: 12, color: Color(0xFFAEAEB2)),
            ),
          ),
        ],
      ),
    );
  }
}
