import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/state/auth_provider.dart';
import '../../router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'BB';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final name = user?.displayName ?? 'Student';
    final email = user?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2557D6).withOpacity(0.15),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2557D6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                _ProfileStatCard(
                  label: 'Tests taken',
                  value: '0',
                ),
                SizedBox(width: 12),
                _ProfileStatCard(
                  label: 'Average score',
                  value: '—',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _ProfileStatCard(
                  label: 'Last test date',
                  value: '—',
                  flex: 2,
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2557D6),
                side: const BorderSide(color: Color(0xFF2557D6)),
              ),
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    this.flex = 1,
  });

  final String label;
  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
