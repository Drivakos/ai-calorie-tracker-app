import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _heightInchesController = TextEditingController(); // For feet/inches
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _selectedGender = 'Male';
  WeightUnit _selectedWeightUnit = WeightUnit.kg;
  HeightUnit _selectedHeightUnit = HeightUnit.cm;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  CalorieGoal _selectedCalorieGoal = CalorieGoal.maintain;
  bool _isLoading = false;

  // Food preferences
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedDietaryRestrictions = {};
  final List<String> _preferredFoods = [];
  final _preferredFoodController = TextEditingController();

  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Calculate height based on unit
      double heightInCm;
      if (_selectedHeightUnit == HeightUnit.ft) {
        final feet = double.parse(_heightController.text);
        final inches = _heightInchesController.text.isNotEmpty 
            ? double.parse(_heightInchesController.text) 
            : 0.0;
        // Convert feet + inches to cm directly
        heightInCm = (feet * 12 + inches) * 2.54;
      } else {
        heightInCm = double.parse(_heightController.text);
      }

      // Convert weight to kg if needed
      double weightInKg = double.parse(_weightController.text);
      if (_selectedWeightUnit == WeightUnit.lbs) {
        weightInKg = _selectedWeightUnit.toKg(weightInKg);
      }

      await Provider.of<UserProvider>(context, listen: false).saveProfile(
        height: heightInCm,
        weight: weightInKg,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        weightUnit: _selectedWeightUnit,
        heightUnit: _selectedHeightUnit,
        activityLevel: _selectedActivityLevel,
        calorieGoal: _selectedCalorieGoal,
        preferredFoods: _preferredFoods,
        allergies: _selectedAllergies.toList(),
        dietaryRestrictions: _selectedDietaryRestrictions.toList(),
      );
      // Navigation is handled by the wrapper in main.dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _preferredFoodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us calculate your daily calorie needs.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Gender Selector
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final age = int.tryParse(v);
                  if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Unit Preferences Section
              _buildSectionHeader('Measurement Units', Icons.straighten),
              const SizedBox(height: 12),
              
              // Weight Unit Toggle
              _buildUnitToggle(
                label: 'Weight',
                options: WeightUnit.values,
                selectedValue: _selectedWeightUnit,
                getLabel: (unit) => unit.label,
                onChanged: (unit) => setState(() => _selectedWeightUnit = unit),
              ),
              const SizedBox(height: 12),
              
              // Height Unit Toggle
              _buildUnitToggle(
                label: 'Height',
                options: HeightUnit.values,
                selectedValue: _selectedHeightUnit,
                getLabel: (unit) => unit.label,
                onChanged: (unit) => setState(() {
                  _selectedHeightUnit = unit;
                  // Clear height fields when changing units
                  _heightController.clear();
                  _heightInchesController.clear();
                }),
              ),
              const SizedBox(height: 24),

              // Height Input
              if (_selectedHeightUnit == HeightUnit.cm)
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                    hintText: 'e.g., 175',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final height = double.tryParse(v);
                    if (height == null || height < 50 || height > 300) {
                      return 'Enter a valid height';
                    }
                    return null;
                  },
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Feet',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.height),
                          hintText: 'e.g., 5',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final feet = int.tryParse(v);
                          if (feet == null || feet < 1 || feet > 8) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightInchesController,
                        decoration: const InputDecoration(
                          labelText: 'Inches',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 10',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final inches = double.tryParse(v);
                            if (inches == null || inches < 0 || inches >= 12) {
                              return 'Invalid';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${_selectedWeightUnit.label})',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  hintText: _selectedWeightUnit == WeightUnit.kg ? 'e.g., 70' : 'e.g., 154',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final weight = double.tryParse(v);
                  if (weight == null) return 'Enter a valid weight';
                  // Validate reasonable weight ranges
                  if (_selectedWeightUnit == WeightUnit.kg) {
                    if (weight < 20 || weight > 300) return 'Enter a valid weight';
                  } else {
                    if (weight < 44 || weight > 660) return 'Enter a valid weight';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),

              // Activity Level Section
              _buildSectionHeader('Activity Level', Icons.directions_run),
              const SizedBox(height: 8),
              const Text(
                'How active are you on a typical week?',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              ...ActivityLevel.values.map((level) => _buildActivityOption(level, colorScheme)),

              const SizedBox(height: 32),

              // Calorie Goal Section
              _buildSectionHeader('Your Goal', Icons.flag_outlined),
              const SizedBox(height: 8),
              const Text(
                'What do you want to achieve?',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              ...CalorieGoal.values.map((goal) => _buildGoalOption(goal, colorScheme)),

              const SizedBox(height: 32),

              // Dietary Restrictions Section
              _buildSectionHeader('Dietary Restrictions', Icons.restaurant_menu),
              const SizedBox(height: 8),
              const Text(
                'Select any dietary restrictions you follow (optional)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildChipSelector(
                items: DietaryRestriction.allRestrictions,
                selectedItems: _selectedDietaryRestrictions,
                colorScheme: colorScheme,
              ),

              const SizedBox(height: 32),

              // Allergies Section
              _buildSectionHeader('Food Allergies', Icons.warning_amber_outlined),
              const SizedBox(height: 8),
              const Text(
                'Select any food allergies (important for AI recommendations)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildChipSelector(
                items: FoodAllergy.allAllergies,
                selectedItems: _selectedAllergies,
                colorScheme: colorScheme,
                isAllergy: true,
              ),

              const SizedBox(height: 32),

              // Preferred Foods Section
              _buildSectionHeader('Preferred Foods', Icons.favorite_outline),
              const SizedBox(height: 8),
              const Text(
                'Add foods you enjoy eating (optional, helps with AI meal suggestions)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildPreferredFoodsInput(colorScheme),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle<T>({
    required String label,
    required List<T> options,
    required T selectedValue,
    required String Function(T) getLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: options.map((option) {
                final isSelected = option == selectedValue;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getLabel(option),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? Colors.white 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(ActivityLevel level, ColorScheme colorScheme) {
    final isSelected = _selectedActivityLevel == level;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedActivityLevel = level),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primaryContainer 
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer.withOpacity(0.8) 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(CalorieGoal goal, ColorScheme colorScheme) {
    final isSelected = _selectedCalorieGoal == goal;
    final adjustment = goal.calorieAdjustment;
    final adjustmentText = adjustment == 0 
        ? 'Maintenance' 
        : '${adjustment > 0 ? '+' : ''}$adjustment cal';
    
    // Color coding for goals
    final goalColor = switch (goal) {
      CalorieGoal.aggressiveCut => Colors.red,
      CalorieGoal.moderateCut => Colors.orange,
      CalorieGoal.mildCut => Colors.amber,
      CalorieGoal.maintain => Colors.green,
      CalorieGoal.mildBulk => Colors.lightBlue,
      CalorieGoal.moderateBulk => Colors.blue,
      CalorieGoal.aggressiveBulk => Colors.indigo,
    };
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCalorieGoal = goal),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primaryContainer 
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          goal.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? colorScheme.onPrimaryContainer 
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: goalColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adjustmentText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: goalColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer.withOpacity(0.8) 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required Set<String> selectedItems,
    required ColorScheme colorScheme,
    bool isAllergy = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedItems.add(item);
              } else {
                selectedItems.remove(item);
              }
            });
          },
          selectedColor: isAllergy 
              ? Colors.red.withOpacity(0.2) 
              : colorScheme.primaryContainer,
          checkmarkColor: isAllergy ? Colors.red : colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected 
                ? (isAllergy ? Colors.red : colorScheme.onPrimaryContainer)
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected 
                ? (isAllergy ? Colors.red : colorScheme.primary)
                : colorScheme.outline.withOpacity(0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreferredFoodsInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _preferredFoodController,
                decoration: InputDecoration(
                  hintText: 'e.g., Chicken, Rice, Broccoli...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addPreferredFood,
                  ),
                ),
                onSubmitted: (_) => _addPreferredFood(),
              ),
            ),
          ],
        ),
        if (_preferredFoods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _preferredFoods.map((food) {
              return Chip(
                label: Text(food),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _preferredFoods.remove(food);
                  });
                },
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addPreferredFood() {
    final food = _preferredFoodController.text.trim();
    if (food.isNotEmpty && !_preferredFoods.contains(food)) {
      setState(() {
        _preferredFoods.add(food);
        _preferredFoodController.clear();
      });
    }
  }
}
