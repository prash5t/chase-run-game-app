import 'package:chase_run_game/core/routes/app_routes.dart';
import 'package:chase_run_game/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:chase_run_game/features/chase_run_game/presentation/screens/game_screen.dart';
import 'package:flutter/material.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  Object? argument = settings.arguments;
  switch (settings.name) {
    case AppRoutes.dashboard:
      return MaterialPageRoute(builder: (context) => DashboardScreen());
    case AppRoutes.game:
      return MaterialPageRoute(builder: (context) => GameScreen());
    default:
      return MaterialPageRoute(builder: (context) => DashboardScreen());
    // return MaterialPageRoute(builder: (context) => const DashboardScreen());
  }
}
