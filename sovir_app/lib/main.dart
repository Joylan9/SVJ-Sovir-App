import 'package:flutter/material.dart';
import 'frontend/create_account.dart';
import 'frontend/profile.dart';
import 'frontend/registration_success.dart';

// Global theme notifier (you’re already using this)
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  runApp(const SovirApp());
}

class SovirApp extends StatelessWidget {
  const SovirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Sovir App',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),

          // 👇 Routes
          initialRoute: '/create-account',
          routes: {
            '/create-account': (context) => const CreateAccountPage(),
            '/profile': (context) => const CreateProfilePage(),
            '/registration-success': (context) =>
                const RegistrationSuccessPage(),
          },
        );
      },
    );
  }
}
