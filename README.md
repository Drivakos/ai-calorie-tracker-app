# AI Calorie Tracker

A Flutter-based calorie tracking app with AI-powered food recognition and personalized nutrition recommendations.

## Features

### 📸 AI Food Recognition
- Take photos of your meals and let AI analyze the nutritional content
- Powered by Google Gemini for accurate food identification
- Get instant calorie, protein, carbs, and fat estimates

### 📊 TDEE Calculator
- Automatic BMR calculation using the Mifflin-St Jeor equation
- Activity level selection for accurate TDEE (Total Daily Energy Expenditure)
- Support for multiple activity levels from sedentary to extra active

### 🎯 Goal-Based Tracking
- Set your fitness goal: cut, maintain, or bulk
- Calorie adjustments from -500 to +500 based on your goal
- Dynamic daily calorie targets

### 📏 Unit Preferences
- Weight: kg or lbs
- Height: cm or feet/inches
- Automatic unit conversion and storage

### 🥗 Dietary Preferences & Allergies
- Select dietary restrictions (Vegetarian, Vegan, Keto, etc.)
- Track food allergies for safe AI recommendations
- Add preferred foods for personalized meal suggestions

### 🔐 Authentication
- Email/Password signup and login
- Google OAuth integration
- Magic link authentication
- Secure session management with Supabase

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth)
- **AI**: Google Gemini API
- **State Management**: Provider
- **Testing**: Flutter Test + Mockito

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Supabase CLI (for local development)
- Node.js (for Supabase functions)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_calorie_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create secrets file**
   
   Create `lib/secrets.dart` with your API keys:
   ```dart
   class Secrets {
     static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
   }
   ```

4. **Create Supabase config**
   
   Create `lib/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String url = 'YOUR_SUPABASE_URL';
     static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

5. **Start local Supabase (optional)**
   ```bash
   npx supabase start
   ```

6. **Apply database migrations**
   ```bash
   npx supabase db push --local
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── secrets.dart           # API keys (gitignored)
├── supabase_config.dart   # Supabase config (gitignored)
├── models/
│   ├── food_log.dart      # Food log model
│   └── user_profile.dart  # User profile with preferences
├── providers/
│   ├── food_provider.dart # Food log state management
│   └── user_provider.dart # User/auth state management
├── screens/
│   ├── analysis_screen.dart     # AI food analysis
│   ├── dashboard_screen.dart    # Main dashboard
│   ├── login_screen.dart        # Authentication
│   ├── manual_entry_screen.dart # Manual food entry
│   └── profile_setup_screen.dart # Profile wizard
├── services/
│   ├── auth_service.dart     # Authentication
│   ├── database_service.dart # Database operations
│   ├── gemini_service.dart   # AI integration
│   └── user_service.dart     # User profile CRUD
└── widgets/                  # Reusable widgets
```

## Database Schema

### user_profiles
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (auth.users FK) |
| email | TEXT | User email |
| height_cm | DOUBLE | Height in centimeters |
| weight_kg | DOUBLE | Weight in kilograms |
| age | INTEGER | User age |
| gender | TEXT | Male, Female, Other |
| weight_unit | TEXT | kg or lbs |
| height_unit | TEXT | cm or ft |
| activity_level | TEXT | sedentary to extra_active |
| calorie_goal | TEXT | aggressive_cut to aggressive_bulk |
| preferred_foods | TEXT[] | Array of preferred foods |
| allergies | TEXT[] | Array of food allergies |
| dietary_restrictions | TEXT[] | Array of dietary restrictions |

### food_logs
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to auth.users |
| name | TEXT | Food name |
| weight_grams | DOUBLE | Portion weight |
| calories | DOUBLE | Calorie count |
| protein | DOUBLE | Protein in grams |
| carbs | DOUBLE | Carbohydrates in grams |
| fat | DOUBLE | Fat in grams |
| meal_type | TEXT | Breakfast, Lunch, Dinner, Snack |
| logged_at | TIMESTAMPTZ | When the food was consumed |

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/user_profile_test.dart

# Run with coverage
flutter test --coverage
```

## Migrations

Database migrations are located in `supabase/migrations/`:

1. `20240111000000_initial_schema.sql` - Initial tables and RLS policies
2. `20240112000000_add_user_preferences.sql` - Units, activity, goals
3. `20240113000000_add_food_preferences.sql` - Dietary preferences & allergies

To apply migrations:
```bash
# Local
npx supabase db push --local

# Production (requires linking)
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

## Environment Variables

For production, set these environment variables or use the secrets files:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `GEMINI_API_KEY` | Google Gemini API key |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
