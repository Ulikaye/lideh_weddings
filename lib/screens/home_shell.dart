import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'add_contributor_screen.dart';
import 'event_setup_screen.dart';
import 'login_screen.dart';
import 'records_screen.dart';
import 'scan_screen.dart';
import 'verify_code_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // start on Records, like the original app after login

  static const _titles = [
    'Event Setup',
    'Add Contributor',
    'Records',
    'Scan / Check-in',
    'Verify Code',
  ];

  final _screens = const [
    EventSetupScreen(),
    AddContributorScreen(),
    RecordsScreen(),
    ScanScreen(),
    VerifyCodeScreen(),
  ];

  void _logout() {
    AuthService.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Harusi Cards'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kwa msaada zaidi: +255 788 939 812'),
            SizedBox(height: 8),
            Text('Developed by Emmanuel Albart Ulikaye'),
            Text('ulikaye635@gmail.com'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
          ),
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
          NavigationDestination(icon: Icon(Icons.pin), label: 'Verify'),
        ],
      ),
    );
  }
}
