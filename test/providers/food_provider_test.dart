import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late FoodProvider foodProvider;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    foodProvider = FoodProvider(db: mockDatabaseService);
  });

  group('FoodProvider', () {
    final foodLog = FoodLog(
      id: '1',
      name: 'Banana',
      weightGrams: 100,
      calories: 89,
      protein: 1.1,
      carbs: 22.8,
      fat: 0.3,
      timestamp: DateTime.now(),
      mealType: 'Snack',
    );

    test('initial state should be empty', () {
      expect(foodProvider.dailyLogs, isEmpty);
      expect(foodProvider.totalCalories, 0.0);
    });

    test('loadLogsForDate should fetch logs from DB and update state', () async {
      when(mockDatabaseService.getLogsForDate(any))
          .thenAnswer((_) async => [foodLog]);

      await foodProvider.loadLogsForDate(DateTime.now());

      expect(foodProvider.dailyLogs.length, 1);
      expect(foodProvider.dailyLogs.first, foodLog);
      verify(mockDatabaseService.getLogsForDate(any)).called(1);
    });

    test('addLog should insert to DB and update state', () async {
      when(mockDatabaseService.insertFoodLog(any)).thenAnswer((_) async {});

      await foodProvider.addLog(foodLog);

      expect(foodProvider.dailyLogs.length, 1);
      expect(foodProvider.totalCalories, 89.0);
      verify(mockDatabaseService.insertFoodLog(foodLog)).called(1);
    });

    test('removeLog should delete from DB and update state', () async {
      // Setup initial state
      when(mockDatabaseService.insertFoodLog(any)).thenAnswer((_) async {});
      when(mockDatabaseService.deleteLog(any)).thenAnswer((_) async {});

      await foodProvider.addLog(foodLog);
      expect(foodProvider.dailyLogs.length, 1);

      await foodProvider.removeLog('1');
      expect(foodProvider.dailyLogs, isEmpty);
      verify(mockDatabaseService.deleteLog('1')).called(1);
    });
  });
}
