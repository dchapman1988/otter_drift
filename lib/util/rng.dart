import 'dart:math';

class SeededRandom {
  final Random _random;
  final int _seed;

  SeededRandom({int? seed})
    : _seed = seed ?? DateTime.now().millisecondsSinceEpoch,
      _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  int get seed => _seed;

  // Generate a random double between 0.0 and 1.0
  double nextDouble() => _random.nextDouble();

  // Generate a random int between 0 (inclusive) and max (exclusive)
  int nextInt(int max) => _random.nextInt(max);

  // Generate a random int between min (inclusive) and max (exclusive)
  int range(int min, int max) => min + _random.nextInt(max - min);

  // Generate a random double between min (inclusive) and max (exclusive)
  double rangeDouble(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  // Generate a random boolean
  bool nextBool() => _random.nextBool();

  // Poisson distribution for spawn timing
  // Returns time until next spawn event in seconds
  double nextPoissonSpawnTime(double meanInterval) {
    // Inverse transform sampling for exponential distribution
    // -ln(1 - U) / λ where U is uniform random and λ = 1/meanInterval
    final u = _random.nextDouble();
    if (u == 0.0) return meanInterval; // Avoid log(0)
    return -log(1.0 - u) * meanInterval;
  }
}
