import 'package:chase_run_game/core/routes/app_routes.dart';
import 'package:chase_run_game/features/chase_run_game/presentation/screens/game_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Join Game'),
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.game);
          },
        ),
      ),
    );
  }
}
