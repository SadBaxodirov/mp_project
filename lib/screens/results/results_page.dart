import 'package:flutter/material.dart';

import '../../widgets/main_navigation_bar.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results & Reports'),
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Best score',
                      value: '1310',
                      subtitle: 'Goal: 1400',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Avg. Reading/Writing',
                      value: '640',
                      subtitle: '3 tests',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Avg. Math',
                      value: '670',
                      subtitle: '3 tests',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Completed',
                      value: '6',
                      subtitle: 'out of 10 planned',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent tests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ..._recentTests.map((test) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          test.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${test.date} - Reading/Writing: ${test.rw} - Math: ${test.math}',
                        ),
                        trailing: Chip(
                          label: Text(test.total),
                          backgroundColor: const Color(0xFFE8EDFF),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            color: Color(0xFF2557D6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTest {
  const _RecentTest({
    required this.title,
    required this.date,
    required this.total,
    required this.rw,
    required this.math,
  });

  final String title;
  final String date;
  final String total;
  final String rw;
  final String math;
}

const _recentTests = <_RecentTest>[
  _RecentTest(
    title: 'SAT Practice Test 3',
    date: 'Nov 18',
    total: '1320',
    rw: '660',
    math: '660',
  ),
  _RecentTest(
    title: 'SAT Practice Test 2',
    date: 'Oct 30',
    total: '1280',
    rw: '640',
    math: '640',
  ),
  _RecentTest(
    title: 'Test Preview',
    date: 'Oct 14',
    total: 'Complete',
    rw: 'Previewed',
    math: 'Previewed',
  ),
];
