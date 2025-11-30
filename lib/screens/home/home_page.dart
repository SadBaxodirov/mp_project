import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/test_api.dart';
import '../../core/models/test.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../router.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/main_navigation_bar.dart';

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

  Future<List<Test>> _loadTests() => _testApi.getTests();

  Future<void> _reload() async {
    setState(() {
      _testsFuture = _loadTests();
    });
    await _testsFuture;
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'BB';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final greetingName = user?.displayName ?? 'Student';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: const Row(
            children: [
              SizedBox(width: 4),
              AppLogo(size: 38),
              SizedBox(width: 12),
              Text(
                'Your Tests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.profile),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE5ECFF),
                  child: Text(
                    _initials(greetingName),
                    style: const TextStyle(
                      color: Color(0xFF2557D6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const MainNavigationBar(currentIndex: 0),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: SafeArea(
            child: FutureBuilder<List<Test>>(
              future: _testsFuture,
              builder: (context, snapshot) {
                final hasError = snapshot.hasError;
                final activeTests = _buildActiveTests(snapshot.data ?? []);
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasError) ...[
                        _ErrorBanner(onRetry: _reload),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Hi, $greetingName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeTests.isEmpty
                            ? "You don't have any active tests."
                            : 'You have ${activeTests.length} active ${activeTests.length == 1 ? 'test' : 'tests'}.',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Overall progress: 3 of 7 tests completed',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const TabBar(
                          indicatorColor: Color(0xFF2557D6),
                          labelColor: Color(0xFF2557D6),
                          unselectedLabelColor: Color(0xFF475569),
                          tabs: [
                            Tab(text: 'Active'),
                            Tab(text: 'Scheduled'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 330,
                        child: TabBarView(
                          children: [
                            _ActiveTestsTab(tests: activeTests),
                            const _ScheduledTestsTab(),
                            const _CompletedTestsTab(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _ProgressSummary(),
                      const SizedBox(height: 16),
                      _PracticeSection(
                        onCardTap: (card) {
                          if (card.route != null) {
                            Navigator.pushNamed(context, card.route!);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<_ActiveTestCardData> _buildActiveTests(List<Test> apiTests) {
    if (apiTests.isEmpty) return _sampleActiveTests;

    final mapped = apiTests.take(3).toList();
    return mapped.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;
      final progress = 0.35 + (index * 0.2);
      return _ActiveTestCardData(
        title: test.name,
        status: 'In progress - Practice mode',
        progress: progress.clamp(0.0, 1.0),
        timeRemaining: 'Untimed',
      );
    }).toList();
  }
}

class _ActiveTestsTab extends StatelessWidget {
  const _ActiveTestsTab({required this.tests});

  final List<_ActiveTestCardData> tests;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No active tests yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRouter.testList),
              icon: const Icon(Icons.add),
              label: const Text('Start a test'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final test = tests[index];
        return _ActiveTestCard(data: test);
      },
    );
  }
}

class _ScheduledTestsTab extends StatelessWidget {
  const _ScheduledTestsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sampleScheduledTests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final test = _sampleScheduledTests[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${test.dateLabel} - ${test.timeLabel}',
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        test.tag,
                        style: const TextStyle(
                          color: Color(0xFF2557D6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRouter.testPreviewInfo),
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompletedTestsTab extends StatelessWidget {
  const _CompletedTestsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sampleCompletedTests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final test = _sampleCompletedTests[index];
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
                        test.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(test.dateLabel),
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFE8EDFF),
                      labelStyle: const TextStyle(
                        color: Color(0xFF2557D6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  test.scoreSummary,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: test.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF2557D6),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.results),
                    child: const Text('View report'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActiveTestCard extends StatelessWidget {
  const _ActiveTestCard({required this.data});

  final _ActiveTestCardData data;

  @override
  Widget build(BuildContext context) {
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
                    data.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Timed mode',
                    style: TextStyle(
                      color: Color(0xFF2557D6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.status,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: data.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(12),
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2557D6),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  data.timeRemaining,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.test,
                      arguments: const <int>[0],
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Discard'),
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

class _PracticeSection extends StatelessWidget {
  const _PracticeSection({required this.onCardTap});

  final void Function(_PracticeCardData card) onCardTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Practice & Prepare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.testList),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _practiceCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final card = _practiceCards[index];
              return GestureDetector(
                onTap: () => onCardTap(card),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: card.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: card.color,
                        child: Icon(card.icon, color: Colors.white, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.subtitle,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Could not refresh your tests. Showing sample data.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _progressStats
                    .map((stat) => _CircularStat(
                          label: stat.label,
                          value: stat.value,
                          tests: stat.tests,
                          color: stat.color,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your best score',
                    style: TextStyle(
                      color: Color(0xFF2557D6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1310',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Goal: 1400',
                    style: TextStyle(color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      side: const BorderSide(color: Color(0xFF2557D6)),
                    ),
                    child: const Text('Set goal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularStat extends StatelessWidget {
  const _CircularStat({
    required this.label,
    required this.value,
    required this.tests,
    required this.color,
  });

  final String label;
  final double value;
  final int tests;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '$tests tests completed',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
        ),
      ],
    );
  }
}

class _ActiveTestCardData {
  const _ActiveTestCardData({
    required this.title,
    required this.status,
    required this.progress,
    required this.timeRemaining,
  });

  final String title;
  final String status;
  final double progress;
  final String timeRemaining;
}

class _ScheduledTestCardData {
  const _ScheduledTestCardData({
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.tag,
  });

  final String title;
  final String dateLabel;
  final String timeLabel;
  final String tag;
}

class _CompletedTestCardData {
  const _CompletedTestCardData({
    required this.title,
    required this.dateLabel,
    required this.scoreSummary,
    required this.progress,
  });

  final String title;
  final String dateLabel;
  final String scoreSummary;
  final double progress;
}

class _PracticeCardData {
  const _PracticeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
}

class _ProgressStat {
  const _ProgressStat({
    required this.label,
    required this.value,
    required this.tests,
    required this.color,
  });

  final String label;
  final double value;
  final int tests;
  final Color color;
}

const _sampleActiveTests = <_ActiveTestCardData>[
  _ActiveTestCardData(
    title: 'SAT Practice Test 2',
    status: 'In progress - Math module 2',
    progress: 0.6,
    timeRemaining: '45 min left (timed mode)',
  ),
  _ActiveTestCardData(
    title: 'SAT Practice Test 3',
    status: 'In progress - Reading & Writing module 1',
    progress: 0.32,
    timeRemaining: 'Untimed practice',
  ),
];

const _sampleScheduledTests = <_ScheduledTestCardData>[
  _ScheduledTestCardData(
    title: 'Mock exam',
    dateLabel: '23 Feb',
    timeLabel: '09:00',
    tag: 'Full test',
  ),
  _ScheduledTestCardData(
    title: 'SAT Practice Test 4',
    dateLabel: '02 Mar',
    timeLabel: '14:00',
    tag: 'Math focus',
  ),
];

const _sampleCompletedTests = <_CompletedTestCardData>[
  _CompletedTestCardData(
    title: 'SAT Practice Test 1',
    dateLabel: 'Last week',
    scoreSummary: 'Total: 1280 - Reading/Writing: 640 - Math: 640',
    progress: 0.82,
  ),
  _CompletedTestCardData(
    title: 'Test Preview',
    dateLabel: '2 weeks ago',
    scoreSummary: 'Finished preview modules',
    progress: 1,
  ),
];

const _practiceCards = <_PracticeCardData>[
  _PracticeCardData(
    title: 'Test Preview',
    subtitle: 'Try a short, untimed demo of the SAT.',
    icon: Icons.visibility,
    color: Color(0xFF2557D6),
    route: AppRouter.testPreviewInfo,
  ),
  _PracticeCardData(
    title: 'Mini Sections',
    subtitle: '10-15 questions focusing on one skill.',
    icon: Icons.bolt,
    color: Color(0xFF0EA5E9),
  ),
  _PracticeCardData(
    title: 'Timed Drills',
    subtitle: 'Practice under real pressure: 15-30 min.',
    icon: Icons.timer_outlined,
    color: Color(0xFF10B981),
  ),
  _PracticeCardData(
    title: 'Question Bank',
    subtitle: 'Practice by difficulty and topic.',
    icon: Icons.grid_view,
    color: Color(0xFF6366F1),
  ),
];

const _progressStats = <_ProgressStat>[
  _ProgressStat(
    label: 'Reading & Writing',
    value: 0.62,
    tests: 3,
    color: Color(0xFF2557D6),
  ),
  _ProgressStat(
    label: 'Math',
    value: 0.70,
    tests: 3,
    color: Color(0xFF10B981),
  ),
];
