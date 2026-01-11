import 'package:flutter_test/flutter_test.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

void main() {
  group('WeightUnit', () {
    test('toKg should convert lbs to kg correctly', () {
      expect(WeightUnit.lbs.toKg(100), closeTo(45.36, 0.01));
      expect(WeightUnit.kg.toKg(100), 100);
    });

    test('fromKg should convert kg to lbs correctly', () {
      expect(WeightUnit.lbs.fromKg(45.36), closeTo(100, 0.1));
      expect(WeightUnit.kg.fromKg(100), 100);
    });

    test('fromString should parse correctly', () {
      expect(WeightUnit.fromString('kg'), WeightUnit.kg);
      expect(WeightUnit.fromString('lbs'), WeightUnit.lbs);
      expect(WeightUnit.fromString(null), WeightUnit.kg);
      expect(WeightUnit.fromString('invalid'), WeightUnit.kg);
    });
  });

  group('HeightUnit', () {
    test('toCm should convert feet to cm correctly', () {
      expect(HeightUnit.ft.toCm(6), closeTo(182.88, 0.01));
      expect(HeightUnit.cm.toCm(180), 180);
    });

    test('fromCm should convert cm to feet correctly', () {
      expect(HeightUnit.ft.fromCm(182.88), closeTo(6, 0.01));
      expect(HeightUnit.cm.fromCm(180), 180);
    });

    test('fromString should parse correctly', () {
      expect(HeightUnit.fromString('cm'), HeightUnit.cm);
      expect(HeightUnit.fromString('ft'), HeightUnit.ft);
      expect(HeightUnit.fromString(null), HeightUnit.cm);
    });
  });

  group('ActivityLevel', () {
    test('multiplier should return correct TDEE multipliers', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
      expect(ActivityLevel.lightlyActive.multiplier, 1.375);
      expect(ActivityLevel.moderatelyActive.multiplier, 1.55);
      expect(ActivityLevel.veryActive.multiplier, 1.725);
      expect(ActivityLevel.extraActive.multiplier, 1.9);
    });

    test('fromString should parse db values correctly', () {
      expect(ActivityLevel.fromString('sedentary'), ActivityLevel.sedentary);
      expect(ActivityLevel.fromString('lightly_active'), ActivityLevel.lightlyActive);
      expect(ActivityLevel.fromString('moderately_active'), ActivityLevel.moderatelyActive);
      expect(ActivityLevel.fromString('very_active'), ActivityLevel.veryActive);
      expect(ActivityLevel.fromString('extra_active'), ActivityLevel.extraActive);
      expect(ActivityLevel.fromString(null), ActivityLevel.sedentary);
    });

    test('dbValue should return correct database values', () {
      expect(ActivityLevel.sedentary.dbValue, 'sedentary');
      expect(ActivityLevel.lightlyActive.dbValue, 'lightly_active');
      expect(ActivityLevel.moderatelyActive.dbValue, 'moderately_active');
      expect(ActivityLevel.veryActive.dbValue, 'very_active');
      expect(ActivityLevel.extraActive.dbValue, 'extra_active');
    });
  });

  group('CalorieGoal', () {
    test('calorieAdjustment should return correct values', () {
      expect(CalorieGoal.aggressiveCut.calorieAdjustment, -500);
      expect(CalorieGoal.moderateCut.calorieAdjustment, -300);
      expect(CalorieGoal.mildCut.calorieAdjustment, -200);
      expect(CalorieGoal.maintain.calorieAdjustment, 0);
      expect(CalorieGoal.mildBulk.calorieAdjustment, 200);
      expect(CalorieGoal.moderateBulk.calorieAdjustment, 300);
      expect(CalorieGoal.aggressiveBulk.calorieAdjustment, 500);
    });

    test('fromString should parse db values correctly', () {
      expect(CalorieGoal.fromString('aggressive_cut'), CalorieGoal.aggressiveCut);
      expect(CalorieGoal.fromString('moderate_cut'), CalorieGoal.moderateCut);
      expect(CalorieGoal.fromString('mild_cut'), CalorieGoal.mildCut);
      expect(CalorieGoal.fromString('maintain'), CalorieGoal.maintain);
      expect(CalorieGoal.fromString('mild_bulk'), CalorieGoal.mildBulk);
      expect(CalorieGoal.fromString('moderate_bulk'), CalorieGoal.moderateBulk);
      expect(CalorieGoal.fromString('aggressive_bulk'), CalorieGoal.aggressiveBulk);
      expect(CalorieGoal.fromString(null), CalorieGoal.maintain);
      expect(CalorieGoal.fromString('invalid'), CalorieGoal.maintain);
    });

    test('dbValue should return correct database values', () {
      expect(CalorieGoal.aggressiveCut.dbValue, 'aggressive_cut');
      expect(CalorieGoal.moderateCut.dbValue, 'moderate_cut');
      expect(CalorieGoal.mildCut.dbValue, 'mild_cut');
      expect(CalorieGoal.maintain.dbValue, 'maintain');
      expect(CalorieGoal.mildBulk.dbValue, 'mild_bulk');
      expect(CalorieGoal.moderateBulk.dbValue, 'moderate_bulk');
      expect(CalorieGoal.aggressiveBulk.dbValue, 'aggressive_bulk');
    });
  });

  group('UserProfile', () {
    final userProfile = UserProfile(
      uid: 'user123',
      email: 'test@example.com',
      heightCm: 180.0,
      weightKg: 75.0,
      age: 30,
      gender: 'Male',
      weightUnit: WeightUnit.kg,
      heightUnit: HeightUnit.cm,
      activityLevel: ActivityLevel.moderatelyActive,
      calorieGoal: CalorieGoal.moderateCut,
      preferredFoods: ['Chicken', 'Rice'],
      allergies: ['Peanuts'],
      dietaryRestrictions: ['Gluten-Free'],
      createdAt: DateTime(2023, 1, 1, 10, 0, 0),
    );

    test('toMap should return valid map', () {
      final map = userProfile.toMap();
      expect(map['uid'], 'user123');
      expect(map['email'], 'test@example.com');
      expect(map['heightCm'], 180.0);
      expect(map['weightKg'], 75.0);
      expect(map['weightUnit'], 'kg');
      expect(map['heightUnit'], 'cm');
      expect(map['activityLevel'], 'moderately_active');
      expect(map['calorieGoal'], 'moderate_cut');
      expect(map['preferredFoods'], ['Chicken', 'Rice']);
      expect(map['allergies'], ['Peanuts']);
      expect(map['dietaryRestrictions'], ['Gluten-Free']);
      expect(map['createdAt'], '2023-01-01T10:00:00.000');
    });

    test('fromMap should return valid object', () {
      final map = {
        'uid': 'user123',
        'email': 'test@example.com',
        'heightCm': 180.0,
        'weightKg': 75.0,
        'age': 30,
        'gender': 'Male',
        'weightUnit': 'lbs',
        'heightUnit': 'ft',
        'activityLevel': 'very_active',
        'calorieGoal': 'aggressive_cut',
        'preferredFoods': ['Salmon', 'Avocado'],
        'allergies': ['Shellfish', 'Eggs'],
        'dietaryRestrictions': ['Keto', 'Dairy-Free'],
        'createdAt': '2023-01-01T10:00:00.000',
      };

      final result = UserProfile.fromMap(map);
      expect(result.uid, 'user123');
      expect(result.email, 'test@example.com');
      expect(result.heightCm, 180.0);
      expect(result.weightUnit, WeightUnit.lbs);
      expect(result.heightUnit, HeightUnit.ft);
      expect(result.activityLevel, ActivityLevel.veryActive);
      expect(result.calorieGoal, CalorieGoal.aggressiveCut);
      expect(result.preferredFoods, ['Salmon', 'Avocado']);
      expect(result.allergies, ['Shellfish', 'Eggs']);
      expect(result.dietaryRestrictions, ['Keto', 'Dairy-Free']);
      expect(result.createdAt, DateTime(2023, 1, 1, 10, 0, 0));
    });

    test('fromMap should handle null optional fields', () {
      final map = {
        'uid': 'user123',
        'email': 'test@example.com',
      };

      final result = UserProfile.fromMap(map);
      expect(result.uid, 'user123');
      expect(result.heightCm, null);
      expect(result.weightUnit, WeightUnit.kg); // default
      expect(result.heightUnit, HeightUnit.cm); // default
      expect(result.activityLevel, null);
      expect(result.calorieGoal, CalorieGoal.maintain); // default
      expect(result.preferredFoods, isEmpty); // default empty
      expect(result.allergies, isEmpty); // default empty
      expect(result.dietaryRestrictions, isEmpty); // default empty
      expect(result.createdAt, null);
    });

    test('weightInPreferredUnit should return weight in user unit', () {
      final profileLbs = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        weightKg: 68.0,
        weightUnit: WeightUnit.lbs,
      );
      expect(profileLbs.weightInPreferredUnit, closeTo(149.9, 0.1));

      final profileKg = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        weightKg: 68.0,
        weightUnit: WeightUnit.kg,
      );
      expect(profileKg.weightInPreferredUnit, 68.0);
    });

    test('heightInPreferredUnit should return height in user unit', () {
      final profileFt = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 182.88,
        heightUnit: HeightUnit.ft,
      );
      expect(profileFt.heightInPreferredUnit, closeTo(6.0, 0.01));

      final profileCm = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        heightUnit: HeightUnit.cm,
      );
      expect(profileCm.heightInPreferredUnit, 180.0);
    });

    test('bmr should calculate correctly for male', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
      );
      // BMR = (10 * 75) + (6.25 * 180) - (5 * 30) + 5 = 750 + 1125 - 150 + 5 = 1730
      expect(profile.bmr, closeTo(1730, 0.1));
    });

    test('bmr should calculate correctly for female', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 165.0,
        weightKg: 60.0,
        age: 25,
        gender: 'Female',
      );
      // BMR = (10 * 60) + (6.25 * 165) - (5 * 25) - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      expect(profile.bmr, closeTo(1345.25, 0.1));
    });

    test('tdee should calculate correctly', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
      );
      // TDEE = BMR * 1.55 = 1730 * 1.55 = 2681.5
      expect(profile.tdee, closeTo(2681.5, 0.1));
    });

    test('tdee should be null if activity level is not set', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
        activityLevel: null,
      );
      expect(profile.tdee, null);
    });

    test('dailyCalorieTarget should calculate correctly with goal', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        calorieGoal: CalorieGoal.moderateCut,
      );
      // TDEE = 2681.5, goal = -300, target = 2382 (rounded)
      expect(profile.dailyCalorieTarget, closeTo(2382, 1));
    });

    test('dailyCalorieTarget should add calories for bulk goals', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
        activityLevel: ActivityLevel.moderatelyActive,
        calorieGoal: CalorieGoal.aggressiveBulk,
      );
      // TDEE = 2681.5, goal = +500, target = 3182 (rounded)
      expect(profile.dailyCalorieTarget, closeTo(3182, 1));
    });

    test('dailyCalorieTarget should be null if tdee is null', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        heightCm: 180.0,
        weightKg: 75.0,
        age: 30,
        gender: 'Male',
        activityLevel: null, // No activity level = no TDEE
      );
      expect(profile.dailyCalorieTarget, null);
    });

    test('copyWith should create a copy with updated fields', () {
      final updated = userProfile.copyWith(
        weightKg: 80.0,
        activityLevel: ActivityLevel.veryActive,
        calorieGoal: CalorieGoal.mildBulk,
        preferredFoods: ['Beef', 'Eggs'],
        allergies: ['Milk/Dairy'],
      );
      
      expect(updated.uid, userProfile.uid);
      expect(updated.email, userProfile.email);
      expect(updated.heightCm, userProfile.heightCm);
      expect(updated.weightKg, 80.0);
      expect(updated.activityLevel, ActivityLevel.veryActive);
      expect(updated.calorieGoal, CalorieGoal.mildBulk);
      expect(updated.preferredFoods, ['Beef', 'Eggs']);
      expect(updated.allergies, ['Milk/Dairy']);
    });

    test('dietaryInfoForAI should format dietary info for AI prompts', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
        preferredFoods: ['Chicken', 'Salmon'],
        allergies: ['Peanuts', 'Shellfish'],
        dietaryRestrictions: ['Keto', 'Dairy-Free'],
      );
      
      final info = profile.dietaryInfoForAI;
      expect(info, contains('Dietary restrictions: Keto, Dairy-Free'));
      expect(info, contains('Allergies (MUST AVOID): Peanuts, Shellfish'));
      expect(info, contains('Preferred foods: Chicken, Salmon'));
    });

    test('dietaryInfoForAI should return default message when empty', () {
      final profile = UserProfile(
        uid: 'user123',
        email: 'test@example.com',
      );
      
      expect(profile.dietaryInfoForAI, 'No dietary restrictions or preferences.');
    });
  });
}
