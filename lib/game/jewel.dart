import 'dart:math';

enum JewelType {
  diamond,
  ruby,
  emerald,
  sapphire,
  topaz,
  amethyst,
  pearl;

  static JewelType random(Random rng) {
    return JewelType.values[rng.nextInt(JewelType.values.length)];
  }
}
