import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/test_api.dart';
import '../../core/api/user_test_api.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../widgets/main_navigation_bar.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _userTestApi = UserTestApi();
  final _testApi = TestApi();
  late Future<_ResultsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadResults();
  }

  Future<_ResultsData> _loadResults() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return const _ResultsData.empty(message: 'Please sign in to see results.');
    }

    try {
      final userTests = await _userTestApi.getUserTests(userId: user.id);
      final tests = await _testApi.getTests();
      final names = {for (final t in tests) t.id: t.name};

      final rows = userTests
          .map(
            (ut) => _ResultRow(
              title: names[ut.test] ?? 'Test ${ut.test}',
              math: ut.mathScore,
              english: ut.englishScore,
              total: ut.mathScore + ut.englishScore,
              date: ut.createdAt,
            ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return rows.isEmpty
          ? const _ResultsData.empty(message: 'No completed tests yet.')
          : _ResultsData(rows: rows);
    } catch (e) {
      return _ResultsData.error('Failed to load results: $e');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadResults();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<_ResultsData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data;
              if (data == null) {
                return const Center(child: Text('Loading...'));
              }
              if (data.error != null) {
                return _ErrorState(
                  message: data.error!,
                  onRetry: _reload,
                );
              }
              if (data.rows.isEmpty) {
                return _EmptyState(message: data.emptyMessage ?? 'No results.');
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: data.rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = data.rows[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(row.date),
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _ScoreChip(
                                label: 'Math',
                                value: row.math,
                                color: const Color(0xFF2563EB),
                              ),
                              _ScoreChip(
                                label: 'English',
                                value: row.english,
                                color: const Color(0xFF10B981),
                              ),
                              _ScoreChip(
                                label: 'Total',
                                value: row.total,
                                color: const Color(0xFF111827),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow {
  const _ResultRow({
    required this.title,
    required this.math,
    required this.english,
    required this.total,
    required this.date,
  });

  final String title;
  final double math;
  final double english;
  final double total;
  final DateTime date;
}

class _ResultsData {
  const _ResultsData({
    required this.rows,
    this.emptyMessage,
    this.error,
  });

  const _ResultsData.empty({required String message})
      : rows = const [],
        emptyMessage = message,
        error = null;

  const _ResultsData.error(String err)
      : rows = const [],
        emptyMessage = null,
        error = err;

  final List<_ResultRow> rows;
  final String? emptyMessage;
  final String? error;
}
