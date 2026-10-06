// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:flutter/material.dart';

import '../../tmp/shared/theme/app_colors.dart';

/// Stand-in for tabs that haven't been built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(title)),
      body: const Center(
        child: Text('Coming soon', style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
