import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/screens/manual_entry_screen.dart';
import 'package:ai_calorie_tracker/screens/analysis_screen.dart';
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

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(imagePath: pickedFile.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final hasLogs = foodProvider.dailyLogs.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Provider.of<UserProvider>(context, listen: false).signOut();
                },
              ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Today\'s Nutrition',
                style: TextStyle(color: Colors.black),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSummaryCard(foodProvider),
          ),
          if (hasLogs)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = foodProvider.dailyLogs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(
                          log.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${log.calories.toInt()} kcal • ${log.weightGrams.toInt()}g',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => foodProvider.removeLog(log.id),
                        ),
                      ),
                    );
                  },
                  childCount: foodProvider.dailyLogs.length,
                ),
              ),
            )
          else
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No meals logged today',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        label: const Text('Add Food'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionTile(
                context,
                icon: Icons.camera_alt,
                label: 'Take Photo',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.edit,
                label: 'Manual Entry',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSummaryCard(FoodProvider provider) {
    // Prevent division by zero or empty chart
    final hasData = provider.totalCalories > 0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Calories Consumed', style: TextStyle(fontSize: 16)),
            Text(
              '${provider.totalCalories.toInt()} / 2000',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  Expanded(
                    child: hasData 
                      ? PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(value: provider.totalProtein, color: Colors.blue, title: 'P', radius: 40),
                              PieChartSectionData(value: provider.totalCarbs, color: Colors.orange, title: 'C', radius: 40),
                              PieChartSectionData(value: provider.totalFat, color: Colors.red, title: 'F', radius: 40),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        )
                      : const Center(child: Text('No Data', style: TextStyle(color: Colors.grey))),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMacroStat('Protein', provider.totalProtein, Colors.blue),
                          const SizedBox(height: 8),
                          _buildMacroStat('Carbs', provider.totalCarbs, Colors.orange),
                          const SizedBox(height: 8),
                          _buildMacroStat('Fat', provider.totalFat, Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text('${value.toInt()}g', style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}
