// Copyright 2026 Christian Delicaat. All rights reserved.

/// Formats as "€ 3.896,20": dots between thousands, comma before the cents.
String formatEuro(double value) {
  final [whole, cents] = value.toStringAsFixed(2).split('.');
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '€ $grouped,$cents';
}
