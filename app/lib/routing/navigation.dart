// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigation on BuildContext {
  /// Opens the card details page (full screen, over the nav bar).
  void openCard(TcgCard card) => push(Routes.cardFor(card.id));

  /// Opens the cart (full screen, over the nav bar).
  void openCart() => push(Routes.cart);
}
