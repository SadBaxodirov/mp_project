import 'package:flutter/material.dart';

import '../../../core/api/token_storage.dart';
import '../data/auth_api.dart';
import '../data/models/auth_tokens.dart';
import '../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authApi);

  final AuthApi _authApi;

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
        currentUser = await _authApi.getCurrentUser();
      } catch (_) {
        await logout();
      }
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _withLoader(() async {
      final tokens = await _authApi.login(email: email, password: password);
      await _saveTokens(tokens);
      currentUser = await _authApi.getCurrentUser();
      notifyListeners();
    });
  }

  Future<void> register(String fullName, String email, String password) async {
    await _withLoader(() async {
      await _authApi.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      final tokens = await _authApi.login(email: email, password: password);
      await _saveTokens(tokens);
      currentUser = await _authApi.getCurrentUser();
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
