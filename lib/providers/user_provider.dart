import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';
import 'package:ai_calorie_tracker/services/auth_service.dart';
import 'package:ai_calorie_tracker/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  UserProvider({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService() {
    _init();
  }

  void _init() {
    // Check current session first
    _user = _authService.currentUser;
    if (_user != null) {
      _loadUserProfile();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    // Listen for auth state changes
    _authSubscription = _authService.authStateChanges.listen((AuthState state) async {
      final AuthChangeEvent event = state.event;
      final Session? session = state.session;

      debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn || 
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _user = session?.user;
        if (_user != null) {
          await _loadUserProfile();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    
    try {
      _userProfile = await _userService.getUserProfile(_user!.id);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.registerWithEmail(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithMagicLink(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> saveProfile({
    required double height, // Always in cm
    required double weight, // Always in kg
    required int age,
    required String gender,
    required WeightUnit weightUnit,
    required HeightUnit heightUnit,
    required ActivityLevel activityLevel,
    required CalorieGoal calorieGoal,
    required int mealsPerDay,
    List<String> preferredFoods = const [],
    List<String> allergies = const [],
    List<String> dietaryRestrictions = const [],
  }) async {
    if (_user == null) return;

    final profile = UserProfile(
      uid: _user!.id,
      email: _user!.email ?? '',
      heightCm: height,
      weightKg: weight,
      age: age,
      gender: gender,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
      activityLevel: activityLevel,
      calorieGoal: calorieGoal,
      mealsPerDay: mealsPerDay,
      preferredFoods: preferredFoods,
      allergies: allergies,
      dietaryRestrictions: dietaryRestrictions,
      createdAt: _userProfile?.createdAt ?? DateTime.now(),
    );

    await _userService.saveUserProfile(profile);
    _userProfile = profile;
    notifyListeners();
  }

  /// Update only the calorie goal (for quick changes from settings)
  Future<void> updateCalorieGoal(CalorieGoal goal) async {
    if (_user == null || _userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(calorieGoal: goal);
    await _userService.saveUserProfile(updatedProfile);
    _userProfile = updatedProfile;
    notifyListeners();
  }

  /// Update food preferences (for quick changes from settings)
  Future<void> updateFoodPreferences({
    List<String>? preferredFoods,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
  }) async {
    if (_user == null || _userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      preferredFoods: preferredFoods,
      allergies: allergies,
      dietaryRestrictions: dietaryRestrictions,
    );
    await _userService.saveUserProfile(updatedProfile);
    _userProfile = updatedProfile;
    notifyListeners();
  }

  /// Refresh user profile from database
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
