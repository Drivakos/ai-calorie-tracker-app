import 'package:flutter_test/flutter_test.dart';
import 'package:ai_calorie_tracker/models/parsed_food.dart';

void main() {
  group('ParsedFoodItem', () {
    test('fromAiParsing should create item from AI response', () {
      final json = {
        'name': 'Scrambled Eggs',
        'quantity': 2,
        'unit': 'large',
        'estimated_grams': 100.0,
        'estimated_calories': 180,
        'estimated_protein_g': 12,
        'estimated_carbs_g': 2,
        'estimated_fat_g': 14,
        'confidence': 0.9,
      };

      final item = ParsedFoodItem.fromAiParsing(json, 'test-id');

      expect(item.id, 'test-id');
      expect(item.aiGuessedName, 'Scrambled Eggs');
      expect(item.estimatedQuantity, 2);
      expect(item.estimatedUnit, 'large');
      expect(item.estimatedGrams, 100.0);
      expect(item.calories, 180);
      expect(item.protein, 12);
      expect(item.carbs, 2);
      expect(item.fat, 14);
      expect(item.aiConfidence, 0.9);
      expect(item.isFromUsda, false);
      expect(item.isVerified, false);
    });

    test('fromAiParsing should handle missing fields with defaults', () {
      final json = {'name': 'Unknown Food'};

      final item = ParsedFoodItem.fromAiParsing(json, 'test-id');

      expect(item.aiGuessedName, 'Unknown Food');
      expect(item.estimatedQuantity, 1.0);
      expect(item.estimatedUnit, 'serving');
      expect(item.estimatedGrams, 100.0);
      expect(item.calories, 0);
    });

    test('displayName should prefer USDA name when available', () {
      final item = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Egg',
        estimatedQuantity: 1,
        estimatedUnit: 'large',
        estimatedGrams: 50,
        calories: 70,
        protein: 6,
        carbs: 0,
        fat: 5,
        usdaFoodName: 'Egg, whole, cooked, scrambled',
      );

      expect(item.displayName, 'Egg, whole, cooked, scrambled');
    });

    test('displayName should fall back to AI name when no USDA name', () {
      final item = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Egg',
        estimatedQuantity: 1,
        estimatedUnit: 'large',
        estimatedGrams: 50,
        calories: 70,
        protein: 6,
        carbs: 0,
        fat: 5,
      );

      expect(item.displayName, 'Egg');
    });

    test('withUsdaData should update item with USDA nutrition', () {
      final item = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Chicken',
        estimatedQuantity: 1,
        estimatedUnit: 'piece',
        estimatedGrams: 150,
        calories: 200,
        protein: 30,
        carbs: 0,
        fat: 8,
      );

      final enriched = item.withUsdaData(
        fdcId: '12345',
        foodName: 'Chicken breast, grilled',
        brandName: null,
        calories: 250,
        protein: 45,
        carbs: 0,
        fat: 6,
        fiber: 0,
        sodium: 80,
        sugar: 0,
      );

      expect(enriched.usdaFdcId, '12345');
      expect(enriched.usdaFoodName, 'Chicken breast, grilled');
      expect(enriched.calories, 250);
      expect(enriched.protein, 45);
      expect(enriched.isFromUsda, true);
      // Should preserve original AI data
      expect(enriched.aiGuessedName, 'Chicken');
      expect(enriched.estimatedGrams, 150);
    });

    test('withUpdatedPortion should recalculate macros', () {
      final item = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Rice',
        estimatedQuantity: 1,
        estimatedUnit: 'cup',
        estimatedGrams: 100,
        calories: 130,
        protein: 3,
        carbs: 28,
        fat: 0,
        isFromUsda: true,
      );

      final updated = item.withUpdatedPortion(
        newGrams: 200,
        caloriesPer100g: 130,
        proteinPer100g: 3,
        carbsPer100g: 28,
        fatPer100g: 0,
      );

      expect(updated.estimatedGrams, 200);
      expect(updated.calories, 260);
      expect(updated.protein, 6);
      expect(updated.carbs, 56);
    });

    test('verified should mark item as verified', () {
      final item = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Apple',
        estimatedQuantity: 1,
        estimatedUnit: 'medium',
        estimatedGrams: 180,
        calories: 95,
        protein: 0,
        carbs: 25,
        fat: 0,
        isVerified: false,
      );

      final verified = item.verified();

      expect(verified.isVerified, true);
      expect(verified.aiGuessedName, 'Apple');
    });

    test('toJson and fromJson should roundtrip correctly', () {
      final original = ParsedFoodItem(
        id: 'test-id',
        aiGuessedName: 'Banana',
        estimatedQuantity: 1,
        estimatedUnit: 'medium',
        estimatedGrams: 120,
        usdaFdcId: '09040',
        usdaFoodName: 'Bananas, raw',
        calories: 105,
        protein: 1,
        carbs: 27,
        fat: 0,
        fiber: 3,
        sodium: 1,
        sugar: 14,
        aiConfidence: 0.95,
        isVerified: true,
        isFromUsda: true,
      );

      final json = original.toJson();
      final restored = ParsedFoodItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.aiGuessedName, original.aiGuessedName);
      expect(restored.usdaFdcId, original.usdaFdcId);
      expect(restored.calories, original.calories);
      expect(restored.fiber, original.fiber);
      expect(restored.isVerified, original.isVerified);
      expect(restored.isFromUsda, original.isFromUsda);
    });
  });

  group('UsdaFoodResult', () {
    test('fromApiResponse should parse USDA API response', () {
      final json = {
        'fdcId': 12345,
        'description': 'Chicken, breast, grilled',
        'brandName': null,
        'dataType': 'SR Legacy',
        'servingSize': 100,
        'servingSizeUnit': 'g',
        'foodNutrients': [
          {'nutrientId': 1008, 'value': 165}, // Energy
          {'nutrientId': 1003, 'value': 31}, // Protein
          {'nutrientId': 1005, 'value': 0}, // Carbs
          {'nutrientId': 1004, 'value': 3.6}, // Fat
          {'nutrientId': 1079, 'value': 0}, // Fiber
          {'nutrientId': 1093, 'value': 74}, // Sodium
          {'nutrientId': 2000, 'value': 0}, // Sugar
        ],
      };

      final result = UsdaFoodResult.fromApiResponse(json);

      expect(result.fdcId, '12345');
      expect(result.description, 'Chicken, breast, grilled');
      expect(result.dataType, 'SR Legacy');
      expect(result.caloriesPer100g, 165);
      expect(result.proteinPer100g, 31);
      expect(result.carbsPer100g, 0);
      expect(result.fatPer100g, 3.6);
      expect(result.fiberPer100g, 0);
      expect(result.sodiumPer100g, 74);
      expect(result.sugarPer100g, 0);
    });

    test('calculateForPortion should scale macros correctly', () {
      final result = UsdaFoodResult(
        fdcId: '12345',
        description: 'Rice, white, cooked',
        caloriesPer100g: 130,
        proteinPer100g: 2.7,
        carbsPer100g: 28,
        fatPer100g: 0.3,
        fiberPer100g: 0.4,
        sodiumPer100g: 1,
        sugarPer100g: 0,
      );

      final macros = result.calculateForPortion(200);

      expect(macros['calories'], 260);
      expect(macros['protein'], 5.4);
      expect(macros['carbs'], 56);
      expect(macros['fat'], 0.6);
      expect(macros['fiber'], 0.8);
      expect(macros['sodium'], 2);
    });

    test('calculateForPortion should handle 50g portion', () {
      final result = UsdaFoodResult(
        fdcId: '12345',
        description: 'Egg',
        caloriesPer100g: 155,
        proteinPer100g: 13,
        carbsPer100g: 1.1,
        fatPer100g: 11,
      );

      final macros = result.calculateForPortion(50);

      expect(macros['calories'], 77.5);
      expect(macros['protein'], 6.5);
      expect(macros['carbs'], 0.55);
      expect(macros['fat'], 5.5);
    });
  });
}
