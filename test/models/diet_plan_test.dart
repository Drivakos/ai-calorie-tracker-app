import 'package:flutter_test/flutter_test.dart';
import 'package:ai_calorie_tracker/models/diet_plan.dart';

void main() {
  group('MealOption', () {
    test('fromJson should parse meal option with detailed macros', () {
      final json = {
        'name': 'Grilled Chicken Salad',
        'description': 'Fresh salad with grilled chicken breast',
        'calories': 350,
        'protein_g': 35,
        'carbs_g': 15,
        'fat_g': 18,
        'fiber_g': 5,
        'sodium_mg': 400,
        'sugar_g': 8,
        'ingredients': ['chicken breast', 'mixed greens', 'olive oil'],
        'preparation_time': '15 mins',
      };

      final option = MealOption.fromJson(json);

      expect(option.name, 'Grilled Chicken Salad');
      expect(option.description, 'Fresh salad with grilled chicken breast');
      expect(option.calories, 350);
      expect(option.proteinG, 35);
      expect(option.carbsG, 15);
      expect(option.fatG, 18);
      expect(option.fiberG, 5);
      expect(option.sodiumMg, 400);
      expect(option.sugarG, 8);
      expect(option.ingredients, ['chicken breast', 'mixed greens', 'olive oil']);
      expect(option.preparationTime, '15 mins');
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'name': 'Simple Meal',
        'description': 'A basic meal',
        'calories': 200,
        'protein_g': 10,
        'carbs_g': 20,
        'fat_g': 8,
      };

      final option = MealOption.fromJson(json);

      expect(option.fiberG, 0);
      expect(option.sodiumMg, 0);
      expect(option.sugarG, 0);
      expect(option.ingredients, isEmpty);
      expect(option.preparationTime, isNull);
    });

    test('toJson should serialize meal option correctly', () {
      const option = MealOption(
        name: 'Test Meal',
        description: 'Test description',
        calories: 400,
        proteinG: 30,
        carbsG: 40,
        fatG: 15,
        fiberG: 6,
        sodiumMg: 500,
        sugarG: 10,
        ingredients: ['ingredient1', 'ingredient2'],
        preparationTime: '20 mins',
      );

      final json = option.toJson();

      expect(json['name'], 'Test Meal');
      expect(json['calories'], 400);
      expect(json['fiber_g'], 6);
      expect(json['sodium_mg'], 500);
      expect(json['sugar_g'], 10);
    });
  });

  group('Meal', () {
    test('fromJson should parse meal with primary and alternatives', () {
      final json = {
        'meal_type': 'Breakfast',
        'meal_number': 1,
        'primary': {
          'name': 'Scrambled Eggs',
          'description': 'Fluffy scrambled eggs',
          'calories': 200,
          'protein_g': 14,
          'carbs_g': 2,
          'fat_g': 15,
        },
        'alternatives': [
          {
            'name': 'Oatmeal',
            'description': 'Healthy oatmeal',
            'calories': 180,
            'protein_g': 6,
            'carbs_g': 32,
            'fat_g': 4,
          },
          {
            'name': 'Greek Yogurt',
            'description': 'Creamy yogurt',
            'calories': 150,
            'protein_g': 15,
            'carbs_g': 10,
            'fat_g': 5,
          },
        ],
      };

      final meal = Meal.fromJson(json);

      expect(meal.mealType, 'Breakfast');
      expect(meal.mealNumber, 1);
      expect(meal.primary.name, 'Scrambled Eggs');
      expect(meal.alternatives.length, 2);
      expect(meal.alternatives[0].name, 'Oatmeal');
      expect(meal.alternatives[1].name, 'Greek Yogurt');
    });

    test('toJson should serialize meal correctly', () {
      const meal = Meal(
        mealType: 'Lunch',
        mealNumber: 2,
        primary: MealOption(
          name: 'Chicken Wrap',
          description: 'Healthy wrap',
          calories: 450,
          proteinG: 35,
          carbsG: 40,
          fatG: 15,
        ),
        alternatives: [],
      );

      final json = meal.toJson();

      expect(json['meal_type'], 'Lunch');
      expect(json['meal_number'], 2);
      expect(json['primary']['name'], 'Chicken Wrap');
      expect(json['alternatives'], isEmpty);
    });
  });

  group('DailyPlan', () {
    test('fromJson should parse daily plan', () {
      final json = {
        'day_of_week': 'Monday',
        'day_number': 1,
        'meals': [
          {
            'meal_type': 'Breakfast',
            'meal_number': 1,
            'primary': {
              'name': 'Eggs',
              'description': 'test',
              'calories': 200,
              'protein_g': 14,
              'carbs_g': 2,
              'fat_g': 15,
            },
            'alternatives': [],
          },
        ],
        'total_calories': 2000,
        'total_protein_g': 150,
        'total_carbs_g': 200,
        'total_fat_g': 67,
      };

      final plan = DailyPlan.fromJson(json);

      expect(plan.dayOfWeek, 'Monday');
      expect(plan.dayNumber, 1);
      expect(plan.meals.length, 1);
      expect(plan.totalCalories, 2000);
      expect(plan.totalProteinG, 150);
      expect(plan.totalCarbsG, 200);
      expect(plan.totalFatG, 67);
    });
  });

  group('MacroTargets', () {
    test('fromJson should parse macro targets', () {
      final json = {
        'daily_calories': 2200,
        'protein_g': 165.0,
        'carbs_g': 220.0,
        'fat_g': 73.0,
        'protein_percentage': 30.0,
        'carbs_percentage': 40.0,
        'fat_percentage': 30.0,
      };

      final targets = MacroTargets.fromJson(json);

      expect(targets.dailyCalories, 2200);
      expect(targets.proteinG, 165.0);
      expect(targets.carbsG, 220.0);
      expect(targets.fatG, 73.0);
    });

    test('toJson should serialize macro targets', () {
      const targets = MacroTargets(
        dailyCalories: 2000,
        proteinG: 150,
        carbsG: 200,
        fatG: 67,
      );

      final json = targets.toJson();

      expect(json['daily_calories'], 2000);
      expect(json['protein_g'], 150);
    });
  });

  group('WeeklyDietPlan', () {
    test('should calculate average daily totals', () {
      final plan = WeeklyDietPlan(
        macroTargets: const MacroTargets(
          dailyCalories: 2000,
          proteinG: 150,
          carbsG: 200,
          fatG: 67,
        ),
        days: [
          const DailyPlan(
            dayOfWeek: 'Monday',
            dayNumber: 1,
            meals: [],
            totalCalories: 1900,
            totalProteinG: 140,
            totalCarbsG: 190,
            totalFatG: 65,
          ),
          const DailyPlan(
            dayOfWeek: 'Tuesday',
            dayNumber: 2,
            meals: [],
            totalCalories: 2100,
            totalProteinG: 160,
            totalCarbsG: 210,
            totalFatG: 69,
          ),
        ],
        mealsPerDay: 3,
        generatedAt: DateTime.now(),
      );

      expect(plan.averageDailyCalories, 2000);
      expect(plan.averageDailyProtein, 150);
      expect(plan.averageDailyCarbs, 200);
      expect(plan.averageDailyFat, 67);
    });

    test('copyWith should create updated copy', () {
      final original = WeeklyDietPlan(
        id: 'original-id',
        macroTargets: const MacroTargets(
          dailyCalories: 2000,
          proteinG: 150,
          carbsG: 200,
          fatG: 67,
        ),
        days: [],
        mealsPerDay: 3,
        generatedAt: DateTime.now(),
        isActive: true,
      );

      final updated = original.copyWith(
        id: 'new-id',
        isActive: false,
      );

      expect(updated.id, 'new-id');
      expect(updated.isActive, false);
      expect(updated.mealsPerDay, 3); // unchanged
      expect(updated.macroTargets.dailyCalories, 2000); // unchanged
    });

    test('toJson and fromJson should roundtrip', () {
      final original = WeeklyDietPlan(
        id: 'test-id',
        macroTargets: const MacroTargets(
          dailyCalories: 2200,
          proteinG: 165,
          carbsG: 220,
          fatG: 73,
        ),
        days: [
          const DailyPlan(
            dayOfWeek: 'Monday',
            dayNumber: 1,
            meals: [],
            totalCalories: 2200,
            totalProteinG: 165,
            totalCarbsG: 220,
            totalFatG: 73,
          ),
        ],
        mealsPerDay: 4,
        avoidedAllergens: ['peanuts', 'shellfish'],
        dietaryRestrictions: ['vegetarian'],
        generatedAt: DateTime(2024, 1, 15),
        isActive: true,
      );

      final json = original.toJson();
      final restored = WeeklyDietPlan.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.mealsPerDay, 4);
      expect(restored.avoidedAllergens, ['peanuts', 'shellfish']);
      expect(restored.dietaryRestrictions, ['vegetarian']);
      expect(restored.days.length, 1);
      expect(restored.isActive, true);
    });
  });
}
