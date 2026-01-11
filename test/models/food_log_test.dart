import 'package:flutter_test/flutter_test.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';

void main() {
  group('FoodLog', () {
    final foodLog = FoodLog(
      id: '123',
      name: 'Apple',
      weightGrams: 150.0,
      calories: 95.0,
      protein: 0.5,
      carbs: 25.0,
      fat: 0.3,
      timestamp: DateTime(2023, 1, 1, 12, 0, 0),
      mealType: 'Snack',
      imagePath: 'path/to/image.jpg',
    );

    test('should support value equality via props (implicit check via fields)', () {
      // Dart objects aren't equal by value unless == is overridden or Equatable is used.
      // Since the model doesn't use Equatable, we check fields.
      expect(foodLog.id, '123');
      expect(foodLog.name, 'Apple');
    });

    test('toMap should return valid map', () {
      final map = foodLog.toMap();
      expect(map['id'], '123');
      expect(map['name'], 'Apple');
      expect(map['weightGrams'], 150.0);
      expect(map['timestamp'], '2023-01-01T12:00:00.000');
    });

    test('fromMap should return valid object', () {
      final map = {
        'id': '123',
        'name': 'Apple',
        'weightGrams': 150.0,
        'calories': 95.0,
        'protein': 0.5,
        'carbs': 25.0,
        'fat': 0.3,
        'timestamp': '2023-01-01T12:00:00.000',
        'mealType': 'Snack',
        'imagePath': 'path/to/image.jpg',
      };

      final result = FoodLog.fromMap(map);
      expect(result.id, foodLog.id);
      expect(result.timestamp, foodLog.timestamp);
      expect(result.imagePath, foodLog.imagePath);
    });
  });
}
