import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final _heightController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _preferredFoodController = TextEditingController();
  final _allergyController = TextEditingController();
  
  late String _selectedGender;
  late WeightUnit _selectedWeightUnit;
  late HeightUnit _selectedHeightUnit;
  late ActivityLevel _selectedActivityLevel;
  late CalorieGoal _selectedCalorieGoal;
  late int _mealsPerDay;
  late Set<String> _selectedAllergies;
  late Set<String> _selectedDietaryRestrictions;
  late List<String> _preferredFoods;
  late List<String> _customAllergies;
  
  bool _isLoading = false;
  bool _initialized = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeFromProfile();
      _initialized = true;
    }
  }

  void _initializeFromProfile() {
    final profile = Provider.of<UserProvider>(context, listen: false).userProfile;
    if (profile != null) {
      _selectedGender = profile.gender ?? 'Male';
      _selectedWeightUnit = profile.weightUnit;
      _selectedHeightUnit = profile.heightUnit;
      _selectedActivityLevel = profile.activityLevel ?? ActivityLevel.moderatelyActive;
      _selectedCalorieGoal = profile.calorieGoal;
      _mealsPerDay = profile.mealsPerDay;
      _selectedAllergies = Set.from(profile.allergies);
      _selectedDietaryRestrictions = Set.from(profile.dietaryRestrictions);
      _preferredFoods = List.from(profile.preferredFoods);
      _customAllergies = profile.allergies
          .where((a) => !FoodAllergy.allAllergies.contains(a))
          .toList();
      
      if (profile.age != null) {
        _ageController.text = profile.age.toString();
      }
      
      if (profile.heightCm != null) {
        if (_selectedHeightUnit == HeightUnit.cm) {
          _heightController.text = profile.heightCm!.toStringAsFixed(0);
        } else {
          final totalInches = profile.heightCm! / 2.54;
          final feet = (totalInches / 12).floor();
          final inches = (totalInches % 12).round();
          _heightController.text = feet.toString();
          _heightInchesController.text = inches.toString();
        }
      }
      
      if (profile.weightKg != null) {
        final weight = _selectedWeightUnit.fromKg(profile.weightKg!);
        _weightController.text = weight.toStringAsFixed(1);
      }
    } else {
      _selectedGender = 'Male';
      _selectedWeightUnit = WeightUnit.kg;
      _selectedHeightUnit = HeightUnit.cm;
      _selectedActivityLevel = ActivityLevel.moderatelyActive;
      _selectedCalorieGoal = CalorieGoal.maintain;
      _mealsPerDay = 3;
      _selectedAllergies = {};
      _selectedDietaryRestrictions = {};
      _preferredFoods = [];
      _customAllergies = [];
    }
  }

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

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Profile Updated'),
            description: Text('Your changes have been saved.'),
          ),
        );
        Navigator.pop(context);
      }
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

  void _addPreferredFood() {
    final food = _preferredFoodController.text.trim();
    if (food.isNotEmpty && !_preferredFoods.contains(food)) {
      setState(() {
        _preferredFoods.add(food);
        _preferredFoodController.clear();
      });
    }
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
  void dispose() {
    _heightController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _preferredFoodController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final profile = Provider.of<UserProvider>(context).userProfile;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Edit Profile', style: theme.textTheme.h4),
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
      body: ShadToaster(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShadForm(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              Color.lerp(theme.colorScheme.primary, Colors.white, 0.3)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(profile?.email ?? '', style: theme.textTheme.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Basic Info Card
                _buildSection(
                  theme,
                  icon: LucideIcons.user,
                  title: 'Basic Information',
                  children: [
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
                        if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Meals Per Day
                _buildSection(
                  theme,
                  icon: LucideIcons.utensilsCrossed,
                  title: 'Meals Per Day',
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
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$_mealsPerDay',
                            style: theme.textTheme.h3,
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
                  ],
                ),
                const SizedBox(height: 16),

                // Measurements
                _buildSection(
                  theme,
                  icon: LucideIcons.ruler,
                  title: 'Measurements',
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
                          if (height == null || height < 50 || height > 300) return 'Enter a valid height';
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
                                if (feet == null || feet < 1 || feet > 8) return 'Invalid';
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
                                  if (inches == null || inches < 0 || inches >= 12) return 'Invalid';
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
                const SizedBox(height: 16),

                // Activity Level
                _buildSection(
                  theme,
                  icon: LucideIcons.activity,
                  title: 'Activity Level',
                  children: [
                    ShadRadioGroup<ActivityLevel>(
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
                  ],
                ),
                const SizedBox(height: 16),

                // Calorie Goal
                _buildSection(
                  theme,
                  icon: LucideIcons.target,
                  title: 'Your Goal',
                  children: [
                    ShadRadioGroup<CalorieGoal>(
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
                              ShadBadge.outline(child: Text(adjustmentText)),
                            ],
                          ),
                          sublabel: Text(goal.description),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dietary Restrictions
                _buildSection(
                  theme,
                  icon: LucideIcons.utensils,
                  title: 'Dietary Restrictions',
                  children: [
                    Wrap(
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
                  ],
                ),
                const SizedBox(height: 16),

                // Allergies
                _buildSection(
                  theme,
                  icon: LucideIcons.triangleAlert,
                  iconColor: theme.colorScheme.destructive,
                  title: 'Food Allergies',
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
                    if (_customAllergies.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                    ],
                    const SizedBox(height: 12),
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
                                style: isSelected ? TextStyle(color: theme.colorScheme.destructive) : null,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Preferred Foods
                _buildSection(
                  theme,
                  icon: LucideIcons.heart,
                  title: 'Preferred Foods',
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
                const SizedBox(height: 32),

                // Save Button
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
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ShadThemeData theme, {
    required IconData icon,
    Color? iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return ShadCard(
      title: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
