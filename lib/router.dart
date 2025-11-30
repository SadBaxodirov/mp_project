import 'package:flutter/material.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/home/home_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/results/results_page.dart';
import 'screens/test/testList.dart';
import 'screens/test/test_page.dart';
import 'screens/test_preview/preparing_test_preview_screen.dart';
import 'screens/test_preview/test_preview_info_screen.dart';

class AppRouter {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const results = '/results';
  static const testList = '/testList';
  static const test = '/test';
  static const testPreviewInfo = '/testPreviewInfo';
  static const preparingTestPreview = '/preparingTestPreview';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    home: (_) => const HomePage(),
    profile: (_) => const ProfilePage(),
    results: (_) => const ResultsPage(),
    testList: (_) => const TestList(),
    test: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final testId = args['testId'] as int? ?? 0;
        final resumeAnswers =
            (args['resumeAnswers'] as Map?)?.cast<int, int?>();
        final resumeUserTestId = args['userTestId'] as int?;
        final resumeSectionIndex = args['resumeSectionIndex'] as int? ?? 0;
        return TestPage(
          testId: testId,
          resumeAnswers: resumeAnswers,
          resumeUserTestId: resumeUserTestId,
          resumeSectionIndex: resumeSectionIndex,
        );
      }
      final testIds = args is List<int> ? args : <int>[];
      final testId = testIds.isNotEmpty ? testIds.first : 0;
      return TestPage(testId: testId);
    },
    testPreviewInfo: (_) => const TestPreviewInfoScreen(),
    preparingTestPreview: (_) => const PreparingTestPreviewScreen(),
  };
}
