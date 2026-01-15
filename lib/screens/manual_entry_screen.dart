import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_calorie_tracker/models/food_log.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _weightController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  void _saveLog() {
    if (_formKey.currentState!.saveAndValidate()) {
      final log = FoodLog(
        id: const Uuid().v4(),
        name: _nameController.text,
        weightGrams: double.tryParse(_weightController.text) ?? 0,
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        timestamp: DateTime.now(),
        mealType: 'Snack',
      );

      Provider.of<FoodProvider>(context, listen: false).addLog(log);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Manual Entry', style: theme.textTheme.h4),
        centerTitle: true,
        leading: ShadButton.ghost(
          size: ShadButtonSize.sm,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            LucideIcons.arrowLeft,
            color: theme.colorScheme.foreground,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ShadForm(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Food Info Card
              ShadCard(
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.utensils,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Food Information'),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      ShadInputFormField(
                        id: 'name',
                        controller: _nameController,
                        label: const Text('Food Name'),
                        placeholder: const Text('e.g., Grilled Chicken Breast'),
                        leading: const Icon(LucideIcons.chefHat, size: 16),
                        validator: (value) => value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ShadInputFormField(
                              id: 'calories',
                              controller: _caloriesController,
                              label: const Text('Calories'),
                              placeholder: const Text('kcal'),
                              leading: const Icon(LucideIcons.flame, size: 16),
                              keyboardType: TextInputType.number,
                              validator: (value) => value.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShadInputFormField(
                              id: 'weight',
                              controller: _weightController,
                              label: const Text('Weight'),
                              placeholder: const Text('grams'),
                              leading: const Icon(LucideIcons.scale, size: 16),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Macros Card
              ShadCard(
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.chartPie,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Macronutrients'),
                  ],
                ),
                description: const Text('Optional - helps track your macros'),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMacroInput(
                          controller: _proteinController,
                          label: 'Protein',
                          color: const Color(0xFF3B82F6),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroInput(
                          controller: _carbsController,
                          label: 'Carbs',
                          color: const Color(0xFFF97316),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroInput(
                          controller: _fatController,
                          label: 'Fat',
                          color: const Color(0xFFEF4444),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              ShadButton(
                onPressed: _saveLog,
                size: ShadButtonSize.lg,
                leading: const Icon(LucideIcons.plus, size: 20),
                child: const Text('Add Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInput({
    required TextEditingController controller,
    required String label,
    required Color color,
    required ShadThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label[0],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: controller,
          placeholder: const Text('0g'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
