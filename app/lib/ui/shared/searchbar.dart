// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../tmp/shared/theme/app_colors.dart';

// Rounded search field with a search icon on the left.
// Named AppSearchBar because Material already has a SearchBar widget.
class AppSearchBar extends StatefulWidget {
  final String? hint; // Placeholder shown while the field is empty
  final String? value; // Text the field starts with; updates the field when it changes
  final ValueChanged<String>? onChanged; // Called on every keystroke

  const AppSearchBar({
    super.key,
    this.hint,
    this.value,
    this.onChanged,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only overwrite the text when the parent passes a new value, so typing isn't interrupted.
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), // Same corner radius as the stat tiles
      borderSide: const BorderSide(color: AppColors.insetBorder),
    );

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search, // Shows a search key on the keyboard
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      cursorColor: AppColors.brandGreen,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.inset,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12), // Field height; horizontal comes from the icon
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.brandGreen)),
      ),
    );
  }
}
