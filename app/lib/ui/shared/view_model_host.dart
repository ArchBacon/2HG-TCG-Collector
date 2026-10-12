// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/widgets.dart';

/// Creates a view model once for the lifetime of the page, and disposes it when the page is
/// removed. Use in a screen's container.
class ViewModelHost<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  const ViewModelHost({super.key, required this.create, required this.builder});

  @override
  State<ViewModelHost<T>> createState() => _ViewModelHostState<T>();
}

class _ViewModelHostState<T extends ChangeNotifier> extends State<ViewModelHost<T>> {
  late final T _viewModel = widget.create(context);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _viewModel);
}

/// Like [ViewModelHost], for a game's page: creates a view model for the selected game, and a new
/// one (disposing the old) when the selected game changes.
class GameViewModelHost<T extends ChangeNotifier> extends StatelessWidget {
  final T Function(BuildContext context, Tcg game) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  const GameViewModelHost({super.key, required this.create, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedGame,
      builder: (context, game, _) => ViewModelHost<T>(
        key: ValueKey(game), // New game, new host: a fresh view model
        create: (context) => create(context, game),
        builder: builder,
      ),
    );
  }
}
