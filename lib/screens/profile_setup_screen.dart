import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final _heightController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _selectedGender = 'Male';
  WeightUnit _selectedWeightUnit = WeightUnit.kg;
  HeightUnit _selectedHeightUnit = HeightUnit.cm;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  CalorieGoal _selectedCalorieGoal = CalorieGoal.maintain;
  int _mealsPerDay = 3;
  bool _isLoading = false;

  // Food preferences
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedDietaryRestrictions = {};
  final List<String> _preferredFoods = [];
  final List<String> _customAllergies = [];
  final _preferredFoodController = TextEditingController();
  final _allergyController = TextEditingController();

  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() => _isLoading = true);
    try {
      double heightInCm;
      if (_selectedHeightUnit == HeightUnit.ft) {
        final feet = double.parse(_heightController.text);
        final inches = _heightInchesController.text.isNotEmpty 
            ? double.parse(_heightInchesController.text) 
            : 0.0;
        heightInCm = (feet * 12 + inches) * 2.54;
      } else {
        heightInCm = double.parse(_heightController.text);
      }

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
        mealsPerDay: _mealsPerDay,
        preferredFoods: _preferredFoods,
        allergies: _selectedAllergies.toList(),
        dietaryRestrictions: _selectedDietaryRestrictions.toList(),
      );
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Error saving profile: $e'),
          ),
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
    _allergyController.dispose();
    super.dispose();
  }

  void _addCustomAllergy() {
    final allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty && !_customAllergies.contains(allergy) && !_selectedAllergies.contains(allergy)) {
      setState(() {
        _customAllergies.add(allergy);
        _selectedAllergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Scaffold(
      body: ShadToaster(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ShadForm(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              Color.lerp(theme.colorScheme.primary, Colors.white, 0.3)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.userCog,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tell us about yourself',
                      style: theme.textTheme.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us calculate your daily calorie needs.',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Basic Info Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.user, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Basic Information'),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            // Gender Select
                            ShadSelect<String>(
                              placeholder: const Text('Select gender'),
                              initialValue: _selectedGender,
                              options: _genders
                                  .map((g) => ShadOption(value: g, child: Text(g)))
                                  .toList(),
                              selectedOptionBuilder: (context, value) => Text(value),
                              onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
                            ),
                            const SizedBox(height: 16),
                            
                            // Age
                            ShadInputFormField(
                              id: 'age',
                              controller: _ageController,
                              label: const Text('Age'),
                              placeholder: const Text('Enter your age'),
                              leading: const Icon(LucideIcons.cake, size: 16),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v.isEmpty) return 'Required';
                                final age = int.tryParse(v);
                                if (age == null || age < 1 || age > 120) {
                                  return 'Enter a valid age';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meals Per Day Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.utensilsCrossed, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Meals Per Day'),
                        ],
                      ),
                      description: const Text('How many meals do you typically eat? (minimum 2)'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShadButton.outline(
                                  size: ShadButtonSize.sm,
                                  onPressed: _mealsPerDay > 2 
                                      ? () => setState(() => _mealsPerDay--) 
                                      : null,
                                  child: const Icon(LucideIcons.minus, size: 16),
                                ),
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    '$_mealsPerDay',
                                    style: theme.textTheme.h2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ShadButton.outline(
                                  size: ShadButtonSize.sm,
                                  onPressed: _mealsPerDay < 8 
                                      ? () => setState(() => _mealsPerDay++) 
                                      : null,
                                  child: const Icon(LucideIcons.plus, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Quick select buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [2, 3, 4, 5, 6].map((count) {
                                final isSelected = _mealsPerDay == count;
                                return ShadButton(
                                  size: ShadButtonSize.sm,
                                  onPressed: () => setState(() => _mealsPerDay = count),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(LucideIcons.check, size: 14),
                                        const SizedBox(width: 4),
                                      ],
                                      Text('$count meals'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Measurements Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.ruler, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Measurements'),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weight Unit Toggle
                            Text('Weight Unit', style: theme.textTheme.small),
                            const SizedBox(height: 8),
                            ShadTabs<WeightUnit>(
                              value: _selectedWeightUnit,
                              onChanged: (v) => setState(() => _selectedWeightUnit = v),
                              tabs: WeightUnit.values.map((unit) => ShadTab(
                                value: unit,
                                content: const SizedBox.shrink(),
                                child: Text(unit.label),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            
                            // Height Unit Toggle
                            Text('Height Unit', style: theme.textTheme.small),
                            const SizedBox(height: 8),
                            ShadTabs<HeightUnit>(
                              value: _selectedHeightUnit,
                              onChanged: (v) {
                                setState(() {
                                  _selectedHeightUnit = v;
                                  _heightController.clear();
                                  _heightInchesController.clear();
                                });
                              },
                              tabs: HeightUnit.values.map((unit) => ShadTab(
                                value: unit,
                                content: const SizedBox.shrink(),
                                child: Text(unit.label),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Height Input
                            if (_selectedHeightUnit == HeightUnit.cm)
                              ShadInputFormField(
                                id: 'height_cm',
                                controller: _heightController,
                                label: const Text('Height (cm)'),
                                placeholder: const Text('e.g., 175'),
                                leading: const Icon(LucideIcons.moveVertical, size: 16),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v.isEmpty) return 'Required';
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
                                    child: ShadInputFormField(
                                      id: 'height_feet',
                                      controller: _heightController,
                                      label: const Text('Feet'),
                                      placeholder: const Text('5'),
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v.isEmpty) return 'Required';
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
                                    child: ShadInputFormField(
                                      id: 'height_inches',
                                      controller: _heightInchesController,
                                      label: const Text('Inches'),
                                      placeholder: const Text('10'),
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v.isNotEmpty) {
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
                            ShadInputFormField(
                              id: 'weight',
                              controller: _weightController,
                              label: Text('Weight (${_selectedWeightUnit.label})'),
                              placeholder: Text(_selectedWeightUnit == WeightUnit.kg ? 'e.g., 70' : 'e.g., 154'),
                              leading: const Icon(LucideIcons.scale, size: 16),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v.isEmpty) return 'Required';
                                final weight = double.tryParse(v);
                                if (weight == null) return 'Enter a valid weight';
                                if (_selectedWeightUnit == WeightUnit.kg) {
                                  if (weight < 20 || weight > 300) return 'Enter a valid weight';
                                } else {
                                  if (weight < 44 || weight > 660) return 'Enter a valid weight';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Activity Level Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.activity, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Activity Level'),
                        ],
                      ),
                      description: const Text('How active are you on a typical week?'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ShadRadioGroup<ActivityLevel>(
                          initialValue: _selectedActivityLevel,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedActivityLevel = v);
                          },
                          items: ActivityLevel.values.map((level) => ShadRadio(
                            value: level,
                            label: Text(level.label),
                            sublabel: Text(level.description),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Calorie Goal Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.target, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Your Goal'),
                        ],
                      ),
                      description: const Text('What do you want to achieve?'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ShadRadioGroup<CalorieGoal>(
                          initialValue: _selectedCalorieGoal,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedCalorieGoal = v);
                          },
                          items: CalorieGoal.values.map((goal) {
                            final adjustment = goal.calorieAdjustment;
                            final adjustmentText = adjustment == 0 
                                ? 'Maintenance' 
                                : '${adjustment > 0 ? '+' : ''}$adjustment cal';
                            return ShadRadio(
                              value: goal,
                              label: Row(
                                children: [
                                  Text(goal.label),
                                  const SizedBox(width: 8),
                                  ShadBadge.outline(
                                    child: Text(adjustmentText),
                                  ),
                                ],
                              ),
                              sublabel: Text(goal.description),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dietary Restrictions Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.utensils, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Dietary Restrictions'),
                        ],
                      ),
                      description: const Text('Select any dietary restrictions you follow (optional)'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DietaryRestriction.allRestrictions.map((item) {
                            final isSelected = _selectedDietaryRestrictions.contains(item);
                            return ShadButton(
                              size: ShadButtonSize.sm,
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedDietaryRestrictions.remove(item);
                                  } else {
                                    _selectedDietaryRestrictions.add(item);
                                  }
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(LucideIcons.check, size: 14),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(item),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Allergies Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.triangleAlert, size: 18, color: theme.colorScheme.destructive),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Food Allergies')),
                        ],
                      ),
                      description: const Text('Select common allergies or add your own'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom allergy input
                            Row(
                              children: [
                                Expanded(
                                  child: ShadInput(
                                    controller: _allergyController,
                                    placeholder: const Text('Add custom allergy...'),
                                    onSubmitted: (_) => _addCustomAllergy(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ShadButton.destructive(
                                  size: ShadButtonSize.sm,
                                  onPressed: _addCustomAllergy,
                                  child: const Icon(LucideIcons.plus, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Custom allergies badges
                            if (_customAllergies.isNotEmpty) ...[
                              Text('Your allergies', style: theme.textTheme.small),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _customAllergies.map((allergy) {
                                  return ShadBadge.destructive(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(allergy),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _customAllergies.remove(allergy);
                                            _selectedAllergies.remove(allergy);
                                          }),
                                          child: const Icon(LucideIcons.x, size: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Common allergies
                            Text('Common allergies', style: theme.textTheme.small),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: FoodAllergy.allAllergies.map((item) {
                                final isSelected = _selectedAllergies.contains(item);
                                return ShadButton(
                                  size: ShadButtonSize.sm,
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedAllergies.remove(item);
                                      } else {
                                        _selectedAllergies.add(item);
                                      }
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        Icon(LucideIcons.check, size: 14, color: theme.colorScheme.destructive),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        item,
                                        style: isSelected 
                                            ? TextStyle(color: theme.colorScheme.destructive)
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preferred Foods Card
                    ShadCard(
                      title: Row(
                        children: [
                          Icon(LucideIcons.heart, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Preferred Foods'),
                        ],
                      ),
                      description: const Text('Add foods you enjoy eating (optional, helps with AI meal suggestions)'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ShadInput(
                                    controller: _preferredFoodController,
                                    placeholder: const Text('e.g., Chicken, Rice...'),
                                    onSubmitted: (_) => _addPreferredFood(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ShadButton.outline(
                                  size: ShadButtonSize.sm,
                                  onPressed: _addPreferredFood,
                                  child: const Icon(LucideIcons.plus, size: 16),
                                ),
                              ],
                            ),
                            if (_preferredFoods.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _preferredFoods.map((food) {
                                  return ShadBadge(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(food),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() => _preferredFoods.remove(food)),
                                          child: const Icon(LucideIcons.x, size: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ShadButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      size: ShadButtonSize.lg,
                      child: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primaryForeground,
                              ),
                            )
                          : const Text('Complete Setup'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
