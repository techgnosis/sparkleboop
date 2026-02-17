import 'dart:async';
import 'package:flutter/material.dart';
import '../game/board.dart';
import '../game/game_state.dart';
import '../widgets/jewel_painter.dart';
import 'main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;

  const GameScreen({super.key, required this.startLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  int? _selectedRow;
  int? _selectedCol;
  bool _processing = false;
  Set<(int, int)> _matchedCells = {};
  bool _showLevelComplete = false;
  bool _showGameOver = false;
  bool _showGameWon = false;

  // Animation
  late AnimationController _matchAnimController;
  late Animation<double> _matchAnim;
  late AnimationController _swapAnimController;
  late Animation<double> _swapAnim;

  // Swap animation state
  int? _swapR1, _swapC1, _swapR2, _swapC2;
  bool _animatingSwap = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(
      board: Board(),
      level: widget.startLevel,
    );
    _saveProgress();

    _matchAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _matchAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _matchAnimController, curve: Curves.easeOut),
    );

    _swapAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _swapAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _swapAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _matchAnimController.dispose();
    _swapAnimController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    await GameState.saveLevel(_gameState.level);
  }

  void _onCellTap(int row, int col) {
    if (_processing) return;

    if (_selectedRow == null) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    } else {
      if (_selectedRow == row && _selectedCol == col) {
        setState(() {
          _selectedRow = null;
          _selectedCol = null;
        });
        return;
      }

      if (_gameState.board.isAdjacent(_selectedRow!, _selectedCol!, row, col)) {
        _trySwap(_selectedRow!, _selectedCol!, row, col);
      } else {
        // Select the new cell instead
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
        });
      }
    }
  }

  Future<void> _trySwap(int r1, int c1, int r2, int c2) async {
    setState(() {
      _processing = true;
      _selectedRow = null;
      _selectedCol = null;
    });

    // Animate swap
    setState(() {
      _swapR1 = r1;
      _swapC1 = c1;
      _swapR2 = r2;
      _swapC2 = c2;
      _animatingSwap = true;
    });
    _swapAnimController.reset();
    await _swapAnimController.forward();
    setState(() => _animatingSwap = false);

    _gameState.board.swap(r1, c1, r2, c2);

    final matches = _gameState.board.findMatches();
    if (matches.isEmpty) {
      // Invalid move - swap back
      setState(() {
        _swapR1 = r2;
        _swapC1 = c2;
        _swapR2 = r1;
        _swapC2 = c1;
        _animatingSwap = true;
      });
      _swapAnimController.reset();
      await _swapAnimController.forward();
      setState(() => _animatingSwap = false);

      _gameState.board.swap(r1, c1, r2, c2);
      setState(() => _processing = false);
      return;
    }

    _gameState.resetCascade();
    await _resolveMatches();

    // Check level complete
    if (_gameState.levelComplete) {
      if (_gameState.level >= GameState.maxLevel) {
        await GameState.clearSave();
        setState(() => _showGameWon = true);
      } else {
        setState(() => _showLevelComplete = true);
      }
      setState(() => _processing = false);
      return;
    }

    // Check for valid moves
    if (!_gameState.board.hasValidMoves()) {
      setState(() => _showGameOver = true);
    }

    setState(() => _processing = false);
  }

  Future<void> _resolveMatches() async {
    while (true) {
      final matches = _gameState.board.findMatches();
      if (matches.isEmpty) break;

      // Show matched cells
      setState(() => _matchedCells = matches);
      _matchAnimController.reset();
      await _matchAnimController.forward();
      setState(() => _matchedCells = {});

      final sizes = _gameState.board.removeMatches(matches);
      _gameState.addMatchScore(sizes);
      _gameState.incrementCascade();

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 100));

      _gameState.board.applyGravity();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 150));

      _gameState.board.fillEmpty();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _nextLevel() {
    _gameState.advanceLevel();
    _gameState.board = Board();
    _saveProgress();
    setState(() => _showLevelComplete = false);
  }

  void _retryLevel() {
    _gameState.score = 0;
    _gameState.board = Board();
    setState(() => _showGameOver = false);
  }

  void _returnToMenu() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
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
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHUD(),
                  Expanded(child: _buildBoard()),
                ],
              ),
              if (_showLevelComplete) _buildLevelCompleteOverlay(),
              if (_showGameOver) _buildGameOverOverlay(),
              if (_showGameWon) _buildGameWonOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    final target = _gameState.targetScore();
    final progress = (_gameState.score / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: _returnToMenu,
              ),
              Text(
                'Level ${_gameState.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_gameState.score} / $target',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.greenAccent : Colors.purpleAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / Board.cols;
              return Stack(
                children: [
                  // Grid background
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Board.cols,
                    ),
                    itemCount: Board.rows * Board.cols,
                    itemBuilder: (context, index) {
                      final row = index ~/ Board.cols;
                      final col = index % Board.cols;
                      return _buildCell(row, col, cellSize);
                    },
                  ),
                  // Swap animation overlay
                  if (_animatingSwap) _buildSwapOverlay(cellSize),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col, double cellSize) {
    final jewel = _gameState.board.get(row, col);
    if (jewel == null) return const SizedBox();

    final isSelected = row == _selectedRow && col == _selectedCol;
    final isMatched = _matchedCells.contains((row, col));

    // Hide cells being swap-animated
    if (_animatingSwap &&
        ((row == _swapR1 && col == _swapC1) ||
            (row == _swapR2 && col == _swapC2))) {
      return const SizedBox();
    }

    Widget cell = GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: CustomPaint(
          painter: JewelPainter(type: jewel, selected: isSelected),
          size: Size(cellSize - 4, cellSize - 4),
        ),
      ),
    );

    if (isMatched) {
      cell = AnimatedBuilder(
        animation: _matchAnim,
        builder: (context, child) {
          return Opacity(
            opacity: _matchAnim.value,
            child: Transform.scale(
              scale: _matchAnim.value,
              child: child,
            ),
          );
        },
        child: cell,
      );
    }

    return cell;
  }

  Widget _buildSwapOverlay(double cellSize) {
    if (_swapR1 == null) return const SizedBox();

    return AnimatedBuilder(
      animation: _swapAnim,
      builder: (context, _) {
        final t = _swapAnim.value;

        final jewel1 = _gameState.board.get(_swapR1!, _swapC1!);
        final jewel2 = _gameState.board.get(_swapR2!, _swapC2!);

        final x1 = _swapC1! * cellSize + ((_swapC2! - _swapC1!) * cellSize * t);
        final y1 = _swapR1! * cellSize + ((_swapR2! - _swapR1!) * cellSize * t);
        final x2 = _swapC2! * cellSize + ((_swapC1! - _swapC2!) * cellSize * t);
        final y2 = _swapR2! * cellSize + ((_swapR1! - _swapR2!) * cellSize * t);

        return Stack(
          children: [
            if (jewel1 != null)
              Positioned(
                left: x1 + 2,
                top: y1 + 2,
                child: CustomPaint(
                  painter: JewelPainter(type: jewel1),
                  size: Size(cellSize - 4, cellSize - 4),
                ),
              ),
            if (jewel2 != null)
              Positioned(
                left: x2 + 2,
                top: y2 + 2,
                child: CustomPaint(
                  painter: JewelPainter(type: jewel2),
                  size: Size(cellSize - 4, cellSize - 4),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay({required List<Widget> children}) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1a0533),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay() {
    return _buildOverlay(
      children: [
        const Text(
          'Level Complete!',
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextLevel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
          ),
          child: const Text('Next Level', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    return _buildOverlay(
      children: [
        const Text(
          'No Moves Left!',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _retryLevel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
          ),
          child: const Text('Retry Level', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _returnToMenu,
          child: const Text('Main Menu', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildGameWonOverlay() {
    return _buildOverlay(
      children: [
        const Text(
          'YOU WIN!',
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Congratulations!\nYou completed all 20 levels!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _returnToMenu,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade700,
          ),
          child: const Text('Main Menu', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
