// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet with a title and a list of options, the [current] one checked. Returns the picked
/// option, or null when dismissed.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.glass.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    // Size to the content instead of the default cap of 9/16 of the screen; scrolls when longer
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _OptionSheet(title: title, options: options, current: current),
  );
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String current;

  const _OptionSheet({required this.title, required this.options, required this.current});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            for (final option in options)
              ListTile(
                title: Text(option, style: TextStyle(color: glass.textPrimary)),
                trailing: option == current ? Icon(LucideIcons.check, size: 18, color: glass.textPrimary) : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
