//SHOULD BE CHANGED TO USERNAME BASED AUTH
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocal {
  AuthLocal._();

  static final instance = AuthLocal._();
  static const _kSignedIn = 'signed_in';
  static const _kEmail = 'email';

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSignedIn) ?? false;
  }

  Future<void> signIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSignedIn, true);
    await prefs.setString(_kEmail, email);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSignedIn);
    await prefs.remove(_kEmail);
  }

  Future<String?> email() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }
}
