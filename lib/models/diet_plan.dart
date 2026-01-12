/// Represents a single meal option with detailed macros
class MealOption {
  final String name;
  final String description;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sodiumMg;
  final double sugarG;
  final List<String> ingredients;
  final String? preparationTime;

  const MealOption({
    required this.name,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.sodiumMg = 0,
    this.sugarG = 0,
    this.ingredients = const [],
    this.preparationTime,
  });

  factory MealOption.fromJson(Map<String, dynamic> json) {
    return MealOption(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0,
      sugarG: (json['sugar_g'] as num?)?.toDouble() ?? 0,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      preparationTime: json['preparation_time'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'fiber_g': fiberG,
    'sodium_mg': sodiumMg,
    'sugar_g': sugarG,
    'ingredients': ingredients,
    'preparation_time': preparationTime,
  };
}

/// Represents a meal slot with primary option and alternatives
class Meal {
  final String mealType; // e.g., "Breakfast", "Lunch", "Dinner", "Snack 1"
  final int mealNumber;
  final MealOption primary;
  final List<MealOption> alternatives;

  const Meal({
    required this.mealType,
    required this.mealNumber,
    required this.primary,
    this.alternatives = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      mealType: json['meal_type'] ?? '',
      mealNumber: (json['meal_number'] as num?)?.toInt() ?? 1,
      primary: MealOption.fromJson(json['primary'] ?? {}),
      alternatives: json['alternatives'] != null
          ? (json['alternatives'] as List)
              .map((a) => MealOption.fromJson(a))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'meal_type': mealType,
    'meal_number': mealNumber,
    'primary': primary.toJson(),
    'alternatives': alternatives.map((a) => a.toJson()).toList(),
  };
}

/// Represents a single day's meal plan
class DailyPlan {
  final String dayOfWeek;
  final int dayNumber;
  final List<Meal> meals;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  const DailyPlan({
    required this.dayOfWeek,
    required this.dayNumber,
    required this.meals,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      dayOfWeek: json['day_of_week'] ?? '',
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      meals: json['meals'] != null
          ? (json['meals'] as List).map((m) => Meal.fromJson(m)).toList()
          : [],
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
      totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'day_number': dayNumber,
    'meals': meals.map((m) => m.toJson()).toList(),
    'total_calories': totalCalories,
    'total_protein_g': totalProteinG,
    'total_carbs_g': totalCarbsG,
    'total_fat_g': totalFatG,
  };
}

/// Macro targets calculated from user profile
class MacroTargets {
  final int dailyCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double proteinPercentage;
  final double carbsPercentage;
  final double fatPercentage;

  const MacroTargets({
    required this.dailyCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.proteinPercentage = 30,
    this.carbsPercentage = 40,
    this.fatPercentage = 30,
  });

  factory MacroTargets.fromJson(Map<String, dynamic> json) {
    return MacroTargets(
      dailyCalories: (json['daily_calories'] as num?)?.toInt() ?? 2000,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 150,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 200,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 67,
      proteinPercentage: (json['protein_percentage'] as num?)?.toDouble() ?? 30,
      carbsPercentage: (json['carbs_percentage'] as num?)?.toDouble() ?? 40,
      fatPercentage: (json['fat_percentage'] as num?)?.toDouble() ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_calories': dailyCalories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'protein_percentage': proteinPercentage,
    'carbs_percentage': carbsPercentage,
    'fat_percentage': fatPercentage,
  };
}

/// Complete weekly diet plan
class WeeklyDietPlan {
  final String? id;
  final MacroTargets macroTargets;
  final List<DailyPlan> days;
  final int mealsPerDay;
  final List<String> avoidedAllergens;
  final List<String> dietaryRestrictions;
  final DateTime generatedAt;
  final DateTime? weekStartDate;
  final bool isActive;

  const WeeklyDietPlan({
    this.id,
    required this.macroTargets,
    required this.days,
    required this.mealsPerDay,
    this.avoidedAllergens = const [],
    this.dietaryRestrictions = const [],
    required this.generatedAt,
    this.weekStartDate,
    this.isActive = true,
  });

  factory WeeklyDietPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyDietPlan(
      id: json['id'],
      macroTargets: MacroTargets.fromJson(json['macro_targets'] ?? {}),
      days: json['days'] != null
          ? (json['days'] as List).map((d) => DailyPlan.fromJson(d)).toList()
          : [],
      mealsPerDay: (json['meals_per_day'] as num?)?.toInt() ?? 3,
      avoidedAllergens: json['avoided_allergens'] != null
          ? List<String>.from(json['avoided_allergens'])
          : [],
      dietaryRestrictions: json['dietary_restrictions'] != null
          ? List<String>.from(json['dietary_restrictions'])
          : [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
      weekStartDate: json['week_start_date'] != null
          ? DateTime.parse(json['week_start_date'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'macro_targets': macroTargets.toJson(),
    'days': days.map((d) => d.toJson()).toList(),
    'meals_per_day': mealsPerDay,
    'avoided_allergens': avoidedAllergens,
    'dietary_restrictions': dietaryRestrictions,
    'generated_at': generatedAt.toIso8601String(),
    if (weekStartDate != null) 'week_start_date': weekStartDate!.toIso8601String(),
    'is_active': isActive,
  };

  /// Create a copy with new values
  WeeklyDietPlan copyWith({
    String? id,
    MacroTargets? macroTargets,
    List<DailyPlan>? days,
    int? mealsPerDay,
    List<String>? avoidedAllergens,
    List<String>? dietaryRestrictions,
    DateTime? generatedAt,
    DateTime? weekStartDate,
    bool? isActive,
  }) {
    return WeeklyDietPlan(
      id: id ?? this.id,
      macroTargets: macroTargets ?? this.macroTargets,
      days: days ?? this.days,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      avoidedAllergens: avoidedAllergens ?? this.avoidedAllergens,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      generatedAt: generatedAt ?? this.generatedAt,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get average daily totals
  int get averageDailyCalories {
    if (days.isEmpty) return 0;
    return (days.fold<int>(0, (sum, day) => sum + day.totalCalories) / days.length).round();
  }

  double get averageDailyProtein {
    if (days.isEmpty) return 0;
    return days.fold<double>(0, (sum, day) => sum + day.totalProteinG) / days.length;
  }

  double get averageDailyCarbs {
    if (days.isEmpty) return 0;
    return days.fold<double>(0, (sum, day) => sum + day.totalCarbsG) / days.length;
  }

  double get averageDailyFat {
    if (days.isEmpty) return 0;
    return days.fold<double>(0, (sum, day) => sum + day.totalFatG) / days.length;
  }
}
