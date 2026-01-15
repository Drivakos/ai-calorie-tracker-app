import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import 'package:ai_calorie_tracker/models/parsed_food.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/services/gemini_service.dart';
import 'package:ai_calorie_tracker/widgets/usda_search_sheet.dart';

class SmartEntryScreen extends StatefulWidget {
  final String? initialMealType;
  
  const SmartEntryScreen({super.key, this.initialMealType});

  @override
  State<SmartEntryScreen> createState() => _SmartEntryScreenState();
}

class _SmartEntryScreenState extends State<SmartEntryScreen> {
  final GeminiService _geminiService = GeminiService();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  
  List<ParsedFoodItem> _items = [];
  bool _isLoading = false;
  String? _selectedMealType;
  String? _imagePath;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? _mealTypes[0];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _parseInput() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    // For text input, go directly to USDA search - no AI needed
    final result = await UsdaSearchSheet.show(
      context,
      initialQuery: input,
    );

    if (result != null && mounted) {
      // Calculate macros for a default portion (100g)
      const defaultGrams = 100.0;
      final macros = result.calculateForPortion(defaultGrams);
      
      final item = ParsedFoodItem(
        id: const Uuid().v4(),
        aiGuessedName: input,
        estimatedQuantity: 1,
        estimatedUnit: 'serving',
        estimatedGrams: defaultGrams,
        usdaFdcId: result.fdcId,
        usdaFoodName: result.description,
        usdaBrandName: result.brandName,
        calories: macros['calories'] ?? 0,
        protein: macros['protein'] ?? 0,
        carbs: macros['carbs'] ?? 0,
        fat: macros['fat'] ?? 0,
        fiber: macros['fiber'],
        sodium: macros['sodium'],
        sugar: macros['sugar'],
        isFromUsda: true,
        isVerified: true,
      );
      
      setState(() {
        _items.add(item);
        _inputController.clear();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _imagePath = image.path;
    });

    try {
      final items = await _geminiService.analyzeFoodImageStructured(image.path);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Failed to analyze image: $e'),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _imagePath = image.path;
    });

