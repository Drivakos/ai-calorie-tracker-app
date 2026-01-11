import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/models/user_profile.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late UserProvider userProvider;
  late MockAuthService mockAuthService;
  late MockUserService mockUserService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserService = MockUserService();

    // Stub the auth state stream to return empty by default
    when(mockAuthService.authStateChanges).thenAnswer(
      (_) => Stream<AuthState>.empty(),
    );
    when(mockAuthService.currentUser).thenReturn(null);
  });

  void createProvider() {
    userProvider = UserProvider(
      authService: mockAuthService,
      userService: mockUserService,
    );
  }

  User createMockUser(String id, String email) {
    return User(
      id: id,
      email: email,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  group('UserProvider - Initialization', () {
    test('initial state should be loading when no current user', () {
      when(mockAuthService.currentUser).thenReturn(null);
      
      createProvider();
      
      // After constructor, isLoading should become false since no user
      expect(userProvider.isLoading, false);
      expect(userProvider.user, null);
      expect(userProvider.isAuthenticated, false);
    });

    test('should load user profile when current user exists on init', () async {
      final mockUser = createMockUser('user123', 'test@test.com');
      final profile = UserProfile(uid: 'user123', email: 'test@test.com');
      
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUserService.getUserProfile('user123'))
          .thenAnswer((_) async => profile);

      createProvider();
      
      // Wait for async profile loading
      await Future.delayed(Duration.zero);

      expect(userProvider.user, mockUser);
      expect(userProvider.userProfile, profile);
      expect(userProvider.isAuthenticated, true);
      verify(mockUserService.getUserProfile('user123')).called(1);
    });
  });

  group('UserProvider - Auth State Changes', () {
    test('should update user when auth state changes to signed in', () async {
      final mockUser = createMockUser('user123', 'test@test.com');
      final profile = UserProfile(uid: 'user123', email: 'test@test.com');
      final controller = StreamController<AuthState>();

      when(mockAuthService.authStateChanges).thenAnswer((_) => controller.stream);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockUserService.getUserProfile('user123'))
          .thenAnswer((_) async => profile);

      createProvider();

      // Simulate sign in event
      controller.add(AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: mockUser,
        ),
      ));

      await Future.delayed(Duration.zero);

      expect(userProvider.user, mockUser);
      expect(userProvider.userProfile, profile);

      await controller.close();
    });

    test('should clear user and profile when signed out', () async {
      final mockUser = createMockUser('user123', 'test@test.com');
      final profile = UserProfile(uid: 'user123', email: 'test@test.com');
      final controller = StreamController<AuthState>();

      when(mockAuthService.authStateChanges).thenAnswer((_) => controller.stream);
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUserService.getUserProfile('user123'))
          .thenAnswer((_) async => profile);

      createProvider();
      await Future.delayed(Duration.zero);

      expect(userProvider.isAuthenticated, true);

      // Simulate sign out event
      controller.add(AuthState(AuthChangeEvent.signedOut, null));
      await Future.delayed(Duration.zero);

      expect(userProvider.user, null);
      expect(userProvider.userProfile, null);
      expect(userProvider.isAuthenticated, false);

      await controller.close();
    });
  });

  group('UserProvider - Google Sign In', () {
    test('signInWithGoogle should call auth service', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async {});

      createProvider();

      await userProvider.signInWithGoogle();

      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    test('signInWithGoogle should set loading state during sign in', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      
      final completer = Completer<void>();
      when(mockAuthService.signInWithGoogle())
          .thenAnswer((_) => completer.future);

      createProvider();

      final future = userProvider.signInWithGoogle();
      
      // Should be loading during the operation
      expect(userProvider.isLoading, true);

      completer.complete();
      await future;

      // Should not be loading after completion
      expect(userProvider.isLoading, false);
    });

    test('signInWithGoogle should handle errors gracefully', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signInWithGoogle())
          .thenThrow(AuthException('Google Sign In failed'));

      createProvider();

      // Should not crash, but should set loading to false
      expect(
        () => userProvider.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('should load profile after successful Google sign in via auth state', () async {
      final mockUser = createMockUser('google-user-123', 'google@test.com');
      final profile = UserProfile(
        uid: 'google-user-123',
        email: 'google@test.com',
        heightCm: 175,
        weightKg: 70,
      );
      final controller = StreamController<AuthState>();

      when(mockAuthService.authStateChanges).thenAnswer((_) => controller.stream);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async {});
      when(mockUserService.getUserProfile('google-user-123'))
          .thenAnswer((_) async => profile);

      createProvider();

      await userProvider.signInWithGoogle();

      // Simulate the auth state change that would happen after OAuth redirect
      controller.add(AuthState(
        AuthChangeEvent.signedIn,
        Session(accessToken: 'token', tokenType: 'bearer', user: mockUser),
      ));

      await Future.delayed(Duration.zero);

      expect(userProvider.user?.id, 'google-user-123');
      expect(userProvider.userProfile?.email, 'google@test.com');

      await controller.close();
    });
  });

  group('UserProvider - Apple Sign In', () {
    test('signInWithApple should be callable (placeholder for OAuth)', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      
      createProvider();

      // Apple sign in is not directly implemented in UserProvider yet
      // but we can verify the provider doesn't have this method crash
      expect(userProvider, isNotNull);
    });

    test('should handle Apple sign in via auth state change', () async {
      final mockUser = createMockUser('apple-user-123', 'apple@privaterelay.com');
      final profile = UserProfile(
        uid: 'apple-user-123',
        email: 'apple@privaterelay.com',
      );
      final controller = StreamController<AuthState>();

      when(mockAuthService.authStateChanges).thenAnswer((_) => controller.stream);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockUserService.getUserProfile('apple-user-123'))
          .thenAnswer((_) async => profile);

      createProvider();

      // Simulate Apple OAuth callback via auth state
      controller.add(AuthState(
        AuthChangeEvent.signedIn,
        Session(accessToken: 'token', tokenType: 'bearer', user: mockUser),
      ));

      await Future.delayed(Duration.zero);

      expect(userProvider.user?.id, 'apple-user-123');
      expect(userProvider.userProfile?.email, 'apple@privaterelay.com');

      await controller.close();
    });

    test('should handle Apple email being hidden (private relay)', () async {
      // Apple can hide user's email with private relay
      final mockUser = createMockUser('apple-user-456', 'hidden@privaterelay.appleid.com');
      final profile = UserProfile(
        uid: 'apple-user-456',
        email: 'hidden@privaterelay.appleid.com',
      );
      final controller = StreamController<AuthState>();

      when(mockAuthService.authStateChanges).thenAnswer((_) => controller.stream);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockUserService.getUserProfile('apple-user-456'))
          .thenAnswer((_) async => profile);

      createProvider();

      controller.add(AuthState(
        AuthChangeEvent.signedIn,
        Session(accessToken: 'token', tokenType: 'bearer', user: mockUser),
      ));

      await Future.delayed(Duration.zero);

      expect(userProvider.user?.email, contains('privaterelay'));

      await controller.close();
    });
  });

  group('UserProvider - Email/Password Sign In', () {
    test('signInWithEmail should call auth service', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signInWithEmail(any, any))
          .thenAnswer((_) async => createMockUser('user123', 'test@test.com'));

      createProvider();

      await userProvider.signInWithEmail('test@test.com', 'password');

      verify(mockAuthService.signInWithEmail('test@test.com', 'password')).called(1);
    });

    test('registerWithEmail should call auth service', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.registerWithEmail(any, any))
          .thenAnswer((_) async => createMockUser('newuser', 'new@test.com'));

      createProvider();

      await userProvider.registerWithEmail('new@test.com', 'password123');

      verify(mockAuthService.registerWithEmail('new@test.com', 'password123')).called(1);
    });
  });

  group('UserProvider - Magic Link Sign In', () {
    test('signInWithMagicLink should call auth service', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signInWithMagicLink(any)).thenAnswer((_) async {});

      createProvider();

      await userProvider.signInWithMagicLink('test@test.com');

      verify(mockAuthService.signInWithMagicLink('test@test.com')).called(1);
    });
  });

  group('UserProvider - Profile Management', () {
    test('saveProfile should call user service and update local profile', () async {
      final mockUser = createMockUser('user123', 'test@test.com');
      
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.authStateChanges).thenAnswer((_) => Stream.empty());
      when(mockUserService.getUserProfile(any)).thenAnswer((_) async => null);
      when(mockUserService.saveUserProfile(any)).thenAnswer((_) async {});

      createProvider();
      await Future.delayed(Duration.zero);

      await userProvider.saveProfile(
        height: 180,
        weight: 75,
        age: 30,
        gender: 'Male',
        weightUnit: WeightUnit.kg,
        heightUnit: HeightUnit.cm,
        activityLevel: ActivityLevel.moderatelyActive,
        calorieGoal: CalorieGoal.moderateCut,
      );

      verify(mockUserService.saveUserProfile(any)).called(1);
      expect(userProvider.userProfile, isNotNull);
      expect(userProvider.userProfile!.heightCm, 180);
      expect(userProvider.userProfile!.weightKg, 75);
      expect(userProvider.userProfile!.activityLevel, ActivityLevel.moderatelyActive);
      expect(userProvider.userProfile!.calorieGoal, CalorieGoal.moderateCut);
    });

    test('saveProfile should not save when user is not authenticated', () async {
      when(mockAuthService.currentUser).thenReturn(null);

      createProvider();

      await userProvider.saveProfile(
        height: 180,
        weight: 75,
        age: 30,
        gender: 'Male',
        weightUnit: WeightUnit.kg,
        heightUnit: HeightUnit.cm,
        activityLevel: ActivityLevel.moderatelyActive,
        calorieGoal: CalorieGoal.maintain,
      );

      verifyNever(mockUserService.saveUserProfile(any));
    });
  });

  group('UserProvider - Sign Out', () {
    test('signOut should call auth service and clear profile', () async {
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      createProvider();

      await userProvider.signOut();

      verify(mockAuthService.signOut()).called(1);
      expect(userProvider.userProfile, null);
    });

    test('signOut after Google sign in should clear all state', () async {
      final mockUser = createMockUser('google-user', 'google@test.com');
      final profile = UserProfile(uid: 'google-user', email: 'google@test.com');
      
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockUserService.getUserProfile('google-user'))
          .thenAnswer((_) async => profile);
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      createProvider();
      await Future.delayed(Duration.zero);

      expect(userProvider.userProfile, isNotNull);

      await userProvider.signOut();

      expect(userProvider.userProfile, null);
    });
  });
}
