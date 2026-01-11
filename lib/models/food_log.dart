
class FoodLog {
  final String id;
  final String name;
  final double weightGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final String? imagePath;

  FoodLog({
    required this.id,
    required this.name,
    required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    required this.mealType,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weightGrams': weightGrams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': timestamp.toIso8601String(),
      'mealType': mealType,
      'imagePath': imagePath,
    };
  }

  factory FoodLog.fromMap(Map<String, dynamic> map) {
    return FoodLog(
      id: map['id'],
      name: map['name'],
      weightGrams: map['weightGrams'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      timestamp: DateTime.parse(map['timestamp']),
      mealType: map['mealType'],
      imagePath: map['imagePath'],
    );
  }
}
