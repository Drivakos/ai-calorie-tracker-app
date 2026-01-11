/// Enum for weight unit preference
enum WeightUnit {
  kg,
  lbs;

  String get label => switch (this) {
    WeightUnit.kg => 'kg',
    WeightUnit.lbs => 'lbs',
  };

  /// Convert a value from this unit to kg
  double toKg(double value) => switch (this) {
    WeightUnit.kg => value,
    WeightUnit.lbs => value * 0.453592,
  };

  /// Convert a value from kg to this unit
  double fromKg(double value) => switch (this) {
    WeightUnit.kg => value,
    WeightUnit.lbs => value / 0.453592,
  };

  static WeightUnit fromString(String? value) {
    return WeightUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WeightUnit.kg,
    );
  }
}

/// Enum for height unit preference
enum HeightUnit {
  cm,
  ft;

  String get label => switch (this) {
    HeightUnit.cm => 'cm',
    HeightUnit.ft => 'ft/in',
  };

  /// Convert a value from this unit to cm
  double toCm(double value) => switch (this) {
    HeightUnit.cm => value,
    HeightUnit.ft => value * 30.48, // feet to cm (inches handled separately)
  };

  /// Convert a value from cm to this unit
  double fromCm(double value) => switch (this) {
    HeightUnit.cm => value,
    HeightUnit.ft => value / 30.48,
  };

  static HeightUnit fromString(String? value) {
    return HeightUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HeightUnit.cm,
    );
  }
}

/// Enum for activity level (for TDEE calculation)
enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive;

  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.lightlyActive => 'Lightly Active',
    ActivityLevel.moderatelyActive => 'Moderately Active',
    ActivityLevel.veryActive => 'Very Active',
    ActivityLevel.extraActive => 'Extra Active',
  };

  String get description => switch (this) {
    ActivityLevel.sedentary => 'Little or no exercise, desk job',
    ActivityLevel.lightlyActive => 'Light exercise 1-3 days/week',
    ActivityLevel.moderatelyActive => 'Moderate exercise 3-5 days/week',
    ActivityLevel.veryActive => 'Hard exercise 6-7 days/week',
    ActivityLevel.extraActive => 'Very hard exercise, physical job',
  };

  /// Activity multiplier for TDEE calculation
  double get multiplier => switch (this) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.lightlyActive => 1.375,
    ActivityLevel.moderatelyActive => 1.55,
    ActivityLevel.veryActive => 1.725,
    ActivityLevel.extraActive => 1.9,
  };

  String get dbValue => switch (this) {
    ActivityLevel.sedentary => 'sedentary',
    ActivityLevel.lightlyActive => 'lightly_active',
    ActivityLevel.moderatelyActive => 'moderately_active',
    ActivityLevel.veryActive => 'very_active',
    ActivityLevel.extraActive => 'extra_active',
  };

  static ActivityLevel fromString(String? value) {
    return switch (value) {
      'sedentary' => ActivityLevel.sedentary,
      'lightly_active' => ActivityLevel.lightlyActive,
      'moderately_active' => ActivityLevel.moderatelyActive,
      'very_active' => ActivityLevel.veryActive,
      'extra_active' => ActivityLevel.extraActive,
      _ => ActivityLevel.sedentary,
    };
  }
}

/// Enum for calorie goal (relative to TDEE maintenance)
enum CalorieGoal {
  aggressiveCut,
  moderateCut,
  mildCut,
  maintain,
  mildBulk,
  moderateBulk,
  aggressiveBulk;

  String get label => switch (this) {
    CalorieGoal.aggressiveCut => 'Aggressive Cut',
    CalorieGoal.moderateCut => 'Moderate Cut',
    CalorieGoal.mildCut => 'Mild Cut',
    CalorieGoal.maintain => 'Maintain Weight',
    CalorieGoal.mildBulk => 'Mild Bulk',
    CalorieGoal.moderateBulk => 'Moderate Bulk',
    CalorieGoal.aggressiveBulk => 'Aggressive Bulk',
  };

