/// Represents a food item parsed by AI with optional USDA data
class ParsedFoodItem {
  final String id;
  final String aiGuessedName;
  final String? aiDescription; // Description of what was identified
  final double estimatedQuantity;
  final String estimatedUnit; // e.g., "large", "slice", "cup", "g"
  final double estimatedGrams;
  
  // USDA data (populated after lookup)
  final String? usdaFdcId;
  final String? usdaFoodName;
  final String? usdaBrandName;
  
  // Macros (calculated for the portion)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sodium;
  final double? sugar;
  
  // Confidence and verification
  final double? aiConfidence; // 0.0 - 1.0
  final bool isVerified; // User confirmed this item
  final bool isFromUsda; // Macros are from USDA vs AI estimate

  const ParsedFoodItem({
    required this.id,
    required this.aiGuessedName,
    this.aiDescription,
    required this.estimatedQuantity,
    required this.estimatedUnit,
    required this.estimatedGrams,
    this.usdaFdcId,
    this.usdaFoodName,
    this.usdaBrandName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
    this.sugar,
    this.aiConfidence,
    this.isVerified = false,
    this.isFromUsda = false,
  });

  /// Display name - prefer USDA name if available
  String get displayName => usdaFoodName ?? aiGuessedName;

  /// Create from AI parsing result
  factory ParsedFoodItem.fromAiParsing(Map<String, dynamic> json, String id) {
    return ParsedFoodItem(
      id: id,
      aiGuessedName: json['name'] ?? 'Unknown Food',
      aiDescription: json['description'],
      estimatedQuantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      estimatedUnit: json['unit'] ?? 'serving',
      estimatedGrams: (json['estimated_grams'] as num?)?.toDouble() ?? 100.0,
      calories: (json['estimated_calories'] as num?)?.toDouble() ?? 0,
      protein: (json['estimated_protein_g'] as num?)?.toDouble() ?? 0,
      carbs: (json['estimated_carbs_g'] as num?)?.toDouble() ?? 0,
      fat: (json['estimated_fat_g'] as num?)?.toDouble() ?? 0,
      aiConfidence: (json['confidence'] as num?)?.toDouble(),
      isFromUsda: false,
    );
  }

  /// Create updated item with USDA nutrition data
  ParsedFoodItem withUsdaData({
    required String fdcId,
    required String foodName,
    String? brandName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sodium,
    double? sugar,
  }) {
    return ParsedFoodItem(
      id: id,
      aiGuessedName: aiGuessedName,
      estimatedQuantity: estimatedQuantity,
      estimatedUnit: estimatedUnit,
      estimatedGrams: estimatedGrams,
      usdaFdcId: fdcId,
      usdaFoodName: foodName,
      usdaBrandName: brandName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
      sugar: sugar,
      aiConfidence: aiConfidence,
      isVerified: isVerified,
      isFromUsda: true,
    );
  }

  /// Update portion size and recalculate macros
  ParsedFoodItem withUpdatedPortion({
    double? quantity,
    String? unit,
    required double newGrams,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    double? fiberPer100g,
    double? sodiumPer100g,
    double? sugarPer100g,
  }) {
    final ratio = newGrams / 100.0;
    return ParsedFoodItem(
      id: id,
      aiGuessedName: aiGuessedName,
      estimatedQuantity: quantity ?? estimatedQuantity,
      estimatedUnit: unit ?? estimatedUnit,
      estimatedGrams: newGrams,
      usdaFdcId: usdaFdcId,
      usdaFoodName: usdaFoodName,
      usdaBrandName: usdaBrandName,
      calories: caloriesPer100g * ratio,
      protein: proteinPer100g * ratio,
      carbs: carbsPer100g * ratio,
      fat: fatPer100g * ratio,
      fiber: fiberPer100g != null ? fiberPer100g * ratio : null,
      sodium: sodiumPer100g != null ? sodiumPer100g * ratio : null,
      sugar: sugarPer100g != null ? sugarPer100g * ratio : null,
      aiConfidence: aiConfidence,
      isVerified: isVerified,
      isFromUsda: isFromUsda,
    );
  }

