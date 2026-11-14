// Copyright 2026 Christian Delicaat. All rights reserved.

/// Formats as "€ 3.896,20": dots between thousands, comma before the cents.
String formatEuro(double value) => formatMoney(value, 'EUR');

/// Formats an amount in [currency] (ISO 4217) as the app writes money, with its symbol: "€ 3.896,20",
/// "$ 3.896,20"; a currency without a known symbol by its code ("CHF 3.896,20").
String formatMoney(double value, String currency) {
  final [whole, cents] = value.toStringAsFixed(2).split('.');
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final symbol = switch (currency) {
    'EUR' => '€',
    'USD' => r'$',
    'GBP' => '£',
    'JPY' => '¥',
    _ => currency,
  };
  return '$symbol $grouped,$cents';
}

/// A condition as the shop names it, with a capital: the shop has e.g. "played".
String formatCondition(String condition) =>
    condition.isEmpty ? condition : condition[0].toUpperCase() + condition.substring(1);
