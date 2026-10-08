// Copyright 2026 Christian Delicaat. All rights reserved.

/// Collection totals for one game, with progress per set.
class CollectionStats {
  final double value; // In euros
  final int collected;
  final int wishlisted;
  final List<SetProgress> sets;

  const CollectionStats({required this.value, required this.collected, required this.wishlisted, required this.sets});
}

class SetProgress {
  final String name;
  final String code;
  final int collected;
  final int total;

  const SetProgress({required this.name, required this.code, required this.collected, required this.total});
}
