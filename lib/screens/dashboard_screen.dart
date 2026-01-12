import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/screens/profile_screen.dart';
import 'package:ai_calorie_tracker/screens/diet_plan_screen.dart';
import 'package:ai_calorie_tracker/screens/smart_entry_screen.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load today's logs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodProvider>(context, listen: false).loadLogsForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final hasLogs = foodProvider.dailyLogs.isNotEmpty;
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: ShadToaster(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 100.0,
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.background,
              surfaceTintColor: Colors.transparent,
              actions: [
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DietPlanScreen()),
                    );
                  },
                  child: Icon(
                    LucideIcons.calendarDays,
                    size: 20,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Icon(
                    LucideIcons.userCog,
                    size: 20,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    Provider.of<UserProvider>(context, listen: false).signOut();
                  },
                  child: Icon(
                    LucideIcons.logOut,
                    size: 20,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Today\'s Nutrition',
                  style: theme.textTheme.h4.copyWith(
                    color: theme.colorScheme.foreground,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            
            // Summary Card
            SliverToBoxAdapter(
              child: _buildSummaryCard(foodProvider, theme),
            ),
            
            // Food Logs
            if (hasLogs)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = foodProvider.dailyLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShadCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.name,
                                      style: theme.textTheme.p.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${log.calories.toInt()} kcal • ${log.weightGrams.toInt()}g',
                                      style: theme.textTheme.muted,
                                    ),
                                  ],
                                ),
                              ),
                              ShadButton.ghost(
                                size: ShadButtonSize.sm,
                                onPressed: () => foodProvider.removeLog(log.id),
                                child: Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: theme.colorScheme.destructive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: foodProvider.dailyLogs.length,
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color.lerp(theme.colorScheme.muted, Colors.white, 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          LucideIcons.chefHat,
                          size: 40,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No meals logged today',
                        style: theme.textTheme.large.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to add your first meal',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ShadButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SmartEntryScreen()),
          );
        },
        leading: const Icon(LucideIcons.sparkles, size: 20),
        child: const Text('Add Food'),
      ),
    );
  }

  Widget _buildSummaryCard(FoodProvider provider, ShadThemeData theme) {
    final hasData = provider.totalCalories > 0;
    const targetCalories = 2000;
    final progress = (provider.totalCalories / targetCalories).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: theme.textTheme.muted),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(theme.colorScheme.primary, Colors.white, 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${provider.totalCalories.toInt()}',
                  style: theme.textTheme.h1.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/ $targetCalories kcal',
                    style: theme.textTheme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShadProgress(value: progress),
            const SizedBox(height: 24),
            
            // Macros Section
            Row(
              children: [
                Expanded(
                  child: hasData 
                    ? SizedBox(
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: provider.totalProtein,
                                color: const Color(0xFF3B82F6),
                                title: '',
                                radius: 35,
                              ),
                              PieChartSectionData(
                                value: provider.totalCarbs,
                                color: const Color(0xFFF97316),
                                title: '',
                                radius: 35,
                              ),
                              PieChartSectionData(
                                value: provider.totalFat,
                                color: const Color(0xFFEF4444),
                                title: '',
                                radius: 35,
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: 25,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          'No Data',
                          style: theme.textTheme.muted,
                        ),
                      ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildMacroStat(
                        'Protein',
                        provider.totalProtein,
                        const Color(0xFF3B82F6),
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildMacroStat(
                        'Carbs',
                        provider.totalCarbs,
                        const Color(0xFFF97316),
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildMacroStat(
                        'Fat',
                        provider.totalFat,
                        const Color(0xFFEF4444),
                        theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat(String label, double value, Color color, ShadThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.small),
        ),
        Text(
          '${value.toInt()}g',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
