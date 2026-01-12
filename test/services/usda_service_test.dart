import 'package:flutter_test/flutter_test.dart';
import 'package:ai_calorie_tracker/services/usda_service.dart';

void main() {
  group('UsdaService - Unit Conversions', () {
    test('convertToGrams should handle grams correctly', () {
      expect(UsdaService.convertToGrams(100, 'g', 'any food'), 100);
      expect(UsdaService.convertToGrams(100, 'gram', 'any food'), 100);
      expect(UsdaService.convertToGrams(100, 'grams', 'any food'), 100);
    });

    test('convertToGrams should convert ounces', () {
      expect(UsdaService.convertToGrams(1, 'oz', 'chicken'), closeTo(28.35, 0.5));
      expect(UsdaService.convertToGrams(4, 'ounce', 'beef'), closeTo(113.4, 2));
    });

    test('convertToGrams should convert cups', () {
      expect(UsdaService.convertToGrams(1, 'cup', 'water'), 240);
      expect(UsdaService.convertToGrams(2, 'cups', 'milk'), 480);
    });

    test('convertToGrams should convert tablespoons', () {
      expect(UsdaService.convertToGrams(1, 'tbsp', 'oil'), 15);
      // For butter, specific conversion of 14g per tbsp is used
      expect(UsdaService.convertToGrams(2, 'tablespoon', 'butter'), 28);
    });

    test('convertToGrams should convert teaspoons', () {
      expect(UsdaService.convertToGrams(1, 'tsp', 'sugar'), 5);
      expect(UsdaService.convertToGrams(3, 'teaspoon', 'salt'), 15);
    });

    test('convertToGrams should handle specific food conversions for eggs', () {
      expect(UsdaService.convertToGrams(1, 'large', 'egg'), 50);
      expect(UsdaService.convertToGrams(2, 'large', 'scrambled eggs'), 100);
      expect(UsdaService.convertToGrams(1, 'medium', 'egg'), 44);
      expect(UsdaService.convertToGrams(1, 'small', 'egg'), 38);
    });

    test('convertToGrams should handle bread slices', () {
      expect(UsdaService.convertToGrams(1, 'slice', 'bread'), 30);
      expect(UsdaService.convertToGrams(2, 'slices', 'whole wheat toast'), 60);
    });

    test('convertToGrams should handle butter measurements', () {
      expect(UsdaService.convertToGrams(1, 'tbsp', 'butter'), 14);
      expect(UsdaService.convertToGrams(1, 'tsp', 'butter'), 5);
      expect(UsdaService.convertToGrams(2, 'pat', 'butter'), 10);
    });

    test('convertToGrams should handle liquid measurements', () {
      expect(UsdaService.convertToGrams(1, 'cup', 'milk'), 240);
      expect(UsdaService.convertToGrams(1, 'glass', 'orange juice'), 240);
    });

    test('convertToGrams should handle chicken portions', () {
      expect(UsdaService.convertToGrams(1, 'breast', 'chicken'), 170);
      expect(UsdaService.convertToGrams(1, 'thigh', 'chicken'), 85);
      // Generic oz conversion for chicken (not specific oz override)
      expect(UsdaService.convertToGrams(6, 'oz', 'chicken breast'), closeTo(170.1, 2.5));
    });

    test('convertToGrams should handle unknown units with default', () {
      expect(UsdaService.convertToGrams(1, 'serving', 'any food'), 100);
      expect(UsdaService.convertToGrams(1, 'piece', 'fruit'), 100);
      expect(UsdaService.convertToGrams(2, 'portion', 'meal'), 200);
    });

    test('convertToGrams should handle kilograms', () {
      expect(UsdaService.convertToGrams(1, 'kg', 'vegetables'), 1000);
      expect(UsdaService.convertToGrams(0.5, 'kilogram', 'meat'), 500);
    });

    test('convertToGrams should handle pounds', () {
      expect(UsdaService.convertToGrams(1, 'lb', 'beef'), closeTo(453.6, 0.1));
      expect(UsdaService.convertToGrams(0.5, 'pound', 'chicken'), closeTo(226.8, 0.1));
    });

    test('convertToGrams should handle milliliters', () {
      expect(UsdaService.convertToGrams(100, 'ml', 'water'), 100);
      expect(UsdaService.convertToGrams(250, 'milliliter', 'milk'), 250);
    });

    test('convertToGrams should handle liters', () {
      expect(UsdaService.convertToGrams(1, 'l', 'water'), 1000);
      expect(UsdaService.convertToGrams(0.5, 'liter', 'juice'), 500);
    });

    test('convertToGrams should handle rice/pasta cups (cooked)', () {
      expect(UsdaService.convertToGrams(1, 'cup', 'cooked rice'), 195);
      expect(UsdaService.convertToGrams(1, 'cup', 'pasta'), 195);
    });
  });

  group('UsdaService - Cache', () {
    test('clearCache should not throw', () {
      final service = UsdaService();
      expect(() => service.clearCache(), returnsNormally);
    });
  });
}
