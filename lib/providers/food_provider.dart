import 'package:flutter/material.dart';
import '../models/food_log.dart';
import '../services/database_service.dart';

class FoodProvider with ChangeNotifier {
  List<FoodLog> _dailyLogs = [];
  final DatabaseService _db;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  FoodProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<FoodLog> get dailyLogs => _dailyLogs;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  double get totalCalories => _dailyLogs.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => _dailyLogs.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => _dailyLogs.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => _dailyLogs.fold(0, (sum, item) => sum + item.fat);

  Future<void> loadLogsForDate(DateTime date) async {
    _isLoading = true;
    _selectedDate = date;
    notifyListeners();
    
    try {
      _dailyLogs = await _db.getLogsForDate(date);
    } catch (e) {
      debugPrint('Error loading food logs: $e');
      _dailyLogs = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(FoodLog log) async {
    try {
      await _db.insertFoodLog(log);
      _dailyLogs.insert(0, log);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding food log: $e');
      rethrow;
    }
  }

  Future<void> removeLog(String id) async {
    try {
      await _db.deleteLog(id);
      _dailyLogs.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing food log: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadLogsForDate(_selectedDate);
  }

  void clearLogs() {
    _dailyLogs = [];
    notifyListeners();
  }

  /// Get logs grouped by meal type
  Map<String, List<FoodLog>> get logsByMealType {
    final grouped = <String, List<FoodLog>>{};
    for (final mealType in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
      grouped[mealType] = _dailyLogs.where((log) => log.mealType == mealType).toList();
    }
    return grouped;
  }

  /// Check which dates in the week have logs
  Future<Set<DateTime>> getLoggedDatesInWeek(DateTime weekStart) async {
    final loggedDates = <DateTime>{};
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      try {
        final logs = await _db.getLogsForDate(date);
        if (logs.isNotEmpty) {
          loggedDates.add(DateTime(date.year, date.month, date.day));
        }
      } catch (e) {
        debugPrint('Error checking logs for date: $e');
      }
    }
    return loggedDates;
  }

  /// Get totals for a specific meal type
  Map<String, double> getTotalsForMealType(String mealType) {
    final logs = _dailyLogs.where((log) => log.mealType == mealType);
    return {
      'calories': logs.fold(0.0, (sum, log) => sum + log.calories),
      'protein': logs.fold(0.0, (sum, log) => sum + log.protein),
      'carbs': logs.fold(0.0, (sum, log) => sum + log.carbs),
      'fat': logs.fold(0.0, (sum, log) => sum + log.fat),
    };
  }
}