  String get description => switch (this) {
    CalorieGoal.aggressiveCut => 'Lose ~0.5 kg/week',
    CalorieGoal.moderateCut => 'Lose ~0.3 kg/week',
    CalorieGoal.mildCut => 'Lose ~0.2 kg/week',
    CalorieGoal.maintain => 'Stay at current weight',
    CalorieGoal.mildBulk => 'Gain ~0.2 kg/week',
    CalorieGoal.moderateBulk => 'Gain ~0.3 kg/week',
    CalorieGoal.aggressiveBulk => 'Gain ~0.5 kg/week',
  };

  /// Calorie adjustment from maintenance TDEE
  int get calorieAdjustment => switch (this) {
    CalorieGoal.aggressiveCut => -500,
    CalorieGoal.moderateCut => -300,
    CalorieGoal.mildCut => -200,
    CalorieGoal.maintain => 0,
    CalorieGoal.mildBulk => 200,
    CalorieGoal.moderateBulk => 300,
    CalorieGoal.aggressiveBulk => 500,
  };

  String get dbValue => switch (this) {
    CalorieGoal.aggressiveCut => 'aggressive_cut',
    CalorieGoal.moderateCut => 'moderate_cut',
    CalorieGoal.mildCut => 'mild_cut',
    CalorieGoal.maintain => 'maintain',
    CalorieGoal.mildBulk => 'mild_bulk',
    CalorieGoal.moderateBulk => 'moderate_bulk',
    CalorieGoal.aggressiveBulk => 'aggressive_bulk',
  };

  static CalorieGoal fromString(String? value) {
    return switch (value) {
      'aggressive_cut' => CalorieGoal.aggressiveCut,
      'moderate_cut' => CalorieGoal.moderateCut,
      'mild_cut' => CalorieGoal.mildCut,
      'maintain' => CalorieGoal.maintain,
      'mild_bulk' => CalorieGoal.mildBulk,
      'moderate_bulk' => CalorieGoal.moderateBulk,
      'aggressive_bulk' => CalorieGoal.aggressiveBulk,
      _ => CalorieGoal.maintain,
    };
  }
}

/// Common dietary restrictions for quick selection
class DietaryRestriction {
  static const String vegetarian = 'Vegetarian';
  static const String vegan = 'Vegan';
  static const String pescatarian = 'Pescatarian';
  static const String glutenFree = 'Gluten-Free';
  static const String dairyFree = 'Dairy-Free';
  static const String nutFree = 'Nut-Free';
  static const String halal = 'Halal';
  static const String kosher = 'Kosher';
  static const String keto = 'Keto';
  static const String paleo = 'Paleo';
  static const String lowCarb = 'Low Carb';
  static const String lowFat = 'Low Fat';

  static List<String> get allRestrictions => [
    vegetarian,
    vegan,
    pescatarian,
    glutenFree,
    dairyFree,
    nutFree,
    halal,
    kosher,
    keto,
    paleo,
    lowCarb,
    lowFat,
  ];
}

/// Common food allergies for quick selection
class FoodAllergy {
  static const String peanuts = 'Peanuts';
  static const String treeNuts = 'Tree Nuts';
  static const String milk = 'Milk/Dairy';
  static const String eggs = 'Eggs';
  static const String wheat = 'Wheat';
  static const String soy = 'Soy';
  static const String fish = 'Fish';
  static const String shellfish = 'Shellfish';
  static const String sesame = 'Sesame';
  static const String mustard = 'Mustard';
  static const String celery = 'Celery';
  static const String lupin = 'Lupin';
  static const String molluscs = 'Molluscs';
  static const String sulphites = 'Sulphites';

  static List<String> get allAllergies => [
    peanuts,
    treeNuts,
    milk,
    eggs,
    wheat,
    soy,
    fish,
    shellfish,
    sesame,
    mustard,
    celery,
    lupin,
    molluscs,
    sulphites,
  ];
}

