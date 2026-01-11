import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/services/gemini_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = true;
  List<FoodAnalysisItem> _items = [];

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final results = await _geminiService.analyzeFoodImage(widget.imagePath);
      setState(() {
        _items = results.map((data) => FoodAnalysisItem(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
      }
    }
  }

  void _saveLogs() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    for (var item in _items) {
      final log = FoodLog(
        id: const Uuid().v4(),
        name: item.nameController.text,
        weightGrams: double.tryParse(item.weightController.text) ?? 0,
        calories: item.currentCalories,
        protein: item.currentProtein,
        carbs: item.currentCarbs,
        fat: item.currentFat,
        timestamp: DateTime.now(),
        mealType: 'Snack',
        imagePath: widget.imagePath,
      );
      provider.addLog(log);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Analysis Result',
                      style: TextStyle(
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50)),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FoodItemEditor(
                          item: _items[index],
                          onUpdate: () => setState(() {}),
                          onDelete: () => setState(() => _items.removeAt(index)),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !_isLoading
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _items.isEmpty ? null : _saveLogs,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Entries', style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }
}

class FoodAnalysisItem {
  final String originalName;
  final double baseWeight;
  final double baseCalories;
  final double baseProtein;
  final double baseCarbs;
  final double baseFat;

  late TextEditingController nameController;
  late TextEditingController weightController;

  FoodAnalysisItem(Map<String, dynamic> data)
      : originalName = data['name'],
        baseWeight = (data['weight_grams'] as num).toDouble(),
        baseCalories = (data['calories'] as num).toDouble(),
        baseProtein = (data['protein_g'] as num).toDouble(),
        baseCarbs = (data['carbs_g'] as num).toDouble(),
        baseFat = (data['fat_g'] as num).toDouble() {
    nameController = TextEditingController(text: originalName);
    weightController = TextEditingController(text: baseWeight.toStringAsFixed(0));
  }

  double get currentWeight => double.tryParse(weightController.text) ?? baseWeight;
  double get ratio => currentWeight / (baseWeight == 0 ? 1 : baseWeight);

  double get currentCalories => baseCalories * ratio;
  double get currentProtein => baseProtein * ratio;
  double get currentCarbs => baseCarbs * ratio;
  double get currentFat => baseFat * ratio;
}

class FoodItemEditor extends StatelessWidget {
  final FoodAnalysisItem item;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const FoodItemEditor({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.nameController,
                    decoration: const InputDecoration(labelText: 'Food Name'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.weightController,
                    decoration: const InputDecoration(labelText: 'Weight (g)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onUpdate(),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item.currentCalories.toInt()} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        'P: ${item.currentProtein.toStringAsFixed(1)}g  C: ${item.currentCarbs.toStringAsFixed(1)}g  F: ${item.currentFat.toStringAsFixed(1)}g',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
