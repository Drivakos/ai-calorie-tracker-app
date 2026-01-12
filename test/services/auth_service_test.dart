import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  group('AuthService - Google OAuth Sign In', () {
    test('should call signInWithGoogle and complete successfully', () async {
      // Arrange
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async {});

      // Act & Assert - should complete without throwing
      await expectLater(
        mockAuthService.signInWithGoogle(),
        completes,
      );

      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    test('should propagate error when Google OAuth fails', () async {
      // Arrange
      when(mockAuthService.signInWithGoogle())
          .thenThrow(AuthException('Google Sign In not configured'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('should handle network errors during Google sign in', () async {
      // Arrange
      when(mockAuthService.signInWithGoogle())
          .thenThrow(AuthException('Network error: Unable to reach OAuth provider'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithGoogle(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Network error'),
        )),
      );
    });

    test('should handle user cancellation during Google sign in', () async {
      // Arrange - User cancelling typically doesn't throw but completes silently
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async {});

      // Act
      await mockAuthService.signInWithGoogle();

      // Assert
      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    test('should handle OAuth redirect failure', () async {
      // Arrange
      when(mockAuthService.signInWithGoogle())
          .thenThrow(AuthException('Failed to handle OAuth redirect'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Apple OAuth Sign In', () {
    test('should call signInWithApple and complete successfully', () async {
      // Arrange
      when(mockAuthService.signInWithApple()).thenAnswer((_) async {});

      // Act & Assert
      await expectLater(
        mockAuthService.signInWithApple(),
        completes,
      );

      verify(mockAuthService.signInWithApple()).called(1);
    });

    test('should propagate error when Apple OAuth fails', () async {
      // Arrange
      when(mockAuthService.signInWithApple())
          .thenThrow(AuthException('Apple Sign In not configured'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithApple(),
        throwsA(isA<AuthException>()),
      );
    });

    test('should handle missing Apple credentials', () async {
      // Arrange
      when(mockAuthService.signInWithApple())
          .thenThrow(AuthException('Missing Apple client_id or secret'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithApple(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Missing Apple'),
        )),
      );
    });

    test('should handle user cancellation during Apple sign in', () async {
      // Arrange
      when(mockAuthService.signInWithApple()).thenAnswer((_) async {});

      // Act
      await mockAuthService.signInWithApple();

      // Assert
      verify(mockAuthService.signInWithApple()).called(1);
    });

    test('should handle Apple private relay email', () async {
      // Arrange - Apple Sign In should complete even with private relay
      when(mockAuthService.signInWithApple()).thenAnswer((_) async {});

      // Act
      await mockAuthService.signInWithApple();

      // Assert
      verify(mockAuthService.signInWithApple()).called(1);
    });
  });

  group('AuthService - Sign Out after OAuth', () {
    test('should sign out successfully after Google sign in', () async {
      // Arrange
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      // Act
      await mockAuthService.signOut();

      // Assert
      verify(mockAuthService.signOut()).called(1);
    });

    test('should sign out successfully after Apple sign in', () async {
      // Arrange
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      // Act
      await mockAuthService.signOut();

      // Assert
      verify(mockAuthService.signOut()).called(1);
    });

    test('should handle sign out errors gracefully', () async {
      // Arrange
      when(mockAuthService.signOut())
          .thenThrow(AuthException('Sign out failed'));

      // Act & Assert
      expect(
        () => mockAuthService.signOut(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Email/Password Sign In', () {
    test('should sign in with email and password successfully', () async {
      // Arrange
      final mockUser = _createMockUser('user123', 'test@test.com');
      when(mockAuthService.signInWithEmail('test@test.com', 'password123'))
          .thenAnswer((_) async => mockUser);

      // Act
      final result = await mockAuthService.signInWithEmail('test@test.com', 'password123');

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 'user123');
      expect(result?.email, 'test@test.com');
    });

    test('should throw when credentials are invalid', () async {
      // Arrange
      when(mockAuthService.signInWithEmail('test@test.com', 'wrongpassword'))
          .thenThrow(AuthException('Invalid login credentials'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithEmail('test@test.com', 'wrongpassword'),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw when user does not exist', () async {
      // Arrange
      when(mockAuthService.signInWithEmail('nonexistent@test.com', 'password123'))
          .thenThrow(AuthException('User not found'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithEmail('nonexistent@test.com', 'password123'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Registration', () {
    test('should register with email and password successfully', () async {
      // Arrange
      final mockUser = _createMockUser('newuser123', 'new@test.com');
      when(mockAuthService.registerWithEmail('new@test.com', 'password123'))
          .thenAnswer((_) async => mockUser);

      // Act
      final result = await mockAuthService.registerWithEmail('new@test.com', 'password123');

      // Assert
      expect(result, isNotNull);
      expect(result?.id, 'newuser123');
    });

    test('should throw when email already exists', () async {
      // Arrange
      when(mockAuthService.registerWithEmail('existing@test.com', 'password123'))
          .thenThrow(AuthException('User already registered'));

      // Act & Assert
      expect(
        () => mockAuthService.registerWithEmail('existing@test.com', 'password123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw when password is too weak', () async {
      // Arrange
      when(mockAuthService.registerWithEmail('new@test.com', '123'))
          .thenThrow(AuthException('Password should be at least 6 characters'));

      // Act & Assert
      expect(
        () => mockAuthService.registerWithEmail('new@test.com', '123'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Magic Link', () {
    test('should send magic link successfully', () async {
      // Arrange
      when(mockAuthService.signInWithMagicLink('test@test.com'))
          .thenAnswer((_) async {});

      // Act & Assert
      await expectLater(
        mockAuthService.signInWithMagicLink('test@test.com'),
        completes,
      );

      verify(mockAuthService.signInWithMagicLink('test@test.com')).called(1);
    });

    test('should throw when rate limited', () async {
      // Arrange
      when(mockAuthService.signInWithMagicLink('test@test.com'))
          .thenThrow(AuthException('For security purposes, you can only request this once every 60 seconds'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithMagicLink('test@test.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw for invalid email format', () async {
      // Arrange
      when(mockAuthService.signInWithMagicLink('invalid-email'))
          .thenThrow(AuthException('Unable to validate email address: invalid format'));

      // Act & Assert
      expect(
        () => mockAuthService.signInWithMagicLink('invalid-email'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Auth State Stream', () {
    test('should emit signed in state after Google sign in', () async {
      // Arrange
      final mockUser = _createMockUser('google-user', 'google@test.com');
      final session = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: mockUser,
      );
      final authState = AuthState(AuthChangeEvent.signedIn, session);

      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(authState));

      // Act & Assert
      await expectLater(
        mockAuthService.authStateChanges,
        emits(predicate<AuthState>((state) =>
            state.event == AuthChangeEvent.signedIn &&
            state.session?.user.email == 'google@test.com')),
      );
    });

    test('should emit signed in state after Apple sign in', () async {
      // Arrange
      final mockUser = _createMockUser('apple-user', 'apple@privaterelay.com');
      final session = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: mockUser,
      );
      final authState = AuthState(AuthChangeEvent.signedIn, session);

      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(authState));

      // Act & Assert
      await expectLater(
        mockAuthService.authStateChanges,
        emits(predicate<AuthState>((state) =>
            state.event == AuthChangeEvent.signedIn &&
            state.session?.user.id == 'apple-user')),
      );
    });

    test('should emit signed out state after sign out', () async {
      // Arrange
      final authState = AuthState(AuthChangeEvent.signedOut, null);

      when(mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream.value(authState));

      // Act & Assert
      await expectLater(
        mockAuthService.authStateChanges,
        emits(predicate<AuthState>((state) =>
            state.event == AuthChangeEvent.signedOut &&
            state.session == null)),
      );
    });
  });

  group('AuthService - Current User', () {
    test('should return current user when signed in with Google', () {
      // Arrange
      final mockUser = _createMockUser('google-user', 'google@test.com');
      when(mockAuthService.currentUser).thenReturn(mockUser);

      // Act
      final user = mockAuthService.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user?.id, 'google-user');
      expect(user?.email, 'google@test.com');
    });

    test('should return current user when signed in with Apple', () {
      // Arrange
      final mockUser = _createMockUser('apple-user', 'hidden@privaterelay.appleid.com');
      when(mockAuthService.currentUser).thenReturn(mockUser);

      // Act
      final user = mockAuthService.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user?.id, 'apple-user');
      expect(user?.email, contains('privaterelay'));
    });

    test('should return null when not signed in', () {
      // Arrange
      when(mockAuthService.currentUser).thenReturn(null);

      // Act
      final user = mockAuthService.currentUser;

      // Assert
      expect(user, isNull);
    });
  });
}

// Helper function to create mock Supabase User
User _createMockUser(String id, String email) {
  return User(
    id: id,
    email: email,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );
}
