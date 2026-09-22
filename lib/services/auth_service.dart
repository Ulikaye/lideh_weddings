import 'package:flutter/foundation.dart';

/// Same idea as the original app's `ADMIN_CREDENTIALS` list: a basic gate
/// for a small private tool, not real security (credentials are bundled in
/// the client, same as before). Edit the list below to change who can sign
/// in, or replace this whole service with Firebase Authentication if you
/// need real per-user accounts / password resets / audit trails later.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const List<Map<String, String>> _adminCredentials = [
    {'username': 'admin', 'password': 'harusi2026'},
    {'username': 'gate', 'password': 'gate2026'},
  ];

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool signIn(String username, String password) {
    final match = _adminCredentials.any(
      (c) => c['username'] == username && c['password'] == password,
    );
    if (match) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return match;
  }

  void signOut() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
