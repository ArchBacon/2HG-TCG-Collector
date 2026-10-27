// Copyright 2026 Christian Delicaat. All rights reserved.

/// Formats as "€ 3.896,20": dots between thousands, comma before the cents.
String formatEuro(double value) {
  final [whole, cents] = value.toStringAsFixed(2).split('.');
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '€ $grouped,$cents';
}

/// A condition as the shop names it, with a capital: the shop has e.g. "played".
String formatCondition(String condition) =>
    condition.isEmpty ? condition : condition[0].toUpperCase() + condition.substring(1);
