import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'user_profiles';

  Future<void> saveUserProfile(UserProfile profile) async {
    await _supabase.from(_table).upsert({
      'id': profile.uid,
      'email': profile.email,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'age': profile.age,
      'gender': profile.gender,
      'weight_unit': profile.weightUnit.name,
      'height_unit': profile.heightUnit.name,
      'activity_level': profile.activityLevel?.dbValue,
      'calorie_goal': profile.calorieGoal.dbValue,
      'preferred_foods': profile.preferredFoods,
      'allergies': profile.allergies,
      'dietary_restrictions': profile.dietaryRestrictions,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final data = await _supabase
          .from(_table)
          .select()
          .eq('id', uid)
          .maybeSingle();
      
      if (data != null) {
        return UserProfile(
          uid: data['id'] as String,
          email: data['email'] as String,
          heightCm: (data['height_cm'] as num?)?.toDouble(),
          weightKg: (data['weight_kg'] as num?)?.toDouble(),
          age: data['age'] as int?,
          gender: data['gender'] as String?,
          weightUnit: WeightUnit.fromString(data['weight_unit'] as String?),
          heightUnit: HeightUnit.fromString(data['height_unit'] as String?),
          activityLevel: data['activity_level'] != null
              ? ActivityLevel.fromString(data['activity_level'] as String?)
              : null,
          calorieGoal: CalorieGoal.fromString(data['calorie_goal'] as String?),
          preferredFoods: _parseStringList(data['preferred_foods']),
          allergies: _parseStringList(data['allergies']),
          dietaryRestrictions: _parseStringList(data['dietary_restrictions']),
          createdAt: data['created_at'] != null 
              ? DateTime.tryParse(data['created_at'] as String)
              : null,
        );
      }
      return null;
    } catch (e) {
      // Profile might not exist yet (will be created by trigger)
      return null;
    }
  }

  /// Check if user has completed profile setup
  Future<bool> hasCompletedProfile(String uid) async {
    final profile = await getUserProfile(uid);
    return profile != null && 
           profile.heightCm != null && 
           profile.weightKg != null &&
           profile.activityLevel != null;
  }

  /// Helper to parse PostgreSQL text arrays
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    return [];
  }
}
