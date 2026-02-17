import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _savedLevel = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSave();
  }

  Future<void> _loadSave() async {
    final level = await GameState.loadSavedLevel();
    setState(() {
      _savedLevel = level;
      _loading = false;
    });
  }

  void _startNewGame() async {
    await GameState.clearSave();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen(startLevel: 1)),
    );
  }

  void _continueGame() {
    if (_savedLevel <= 0) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(startLevel: _savedLevel)),
    );
  }

  void _exitGame() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a0533), Color(0xFF0d001a)],
          ),
        ),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SPARKLEBOOP',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              Colors.pinkAccent,
                              Colors.purpleAccent,
                              Colors.blueAccent,
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 80),
                    _MenuButton(
                      label: 'New Game',
                      onPressed: _startNewGame,
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'Continue',
                      onPressed: _savedLevel > 0 ? _continueGame : null,
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'Exit',
                      onPressed: _exitGame,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _MenuButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? Colors.deepPurple.shade700
              : Colors.grey.shade800,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: enabled
                  ? Colors.purpleAccent.shade100
                  : Colors.grey.shade700,
              width: 1.5,
            ),
          ),
          elevation: enabled ? 8 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, letterSpacing: 2),
        ),
      ),
    );
  }
}
