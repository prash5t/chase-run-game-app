import 'package:chase_run_game/core/routes/route_generator.dart';
import 'package:flutter/material.dart';

class LearnArApp extends StatelessWidget {
  const LearnArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
