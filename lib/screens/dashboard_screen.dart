import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/screens/smart_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  Set<DateTime> _loggedDates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    await foodProvider.loadLogsForDate(_selectedDate);
    await _loadLoggedDates();
  }

  Future<void> _loadLoggedDates() async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final weekStart = _getWeekStart(_selectedDate);
    final dates = await foodProvider.getLoggedDatesInWeek(weekStart);
    setState(() {
      _loggedDates = dates;
    });
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    Provider.of<FoodProvider>(context, listen: false).loadLogsForDate(date);
  }

  void _navigateToAddFood(String mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartEntryScreen(initialMealType: mealType),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);

    final targetCalories = userProvider.userProfile?.dailyCalorieTarget ?? 2000;
    final targetCarbs = (targetCalories * 0.5 / 4).round(); // 50% of calories from carbs
    final targetFat = (targetCalories * 0.25 / 9).round(); // 25% from fat
    final targetProtein = (targetCalories * 0.25 / 4).round(); // 25% from protein

    final caloriesLeft = (targetCalories - foodProvider.totalCalories).round();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            // Week selector
            _buildWeekSelector(theme),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Calories Card
                    _buildCaloriesCard(
                      theme,
                      foodProvider.totalCalories.round(),
                      targetCalories,
                      caloriesLeft,
                    ),

                    const SizedBox(height: 16),

                    // Macros Row
                    _buildMacrosRow(
                      theme,
                      foodProvider.totalCarbs.round(),
                      targetCarbs,
                      foodProvider.totalFat.round(),
                      targetFat,
                      foodProvider.totalProtein.round(),
                      targetProtein,
                    ),

                    const SizedBox(height: 24),

                    // Diary Section
                    _buildDiarySection(theme, foodProvider),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateText = isToday ? 'Today' : DateFormat('MMM d').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                _selectDate(picked);
                _loadLoggedDates();
              }
            },
            child: Row(
              children: [
                Text(
                  dateText,
                  style: theme.textTheme.h3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronDown,
                  size: 20,
                  color: theme.colorScheme.foreground,
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('d ↑').format(_selectedDate),
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(ShadThemeData theme) {
    final weekStart = _getWeekStart(_selectedDate);
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final hasLogs = _loggedDates.contains(DateTime(date.year, date.month, date.day));
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => _selectDate(date),
            child: Column(
              children: [
                Text(
                  days[index],
                  style: theme.textTheme.small.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: hasLogs && !isSelected
                        ? Icon(
                            LucideIcons.check,
                            size: 16,
                            color: theme.colorScheme.primary,
                          )
                        : Text(
                            '${date.day}',
                            style: theme.textTheme.small.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCaloriesCard(
    ShadThemeData theme,
    int current,
    int target,
    int left,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calories',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current cal',
                style: theme.textTheme.h2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${NumberFormat('#,###').format(target)}',
                  style: theme.textTheme.muted.copyWith(fontSize: 16),
                ),
              ),
              const Spacer(),
              Text(
                '${NumberFormat('#,###').format(left.abs())} ${left >= 0 ? 'left' : 'over'}',
                style: theme.textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.muted.withValues(alpha: 0.2),
              color: left >= 0 ? theme.colorScheme.primary : theme.colorScheme.destructive,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow(
    ShadThemeData theme,
    int carbs,
    int carbsTarget,
    int fat,
    int fatTarget,
    int protein,
    int proteinTarget,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMacroItem(
              theme,
              'Carbs',
              carbs,
              carbsTarget,
              const Color(0xFF8B5CF6), // Purple
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.border,
          ),
          Expanded(
            child: _buildMacroItem(
              theme,
              'Fat',
              fat,
              fatTarget,
              const Color(0xFFF59E0B), // Amber/Orange
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.border,
          ),
          Expanded(
            child: _buildMacroItem(
              theme,
              'Protein',
              protein,
              proteinTarget,
              const Color(0xFF06B6D4), // Cyan
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    ShadThemeData theme,
    String label,
    int current,
    int target,
    Color color,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${current}g',
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / $target',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiarySection(ShadThemeData theme, FoodProvider provider) {
    final logsByMeal = provider.logsByMealType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diary',
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full diary view
              },
              child: Text(
                'View all',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Meal sections
        _buildMealSection(
          theme,
          'Breakfast',
          LucideIcons.coffee,
          logsByMeal['Breakfast'] ?? [],
          provider,
        ),
        _buildMealSection(
          theme,
          'Lunch',
          LucideIcons.utensils,
          logsByMeal['Lunch'] ?? [],
          provider,
        ),
        _buildMealSection(
          theme,
          'Dinner',
          LucideIcons.utensilsCrossed,
          logsByMeal['Dinner'] ?? [],
          provider,
        ),
        _buildMealSection(
          theme,
          'Snack',
          LucideIcons.apple,
          logsByMeal['Snack'] ?? [],
          provider,
        ),
      ],
    );
  }

  Widget _buildMealSection(
    ShadThemeData theme,
    String mealType,
    IconData icon,
    List logs,
    FoodProvider provider,
  ) {
    final totals = provider.getTotalsForMealType(mealType);
    final hasLogs = logs.isNotEmpty;
    final foodNames = logs.take(2).map((log) => log.name).toList();
    final extraCount = logs.length - 2;

    String subtitle;
    if (!hasLogs) {
      subtitle = 'No items logged';
    } else if (logs.length == 1) {
      subtitle = foodNames[0];
    } else if (logs.length == 2) {
      subtitle = '${foodNames[0]} and ${foodNames[1]}';
    } else {
      subtitle = '${foodNames[0]} and $extraCount more';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mealType,
                          style: theme.textTheme.p.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                LucideIcons.ellipsis,
                                size: 18,
                                color: theme.colorScheme.mutedForeground,
                              ),
                              onPressed: () {
                                // Show meal options
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _navigateToAddFood(mealType),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Log',
                                style: theme.textTheme.small.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasLogs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${totals['calories']!.round()} cal',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text('·', style: theme.textTheme.small),
                const SizedBox(width: 8),
                Text(
                  'C ${((totals['carbs']! * 4 / (totals['calories']! == 0 ? 1 : totals['calories']!)) * 100).round()}%',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'F ${((totals['fat']! * 9 / (totals['calories']! == 0 ? 1 : totals['calories']!)) * 100).round()}%',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'P ${((totals['protein']! * 4 / (totals['calories']! == 0 ? 1 : totals['calories']!)) * 100).round()}%',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
