import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class BabyCareApp extends ConsumerWidget {
  const BabyCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    const primary = Color(0xFFFF9F9F);
    const primaryDark = Color(0xFFFF6B6B);
    const bg = Color(0xFFF2F2F7);
    const textPrimary = Color(0xFF1C1C1E);
    const textSecondary = Color(0xFF6C6C70);
    return MaterialApp.router(
      title: 'BabyCare',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: const Color(0xFF4ECDC4),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shadowColor: const Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: Color(0xFFAEAEB2)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryDark, width: 1.4),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return const Color(0xFFF2F2F7);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return textPrimary;
              return textSecondary;
            }),
            side: const WidgetStatePropertyAll(
              BorderSide(color: Color(0xFFE5E5EA)),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF2F2F7),
          selectedColor: const Color(0xFFFFE5E5),
          labelStyle: const TextStyle(color: textSecondary),
          secondaryLabelStyle: const TextStyle(color: textPrimary),
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          indicatorColor: const Color(0xFFFFE5E5),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
