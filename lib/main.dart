import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WeddingQrApp());
}

class WeddingQrApp extends StatelessWidget {
  const WeddingQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harusi Cards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: AuthService.instance.isAuthenticated ? const HomeShell() : const LoginScreen(),
    );
  }
}
