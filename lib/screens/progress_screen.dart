import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);

    final targetCalories = userProvider.userProfile?.dailyCalorieTarget ?? 2000;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.background,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Progress',
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Today's Summary Card
                  _buildTodaySummary(theme, foodProvider, targetCalories),
                  const SizedBox(height: 24),

                  // Macro Distribution
                  _buildMacroDistribution(theme, foodProvider),
                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsGrid(theme, foodProvider, targetCalories),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary(
    ShadThemeData theme,
    FoodProvider provider,
    int targetCalories,
  ) {
    final progress = (provider.totalCalories / targetCalories).clamp(0.0, 1.0);
    final remaining = targetCalories - provider.totalCalories.round();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: theme.textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.totalCalories.round()}',
                      style: theme.textTheme.h1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'of $targetCalories cal',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.muted.withValues(alpha: 0.2),
                        color: remaining >= 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.destructive,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.large.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: remaining >= 0
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  remaining >= 0 ? LucideIcons.target : LucideIcons.triangleAlert,
                  size: 16,
                  color: remaining >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.destructive,
                ),
                const SizedBox(width: 8),
                Text(
                  remaining >= 0
                      ? '$remaining calories remaining'
                      : '${remaining.abs()} calories over budget',
                  style: theme.textTheme.small.copyWith(
                    color: remaining >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistribution(ShadThemeData theme, FoodProvider provider) {
    final hasData = provider.totalCalories > 0;
    final totalMacroCalories =
        (provider.totalProtein * 4) + (provider.totalCarbs * 4) + (provider.totalFat * 9);

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
            'Macro Distribution',
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (hasData)
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: provider.totalProtein * 4,
                          color: const Color(0xFF06B6D4),
                          title: '',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: provider.totalCarbs * 4,
                          color: const Color(0xFF8B5CF6),
                          title: '',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: provider.totalFat * 9,
                          color: const Color(0xFFF59E0B),
                          title: '',
                          radius: 40,
                        ),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildMacroRow(
                        theme,
                        'Protein',
                        provider.totalProtein,
                        totalMacroCalories > 0
                            ? (provider.totalProtein * 4 / totalMacroCalories * 100).round()
                            : 0,
                        const Color(0xFF06B6D4),
                      ),
                      const SizedBox(height: 12),
                      _buildMacroRow(
                        theme,
                        'Carbs',
                        provider.totalCarbs,
                        totalMacroCalories > 0
                            ? (provider.totalCarbs * 4 / totalMacroCalories * 100).round()
                            : 0,
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 12),
                      _buildMacroRow(
                        theme,
                        'Fat',
                        provider.totalFat,
                        totalMacroCalories > 0
                            ? (provider.totalFat * 9 / totalMacroCalories * 100).round()
                            : 0,
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.chartPie,
                      size: 48,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No data yet',
                      style: theme.textTheme.muted,
                    ),
                    Text(
                      'Log some food to see your macro distribution',
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    ShadThemeData theme,
    String label,
    double grams,
    int percentage,
    Color color,
  ) {
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
          '${grams.round()}g',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$percentage%',
            style: theme.textTheme.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    ShadThemeData theme,
    FoodProvider provider,
    int targetCalories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Meals Today',
                '${provider.dailyLogs.length}',
                LucideIcons.utensils,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Avg per Meal',
                provider.dailyLogs.isNotEmpty
                    ? '${(provider.totalCalories / provider.dailyLogs.length).round()}'
                    : '0',
                LucideIcons.calculator,
                const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Protein Goal',
                '${((provider.totalProtein / ((targetCalories * 0.25) / 4)) * 100).clamp(0, 999).round()}%',
                LucideIcons.beef,
                const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Fiber',
                '${provider.dailyLogs.fold(0.0, (sum, log) => sum).round()}g',
                LucideIcons.leaf,
                const Color(0xFF84CC16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ShadThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
