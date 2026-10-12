// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/card/view_models/card_viewmodel.dart';
import 'package:app/ui/card/widgets/card_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [CardViewModel] for the card with [cardId].
class CardScreenContainer extends StatelessWidget {
  final String cardId;

  const CardScreenContainer({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => CardViewModel(
        cardId: cardId,
        catalogRepository: context.read(),
        marketRepository: context.read(),
        cartRepository: context.read(),
      ),
      builder: (context, viewModel) => CardScreen(viewModel: viewModel),
    );
  }
}
