# Sparkleboop

A match-3 jewel puzzle game built with Flutter, targeting Android.

## Gameplay

Swap adjacent jewels on an 8x8 board to create matches of 3 or more in a row or column. Matched jewels disappear, the board collapses under gravity, new jewels fill in from the top, and cascading matches multiply your score. Reach the target score to advance through 20 levels of increasing difficulty.

## Project Structure

```
lib/
  main.dart                      # App entry point, Material theme (dark purple)
  game/
    jewel.dart                   # JewelType enum: diamond, ruby, emerald, sapphire, topaz, amethyst, pearl
    board.dart                   # 8x8 grid logic: match detection, gravity, swap, fill, valid-move check
    game_state.dart              # Score, level progression, cascade multiplier, SharedPreferences persistence
  screens/
    main_menu_screen.dart        # Title screen with New Game / Continue / Exit
    game_screen.dart             # Game board, HUD, swap/match/cascade animations, overlay dialogs
  widgets/
    jewel_painter.dart           # CustomPainter that draws each jewel type as a distinct shape with gradients

scripts/
    generate_icon.py             # Generates launcher icons from pure Python (no image libraries)
    flutter-start.sh             # Starts `flutter run --machine` with a named pipe for programmatic control
    flutter-reload.sh            # Sends hot reload or full restart via the machine protocol pipe
    flutter-stop.sh              # Gracefully stops the running flutter session and cleans up
```

### Game Logic (`lib/game/`)

**`jewel.dart`** defines 7 jewel types as an enum with a `random()` factory.

**`board.dart`** manages the 8x8 grid. On construction it fills the board randomly and then iteratively re-rolls cells until no initial matches exist. Core operations:
- `findMatches()` scans rows and columns for runs of 3+ identical jewels, returning matched positions as a set.
- `removeMatches()` groups matched cells into connected components (BFS), removes them, and returns group sizes for scoring.
- `applyGravity()` compacts each column downward to fill gaps.
- `fillEmpty()` populates remaining empty cells with random jewels.
- `hasValidMoves()` brute-forces every adjacent swap to check if any move produces a match, triggering game-over when none exist.

**`game_state.dart`** tracks score, level (1-20), and a cascade multiplier that increments with each consecutive match chain. Scoring: 50 pts for 3-matches, 100 for 4, 200 for 5+, all multiplied by the cascade depth. Level targets scale as `1000 + (level - 1) * 500`. Progress is persisted to `SharedPreferences`.

### Rendering (`lib/widgets/`)

**`jewel_painter.dart`** is a `CustomPainter` that draws each jewel type with a unique shape and gradient:

| Jewel    | Shape    | Colors              |
|----------|----------|---------------------|
| Diamond  | Rhombus  | White to light blue |
| Ruby     | Circle   | Red radial gradient |
| Emerald  | Octagon  | Green diagonal      |
| Sapphire | Triangle | Blue vertical       |
| Topaz    | Square   | Yellow to orange    |
| Amethyst | Hexagon  | Purple radial       |
| Pearl    | Star     | White to pink       |

Each jewel gets a small white highlight circle for a sparkle effect. Selected jewels show a white ring outline.

### Screens (`lib/screens/`)

**`main_menu_screen.dart`** presents the title with a pink-purple-blue gradient shader and three buttons. Continue is disabled when no saved progress exists.

**`game_screen.dart`** is the main gameplay screen. It uses two `AnimationController`s:
- A swap animation (200ms ease-in-out) that slides two jewels to each other's positions.
- A match animation (300ms ease-out) that fades and shrinks matched jewels before removal.

The resolve loop runs after every valid swap: find matches, animate removal, apply gravity, fill empties, repeat until no cascading matches remain. Overlay dialogs handle level completion, game over (no valid moves), and the final win screen.

### Dev Scripts (`scripts/`)

Shell scripts for headless Flutter development via the `flutter run --machine` JSON protocol:
- **`flutter-start.sh`** creates a named pipe at `/tmp/flutter_in`, launches `flutter run --machine` reading from it, and waits up to 5 minutes for the app to report its `appId`.
- **`flutter-reload.sh`** writes a JSON-RPC `app.restart` command to the pipe (hot reload by default, `--full` for full restart) and polls the log for the result.
- **`flutter-stop.sh`** sends `app.stop` via the pipe, kills the process, and cleans up temp files.

## Launcher Icon Generation

The launcher icon is a **pink faceted diamond on a deep purple background**, generated entirely in Python without any image libraries. The script `scripts/generate_icon.py` builds PNG files from scratch using only `struct` and `zlib` from the standard library.

**How it works:**

1. **Raw PNG construction** -- The `create_png()` function manually assembles a valid PNG byte stream: the 8-byte magic header, an `IHDR` chunk (packed with `struct`), pixel data compressed with `zlib` into an `IDAT` chunk, and a terminating `IEND` chunk. CRC checksums are computed with `zlib.crc32`.

2. **Pixel-by-pixel rendering** -- For each pixel in the output image:
   - A rounded-rectangle boundary test clips the icon shape (with configurable corner radius).
   - A vertical gradient fills the background from deep purple to near-black.
   - A radial glow is blended into the center.
   - A diamond (rhombus) shape is tested with `point_in_diamond()` using Manhattan-distance normalization (`|dx/w| + |dy/h| <= 1`).
   - Inside the diamond, a three-band vertical gradient (highlight pink, magenta, dark magenta) simulates facets.
   - Facet edge lines are drawn by testing narrow bands along diagonal and horizontal axes relative to the diamond center.
   - A bright highlight dot sits at the upper-right of the gem.

3. **Sparkle accents** -- Six small cross-shaped sparkles are placed around the diamond at hardcoded normalized positions, blended with distance falloff.

4. **Multi-density output** -- The `main()` function generates icons at all 5 Android density buckets (mdpi 48px through xxxhdpi 192px), writing directly to `android/app/src/main/res/mipmap-*/ic_launcher.png`.

## Building

```bash
flutter pub get
flutter build apk
```

Or use the dev scripts for iterative development:

```bash
./scripts/flutter-start.sh    # launch on device/emulator
./scripts/flutter-reload.sh   # hot reload after edits
./scripts/flutter-stop.sh     # stop when done
```
