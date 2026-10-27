// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/card_image_store.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Storage: the card images kept on the device (CardImageStore), how much room they take, and
/// clearing them. They download again when next shown.
class StorageSettings extends StatefulWidget {
  final Color accent;

  const StorageSettings({super.key, required this.accent});

  @override
  State<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends State<StorageSettings> {
  ({int bytes, int count})? _usage; // Null while counting

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    final usage = await CardImageStore.usage();
    if (mounted) setState(() => _usage = usage);
  }

  static String _size(int bytes) => switch (bytes) {
    < 1024 * 1024 => '${(bytes / 1024).toStringAsFixed(0)} KB',
    < 1024 * 1024 * 1024 => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB',
    _ => '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
  };

  Future<void> _clear() async {
    final glass = context.glass;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glass.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear card images?',
          style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'The images of your collection and wishlist cards are removed from this device. They download again when you next see them.',
          style: TextStyle(color: glass.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: glass.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _usage = null);
    await CardImageStore.clear();
    PaintingBinding.instance.imageCache.clear(); // And the ones decoded in memory
    await _measure();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card images cleared')));
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;

    return SettingsGroup(
      title: 'Storage',
      rows: [
        SettingRow(
          icon: LucideIcons.images,
          title: 'Card images',
          subtitle: usage == null
              ? 'Counting…'
              : usage.count == 0
              ? 'None kept on this device'
              : '${usage.count} images of your collection and wishlist',
          value: usage == null || usage.count == 0 ? null : _size(usage.bytes),
          onTap: usage == null || usage.count == 0 ? null : _clear,
        ),
      ],
    );
  }
}
