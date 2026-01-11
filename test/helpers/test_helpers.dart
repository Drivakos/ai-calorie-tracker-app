import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ai_calorie_tracker/services/database_service.dart';
import 'package:ai_calorie_tracker/services/auth_service.dart';
import 'package:ai_calorie_tracker/services/user_service.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';

@GenerateMocks([
  DatabaseService,
  AuthService,
  UserService,
  UserProvider,
  SupabaseClient,
  GoTrueClient,
])
void main() {}
