import 'package:ai_calorie_tracker/models/diet_plan.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

/// Service for calculating macros and generating diet plans
class DietService {
  /// Calculate macro targets based on user profile
  /// Uses standard macro split: 30% protein, 40% carbs, 30% fat
  /// Can be customized based on goals
  static MacroTargets calculateMacros(UserProfile profile) {
    final dailyCalories = profile.dailyCalorieTarget ?? 2000;
    
    // Adjust macro split based on calorie goal
    double proteinPercentage;
    double carbsPercentage;
    double fatPercentage;
    
    switch (profile.calorieGoal) {
      case CalorieGoal.aggressiveCut:
      case CalorieGoal.moderateCut:
        // Higher protein for cutting to preserve muscle
        proteinPercentage = 35;
        carbsPercentage = 35;
        fatPercentage = 30;
        break;
      case CalorieGoal.mildCut:
        proteinPercentage = 32;
        carbsPercentage = 38;
        fatPercentage = 30;
        break;
      case CalorieGoal.maintain:
        proteinPercentage = 30;
        carbsPercentage = 40;
        fatPercentage = 30;
        break;
      case CalorieGoal.mildBulk:
        proteinPercentage = 28;
        carbsPercentage = 45;
        fatPercentage = 27;
        break;
      case CalorieGoal.moderateBulk:
      case CalorieGoal.aggressiveBulk:
        // Higher carbs for bulking
        proteinPercentage = 25;
        carbsPercentage = 50;
        fatPercentage = 25;
        break;
    }
    
    // Calculate grams from percentages
    // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    final proteinG = (dailyCalories * (proteinPercentage / 100)) / 4;
    final carbsG = (dailyCalories * (carbsPercentage / 100)) / 4;
    final fatG = (dailyCalories * (fatPercentage / 100)) / 9;
    
    return MacroTargets(
      dailyCalories: dailyCalories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      proteinPercentage: proteinPercentage,
      carbsPercentage: carbsPercentage,
      fatPercentage: fatPercentage,
    );
  }

