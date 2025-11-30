import 'package:flutter/material.dart';

import '../../core/api/test_api.dart';
import '../../core/models/test.dart';
import '../../router.dart';
import '../../widgets/main_navigation_bar.dart';

class TestList extends StatefulWidget {
  const TestList({super.key});

  @override
  State<TestList> createState() => _TestListState();
}

class _TestListState extends State<TestList> {
  final _searchController = TextEditingController();
  final _testApi = TestApi();
  late Future<List<Test>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _loadTests();
  }

  Future<List<Test>> _loadTests() => _testApi.getTests();

  Future<void> _reload() async {
    setState(() {
      _testsFuture = _loadTests();
    });
    await _testsFuture;
  }

  List<Test> _filteredTests(List<Test> tests) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return tests;

    return tests.where((test) {
      final name = test.name.toLowerCase();
      final description = test.description.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Tests'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRouter.home),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Test>>(
                    future: _testsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return _ErrorState(
                          message: 'Failed to load tests',
                          onRetry: _reload,
                        );
                      }

                      final tests = _filteredTests(snapshot.data ?? []);
                      if (tests.isEmpty) {
                        return const Center(
                          child: Text('No tests available.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: tests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final test = tests[index];
                          return _TestCard(
                            test: test,
                            onStart: () => Navigator.pushNamed(
                              context,
                              AppRouter.test,
                              arguments: <int>[test.id],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search tests...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            controller.clear();
            FocusScope.of(context).unfocus();
            onChanged();
          },
          icon: const Icon(Icons.close),
        )
            : null,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.onStart,
  });

  final Test test;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              test.description,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStart,
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
