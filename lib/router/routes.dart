import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanner/screens/setup/setup.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  List<NavigatorObserver> observers,
) =>
    GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      navigatorKey: rootNavigatorKey,
      observers: observers,
      routes: [
        GoRoute(
          name: 'Setup',
          path: '/',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SetupScreen(),
        ),
      ],
    );
