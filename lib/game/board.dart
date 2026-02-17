import 'dart:math';
import 'jewel.dart';

class Board {
  static const int rows = 8;
  static const int cols = 8;

  final List<List<JewelType?>> grid;
  final Random _rng;

  Board({Random? rng})
      : _rng = rng ?? Random(),
        grid = List.generate(rows, (_) => List<JewelType?>.filled(cols, null)) {
    _fillBoard();
    _removeInitialMatches();
  }

  Board._fromGrid(this.grid, this._rng);

  Board copy() {
    final newGrid = List.generate(
      rows,
      (r) => List<JewelType?>.from(grid[r]),
    );
    return Board._fromGrid(newGrid, _rng);
  }

  void _fillBoard() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c] = JewelType.random(_rng);
      }
    }
  }

  void _removeInitialMatches() {
    // Keep regenerating until no matches exist
    bool hasMatches = true;
    int attempts = 0;
    while (hasMatches && attempts < 100) {
      final matches = findMatches();
      if (matches.isEmpty) {
        hasMatches = false;
      } else {
        for (final pos in matches) {
          grid[pos.$1][pos.$2] = JewelType.random(_rng);
        }
      }
      attempts++;
    }
  }

  JewelType? get(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return null;
    return grid[row][col];
  }

  void set(int row, int col, JewelType? type) {
    grid[row][col] = type;
  }

  bool isAdjacent(int r1, int c1, int r2, int c2) {
    return (r1 == r2 && (c1 - c2).abs() == 1) ||
        (c1 == c2 && (r1 - r2).abs() == 1);
  }

  void swap(int r1, int c1, int r2, int c2) {
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;
  }

  /// Find all matches of 3+ in a row/column.
  /// Returns set of (row, col) positions that are part of matches.
  Set<(int, int)> findMatches() {
    final matched = <(int, int)>{};

    // Horizontal matches
    for (int r = 0; r < rows; r++) {
      int c = 0;
      while (c < cols) {
        final type = grid[r][c];
        if (type == null) {
          c++;
          continue;
        }
        int end = c + 1;
        while (end < cols && grid[r][end] == type) {
          end++;
        }
        if (end - c >= 3) {
          for (int i = c; i < end; i++) {
            matched.add((r, i));
          }
        }
        c = end;
      }
    }

    // Vertical matches
    for (int c = 0; c < cols; c++) {
      int r = 0;
      while (r < rows) {
        final type = grid[r][c];
        if (type == null) {
          r++;
          continue;
        }
        int end = r + 1;
        while (end < rows && grid[end][c] == type) {
          end++;
        }
        if (end - r >= 3) {
          for (int i = r; i < end; i++) {
            matched.add((i, c));
          }
        }
        r = end;
      }
    }

    return matched;
  }

  /// Remove matched jewels, return count of individual match groups and their sizes.
  List<int> removeMatches(Set<(int, int)> matches) {
    // Group matches to determine scoring
    // For simplicity, count connected components by type
    final sizes = <int>[];

    // Find connected groups
    final remaining = Set<(int, int)>.from(matches);
    while (remaining.isNotEmpty) {
      final start = remaining.first;
      final group = <(int, int)>{};
      final queue = [start];
      final type = grid[start.$1][start.$2];

      while (queue.isNotEmpty) {
        final pos = queue.removeLast();
        if (!remaining.contains(pos)) continue;
        if (grid[pos.$1][pos.$2] != type) continue;
        remaining.remove(pos);
        group.add(pos);
        // Check neighbors
        for (final d in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final next = (pos.$1 + d.$1, pos.$2 + d.$2);
          if (remaining.contains(next)) {
            queue.add(next);
          }
        }
      }
      sizes.add(group.length);
    }

    // Remove
    for (final pos in matches) {
      grid[pos.$1][pos.$2] = null;
    }

    return sizes;
  }

  /// Drop jewels down to fill gaps. Returns true if anything moved.
  bool applyGravity() {
    bool moved = false;
    for (int c = 0; c < cols; c++) {
      int writeRow = rows - 1;
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] != null) {
          if (writeRow != r) {
            grid[writeRow][c] = grid[r][c];
            grid[r][c] = null;
            moved = true;
          }
          writeRow--;
        }
      }
    }
    return moved;
  }

  /// Fill empty cells at top with random jewels.
  void fillEmpty() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == null) {
          grid[r][c] = JewelType.random(_rng);
        }
      }
    }
  }

  /// Check if any valid moves exist.
  bool hasValidMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Try swap right
        if (c + 1 < cols) {
          swap(r, c, r, c + 1);
          if (findMatches().isNotEmpty) {
            swap(r, c, r, c + 1);
            return true;
          }
          swap(r, c, r, c + 1);
        }
        // Try swap down
        if (r + 1 < rows) {
          swap(r, c, r + 1, c);
          if (findMatches().isNotEmpty) {
            swap(r, c, r + 1, c);
            return true;
          }
          swap(r, c, r + 1, c);
        }
      }
    }
    return false;
  }
}
