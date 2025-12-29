# Parking Host

A Flutter application for parking space hosts to manage their parking spots and bookings.

## Features

- **Secure Authentication**: Email/password and social login (Google, Apple) via Supabase
- **Role Management**: Users are automatically assigned the "host" role upon registration
- **Host Dashboard**: Manage parking spots, view bookings, and track earnings
- **Modern UI**: Built with Flutter Material 3 design system

## Setup

### Prerequisites

- Flutter SDK (3.10.3 or higher)
- Supabase account

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd praking_host
flutter pub get
```

### 2. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Settings > API and copy your project URL and anon key
3. Update `.env` file with your Supabase credentials:

```env
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 3. Create Database Tables

In your Supabase dashboard, go to SQL Editor and run:

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  role TEXT NOT NULL DEFAULT 'host',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

### 4. Configure OAuth (Optional)

For Google and Apple sign-in:

1. Go to Authentication > Providers in Supabase dashboard
2. Enable Google and Apple providers
3. Configure OAuth credentials from Google Cloud Console and Apple Developer Console
4. Update `.env` with OAuth client IDs if needed

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point with Supabase initialization
├── app_colors.dart           # Material 3 color scheme
├── services/
│   └── auth_service.dart     # Authentication service
└── screens/
    ├── splash_screen.dart    # Splash screen
    ├── login_screen.dart     # Login screen
    ├── signup_screen.dart    # Signup screen
    └── home_screen.dart      # Host dashboard
```

## Authentication Flow

1. Users see splash screen on app launch
2. If not authenticated, redirected to login/signup
3. Upon successful authentication, user role is set to "host"
4. Authenticated users see the host dashboard

## Technologies Used

- **Flutter**: UI framework
- **Supabase**: Backend as a Service (Auth, Database)
- **Material 3**: Design system
- **flutter_dotenv**: Environment variable management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
"# parking_partner_app" 