  /// Generate meal type names based on number of meals
  static List<String> getMealTypes(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return ['Brunch', 'Dinner'];
      case 3:
        return ['Breakfast', 'Lunch', 'Dinner'];
      case 4:
        return ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
      case 5:
        return ['Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner'];
      case 6:
        return ['Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Evening Snack'];
      default:
        // For 7+ meals
        final types = ['Breakfast', 'Lunch', 'Dinner'];
        for (int i = 4; i <= mealsPerDay; i++) {
          types.add('Snack ${i - 3}');
        }
        return types;
    }
  }

  /// Calculate calories per meal based on meal type and total daily calories
  static Map<String, int> calculateCaloriesPerMeal(int totalCalories, int mealsPerDay) {
    final mealTypes = getMealTypes(mealsPerDay);
    final Map<String, int> distribution = {};
    
    // Different distributions based on meal count
    if (mealsPerDay == 2) {
      distribution['Brunch'] = (totalCalories * 0.45).round();
      distribution['Dinner'] = (totalCalories * 0.55).round();
    } else if (mealsPerDay == 3) {
      distribution['Breakfast'] = (totalCalories * 0.25).round();
      distribution['Lunch'] = (totalCalories * 0.35).round();
      distribution['Dinner'] = (totalCalories * 0.40).round();
    } else if (mealsPerDay == 4) {
      distribution['Breakfast'] = (totalCalories * 0.25).round();
      distribution['Lunch'] = (totalCalories * 0.30).round();
      distribution['Snack'] = (totalCalories * 0.10).round();
      distribution['Dinner'] = (totalCalories * 0.35).round();
    } else if (mealsPerDay == 5) {
      distribution['Breakfast'] = (totalCalories * 0.20).round();
      distribution['Morning Snack'] = (totalCalories * 0.10).round();
      distribution['Lunch'] = (totalCalories * 0.25).round();
      distribution['Afternoon Snack'] = (totalCalories * 0.10).round();
      distribution['Dinner'] = (totalCalories * 0.35).round();
    } else {
      // Even distribution for 6+ meals with main meals getting more
      final mainMealCal = (totalCalories * 0.25).round();
      final snackCal = (totalCalories * 0.08).round();
      
      for (final type in mealTypes) {
        if (type.contains('Snack')) {
          distribution[type] = snackCal;
        } else {
          distribution[type] = mainMealCal;
        }
      }
    }
    
    return distribution;
  }

  /// Build the AI prompt for generating a weekly diet plan
  static String buildDietPlanPrompt({
    required UserProfile profile,
    required MacroTargets macros,
  }) {
    final mealTypes = getMealTypes(profile.mealsPerDay);
    final caloriesPerMeal = calculateCaloriesPerMeal(macros.dailyCalories, profile.mealsPerDay);
    
    // Build allergen warning
    final allergenWarning = profile.allergies.isNotEmpty
        ? '''
CRITICAL - FOOD ALLERGIES (MUST ABSOLUTELY AVOID - USER SAFETY):
${profile.allergies.map((a) => '- $a').join('\n')}
DO NOT include any foods or ingredients containing these allergens. This is a safety requirement.
'''
        : '';
    
    // Build dietary restrictions
    final restrictionsSection = profile.dietaryRestrictions.isNotEmpty
        ? '''
Dietary Restrictions to Follow:
${profile.dietaryRestrictions.map((r) => '- $r').join('\n')}
'''
        : '';
    
    // Build preferred foods
    final preferencesSection = profile.preferredFoods.isNotEmpty
        ? '''
Preferred Foods (include when possible):
${profile.preferredFoods.map((f) => '- $f').join('\n')}
'''
        : '';
    
    // Build meal distribution
    final mealDistribution = mealTypes.map((type) {
      final cals = caloriesPerMeal[type] ?? (macros.dailyCalories ~/ mealTypes.length);
      return '$type: ~$cals calories';
    }).join('\n');

    return '''
Generate a complete 7-day weekly meal plan with the following requirements:

USER PROFILE:
- Daily Calorie Target: ${macros.dailyCalories} kcal
- Daily Protein Target: ${macros.proteinG.round()}g
- Daily Carbs Target: ${macros.carbsG.round()}g
- Daily Fat Target: ${macros.fatG.round()}g
- Goal: ${profile.calorieGoal.label}
- Meals Per Day: ${profile.mealsPerDay}

$allergenWarning
$restrictionsSection
$preferencesSection

MEAL DISTRIBUTION (${profile.mealsPerDay} meals/day):
$mealDistribution

REQUIREMENTS:
1. Generate meals for all 7 days (Monday through Sunday)
2. Each day must have exactly ${profile.mealsPerDay} meals
3. For EACH meal, provide:
   - A PRIMARY meal option with DETAILED macros
   - EXACTLY 10 ALTERNATIVE meal options (different foods, similar macros, each with full macro details)
4. Include variety - don't repeat the same meal across days
5. Make meals practical and easy to prepare
6. Daily totals should be close to the macro targets
7. EVERY meal option (primary and all 10 alternatives) MUST include:
   - Precise calorie count
   - Protein in grams
   - Carbs in grams  
   - Fat in grams
   - Fiber in grams
   - Sodium in mg
   - Sugar in grams

Return a raw JSON object (NO MARKDOWN, NO CODE BLOCKS) with this EXACT structure:
{
  "days": [
    {
      "day_of_week": "Monday",
      "day_number": 1,
      "meals": [
        {
          "meal_type": "Breakfast",
          "meal_number": 1,
          "primary": {
            "name": "Meal Name",
            "description": "Brief description",
            "calories": 400,
            "protein_g": 30,
            "carbs_g": 40,
            "fat_g": 12,
            "fiber_g": 5,
            "sodium_mg": 300,
            "sugar_g": 8,
            "ingredients": ["ingredient1", "ingredient2"],
            "preparation_time": "10 mins"
          },
          "alternatives": [
            {
              "name": "Alternative 1 Name",
              "description": "Brief description",
              "calories": 390,
              "protein_g": 28,
              "carbs_g": 42,
              "fat_g": 11,
              "fiber_g": 6,
              "sodium_mg": 280,
              "sugar_g": 7,
              "ingredients": ["ingredient1", "ingredient2"],
              "preparation_time": "15 mins"
            }
          ]
        }
      ],
      "total_calories": 2000,
      "total_protein_g": 150,
      "total_carbs_g": 200,
      "total_fat_g": 67
    }
  ]
}

IMPORTANT: Each meal MUST have EXACTLY 10 alternatives. All alternatives must have complete detailed macros.

Remember: Return ONLY the raw JSON, no markdown formatting.
''';
  }
}
