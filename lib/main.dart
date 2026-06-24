import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; 

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/register_screen.dart'; 
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart'; 
import 'screens/dashboard/dashboard_screen.dart'; 
import 'screens/task/add_task_screen.dart';
import 'screens/task/task_detail_screen.dart';
import 'screens/task/edit_task_screen.dart';
import 'package:mon_projet/screens/search/search_screen.dart';
import 'screens/notification/notification_screen.dart'; 
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  // 1. Assure la liaison avec les services natifs
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Initialise TOUTES les langues pour le formatage des dates (Règle l'erreur rouge)
  await initializeDateFormatting(null, null);

  // 4. Lance l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(), 
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add-task': (context) => const AddTaskScreen(),
        '/task-details': (context) => const TaskDetailsScreen(),
        '/edit-task': (context) => const EditTaskScreen(),
        '/search': (context) => SearchScreen(),
        '/notifications': (context) => const NotificationsScreen(), 
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}