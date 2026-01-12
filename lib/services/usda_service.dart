import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parsed_food.dart';
import '../secrets.dart';

/// Service for interacting with the USDA FoodData Central API
class UsdaService {
  static final UsdaService _instance = UsdaService._internal();
  factory UsdaService() => _instance;
  UsdaService._internal();

  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  
  // Simple in-memory cache for frequent lookups
  final Map<String, List<UsdaFoodResult>> _searchCache = {};
  final Map<String, UsdaFoodResult> _foodCache = {};

  /// Search for foods by query string
  /// Returns list of matching foods with nutrition data
  Future<List<UsdaFoodResult>> searchFoods(
    String query, {
    int pageSize = 10,
    List<String>? dataTypes,
  }) async {
    if (query.trim().isEmpty) return [];

    // Check cache first
    final cacheKey = '${query.toLowerCase()}_$pageSize';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    try {
      final queryParams = <String, String>{
        'api_key': usdaApiKey,
        'query': query,
        'pageSize': pageSize.toString(),
      };
      if (dataTypes != null && dataTypes.isNotEmpty) {
        queryParams['dataType'] = dataTypes.join(',');
      }
      
      final uri = Uri.parse('$_baseUrl/foods/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('USDA API error: ${response.statusCode} - ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final foods = (data['foods'] as List?) ?? [];

      final results = foods
          .map((f) => UsdaFoodResult.fromApiResponse(f))
          .where((f) => f.fdcId.isNotEmpty)
          .toList();

      // Cache the results
      _searchCache[cacheKey] = results;

      return results;
    } catch (e) {
      debugPrint('USDA search error: $e');
      return [];
    }
  }

  /// Get detailed food data by FDC ID
  Future<UsdaFoodResult?> getFoodById(String fdcId) async {
    // Check cache
    if (_foodCache.containsKey(fdcId)) {
      return _foodCache[fdcId];
    }

    try {
      final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(
        queryParameters: {
          'api_key': usdaApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('USDA API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      final result = UsdaFoodResult.fromApiResponse(data);

      // Cache the result
      _foodCache[fdcId] = result;

      return result;
    } catch (e) {
      debugPrint('USDA get food error: $e');
      return null;
    }
  }

  /// Search and return best match for a food name
  /// Useful for auto-matching AI-parsed ingredients
  Future<UsdaFoodResult?> findBestMatch(String foodName) async {
    final results = await searchFoods(
      foodName,
      pageSize: 5,
      // Prefer survey/standard reference data over branded
      dataTypes: ['Survey (FNDDS)', 'SR Legacy', 'Foundation'],
    );

    if (results.isEmpty) {
      // Try again with branded foods
      final brandedResults = await searchFoods(foodName, pageSize: 3);
      return brandedResults.isNotEmpty ? brandedResults.first : null;
    }

    return results.first;
  }

  /// Enrich a parsed food item with USDA nutrition data
  Future<ParsedFoodItem> enrichWithUsdaData(ParsedFoodItem item) async {
    final match = await findBestMatch(item.aiGuessedName);
    
    if (match == null) {
      // No USDA match found, return original with AI estimates
      return item;
    }

    // Calculate macros for the estimated portion
    final macros = match.calculateForPortion(item.estimatedGrams);

    return item.withUsdaData(
      fdcId: match.fdcId,
      foodName: match.description,
      brandName: match.brandName,
      calories: macros['calories'] ?? 0,
      protein: macros['protein'] ?? 0,
      carbs: macros['carbs'] ?? 0,
      fat: macros['fat'] ?? 0,
      fiber: macros['fiber'],
      sodium: macros['sodium'],
      sugar: macros['sugar'],
    );
  }

  /// Batch enrich multiple parsed items
  Future<List<ParsedFoodItem>> enrichMultiple(List<ParsedFoodItem> items) async {
    final enriched = <ParsedFoodItem>[];
    
    for (final item in items) {
      try {
        final enrichedItem = await enrichWithUsdaData(item);
        enriched.add(enrichedItem);
      } catch (e) {
        debugPrint('Failed to enrich ${item.aiGuessedName}: $e');
        enriched.add(item); // Keep original on failure
      }
    }
    
    return enriched;
  }

  /// Clear the cache (useful for testing or memory management)
  void clearCache() {
    _searchCache.clear();
    _foodCache.clear();
  }

  /// Common unit to gram conversions
  static double convertToGrams(double quantity, String unit, String foodName) {
    final lowerUnit = unit.toLowerCase();
    final lowerFood = foodName.toLowerCase();

    // Specific food conversions
    if (lowerFood.contains('egg')) {
      if (lowerUnit == 'large' || lowerUnit == 'whole') return quantity * 50;
      if (lowerUnit == 'medium') return quantity * 44;
      if (lowerUnit == 'small') return quantity * 38;
    }

    if (lowerFood.contains('bread') || lowerFood.contains('toast')) {
      if (lowerUnit == 'slice' || lowerUnit == 'slices') return quantity * 30;
    }

    if (lowerFood.contains('butter')) {
      if (lowerUnit == 'tbsp' || lowerUnit == 'tablespoon') return quantity * 14;
      if (lowerUnit == 'tsp' || lowerUnit == 'teaspoon') return quantity * 5;
      if (lowerUnit == 'pat') return quantity * 5;
    }

    if (lowerFood.contains('milk') || lowerFood.contains('juice')) {
      if (lowerUnit == 'cup' || lowerUnit == 'cups') return quantity * 240;
      if (lowerUnit == 'glass') return quantity * 240;
      if (lowerUnit == 'oz' || lowerUnit == 'ounce') return quantity * 30;
    }

    if (lowerFood.contains('rice') || lowerFood.contains('pasta')) {
      if (lowerUnit == 'cup' || lowerUnit == 'cups') return quantity * 195; // cooked
    }

    if (lowerFood.contains('chicken') || lowerFood.contains('meat') || lowerFood.contains('beef')) {
      if (lowerUnit == 'oz' || lowerUnit == 'ounce') return quantity * 28;
      if (lowerUnit == 'breast') return quantity * 170;
      if (lowerUnit == 'thigh') return quantity * 85;
    }

    // Generic conversions
    switch (lowerUnit) {
      case 'g':
      case 'gram':
      case 'grams':
        return quantity;
      case 'kg':
      case 'kilogram':
        return quantity * 1000;
      case 'oz':
      case 'ounce':
      case 'ounces':
        return quantity * 28.35;
      case 'lb':
      case 'pound':
      case 'pounds':
        return quantity * 453.6;
      case 'cup':
      case 'cups':
        return quantity * 240;
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return quantity * 15;
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return quantity * 5;
      case 'ml':
      case 'milliliter':
        return quantity;
      case 'l':
      case 'liter':
        return quantity * 1000;
      case 'piece':
      case 'pieces':
      case 'serving':
      case 'servings':
      case 'portion':
        return quantity * 100; // Default serving size
      default:
        return quantity * 100; // Default assumption
    }
  }
}
