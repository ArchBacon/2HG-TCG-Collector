// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/home/widgets/home_screen_container.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Top go_router entry point.
GoRouter router() => GoRouter(
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreenContainer(),
    ),
  ],
);
