import 'package:shared_preferences/shared_preferences.dart';
import 'board.dart';

class GameState {
  Board board;
  int score;
  int level;
  int cascadeMultiplier;

  static const int maxLevel = 20;

  GameState({
    required this.board,
    this.score = 0,
    this.level = 1,
    this.cascadeMultiplier = 1,
  });

  int targetScore() {
    return 1000 + (level - 1) * 500;
  }

  bool get levelComplete => score >= targetScore();
  bool get gameWon => level > maxLevel;

  int scoreForMatchSize(int size) {
    if (size <= 3) return 50;
    if (size == 4) return 100;
    return 200; // 5+
  }

  int addMatchScore(List<int> matchSizes) {
    int points = 0;
    for (final size in matchSizes) {
      points += scoreForMatchSize(size) * cascadeMultiplier;
    }
    score += points;
    return points;
  }

  void resetCascade() {
    cascadeMultiplier = 1;
  }

  void incrementCascade() {
    cascadeMultiplier++;
  }

  void advanceLevel() {
    level++;
    score = 0;
  }

  // Persistence
  static const _levelKey = 'sparkleboop_level';

  static Future<int> loadSavedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 0; // 0 means no save
  }

  static Future<void> saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, level);
  }

  static Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_levelKey);
  }
}
