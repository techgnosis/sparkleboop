import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SparkleBoopApp());
}

class SparkleBoopApp extends StatelessWidget {
  const SparkleBoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sparkleboop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
