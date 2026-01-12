import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/diet_plan.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';
import 'package:ai_calorie_tracker/models/parsed_food.dart';
import 'package:ai_calorie_tracker/services/diet_service.dart';
import 'package:ai_calorie_tracker/services/usda_service.dart';
import '../secrets.dart';

class GeminiService {
  late final GenerativeModel _model;
  final UsdaService _usdaService = UsdaService();

  GeminiService() {
    // Using gemini-3-flash-preview - latest and fastest model
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: geminiApiKey,
    );
  }

  /// Get image bytes from either a file path (desktop) or blob URL (web)
  Future<Uint8List> _getImageBytes(String imagePath) async {
    if (kIsWeb) {
      // For Web, imagePath is a blob URL - fetch via http
      final response = await http.get(Uri.parse(imagePath));
      return response.bodyBytes;
    } else {
      // For desktop/mobile, read from file system
      final file = File(imagePath);
      return await file.readAsBytes();
    }
  }

  /// Extract JSON from AI response that may contain extra text
  String? _extractJson(String text) {
    // Remove markdown code blocks
    String cleaned = text.replaceAll('```json', '').replaceAll('```', '');
    
    // Try to find JSON object boundaries with proper brace matching
    final startIndex = cleaned.indexOf('{');
    if (startIndex == -1) return null;
    
    int braceCount = 0;
    int endIndex = -1;
    
    for (int i = startIndex; i < cleaned.length; i++) {
      if (cleaned[i] == '{') {
        braceCount++;
      } else if (cleaned[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }
    }
    
    if (endIndex == -1) return null;
    
    String jsonStr = cleaned.substring(startIndex, endIndex + 1);
    
    // Fix common JSON issues from AI responses
    // Remove trailing commas before closing brackets/braces
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*}'), '}');
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*\]'), ']');
    
    return jsonStr;
  }

  /// Parse natural language food input into structured ingredients
  /// Example: "2 eggs with toast and butter" -> list of parsed items
  Future<List<ParsedFoodItem>> parseFoodInput(String input) async {
    if (input.trim().isEmpty) return [];

    final prompt = '''
Parse this food description into individual food items with quantities and estimated nutrition.
Be specific about each ingredient - separate compound dishes into components.

Input: "$input"

Return a raw JSON object (NO MARKDOWN, NO CODE BLOCKS) with this structure:
{
  "items": [
    {
      "name": "Egg, scrambled",
      "quantity": 2,
      "unit": "large",
      "estimated_grams": 100,
      "estimated_calories": 180,
      "estimated_protein_g": 12,
      "estimated_carbs_g": 2,
      "estimated_fat_g": 14,
      "confidence": 0.9
    },
    {
      "name": "Whole wheat toast",
      "quantity": 1,
      "unit": "slice",
      "estimated_grams": 30,
      "estimated_calories": 80,
      "estimated_protein_g": 3,
      "estimated_carbs_g": 15,
      "estimated_fat_g": 1,
      "confidence": 0.85
    }
  ]
}

Rules:
1. Separate each distinct food item
2. Use standard units (g, large, medium, small, slice, cup, tbsp, tsp, oz)
3. Estimate grams based on typical serving sizes
4. Provide rough calorie/macro estimates (will be refined with USDA data)
5. Confidence: 0.0-1.0 based on how certain you are about the identification
6. For ambiguous items, make reasonable assumptions and note lower confidence
7. Use descriptive names that match USDA database naming conventions
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) return [];

      final jsonStr = _extractJson(text);
      if (jsonStr == null) {
        debugPrint('Gemini Parse: Could not find JSON in response');
        return [];
      }
      
      final data = jsonDecode(jsonStr);
      
      if (data is Map && data.containsKey('items')) {
        final items = (data['items'] as List).map((item) {
          return ParsedFoodItem.fromAiParsing(item, const Uuid().v4());
        }).toList();
        
        // Enrich with USDA data
        return await _usdaService.enrichMultiple(items);
      }
      
      return [];
    } catch (e) {
      debugPrint('Gemini Parse Error: $e');
      return [];
    }
  }

  /// Analyze food image - identify WHOLE DISHES first, not individual ingredients
  /// Returns dishes as they would appear on a menu (e.g., "Beef Burger" not "bun, lettuce, patty...")
  Future<List<ParsedFoodItem>> analyzeFoodImageStructured(String imagePath, {String? userFeedback}) async {
    debugPrint('Analyzing image: $imagePath');
    if (userFeedback != null) {
      debugPrint('With user feedback: $userFeedback');
    }
    
    final imageBytes = await _getImageBytes(imagePath);
    debugPrint('Image bytes loaded: ${imageBytes.length} bytes');
    
    String prompt = '''
Analyze this food image. Identify the COMPLETE DISH or MEAL as it would appear on a menu.
DO NOT break down into individual ingredients - identify the whole food item.

Examples of CORRECT identification:
- "Beef burger with cheese" (NOT: bun, patty, lettuce, cheese separately)
- "Caesar salad" (NOT: lettuce, croutons, dressing separately)
- "Pepperoni pizza slice" (NOT: dough, sauce, cheese, pepperoni separately)
- "Spaghetti carbonara" (NOT: pasta, bacon, egg, cheese separately)

Return a raw JSON object (NO MARKDOWN, NO CODE BLOCKS) with this structure:
{
  "items": [
    {
      "name": "Beef burger with cheese",
      "quantity": 1,
      "unit": "burger",
      "estimated_grams": 250,
      "estimated_calories": 550,
      "estimated_protein_g": 30,
      "estimated_carbs_g": 40,
      "estimated_fat_g": 28,
      "confidence": 0.85,
      "description": "Classic beef burger with cheese, lettuce, tomato, and sauce on a sesame bun"
    }
  ]
}

Rules:
1. Identify the WHOLE DISH as it would be named on a restaurant menu
2. Only list separate items if they are truly distinct (e.g., "burger" and "fries" as two items)
3. Estimate total weight and macros for the complete dish
4. Include a brief description of what you see
5. Use common food names that would match in nutrition databases
6. Confidence: 0.0-1.0 based on how certain you are
''';

    // Add user feedback context if provided
    if (userFeedback != null && userFeedback.isNotEmpty) {
      prompt += '''

**CRITICAL USER CORRECTION - YOUR PREVIOUS ANALYSIS WAS WRONG:**
The user says: "$userFeedback"

YOU MUST:
1. TRUST the user's correction - they know what food this is
2. Use the user's description to identify the food correctly
3. DO NOT repeat your previous wrong identification
4. If the user says it's a cheeseburger, it IS a cheeseburger (not vegan, not plant-based)
5. Look at the image again with the user's correction in mind

Example: If user says "it's a beef cheeseburger not vegan" → identify as "Beef cheeseburger" with appropriate meat-based macros.
''';
    }
    
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) return [];

      final jsonStr = _extractJson(text);
      if (jsonStr == null) {
        debugPrint('Gemini Image Analysis: Could not find JSON in response');
        debugPrint('Raw response: $text');
        return [];
      }
      
      dynamic data;
      try {
        data = jsonDecode(jsonStr);
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        debugPrint('Attempted to parse: $jsonStr');
        return [];
      }
      
      if (data is Map && data.containsKey('items')) {
        final items = (data['items'] as List).map((item) {
          return ParsedFoodItem.fromAiParsing(item, const Uuid().v4());
        }).toList();
        
        // Enrich with USDA data
        return await _usdaService.enrichMultiple(items);
      }
      
      return [];
    } catch (e) {
      debugPrint('Gemini Image Analysis Error: $e');
      return [];
    }
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> analyzeFoodImage(String imagePath) async {
    final imageBytes = await _getImageBytes(imagePath);
    
    final content = [
      Content.multi([
        TextPart(
            'Analyze this food image. Identify the items. Estimate the weight in grams for each based on visual cues (portion size). Calculate approximate calories, protein, carbs, and fat for that estimated weight. Return a raw JSON object (NO MARKDOWN, NO CODE BLOCKS, just the raw json string) with this structure: { "items": [ { "name": "Food Name", "weight_grams": 100, "calories": 200, "protein_g": 10, "carbs_g": 20, "fat_g": 5 } ] }'),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) return [];

      final jsonStr = _extractJson(text);
      if (jsonStr == null) return [];

      final data = jsonDecode(jsonStr);
      if (data is Map && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return [];
    } catch (e) {
      debugPrint('Gemini Error: $e');
      // Fallback or rethrow
      return [];
    }
  }

  /// Generate a weekly diet plan based on user profile
  Future<WeeklyDietPlan> generateWeeklyDietPlan(UserProfile profile) async {
    // Calculate macro targets
    final macros = DietService.calculateMacros(profile);
    
    // Build the prompt
    final prompt = DietService.buildDietPlanPrompt(
      profile: profile,
      macros: macros,
    );

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) {
        throw Exception('No response from AI');
      }

      // Clean up potential markdown code blocks
      final jsonStr = _extractJson(text);
      if (jsonStr == null) throw Exception('Could not parse diet plan response');

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Build the complete diet plan
      final days = (data['days'] as List?)
          ?.map((d) => DailyPlan.fromJson(d))
          .toList() ?? [];

      return WeeklyDietPlan(
        macroTargets: macros,
        days: days,
        mealsPerDay: profile.mealsPerDay,
        avoidedAllergens: profile.allergies,
        dietaryRestrictions: profile.dietaryRestrictions,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Gemini Diet Plan Error: $e');
      rethrow;
    }
  }

  /// Generate a single day's meal plan (for quick regeneration)
  Future<DailyPlan> regenerateDayPlan({
    required UserProfile profile,
    required String dayOfWeek,
    required int dayNumber,
  }) async {
    final macros = DietService.calculateMacros(profile);
    final mealTypes = DietService.getMealTypes(profile.mealsPerDay);
    final caloriesPerMeal = DietService.calculateCaloriesPerMeal(
      macros.dailyCalories, 
      profile.mealsPerDay,
    );
    
    final allergenWarning = profile.allergies.isNotEmpty
        ? 'CRITICAL - MUST AVOID these allergens: ${profile.allergies.join(", ")}'
        : '';
    
    final mealDistribution = mealTypes.map((type) {
      final cals = caloriesPerMeal[type] ?? (macros.dailyCalories ~/ mealTypes.length);
      return '$type: ~$cals calories';
    }).join('\n');

    final prompt = '''
Generate a meal plan for $dayOfWeek with ${profile.mealsPerDay} meals.

Daily Targets: ${macros.dailyCalories} kcal, ${macros.proteinG.round()}g protein, ${macros.carbsG.round()}g carbs, ${macros.fatG.round()}g fat

$allergenWarning

Dietary restrictions: ${profile.dietaryRestrictions.join(", ")}
Preferred foods: ${profile.preferredFoods.join(", ")}

Meals: $mealDistribution

For EACH meal provide a primary option and EXACTLY 10 alternatives with detailed macros.
EVERY meal option MUST include: calories, protein_g, carbs_g, fat_g, fiber_g, sodium_mg, sugar_g

Return raw JSON (no markdown):
{
  "day_of_week": "$dayOfWeek",
  "day_number": $dayNumber,
  "meals": [
    {
      "meal_type": "MealType",
      "meal_number": 1,
      "primary": {
        "name": "Name",
        "description": "Description",
        "calories": 400,
        "protein_g": 30,
        "carbs_g": 40,
        "fat_g": 12,
        "fiber_g": 5,
        "sodium_mg": 300,
        "sugar_g": 8,
        "ingredients": ["ing1", "ing2"],
        "preparation_time": "10 mins"
      },
      "alternatives": [
        {
          "name": "Alt Name",
          "description": "Description",
          "calories": 390,
          "protein_g": 28,
          "carbs_g": 42,
          "fat_g": 11,
          "fiber_g": 6,
          "sodium_mg": 280,
          "sugar_g": 7,
          "ingredients": ["ing1", "ing2"],
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

IMPORTANT: Each meal MUST have EXACTLY 10 alternatives with complete detailed macros.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      
      if (text == null) throw Exception('No response');

      final jsonStr = _extractJson(text);
      if (jsonStr == null) throw Exception('Could not parse day plan response');
      
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return DailyPlan.fromJson(data);
    } catch (e) {
      debugPrint('Gemini Day Plan Error: $e');
      rethrow;
    }
  }
}
