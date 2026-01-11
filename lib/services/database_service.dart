import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'food_logs';

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
}
