import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/diet_plan.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/services/gemini_service.dart';
import 'package:ai_calorie_tracker/services/database_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final GeminiService _geminiService = GeminiService();
  final DatabaseService _databaseService = DatabaseService();
  WeeklyDietPlan? _dietPlan;
  bool _isLoading = false;
  bool _isLoadingFromDb = true;
  String? _error;
  int _selectedDayIndex = 0;
  int _selectedMealIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  /// Load saved plan from database first
  Future<void> _loadSavedPlan() async {
    setState(() => _isLoadingFromDb = true);
    
    try {
      final savedPlan = await _databaseService.getActiveDietPlan();
      if (savedPlan != null) {
        setState(() {
          _dietPlan = savedPlan;
          _isLoadingFromDb = false;
        });
      } else {
        setState(() => _isLoadingFromDb = false);
        // No saved plan, generate a new one
        _generateDietPlan();
      }
    } catch (e) {
      setState(() => _isLoadingFromDb = false);
      _generateDietPlan();
    }
  }

  Future<void> _generateDietPlan() async {
    final profile = Provider.of<UserProvider>(context, listen: false).userProfile;
    if (profile == null) {
      setState(() => _error = 'Please complete your profile first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plan = await _geminiService.generateWeeklyDietPlan(profile);
      
      // Save the plan to database
      final savedPlan = await _databaseService.saveDietPlan(plan);
      
      setState(() {
        _dietPlan = savedPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate diet plan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateDay(int dayIndex) async {
    final profile = Provider.of<UserProvider>(context, listen: false).userProfile;
    if (profile == null || _dietPlan == null) return;

    final day = _dietPlan!.days[dayIndex];
    
    setState(() => _isLoading = true);

    try {
      final newDay = await _geminiService.regenerateDayPlan(
        profile: profile,
        dayOfWeek: day.dayOfWeek,
        dayNumber: day.dayNumber,
      );

      final updatedDays = List<DailyPlan>.from(_dietPlan!.days);
      updatedDays[dayIndex] = newDay;

      final updatedPlan = _dietPlan!.copyWith(days: updatedDays);
      
      // Update in database
      if (updatedPlan.id != null) {
        await _databaseService.updateDietPlan(updatedPlan);
      }
      
      setState(() {
        _dietPlan = updatedPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to regenerate day: $e';
        _isLoading = false;
      });
    }
  }

  /// Log a meal option to the food diary
  Future<void> _logMeal(MealOption option, String mealType) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    
    // Calculate estimated weight from ingredients or use default
    double estimatedWeight = 0;
    if (option.usdaIngredients.isNotEmpty) {
      estimatedWeight = option.usdaIngredients.fold(0.0, (sum, ing) => sum + ing.quantityGrams);
    } else {
      estimatedWeight = 300; // Default meal weight
    }
    
    final log = FoodLog(
      id: const Uuid().v4(),
      name: option.name,
      weightGrams: estimatedWeight,
      calories: option.calories.toDouble(),
      protein: option.proteinG,
      carbs: option.carbsG,
      fat: option.fatG,
      timestamp: DateTime.now(),
      mealType: mealType,
    );
    
    try {
      await foodProvider.addLog(log);
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Meal logged!'),
            description: Text('${option.name} added to $mealType'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Failed to log meal'),
            description: Text('$e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final profile = Provider.of<UserProvider>(context).userProfile;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Weekly Diet Plan', style: theme.textTheme.h4),
        centerTitle: true,
        automaticallyImplyLeading: false, // This is a tab screen, no back button
        actions: [
          if (!_isLoading && !_isLoadingFromDb)
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: _generateDietPlan,
              child: Icon(
                LucideIcons.refreshCw,
                color: theme.colorScheme.foreground,
              ),
            ),
        ],
      ),
      body: ShadToaster(
        child: _isLoadingFromDb
            ? _buildLoadingState(theme, 'Loading your saved plan...')
            : _isLoading
                ? _buildLoadingState(theme, 'Generating your meal plan...')
                : _error != null
                    ? _buildErrorState(theme)
                    : _dietPlan != null
                        ? _buildDietPlanView(theme, profile)
                        : _buildEmptyState(theme),
      ),
    );
  }

  Widget _buildLoadingState(ShadThemeData theme, String message) {
    return Center(
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
          Text(message, style: theme.textTheme.large),
          const SizedBox(height: 8),
          Text(
            'AI is creating personalized meals',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 4),
          Text(
            'Validating nutrition with USDA database',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ShadThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.destructive.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LucideIcons.circleAlert,
                size: 40,
                color: theme.colorScheme.destructive,
              ),
            ),
            const SizedBox(height: 24),
            Text('Something went wrong', style: theme.textTheme.large),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ShadButton(
              onPressed: _generateDietPlan,
              leading: const Icon(LucideIcons.refreshCw, size: 16),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.utensils,
            size: 64,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text('No diet plan yet', style: theme.textTheme.large),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: _generateDietPlan,
            child: const Text('Generate Diet Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPlanView(ShadThemeData theme, userProfile) {
    final plan = _dietPlan!;
    
    return Column(
      children: [
        // Macro Summary Card
        _buildMacroSummary(theme, plan),
        
        // Day Selector
        _buildDaySelector(theme, plan),
        
        // Meals List
        Expanded(
          child: _buildMealsList(theme, plan),
        ),
      ],
    );
  }

  Widget _buildMacroSummary(ShadThemeData theme, WeeklyDietPlan plan) {
    final macros = plan.macroTargets;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Targets', style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
                    if (plan.id != null)
                      Row(
                        children: [
                          Icon(LucideIcons.cloudCheck, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text('Saved', style: theme.textTheme.muted.copyWith(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
                if (plan.avoidedAllergens.isNotEmpty)
                  ShadBadge.destructive(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldAlert, size: 12),
                        const SizedBox(width: 4),
                        Text('${plan.avoidedAllergens.length} allergens avoided'),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  theme,
                  'Calories',
                  '${macros.dailyCalories}',
                  'kcal',
                  theme.colorScheme.primary,
                ),
                _buildMacroItem(
                  theme,
                  'Protein',
                  '${macros.proteinG.round()}',
                  'g',
                  const Color(0xFF3B82F6),
                ),
                _buildMacroItem(
                  theme,
                  'Carbs',
                  '${macros.carbsG.round()}',
                  'g',
                  const Color(0xFFF97316),
                ),
                _buildMacroItem(
                  theme,
                  'Fat',
                  '${macros.fatG.round()}',
                  'g',
                  const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(ShadThemeData theme, String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.muted),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: theme.textTheme.h4.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(unit, style: theme.textTheme.small),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector(ShadThemeData theme, WeeklyDietPlan plan) {
    // Single letter abbreviations for compact display
    final dayAbbreviations = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: plan.days.asMap().entries.map((entry) {
          final index = entry.key;
          final isSelected = index == _selectedDayIndex;
          final abbrev = index < dayAbbreviations.length 
              ? dayAbbreviations[index] 
              : entry.value.dayOfWeek.substring(0, 1);
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < plan.days.length - 1 ? 4 : 0),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedDayIndex = index;
                  _selectedMealIndex = 0;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      abbrev,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected 
                            ? theme.colorScheme.primaryForeground 
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealsList(ShadThemeData theme, WeeklyDietPlan plan) {
    if (plan.days.isEmpty || _selectedDayIndex >= plan.days.length) {
      return const Center(child: Text('No meals available'));
    }

    final selectedDay = plan.days[_selectedDayIndex];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedDay.meals.length + 2, // +1 for day summary, +1 for regenerate button
      itemBuilder: (context, index) {
        if (index == 0) {
          // Day summary with regenerate button
          return _buildDaySummary(theme, selectedDay);
        }
        
        if (index == selectedDay.meals.length + 1) {
          // Regenerate day button
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ShadButton.outline(
              onPressed: () => _regenerateDay(_selectedDayIndex),
              leading: const Icon(LucideIcons.refreshCw, size: 16),
              child: Text('Regenerate ${selectedDay.dayOfWeek}\'s Meals'),
            ),
          );
        }
        
        final meal = selectedDay.meals[index - 1];
        return _buildMealCard(theme, meal, index - 1);
      },
    );
  }

  Widget _buildDaySummary(ShadThemeData theme, DailyPlan day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day.dayOfWeek,
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              _buildMiniStat('${day.totalCalories}', 'kcal', theme),
              const SizedBox(width: 12),
              _buildMiniStat('${day.totalProteinG.round()}g', 'P', theme),
              const SizedBox(width: 8),
              _buildMiniStat('${day.totalCarbsG.round()}g', 'C', theme),
              const SizedBox(width: 8),
              _buildMiniStat('${day.totalFatG.round()}g', 'F', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, ShadThemeData theme) {
    return Row(
      children: [
        Text(value, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
        Text(' $label', style: theme.textTheme.muted.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildMealCard(ShadThemeData theme, Meal meal, int mealIndex) {
    final isExpanded = _selectedMealIndex == mealIndex;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Header
            GestureDetector(
              onTap: () => setState(() {
                _selectedMealIndex = isExpanded ? -1 : mealIndex;
              }),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${meal.mealNumber}',
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType,
                          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              '${meal.primary.calories} kcal',
                              style: theme.textTheme.muted,
                            ),
                            const SizedBox(width: 8),
                            ShadBadge.secondary(
                              child: Text('${meal.alternatives.length} alternatives'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Primary Meal (always visible)
            _buildMealOption(theme, meal.primary, mealType: meal.mealType, isPrimary: true),
            
            // Alternatives (expanded view)
            if (isExpanded && meal.alternatives.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alternative Options (${meal.alternatives.length})',
                    style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Scrollable alternatives list
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: meal.alternatives.length,
                  itemBuilder: (context, altIndex) {
                    return Container(
                      width: 280,
                      height: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildMealOption(
                        theme, 
                        meal.alternatives[altIndex], 
                        mealType: meal.mealType,
                        isPrimary: false,
                        altNumber: altIndex + 1,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption(ShadThemeData theme, MealOption option, {required String mealType, required bool isPrimary, int? altNumber}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isPrimary 
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.muted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: isPrimary 
                ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
                : Border.all(color: theme.colorScheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isPrimary ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isPrimary)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'MAIN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primaryForeground,
                                  ),
                                ),
                              )
                            else if (altNumber != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.muted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ALT $altNumber',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                ),
                              ),
                            // USDA Verification Badge
                            if (option.usdaVerified)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.badgeCheck,
                                      size: 10,
                                      color: Color(0xFF22C55E),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'USDA',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF22C55E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                option.name,
                                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description,
                          style: theme.textTheme.muted,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (option.preparationTime != null)
                    ShadBadge.outline(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.clock, size: 10),
                          const SizedBox(width: 4),
                          Text(option.preparationTime!),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Primary Macros Row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildMacroBadge('${option.calories}', 'kcal', theme.colorScheme.primary),
                  _buildMacroBadge('${option.proteinG.round()}g', 'P', const Color(0xFF3B82F6)),
                  _buildMacroBadge('${option.carbsG.round()}g', 'C', const Color(0xFFF97316)),
                  _buildMacroBadge('${option.fatG.round()}g', 'F', const Color(0xFFEF4444)),
                ],
              ),
              
              // Detailed Macros (fiber, sodium, sugar)
              if (option.fiberG > 0 || option.sodiumMg > 0 || option.sugarG > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (option.fiberG > 0)
                      _buildDetailMacroBadge('${option.fiberG.round()}g fiber', theme),
                    if (option.sodiumMg > 0)
                      _buildDetailMacroBadge('${option.sodiumMg.round()}mg sodium', theme),
                    if (option.sugarG > 0)
                      _buildDetailMacroBadge('${option.sugarG.round()}g sugar', theme),
                  ],
                ),
              ],
              
              // Ingredients section
              if (option.ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                // For alternative cards (fixed height), use Expanded with scroll
                if (!isPrimary)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: option.ingredients.map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ing,
                              style: theme.textTheme.muted.copyWith(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else ...[
                  // For primary cards, show limited ingredients
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: option.ingredients.take(6).map((ing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ing,
                          style: theme.textTheme.muted.copyWith(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                  if (option.ingredients.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${option.ingredients.length - 6} more ingredients',
                        style: theme.textTheme.muted.copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ],
              // Add bottom padding for the + button
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Log button (+) positioned at bottom right
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _logMeal(option, mealType),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildDetailMacroBadge(String text, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}
