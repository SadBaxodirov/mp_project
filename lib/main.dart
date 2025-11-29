import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'router.dart';
import 'core/api/user_api.dart';
import 'features/auth/state/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider(UserApi());
  await authProvider.loadFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: BluebookApp(
        initialRoute: authProvider.isLoggedIn
            ? AppRouter.home
            : AppRouter.login,
      ),
    ),
  );
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
