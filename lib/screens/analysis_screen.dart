import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import 'package:ai_calorie_tracker/models/parsed_food.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/services/gemini_service.dart';
import 'package:ai_calorie_tracker/services/usda_service.dart';
import 'package:ai_calorie_tracker/widgets/usda_search_sheet.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final GeminiService _geminiService = GeminiService();
  final UsdaService _usdaService = UsdaService();
  bool _isLoading = true;
  List<ParsedFoodItem> _items = [];
  String? _selectedMealType;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _selectedMealType = 'Snack';
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      // Use the new structured analysis with USDA enrichment
      final results = await _geminiService.analyzeFoodImageStructured(widget.imagePath);
      setState(() {
        _items = results;
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

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _searchUsdaForItem(int index) async {
    final item = _items[index];
    final result = await UsdaSearchSheet.show(
      context,
      initialQuery: item.aiGuessedName,
    );

    if (result != null) {
      final macros = result.calculateForPortion(item.estimatedGrams);
      final updatedItem = item.withUsdaData(
        fdcId: result.fdcId,
        foodName: result.description,
        brandName: result.brandName,
        calories: macros['calories'] ?? 0,
        protein: macros['protein'] ?? 0,
        carbs: macros['carbs'] ?? 0,
        fat: macros['fat'] ?? 0,
        fiber: macros['fiber'],
        sodium: macros['sodium'],
        sugar: macros['sugar'],
      );

      setState(() {
        _items[index] = updatedItem;
      });
    }
  }

  void _updateItemGrams(int index, double newGrams) {
    final item = _items[index];
    
    if (item.isFromUsda && item.usdaFdcId != null) {
      _usdaService.getFoodById(item.usdaFdcId!).then((usdaFood) {
        if (usdaFood != null && mounted) {
          setState(() {
            _items[index] = item.withUpdatedPortion(
              newGrams: newGrams,
              caloriesPer100g: usdaFood.caloriesPer100g,
              proteinPer100g: usdaFood.proteinPer100g,
              carbsPer100g: usdaFood.carbsPer100g,
              fatPer100g: usdaFood.fatPer100g,
              fiberPer100g: usdaFood.fiberPer100g,
              sodiumPer100g: usdaFood.sodiumPer100g,
              sugarPer100g: usdaFood.sugarPer100g,
            );
          });
        }
      });
    } else {
      final ratio = newGrams / (item.estimatedGrams == 0 ? 100 : item.estimatedGrams);
      setState(() {
        _items[index] = ParsedFoodItem(
          id: item.id,
          aiGuessedName: item.aiGuessedName,
          estimatedQuantity: item.estimatedQuantity,
          estimatedUnit: item.estimatedUnit,
          estimatedGrams: newGrams,
          usdaFdcId: item.usdaFdcId,
          usdaFoodName: item.usdaFoodName,
          usdaBrandName: item.usdaBrandName,
          calories: item.calories * ratio,
          protein: item.protein * ratio,
          carbs: item.carbs * ratio,
          fat: item.fat * ratio,
          fiber: item.fiber != null ? item.fiber! * ratio : null,
          sodium: item.sodium != null ? item.sodium! * ratio : null,
          sugar: item.sugar != null ? item.sugar! * ratio : null,
          aiConfidence: item.aiConfidence,
          isVerified: item.isVerified,
          isFromUsda: item.isFromUsda,
        );
      });
    }
  }

  void _saveLogs() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    for (var item in _items) {
      final log = FoodLog(
        id: const Uuid().v4(),
        name: item.displayName,
        weightGrams: item.estimatedGrams,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        timestamp: DateTime.now(),
        mealType: _selectedMealType ?? 'Snack',
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
                      'AI + USDA for accurate nutrition',
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
                                            'AI + USDA',
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
                                    const SizedBox(width: 8),
                                    if (_items.any((i) => i.isFromUsda))
                                      ShadBadge(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.circleCheck, size: 10),
                                            const SizedBox(width: 4),
                                            Text('${_items.where((i) => i.isFromUsda).length} verified'),
                                          ],
                                        ),
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
                  
                  // Meal Type Selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text('Meal: ', style: theme.textTheme.p),
                          const SizedBox(width: 8),
                          ShadSelect<String>(
                            placeholder: const Text('Select meal'),
                            options: _mealTypes.map((type) => ShadOption(
                              value: type,
                              child: Text(type),
                            )).toList(),
                            selectedOptionBuilder: (context, value) => Text(value),
                            onChanged: (value) => setState(() => _selectedMealType = value),
                            initialValue: _selectedMealType,
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
                            child: _FoodItemCard(
                              item: _items[index],
                              theme: theme,
                              onRemove: () => _removeItem(index),
                              onSearchUsda: () => _searchUsdaForItem(index),
                              onGramsChanged: (grams) => _updateItemGrams(index, grams),
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
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color.lerp(theme.colorScheme.primary, Colors.white, 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTotalStat(
                                'Calories',
                                '${_items.fold<double>(0, (sum, item) => sum + item.calories).toInt()}',
                                'kcal',
                                theme,
                              ),
                              _buildTotalStat(
                                'Protein',
                                '${_items.fold<double>(0, (sum, item) => sum + item.protein).toInt()}',
                                'g',
                                theme,
                              ),
                              _buildTotalStat(
                                'Carbs',
                                '${_items.fold<double>(0, (sum, item) => sum + item.carbs).toInt()}',
                                'g',
                                theme,
                              ),
                              _buildTotalStat(
                                'Fat',
                                '${_items.fold<double>(0, (sum, item) => sum + item.fat).toInt()}',
                                'g',
                                theme,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ShadButton(
                      onPressed: _items.isEmpty ? null : _saveLogs,
                      size: ShadButtonSize.lg,
                      width: double.infinity,
                      leading: const Icon(LucideIcons.check, size: 20),
                      child: Text(_items.isEmpty ? 'No items to save' : 'Save ${_items.length} ${_items.length == 1 ? 'Item' : 'Items'}'),
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
        Text(label, style: theme.textTheme.muted.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(unit, style: theme.textTheme.muted.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _FoodItemCard extends StatefulWidget {
  final ParsedFoodItem item;
  final ShadThemeData theme;
  final VoidCallback onRemove;
  final VoidCallback onSearchUsda;
  final Function(double) onGramsChanged;

  const _FoodItemCard({
    required this.item,
    required this.theme,
    required this.onRemove,
    required this.onSearchUsda,
    required this.onGramsChanged,
  });

  @override
  State<_FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<_FoodItemCard> {
  late TextEditingController _gramsController;

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(
      text: widget.item.estimatedGrams.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _FoodItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.estimatedGrams != widget.item.estimatedGrams) {
      _gramsController.text = widget.item.estimatedGrams.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = widget.theme;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isFromUsda
                      ? Color.lerp(theme.colorScheme.primary, Colors.white, 0.85)
                      : Color.lerp(const Color(0xFFF97316), Colors.white, 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isFromUsda ? LucideIcons.database : LucideIcons.sparkles,
                  size: 20,
                  color: item.isFromUsda
                      ? theme.colorScheme.primary
                      : const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.isFromUsda)
                          ShadBadge(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.circleCheck, size: 10),
                                const SizedBox(width: 4),
                                const Text('USDA'),
                              ],
                            ),
                          )
                        else
                          ShadBadge.secondary(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.sparkles, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  item.aiConfidence != null
                                      ? 'AI ${(item.aiConfidence! * 100).round()}%'
                                      : 'AI Estimate',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: widget.onRemove,
                child: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Portion and macros row
          Row(
            children: [
              SizedBox(
                width: 100,
                child: ShadInput(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('g', style: theme.textTheme.muted),
                  ),
                  onChanged: (value) {
                    final grams = double.tryParse(value);
                    if (grams != null && grams > 0) {
                      widget.onGramsChanged(grams);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMacroBadge('${item.calories.round()}', 'kcal', theme.colorScheme.primary),
                    _buildMacroBadge('${item.protein.round()}g', 'P', const Color(0xFF3B82F6)),
                    _buildMacroBadge('${item.carbs.round()}g', 'C', const Color(0xFFF97316)),
                    _buildMacroBadge('${item.fat.round()}g', 'F', const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
          
          if (!item.isFromUsda) ...[
            const SizedBox(height: 12),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: widget.onSearchUsda,
              leading: const Icon(LucideIcons.search, size: 14),
              child: const Text('Search USDA'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            ' $label',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
