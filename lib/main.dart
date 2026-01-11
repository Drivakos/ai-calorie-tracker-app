import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_calorie_tracker/providers/food_provider.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';
import 'package:ai_calorie_tracker/screens/dashboard_screen.dart';
import 'package:ai_calorie_tracker/screens/login_screen.dart';
import 'package:ai_calorie_tracker/screens/profile_setup_screen.dart';
import 'package:ai_calorie_tracker/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool supabaseInitialized = false;
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    supabaseInitialized = true;
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(MyApp(supabaseInitialized: supabaseInitialized));
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final bool supabaseInitialized;

  const MyApp({super.key, required this.supabaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
      ],
      child: ShadApp(
        title: 'AI Calorie Tracker',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: ShadColorScheme.fromName('green'),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: ShadColorScheme.fromName('green', brightness: Brightness.dark),
        ),
        home: supabaseInitialized 
          ? const AuthWrapper()
          : const _ErrorScreen(),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ShadCard(
            title: const Text('Configuration Error'),
            description: const Text('Supabase is not configured properly.'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Make sure Supabase is running:\nnpx supabase start',
                  textAlign: TextAlign.center,
                  style: ShadTheme.of(context).textTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = ShadTheme.of(context);

    if (userProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Loading...', style: theme.textTheme.muted),
            ],
          ),
        ),
      );
    }

    if (userProvider.user == null) {
      return const LoginScreen();
    }

    if (userProvider.userProfile == null || 
        userProvider.userProfile!.heightCm == null) {
      return const ProfileSetupScreen();
    }

    return const DashboardScreen();
  }
}