class UserProfile {
  final String uid;
  final String email;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final String? gender; // 'Male', 'Female', 'Other'
  final WeightUnit weightUnit;
  final HeightUnit heightUnit;
  final ActivityLevel? activityLevel;
  final CalorieGoal calorieGoal;
  final List<String> preferredFoods;
  final List<String> allergies;
  final List<String> dietaryRestrictions;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.heightCm,
    this.weightKg,
    this.age,
    this.gender,
    this.weightUnit = WeightUnit.kg,
    this.heightUnit = HeightUnit.cm,
    this.activityLevel,
    this.calorieGoal = CalorieGoal.maintain,
    this.preferredFoods = const [],
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.createdAt,
  });

  /// Get weight in user's preferred unit
  double? get weightInPreferredUnit {
    if (weightKg == null) return null;
    return weightUnit.fromKg(weightKg!);
  }

  /// Get height in user's preferred unit
  double? get heightInPreferredUnit {
    if (heightCm == null) return null;
    return heightUnit.fromCm(heightCm!);
  }

  /// Calculate BMR using Mifflin-St Jeor equation
  double? get bmr {
    if (heightCm == null || weightKg == null || age == null || gender == null) {
      return null;
    }

    // Mifflin-St Jeor Equation
    if (gender == 'Male') {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) + 5;
    } else {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) - 161;
    }
  }

  /// Calculate TDEE (Total Daily Energy Expenditure) - maintenance calories
  double? get tdee {
    if (bmr == null || activityLevel == null) return null;
    return bmr! * activityLevel!.multiplier;
  }

  /// Calculate daily calorie target based on TDEE and goal
  int? get dailyCalorieTarget {
    if (tdee == null) return null;
    return (tdee! + calorieGoal.calorieAdjustment).round();
  }

  /// Get a formatted string of dietary info for AI prompts
  String get dietaryInfoForAI {
    final parts = <String>[];
    
    if (dietaryRestrictions.isNotEmpty) {
      parts.add('Dietary restrictions: ${dietaryRestrictions.join(", ")}');
    }
    if (allergies.isNotEmpty) {
      parts.add('Allergies (MUST AVOID): ${allergies.join(", ")}');
    }
    if (preferredFoods.isNotEmpty) {
      parts.add('Preferred foods: ${preferredFoods.join(", ")}');
    }
    
    return parts.isEmpty ? 'No dietary restrictions or preferences.' : parts.join('. ');
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'age': age,
      'gender': gender,
      'weightUnit': weightUnit.name,
      'heightUnit': heightUnit.name,
      'activityLevel': activityLevel?.dbValue,
      'calorieGoal': calorieGoal.dbValue,
      'preferredFoods': preferredFoods,
      'allergies': allergies,
      'dietaryRestrictions': dietaryRestrictions,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      heightCm: map['heightCm']?.toDouble(),
      weightKg: map['weightKg']?.toDouble(),
      age: map['age'],
      gender: map['gender'],
      weightUnit: WeightUnit.fromString(map['weightUnit']),
      heightUnit: HeightUnit.fromString(map['heightUnit']),
      activityLevel: map['activityLevel'] != null 
          ? ActivityLevel.fromString(map['activityLevel'])
          : null,
      calorieGoal: CalorieGoal.fromString(map['calorieGoal']),
      preferredFoods: _parseStringList(map['preferredFoods']),
      allergies: _parseStringList(map['allergies']),
      dietaryRestrictions: _parseStringList(map['dietaryRestrictions']),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    return [];
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    double? heightCm,
    double? weightKg,
    int? age,
    String? gender,
    WeightUnit? weightUnit,
    HeightUnit? heightUnit,
    ActivityLevel? activityLevel,
    CalorieGoal? calorieGoal,
    List<String>? preferredFoods,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      activityLevel: activityLevel ?? this.activityLevel,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      preferredFoods: preferredFoods ?? this.preferredFoods,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
