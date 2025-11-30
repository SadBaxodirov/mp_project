import 'package:flutter/material.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/api/user_api.dart';
import '../../../core/models/auth_tokens.dart';
import '../../../core/models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._userApi);

  final UserApi _userApi;

  User? currentUser;
  String? accessToken;
  String? refreshToken;

  bool _isLoading = false;
  bool _isInitializing = true;

  bool get isLoading => _isLoading;

  bool get isInitializing => _isInitializing;

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  Future<void> loadFromStorage() async {
    accessToken = await TokenStorage.getAccess();
    refreshToken = await TokenStorage.getRefresh();
    if (isLoggedIn) {
      try {
        currentUser = await _userApi.getCurrentUser();
      } catch (_) {
        await logout();
      }
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await _withLoader(() async {
      final tokens =
          await _userApi.login(username: username, password: password);
      await _saveTokens(tokens);
      currentUser = await _userApi.getCurrentUser();
      notifyListeners();
    });
  }

  Future<void> register(
      String username,
      String firstName,
      String lastName,
      String school,
      String grade,
      String phoneNumber,
      String email,
      String password) async {
    await _withLoader(() async {
      final newUser = User(
          username: username,
          firstName: firstName,
          lastName: lastName,
          school: school,
          grade: grade,
          phoneNumber: phoneNumber,
          email: email);
      await _userApi.register(
        user: newUser,
        password: password,
      );
      final tokens =
          await _userApi.login(username: username, password: password);
      await _saveTokens(tokens);
      currentUser = await _userApi.getCurrentUser();
      notifyListeners();
    });
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    currentUser = null;
    await TokenStorage.clear();
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (!isLoggedIn) return;
    try {
      currentUser = await _userApi.getCurrentUser();
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? school,
    String? grade,
    String? phoneNumber,
    String? email,
  }) async {
    await _withLoader(() async {
      final existing = currentUser;
      if (existing == null) throw Exception('Not logged in');
      final updated = await _userApi.updateCurrentUser(
        username: username,
        firstName: firstName,
        lastName: lastName,
        school: school,
        grade: grade,
        phoneNumber: phoneNumber,
        email: email,
        existing: existing,
      );
      currentUser = updated;
      notifyListeners();
    });
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    accessToken = tokens.access;
    refreshToken = tokens.refresh;
    await TokenStorage.saveTokens(tokens.access, tokens.refresh);
  }

  Future<void> _withLoader(Future<void> Function() action) async {
    _isLoading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
