import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Error analyzing image: $e'),
          ),
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
    final theme = ShadTheme.of(context);
    
    return Scaffold(
      body: ShadToaster(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color.lerp(theme.colorScheme.primary, Colors.white, 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Analyzing your meal...', style: theme.textTheme.large),
                    const SizedBox(height: 8),
                    Text(
                      'AI is identifying food items',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Image Header
                  SliverAppBar(
                    expandedHeight: 280.0,
                    pinned: true,
                    backgroundColor: theme.colorScheme.background,
                    surfaceTintColor: Colors.transparent,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ShadButton.secondary(
                        size: ShadButtonSize.sm,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(LucideIcons.arrowLeft, size: 20),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: theme.colorScheme.muted,
                                    child: Icon(
                                      LucideIcons.imageOff,
                                      size: 50,
                                      color: theme.colorScheme.mutedForeground,
                                    ),
                                  ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.sparkles,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI Analysis',
                                            style: theme.textTheme.small.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ShadBadge.secondary(
                                      child: Text('${_items.length} items found'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Analysis Result',
                                  style: theme.textTheme.h3.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Food Items
                  SliverPadding(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FoodItemEditor(
                              item: _items[index],
                              theme: theme,
                              onUpdate: () => setState(() {}),
                              onDelete: () => setState(() => _items.removeAt(index)),
                            ),
                          );
                        },
                        childCount: _items.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: !_isLoading
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.border,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Summary
                    if (_items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTotalStat(
                              'Calories',
                              '${_items.fold<double>(0, (sum, item) => sum + item.currentCalories).toInt()}',
                              'kcal',
                              theme,
                            ),
                            _buildTotalStat(
                              'Protein',
                              '${_items.fold<double>(0, (sum, item) => sum + item.currentProtein).toInt()}',
                              'g',
                              theme,
                            ),
                            _buildTotalStat(
                              'Carbs',
                              '${_items.fold<double>(0, (sum, item) => sum + item.currentCarbs).toInt()}',
                              'g',
                              theme,
                            ),
                            _buildTotalStat(
                              'Fat',
                              '${_items.fold<double>(0, (sum, item) => sum + item.currentFat).toInt()}',
                              'g',
                              theme,
                            ),
                          ],
                        ),
                      ),
                    ShadButton(
                      onPressed: _items.isEmpty ? null : _saveLogs,
                      size: ShadButtonSize.lg,
                      width: double.infinity,
                      leading: const Icon(LucideIcons.check, size: 20),
                      child: Text(_items.isEmpty ? 'No items to save' : 'Save Entries'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTotalStat(String label, String value, String unit, ShadThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.muted),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(unit, style: theme.textTheme.muted),
          ],
        ),
      ],
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
  final ShadThemeData theme;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const FoodItemEditor({
    super.key,
    required this.item,
    required this.theme,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color.lerp(theme.colorScheme.primary, Colors.white, 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.utensils,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadInput(
                  controller: item.nameController,
                  placeholder: const Text('Food name'),
                ),
              ),
              const SizedBox(width: 8),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: onDelete,
                child: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: item.weightController,
                  placeholder: const Text('Weight'),
                  keyboardType: TextInputType.number,
                  leading: const Icon(LucideIcons.scale, size: 16),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text('g', style: theme.textTheme.muted),
                  ),
                  onChanged: (_) => onUpdate(),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color.lerp(theme.colorScheme.primary, Colors.white, 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.currentCalories.toInt()} kcal',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMacroBadge('P', item.currentProtein, const Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        _buildMacroBadge('C', item.currentCarbs, const Color(0xFFF97316)),
                        const SizedBox(width: 6),
                        _buildMacroBadge('F', item.currentFat, const Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String letter, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$letter: ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
