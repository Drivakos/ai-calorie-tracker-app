import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:ai_calorie_tracker/screens/login_screen.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockUserProvider = MockUserProvider();
    
    // Default stubs
    when(mockUserProvider.isLoading).thenReturn(false);
    when(mockUserProvider.isAuthenticated).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<UserProvider>.value(
        value: mockUserProvider,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen - UI Rendering', () {
    testWidgets('renders login form by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('AI Calorie Tracker'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
    });

    testWidgets('toggling switch changes to Sign Up mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Login'), findsOneWidget);
    });

    testWidgets('renders magic link option', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Use magic link (passwordless)'), findsOneWidget);
    });

    testWidgets('renders OR divider', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('shows message when social login not available on platform', (WidgetTester tester) async {
      // In test environment, we're not on web/mobile, so social login is disabled
      await tester.pumpWidget(createWidgetUnderTest());

      // Either shows social buttons OR shows the "not available" message
      final hasSocialButtons = find.text('Continue with Google').evaluate().isNotEmpty;
      final hasNotAvailableMessage = find.text('Social Login available on Mobile & Web').evaluate().isNotEmpty;
      
      expect(hasSocialButtons || hasNotAvailableMessage, true);
    });
  });

  group('LoginScreen - Email/Password Sign In', () {
    testWidgets('tap Login calls signInWithEmail with valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      verify(mockUserProvider.signInWithEmail('test@test.com', 'password123')).called(1);
    });

    testWidgets('shows validation error for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invalidemail');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
      verifyNever(mockUserProvider.signInWithEmail(any, any));
    });

    testWidgets('shows validation error for short password', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '12345');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Min 6 chars'), findsOneWidget);
      verifyNever(mockUserProvider.signInWithEmail(any, any));
    });

    testWidgets('shows error snackbar when sign in fails', (WidgetTester tester) async {
      when(mockUserProvider.signInWithEmail(any, any))
          .thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  group('LoginScreen - Magic Link Sign In', () {
    testWidgets('switching to magic link mode hides password field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially password field is visible
      expect(find.text('Password'), findsOneWidget);

      // Tap magic link toggle
      await tester.tap(find.text('Use magic link (passwordless)'));
      await tester.pump();

      // Password field should be hidden
      expect(find.text('Password'), findsNothing);
      expect(find.text('Send Magic Link'), findsOneWidget);
    });

    testWidgets('magic link button calls signInWithMagicLink', (WidgetTester tester) async {
      when(mockUserProvider.signInWithMagicLink(any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createWidgetUnderTest());

      // Switch to magic link mode
      await tester.tap(find.text('Use magic link (passwordless)'));
      await tester.pump();

      // Enter email
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');

      // Tap send
      await tester.tap(find.text('Send Magic Link'));
      await tester.pump();

      verify(mockUserProvider.signInWithMagicLink('test@test.com')).called(1);
    });

    testWidgets('shows success message after sending magic link', (WidgetTester tester) async {
      when(mockUserProvider.signInWithMagicLink(any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Use magic link (passwordless)'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Check your email'), findsOneWidget);
    });

    testWidgets('can toggle back from magic link to password mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Switch to magic link
      await tester.tap(find.text('Use magic link (passwordless)'));
      await tester.pump();
      expect(find.text('Password'), findsNothing);

      // Switch back to password
      await tester.tap(find.text('Use password instead'));
      await tester.pump();
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error when magic link fails', (WidgetTester tester) async {
      when(mockUserProvider.signInWithMagicLink(any))
          .thenThrow(Exception('Rate limited'));
      
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Use magic link (passwordless)'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  group('LoginScreen - Registration', () {
    testWidgets('tap Sign Up calls registerWithEmail', (WidgetTester tester) async {
      when(mockUserProvider.registerWithEmail(any, any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createWidgetUnderTest());

      // Switch to sign up mode
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'new@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      verify(mockUserProvider.registerWithEmail('new@test.com', 'password123')).called(1);
    });

    testWidgets('shows success snackbar after registration', (WidgetTester tester) async {
      when(mockUserProvider.registerWithEmail(any, any)).thenAnswer((_) async {});
      
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'new@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Account created'), findsOneWidget);
    });

    testWidgets('shows error when registration fails', (WidgetTester tester) async {
      when(mockUserProvider.registerWithEmail(any, any))
          .thenThrow(Exception('User already exists'));
      
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'existing@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  group('LoginScreen - Form Validation', () {
    testWidgets('empty email shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('empty password shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Min 6 chars'), findsOneWidget);
    });
  });
}
