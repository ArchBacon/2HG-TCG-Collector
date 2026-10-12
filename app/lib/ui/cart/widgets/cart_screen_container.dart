// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/cart/view_models/cart_viewmodel.dart';
import 'package:app/ui/cart/widgets/cart_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [CartViewModel] for the cart page.
class CartScreenContainer extends StatelessWidget {
  const CartScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => CartViewModel(cartRepository: context.read()),
      builder: (context, viewModel) => CartScreen(viewModel: viewModel),
    );
  }
}