  /// Mark as verified by user
  ParsedFoodItem verified() {
    return ParsedFoodItem(
      id: id,
      aiGuessedName: aiGuessedName,
      estimatedQuantity: estimatedQuantity,
      estimatedUnit: estimatedUnit,
      estimatedGrams: estimatedGrams,
      usdaFdcId: usdaFdcId,
      usdaFoodName: usdaFoodName,
      usdaBrandName: usdaBrandName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
      sugar: sugar,
      aiConfidence: aiConfidence,
      isVerified: true,
      isFromUsda: isFromUsda,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ai_guessed_name': aiGuessedName,
    'ai_description': aiDescription,
    'estimated_quantity': estimatedQuantity,
    'estimated_unit': estimatedUnit,
    'estimated_grams': estimatedGrams,
    'usda_fdc_id': usdaFdcId,
    'usda_food_name': usdaFoodName,
    'usda_brand_name': usdaBrandName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sodium': sodium,
    'sugar': sugar,
    'ai_confidence': aiConfidence,
    'is_verified': isVerified,
    'is_from_usda': isFromUsda,
  };

  factory ParsedFoodItem.fromJson(Map<String, dynamic> json) {
    return ParsedFoodItem(
      id: json['id'],
      aiGuessedName: json['ai_guessed_name'] ?? '',
      aiDescription: json['ai_description'],
      estimatedQuantity: (json['estimated_quantity'] as num?)?.toDouble() ?? 1.0,
      estimatedUnit: json['estimated_unit'] ?? 'serving',
      estimatedGrams: (json['estimated_grams'] as num?)?.toDouble() ?? 100.0,
      usdaFdcId: json['usda_fdc_id'],
      usdaFoodName: json['usda_food_name'],
      usdaBrandName: json['usda_brand_name'],
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      isVerified: json['is_verified'] ?? false,
      isFromUsda: json['is_from_usda'] ?? false,
    );
  }
}

/// USDA food search result
class UsdaFoodResult {
  final String fdcId;
  final String description;
  final String? brandName;
  final String? dataType; // "Branded", "Survey (FNDDS)", "SR Legacy"
  final double? servingSize;
  final String? servingSizeUnit;
  
  // Nutrition per 100g
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sodiumPer100g;
  final double? sugarPer100g;

  const UsdaFoodResult({
    required this.fdcId,
    required this.description,
    this.brandName,
    this.dataType,
    this.servingSize,
    this.servingSizeUnit,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sodiumPer100g,
    this.sugarPer100g,
  });

  /// Calculate macros for a given portion in grams
  Map<String, double> calculateForPortion(double grams) {
    final ratio = grams / 100.0;
    return {
      'calories': caloriesPer100g * ratio,
      'protein': proteinPer100g * ratio,
      'carbs': carbsPer100g * ratio,
      'fat': fatPer100g * ratio,
      if (fiberPer100g != null) 'fiber': fiberPer100g! * ratio,
      if (sodiumPer100g != null) 'sodium': sodiumPer100g! * ratio,
      if (sugarPer100g != null) 'sugar': sugarPer100g! * ratio,
    };
  }

  factory UsdaFoodResult.fromApiResponse(Map<String, dynamic> json) {
    // Extract nutrients from the foodNutrients array
    final nutrients = json['foodNutrients'] as List? ?? [];
    
    double getNutrient(int nutrientId) {
      for (final n in nutrients) {
        if (n['nutrientId'] == nutrientId || n['nutrientNumber'] == nutrientId.toString()) {
          return (n['value'] as num?)?.toDouble() ?? 0;
        }
      }
      return 0;
    }

    // USDA nutrient IDs:
    // 1008 = Energy (kcal)
    // 1003 = Protein
    // 1005 = Carbohydrate
    // 1004 = Total fat
    // 1079 = Fiber
    // 1093 = Sodium
    // 2000 = Total sugars
    
    return UsdaFoodResult(
      fdcId: json['fdcId']?.toString() ?? '',
      description: json['description'] ?? '',
      brandName: json['brandName'] ?? json['brandOwner'],
      dataType: json['dataType'],
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: json['servingSizeUnit'],
      caloriesPer100g: getNutrient(1008),
      proteinPer100g: getNutrient(1003),
      carbsPer100g: getNutrient(1005),
      fatPer100g: getNutrient(1004),
      fiberPer100g: getNutrient(1079),
      sodiumPer100g: getNutrient(1093),
      sugarPer100g: getNutrient(2000),
    );
  }
}
