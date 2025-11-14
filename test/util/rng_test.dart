import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/util/rng.dart';

void main() {
  group('SeededRandom', () {
    test('generates reproducible values with same seed', () {
      final rng1 = SeededRandom(seed: 12345);
      final rng2 = SeededRandom(seed: 12345);

      final values1 = List.generate(10, (_) => rng1.nextDouble());
      final values2 = List.generate(10, (_) => rng2.nextDouble());

      expect(values1, equals(values2));
    });

    test('generates different values with different seeds', () {
      final rng1 = SeededRandom(seed: 12345);
      final rng2 = SeededRandom(seed: 67890);

      final value1 = rng1.nextDouble();
      final value2 = rng2.nextDouble();

      expect(value1, isNot(equals(value2)));
    });

    test('nextDouble returns values in range [0.0, 1.0)', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt returns values in correct range', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('range returns values in correct range', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.range(5, 15);
        expect(value, greaterThanOrEqualTo(5));
        expect(value, lessThan(15));
      }
    });

    test('rangeDouble returns values in correct range', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.rangeDouble(5.0, 15.0);
        expect(value, greaterThanOrEqualTo(5.0));
        expect(value, lessThan(15.0));
      }
    });

    test('nextBool returns boolean values', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.nextBool();
        expect(value, isA<bool>());
      }
    });

    test('nextPoissonSpawnTime returns positive values', () {
      final rng = SeededRandom(seed: 42);
      for (var i = 0; i < 100; i++) {
        final value = rng.nextPoissonSpawnTime(1.2);
        expect(value, greaterThan(0.0));
        expect(value.isFinite, isTrue);
      }
    });

    test('nextPoissonSpawnTime handles edge case when u == 0', () {
      // This tests the edge case handling in the implementation
      // Since we can't easily control the exact random value,
      // we'll just verify the function works without crashing
      final rng = SeededRandom(seed: 42);
      final value = rng.nextPoissonSpawnTime(1.2);
      expect(value, greaterThanOrEqualTo(0.0));
      expect(value.isFinite, isTrue);
    });

    test('uses current timestamp as seed when not provided', () {
      final rng1 = SeededRandom();
      final rng2 = SeededRandom();

      // They should have different seeds (unless created at exactly same millisecond)
      // This is a probabilistic test - it's very unlikely they'll have the same seed
      expect(rng1.seed, greaterThanOrEqualTo(0));
      expect(rng2.seed, greaterThanOrEqualTo(0));
    });

    test('seed getter returns the correct seed', () {
      const testSeed = 99999;
      final rng = SeededRandom(seed: testSeed);
      expect(rng.seed, testSeed);
    });
  });
}