    try {
      final items = await _geminiService.analyzeFoodImageStructured(image.path);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text('Failed to analyze image: $e'),
        ),
      );
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
      // Update the item with USDA data
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
    final oldGrams = item.estimatedGrams;
    
    // Avoid division by zero
    if (oldGrams == 0 || newGrams == oldGrams) return;
    
    // Simple ratio calculation - works for both USDA and AI data
    // No API call needed since we just scale existing values
    final ratio = newGrams / oldGrams;
    
    setState(() {
      _items[index] = ParsedFoodItem(
        id: item.id,
        aiGuessedName: item.aiGuessedName,
        aiDescription: item.aiDescription,
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
        isFromUsda: item.isFromUsda,
        isVerified: item.isVerified,
      );
    });
  }

  void _saveLogs() {
    if (_items.isEmpty) return;

    final provider = Provider.of<FoodProvider>(context, listen: false);
    
    for (final item in _items) {
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
        imagePath: _imagePath,
      );
      provider.addLog(log);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Log Food', style: theme.textTheme.h4),
        centerTitle: true,
        leading: ShadButton.ghost(
          size: ShadButtonSize.sm,
          onPressed: () => Navigator.pop(context),
          child: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.foreground),
        ),
      ),
      body: ShadToaster(
        child: Column(
          children: [
            // Input Section
            _buildInputSection(theme),
            
            // Results Section
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(theme)
                  : _items.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildResultsList(theme),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _items.isNotEmpty && !_isLoading
          ? _buildBottomBar(theme)
          : null,
    );
  }

  Widget _buildInputSection(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Input
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _inputController,
                  focusNode: _focusNode,
                  placeholder: const Text('What did you eat? (e.g., 2 eggs with toast)'),
                  leading: Icon(
                    LucideIcons.messageSquare,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  onSubmitted: (_) => _parseInput(),
                ),
              ),
              const SizedBox(width: 8),
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: _inputController.text.trim().isNotEmpty ? _parseInput : null,
                child: const Icon(LucideIcons.sparkles, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image options & Meal Type
          Row(
            children: [
              // Camera button
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: _pickImage,
                leading: const Icon(LucideIcons.camera, size: 14),
                child: const Text('Camera'),
              ),
              const SizedBox(width: 8),
              
              // Gallery button
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: _pickFromGallery,
                leading: const Icon(LucideIcons.image, size: 14),
                child: const Text('Gallery'),
              ),
              
              const Spacer(),
              
              // Meal type selector
              ShadSelect<String>(
                placeholder: const Text('Meal'),
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
        ],
      ),
    );
  }

  Widget _buildLoadingState(ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Analyzing your food...', style: theme.textTheme.large),
          const SizedBox(height: 8),
          Text(
            'AI is identifying items and looking up nutrition',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LucideIcons.utensils,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Describe your meal', style: theme.textTheme.h4),
            const SizedBox(height: 12),
            Text(
              'Type what you ate in plain language, or take a photo of your food. AI will identify the items and find accurate nutrition from USDA.',
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildExampleChip('2 scrambled eggs', theme),
                _buildExampleChip('Caesar salad', theme),
                _buildExampleChip('Chicken and rice', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text, ShadThemeData theme) {
    return GestureDetector(
      onTap: () {
        _inputController.text = text;
        _parseInput();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: theme.textTheme.small.copyWith(color: theme.colorScheme.foreground),
        ),
      ),
    );
  }

  Widget _buildResultsList(ShadThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Food items
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FoodItemCard(
              item: item,
              theme: theme,
              onRemove: () => _removeItem(index),
              onSearchUsda: () => _searchUsdaForItem(index),
              onGramsChanged: (grams) => _updateItemGrams(index, grams),
            ),
          );
        }),
        
        // Help section for unverified items
        const SizedBox(height: 8),
        _buildHelpSection(theme),
      ],
    );
  }

  Widget _buildHelpSection(ShadThemeData theme) {
    // Check if any items are not USDA verified
    final hasUnverifiedItems = _items.any((item) => !item.isFromUsda);
    
    if (!hasUnverifiedItems) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.lightbulb,
            size: 20,
            color: Color(0xFFF97316),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI guess needs verification',
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap on any orange item above to search and select the correct food from USDA database',
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ShadThemeData theme) {
    // Calculate totals
    final totalCalories = _items.fold<double>(0, (sum, item) => sum + item.calories);
    final totalProtein = _items.fold<double>(0, (sum, item) => sum + item.protein);
    final totalCarbs = _items.fold<double>(0, (sum, item) => sum + item.carbs);
    final totalFat = _items.fold<double>(0, (sum, item) => sum + item.fat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Totals row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalStat('Calories', '${totalCalories.round()}', 'kcal', theme),
                  _buildTotalStat('Protein', '${totalProtein.round()}', 'g', theme),
                  _buildTotalStat('Carbs', '${totalCarbs.round()}', 'g', theme),
                  _buildTotalStat('Fat', '${totalFat.round()}', 'g', theme),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Save button
            ShadButton(
              width: double.infinity,
              size: ShadButtonSize.lg,
              onPressed: _saveLogs,
              leading: const Icon(LucideIcons.check, size: 18),
              child: Text('Save ${_items.length} ${_items.length == 1 ? 'Item' : 'Items'}'),
            ),
          ],
        ),
      ),
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
              style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700),
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
          // Header row - TAPPABLE to change food
          InkWell(
            onTap: widget.onSearchUsda,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.isFromUsda 
                    ? Colors.transparent 
                    : theme.colorScheme.muted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: item.isFromUsda 
                    ? null 
                    : Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/confidence indicator
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.isFromUsda
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : const Color(0xFFF97316).withValues(alpha: 0.15),
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
                  
                  // Food name and source
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.displayName,
                                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Edit icon hint
                            if (!item.isFromUsda)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  LucideIcons.pencil,
                                  size: 14,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                          ],
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
                                    const Text('USDA Verified'),
                                  ],
                                ),
                              )
                            else
                              ShadBadge.destructive(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.triangleAlert, size: 10),
                                    const SizedBox(width: 4),
                                    const Text('Tap to verify'),
                                  ],
                                ),
                              ),
                            if (item.usdaBrandName != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.usdaBrandName!,
                                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Show AI description if available
                        if (item.aiDescription != null && item.aiDescription!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.aiDescription!,
                            style: theme.textTheme.muted.copyWith(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Tap to change hint for non-verified items
                        if (!item.isFromUsda) ...[
                          const SizedBox(height: 8),
                          Text(
                            '👆 Tap here to search & verify the correct food',
                            style: theme.textTheme.muted.copyWith(
                              fontSize: 11,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Delete button row
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: widget.onRemove,
              child: Icon(
                LucideIcons.trash2,
                size: 16,
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Portion and macros row
          Row(
            children: [
              // Grams input
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
              
              // Macros
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
          
          // Search USDA button (if not already from USDA or low confidence)
          if (!item.isFromUsda || (item.aiConfidence != null && item.aiConfidence! < 0.7)) ...[
            const SizedBox(height: 12),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: widget.onSearchUsda,
              leading: const Icon(LucideIcons.search, size: 14),
              child: const Text('Search USDA Database'),
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
        color: color.withValues(alpha: 0.15),
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
