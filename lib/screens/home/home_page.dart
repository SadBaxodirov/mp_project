import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/test_api.dart';
import '../../core/models/test.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _testApi = TestApi();
  late Future<List<Test>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  Future<List<Test>> _loadTests() {
    return _testApi.getTests();
  }

  Future<void> _reload() async {
    setState(() {
      _testsFuture = _loadTests();
    });
    await _testsFuture;
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bluebook'),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null ? 'Welcome back, ${user.displayName}' : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Tests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TabBar(
                      indicatorColor: Color(0xFF2557D6),
                      labelColor: Color(0xFF2557D6),
                      unselectedLabelColor: Color(0xFF475569),
                      tabs: [
                        Tab(text: 'Active'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Test>>(
                    future: _testsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 220,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Could not load tests right now.'),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _reload,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final tests = snapshot.data ?? [];
                      final pastTests = tests.length > 1 ? tests.sublist(0, tests.length ~/ 2) : <Test>[];

                      return SizedBox(
                        height: 280,
                        child: TabBarView(
                          children: [
                            _ActiveTestsTab(
                              tests: tests,
                              onSignOut: () => _signOut(context),
                            ),
                            _PastTestsTab(
                              tests: pastTests,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _PracticeSection(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.testPreviewInfo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTestsTab extends StatelessWidget {
  const _ActiveTestsTab({
    required this.tests,
    required this.onSignOut,
  });

  final List<Test> tests;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You have no upcoming tests.'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: tests.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final test = tests[index];
        return Card(
          child: ListTile(
            title: Text(test.name),
            subtitle: Text(test.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.test,
              arguments: <int>[test.id],
            ),
          ),
        );
      },
    );
  }
}

class _PastTestsTab extends StatelessWidget {
  const _PastTestsTab({required this.tests});

  final List<Test> tests;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return const Center(
        child: Text('No past tests yet.'),
      );
    }

    return ListView.separated(
      itemCount: tests.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final test = tests[index];
        return Card(
          child: ListTile(
            title: Text(test.name),
            subtitle: Text('Score pending • ${test.code ?? 'No code'}'),
          ),
        );
      },
    );
  }
}

class _PracticeSection extends StatelessWidget {
  const _PracticeSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice and Prepare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              onTap: onTap,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2557D6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Color(0xFF2557D6),
                ),
              ),
              title: const Text(
                'Test Preview',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle:
                  const Text('Explore the test format before your exam.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
