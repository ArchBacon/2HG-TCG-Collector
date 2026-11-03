// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/colors.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/themes/theme.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/brand_icon.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown in place of the app when the API can't be reached on startup: a message to try again
/// later, and a button that tries right away. [onRetry] starts the app when it connects, and shows
/// this screen again when it doesn't.
class OfflineApp extends StatelessWidget {
  final Future<void> Function() onRetry;

  const OfflineApp({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeModeSetting,
      builder: (context, themeMode, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: _OfflineScreen(onRetry: onRetry),
      ),
    );
  }
}

class _OfflineScreen extends StatefulWidget {
  final Future<void> Function() onRetry;

  const _OfflineScreen({required this.onRetry});

  @override
  State<_OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<_OfflineScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await widget.onRetry();
    // Still offline: this screen stays (runApp kept its state), ready for another try
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandIcon(size: 64),
                const SizedBox(height: 28),
                Icon(LucideIcons.wifiOff, size: 28, color: glass.textSecondary),
                const SizedBox(height: 14),
                Text(
                  'Couldn\'t connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: glass.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'We can\'t reach the server right now. Check your internet connection, or try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: glass.textSecondary, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _retrying ? null : _retry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: const Color(0xFF0A0E12), // Dark text on the brand green, in both themes
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: _retrying
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Try again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
