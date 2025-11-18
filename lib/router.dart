import 'package:flutter/material.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home/home_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/results/results_page.dart';
import 'screens/test/testList.dart';
import 'screens/test/test_page.dart';

class AppRouter {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const results = '/results';
  static const testList = '/testList';
  static const test = '/test';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    home: (_) => const HomePage(),
    profile: (_) => const ProfilePage(),
    results: (_) => const ResultsPage(),
    testList: (_) => const TestList(),
    test: (_) => const TestPage(testList: []),
  };
}
