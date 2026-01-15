import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/screens/dashboard_screen.dart';
import 'package:ai_calorie_tracker/screens/diet_plan_screen.dart';
import 'package:ai_calorie_tracker/screens/smart_entry_screen.dart';
import 'package:ai_calorie_tracker/screens/progress_screen.dart';
import 'package:ai_calorie_tracker/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DietPlanScreen(),
    const SizedBox(), // Placeholder for FAB
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center button - open add food screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SmartEntryScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < 2 ? _currentIndex : _currentIndex - 1,
        children: [
          _screens[0], // Today
          _screens[1], // Plan
          _screens[3], // Progress
          _screens[4], // More
        ],
      ),
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: LucideIcons.calendar,
                  label: 'Today',
                  index: 0,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: LucideIcons.clipboardList,
                  label: 'Plan',
                  index: 1,
                  theme: theme,
                ),
                _buildCenterButton(theme),
                _buildNavItem(
                  icon: LucideIcons.chartBar,
                  label: 'Progress',
                  index: 3,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: LucideIcons.menu,
                  label: 'More',
                  index: 4,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ShadThemeData theme,
  }) {
    final actualSelected = index == 0 && _currentIndex == 0 ||
        index == 1 && _currentIndex == 1 ||
        index == 3 && _currentIndex == 3 ||
        index == 4 && _currentIndex == 4;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: actualSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.small.copyWith(
                fontSize: 11,
                color: actualSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.mutedForeground,
                fontWeight: actualSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(ShadThemeData theme) {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.plus,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
