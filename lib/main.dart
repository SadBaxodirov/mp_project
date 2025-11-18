import 'package:flutter/material.dart';

import 'router.dart';
import 'services/auth_local.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isSignedIn = await AuthLocal.instance.isSignedIn();
  runApp(BluebookApp(
    initialRoute: isSignedIn ? AppRouter.home : AppRouter.login,
  ));
}


class BluebookApp extends StatelessWidget {
  final String initialRoute;

  const BluebookApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluebook Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      routes: AppRouter.routes,
    );
  }
}
