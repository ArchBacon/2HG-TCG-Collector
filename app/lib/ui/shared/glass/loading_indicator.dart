// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';

/// Small spinner, in [color] (the secondary text color by default).
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: size / 10, color: color ?? context.glass.textSecondary),
    );
  }
}

/// A page's content while it loads: a spinner, centered, with room around it.
class LoadingSection extends StatelessWidget {
  final Color? color;

  const LoadingSection({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(child: LoadingIndicator(color: color)),
    );
  }
}
