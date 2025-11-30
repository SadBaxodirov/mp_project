import 'package:flutter/material.dart';

import '../router.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _handleDestination(BuildContext context, int index) {
    final destinations = <int, String>{
      0: AppRouter.home,
      1: AppRouter.testList,
      2: AppRouter.results,
      3: AppRouter.profile,
    };

    final target = destinations[index];
    if (target == null) return;

    final current = ModalRoute.of(context)?.settings.name;
    if (current == target) return;

    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      onDestinationSelected: (index) => _handleDestination(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Tests',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Results',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
