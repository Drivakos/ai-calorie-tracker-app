import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_log.dart';
import '../models/diet_plan.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'food_logs';
  static const String _dietPlansTable = 'diet_plans';

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> insertFoodLog(FoodLog log) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _supabase.from(_table).insert({
      'id': log.id,
      'user_id': _userId,
      'name': log.name,
      'weight_grams': log.weightGrams,
      'calories': log.calories,
      'protein': log.protein,
      'carbs': log.carbs,
      'fat': log.fat,
      'meal_type': log.mealType,
      'image_path': log.imagePath,
      'logged_at': log.timestamp.toIso8601String(),
    });
  }

  Future<List<FoodLog>> getLogsForDate(DateTime date) async {
    if (_userId == null) return [];

    // Get start and end of the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await _supabase
        .from(_table)
        .select()
        .eq('user_id', _userId!)
        .gte('logged_at', startOfDay.toIso8601String())
        .lt('logged_at', endOfDay.toIso8601String())
        .order('logged_at', ascending: false);

    return (data as List).map((item) => FoodLog(
      id: item['id'] as String,
      name: item['name'] as String,
      weightGrams: (item['weight_grams'] as num).toDouble(),
      calories: (item['calories'] as num).toDouble(),
      protein: (item['protein'] as num).toDouble(),
      carbs: (item['carbs'] as num).toDouble(),
      fat: (item['fat'] as num).toDouble(),
      timestamp: DateTime.parse(item['logged_at'] as String),
      mealType: item['meal_type'] as String,
      imagePath: item['image_path'] as String?,
    )).toList();
  }

  Future<void> deleteLog(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _supabase
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<void> updateLog(FoodLog log) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _supabase.from(_table).update({
      'name': log.name,
      'weight_grams': log.weightGrams,
      'calories': log.calories,
      'protein': log.protein,
      'carbs': log.carbs,
      'fat': log.fat,
      'meal_type': log.mealType,
      'image_path': log.imagePath,
      'logged_at': log.timestamp.toIso8601String(),
    }).eq('id', log.id).eq('user_id', _userId!);
  }

  // ==================== DIET PLANS ====================

  /// Save a new diet plan
  Future<WeeklyDietPlan> saveDietPlan(WeeklyDietPlan plan) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Deactivate previous active plans
    await _supabase
        .from(_dietPlansTable)
        .update({'is_active': false})
        .eq('user_id', _userId!)
        .eq('is_active', true);

    // Calculate week start date (Monday of current week)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final data = await _supabase.from(_dietPlansTable).insert({
      'user_id': _userId,
      'plan_data': jsonEncode({'days': plan.days.map((d) => d.toJson()).toList()}),
      'macro_targets': plan.macroTargets.toJson(),
      'meals_per_day': plan.mealsPerDay,
      'avoided_allergens': plan.avoidedAllergens,
      'dietary_restrictions': plan.dietaryRestrictions,
      'is_active': true,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'generated_at': plan.generatedAt.toIso8601String(),
    }).select().single();

    return _parseDietPlanFromDb(data);
  }

  /// Get the active diet plan for the current user
  Future<WeeklyDietPlan?> getActiveDietPlan() async {
    if (_userId == null) return null;

    try {
      final data = await _supabase
          .from(_dietPlansTable)
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return _parseDietPlanFromDb(data);
    } catch (e) {
      return null;
    }
  }

  /// Get all diet plans for the current user
  Future<List<WeeklyDietPlan>> getAllDietPlans() async {
    if (_userId == null) return [];

    final data = await _supabase
        .from(_dietPlansTable)
        .select()
        .eq('user_id', _userId!)
        .order('generated_at', ascending: false);

    return (data as List).map((item) => _parseDietPlanFromDb(item)).toList();
  }

  /// Get diet plan for a specific week
  Future<WeeklyDietPlan?> getDietPlanForWeek(DateTime weekStartDate) async {
    if (_userId == null) return null;

    final dateStr = weekStartDate.toIso8601String().split('T')[0];

    try {
      final data = await _supabase
          .from(_dietPlansTable)
          .select()
          .eq('user_id', _userId!)
          .eq('week_start_date', dateStr)
          .maybeSingle();

      if (data == null) return null;
      return _parseDietPlanFromDb(data);
    } catch (e) {
      return null;
    }
  }

  /// Update a diet plan
  Future<void> updateDietPlan(WeeklyDietPlan plan) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (plan.id == null) throw Exception('Diet plan has no ID');

    await _supabase.from(_dietPlansTable).update({
      'plan_data': jsonEncode({'days': plan.days.map((d) => d.toJson()).toList()}),
      'macro_targets': plan.macroTargets.toJson(),
      'meals_per_day': plan.mealsPerDay,
      'avoided_allergens': plan.avoidedAllergens,
      'dietary_restrictions': plan.dietaryRestrictions,
      'is_active': plan.isActive,
    }).eq('id', plan.id!).eq('user_id', _userId!);
  }

  /// Delete a diet plan
  Future<void> deleteDietPlan(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _supabase
        .from(_dietPlansTable)
        .delete()
        .eq('id', planId)
        .eq('user_id', _userId!);
  }

  /// Set a diet plan as active
  Future<void> setActiveDietPlan(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Deactivate all plans
    await _supabase
        .from(_dietPlansTable)
        .update({'is_active': false})
        .eq('user_id', _userId!);

    // Activate the selected plan
    await _supabase
        .from(_dietPlansTable)
        .update({'is_active': true})
        .eq('id', planId)
        .eq('user_id', _userId!);
  }

  /// Parse diet plan from database response
  WeeklyDietPlan _parseDietPlanFromDb(Map<String, dynamic> data) {
    final planData = data['plan_data'] is String 
        ? jsonDecode(data['plan_data']) 
        : data['plan_data'];
    
    final days = (planData['days'] as List?)
        ?.map((d) => DailyPlan.fromJson(d))
        .toList() ?? [];

    return WeeklyDietPlan(
      id: data['id'],
      macroTargets: MacroTargets.fromJson(data['macro_targets'] ?? {}),
      days: days,
      mealsPerDay: data['meals_per_day'] ?? 3,
      avoidedAllergens: data['avoided_allergens'] != null
          ? List<String>.from(data['avoided_allergens'])
          : [],
      dietaryRestrictions: data['dietary_restrictions'] != null
          ? List<String>.from(data['dietary_restrictions'])
          : [],
      generatedAt: data['generated_at'] != null
          ? DateTime.parse(data['generated_at'])
          : DateTime.now(),
      weekStartDate: data['week_start_date'] != null
          ? DateTime.parse(data['week_start_date'])
          : null,
      isActive: data['is_active'] ?? true,
    );
  }
}
