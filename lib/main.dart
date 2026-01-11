import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      child: MaterialApp(
        title: 'AI Calorie Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: supabaseInitialized 
          ? const AuthWrapper()
          : const Scaffold(body: Center(child: Text('Supabase Configuration Error\n\nMake sure Supabase is running:\nnpx supabase start', textAlign: TextAlign.center))),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
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
