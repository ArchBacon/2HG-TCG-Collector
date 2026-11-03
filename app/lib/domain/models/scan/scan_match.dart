// Copyright 2026 Christian Delicaat. All rights reserved.

/// The card a scan was recognized as, in the catalog.
class ScanMatch {
  final String cardId;
  final String name;

  const ScanMatch({required this.cardId, required this.name});
}

/// Why a scan didn't give a card.
enum ScanFailure {
  notRecognized, // Magic Sorter saw no card it knows
  notInCatalog, // It recognized one, but it isn't in the catalog
  unsupported, // The game can't be scanned
  unavailable, // No server, Magic Sorter down or not set up, or no connection
}

class ScanException implements Exception {
  final ScanFailure failure;

  /// What it was recognized as, for [ScanFailure.notInCatalog]: e.g. `Vodalian Arcanist (DOM #73)`.
  final String? recognized;

  const ScanException(this.failure, {this.recognized});

  @override
  String toString() => 'ScanException(${failure.name}${recognized != null ? ', $recognized' : ''})';
}
