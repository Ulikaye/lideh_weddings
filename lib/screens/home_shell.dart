import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'add_contributor_screen.dart';
import 'event_setup_screen.dart';
import 'login_screen.dart';
import 'records_screen.dart';
import 'scan_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // start on Records, like the original app after login

  static const _titles = ['Event Setup', 'Add Contributor', 'Records', 'Scan / Check-in'];

  final _screens = const [
    EventSetupScreen(),
    AddContributorScreen(),
    RecordsScreen(),
    ScanScreen(),
  ];

  void _logout() {
    AuthService.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Event'),
          NavigationDestination(icon: Icon(Icons.person_add_alt), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        ],
      ),
    );
  }
}
