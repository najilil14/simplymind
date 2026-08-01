import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SimplyMindApp());
}

class SimplyMindApp extends StatelessWidget {
  const SimplyMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F6DF5);
    return MaterialApp(
      title: 'SimplyMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
