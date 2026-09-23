import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_form_card.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  void _submit() {
    final ok = AuthService.instance.signIn(_userCtrl.text.trim(), _passCtrl.text);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      setState(() => _error = 'Incorrect username or password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AppFormCard(
                maxWidth: 440,
                title: 'Harusi Cards',
                subtitle: 'Sign in to manage the wedding ledger.',
                children: [
                  Center(child: Image.asset('assets/logo.png', height: 64)),
                  const SizedBox(height: 24),
                  const AppFieldLabel('Username'),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(hintText: 'Enter your username'),
                  ),
                  const SizedBox(height: 18),
                  const AppFieldLabel('Password'),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Enter your password'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Developed by Emmanuel Albart Ulikaye',
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
