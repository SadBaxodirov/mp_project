import 'package:flutter/material.dart';
import '../../router.dart';
import '../../services/auth_local.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthLocal.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluebook Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _dashboardCard(
                    icon: Icons.person,
                    title: "Profile",
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.profile),
                  ),
                  _dashboardCard(
                    icon: Icons.list_alt,
                    title: "Test List",
                    color: Colors.green,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.testList),
                  ),
                  _dashboardCard(
                    icon: Icons.quiz,
                    title: "Take Test",
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, AppRouter.test),
                  ),
                  _dashboardCard(
                    icon: Icons.score,
                    title: "My Results",
                    color: Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.results),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _signOut(context),
        label: const Text('Sign out'),
        icon: const Icon(Icons.logout),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
