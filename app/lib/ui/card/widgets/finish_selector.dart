// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';

/// Glass segmented control for the card's finish (e.g. Normal / Holofoil / Reverse Holo).
class FinishSelector extends StatelessWidget {
  final List<CardFinish> options;
  final String selected; // A finish id
  final Color accent;
  final ValueChanged<String> onChanged;

  const FinishSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glass.edge),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                selected: option.id == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: option.id == selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: option.id == selected ? accent.withValues(alpha: 0.5) : Colors.transparent),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: option.id == selected ? accent : glass.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
