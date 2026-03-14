import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../session/application/session_providers.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyId = ref.watch(currentBabyIdProvider);
    return Scaffold(
      body: navigationShell,
      floatingActionButton: babyId == null
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/feeding/add'),
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: '日常动态',
          ),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined), label: '统计'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
