import 'package:flutter/material.dart';
import 'frontend/create_account.dart';
import 'frontend/profile.dart';
import 'frontend/registration_success.dart';
import 'frontend/login.dart';
import 'frontend/forgot_password.dart';

// Global theme notifier (you’re already using this)


void main() {
  runApp(const SovirApp());
}

class SovirApp extends StatelessWidget {
  const SovirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sovir App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

          // 👇 Routes
          initialRoute: '/login',
          routes: {
            '/create-account': (context) => const CreateAccountPage(),
            '/login': (context) => const LoginPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/profile': (context) => const CreateProfilePage(),
            '/registration-success': (context) =>
                const RegistrationSuccessPage(),
          },
        );
  }
}
