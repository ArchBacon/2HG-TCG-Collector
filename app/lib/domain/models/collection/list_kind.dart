// Copyright 2026 Christian Delicaat. All rights reserved.

/// The kinds of lists a user keeps cards in. They work the same: several of each, made, renamed and
/// deleted by the user, holding copies of cards of every game. [name] is the API's list type, and
/// how the screens call one in a sentence ("New wishlist").
enum ListKind {
  collection('Collection'),
  wishlist('Wishlist');

  const ListKind(this.label);

  /// As a title, e.g. "Wishlist".
  final String label;
}
