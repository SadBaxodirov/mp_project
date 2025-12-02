import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/test_api.dart';
import '../../core/api/user_test_api.dart';
import '../../core/models/test.dart';
import '../../core/models/user_test.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../router.dart';
import '../../utils/DB_answers.dart';
import '../../utils/DB_progress.dart';
import '../../utils/DB_tests.dart';
import '../../utils/profile_photo_store.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/main_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _testApi = TestApi();
  final _userTestApi = UserTestApi();
  final _photoStore = ProfilePhotoStore.instance;
  final DatabaseHelper _answersDb = DatabaseHelper.instance;
  final DatabaseHelperTests _testsDb = DatabaseHelperTests.instance;
  final DatabaseHelperProgress _progressDb = DatabaseHelperProgress.instance;

  Uint8List? _photoBytes;
  late Future<_HomeData> _homeFuture;

  // goal / progress state (from first version)
  static const _goalPrefsKey = 'home_goal_score';
  int _goalScore = 1400;
  final int _bestScore = 1310;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
    _loadProfilePhoto();
    _loadGoal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When returning to this page after navigating away, refresh data
    // so newly saved progress shows up without manual pull-to-refresh.
    if (_didInitialLoad) {
      _reload();
    } else {
      _didInitialLoad = true;
    }
  }

  Future<void> _loadProfilePhoto() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      if (_photoBytes != null) {
        setState(() => _photoBytes = null);
      }
      return;
    }

    try {
      final bytes = await _photoStore.loadPhoto(userId);
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _homeFuture = _loadHomeData();
    });
    await _homeFuture;
    await _loadProfilePhoto();
  }

  Future<void> _loadGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedGoal = prefs.getInt(_goalPrefsKey);
      if (storedGoal != null && mounted) {
        setState(() => _goalScore = storedGoal);
      }
    } catch (e) {
      debugPrint('Error loading goal: $e');
    }
  }

  Future<void> _saveGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalPrefsKey, goal);
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  Future<_HomeData> _loadHomeData() async {
    final List<Test> tests = await _testApi.getTests();
    final testNameById = {for (final t in tests) t.id: t.name};

    final userId = context.read<AuthProvider>().currentUser?.id;
    List<UserTest> completed = [];
    if (userId != null) {
      try {
        completed = await _userTestApi.getUserTests(userId: userId);
      } catch (e) {
        debugPrint('Failed to load completed tests: $e');
      }
    }

    final progressRows = await _progressDb.getAll();
    final active = <_ActiveTestCardData>[];

    for (final row in progressRows) {
      final testId = (row['test_id'] as num?)?.toInt();
      final userTestId = (row['user_test_id'] as num?)?.toInt();
      if (testId == null || userTestId == null) continue;

      final sectionIndex = (row['section_index'] as num?)?.toInt() ?? 0;
      final millisLeft = (row['millis_left'] as num?)?.toInt() ?? 0;
      final title = testNameById[testId] ?? 'Test $testId';
      final status = _sectionName(sectionIndex);
      final timeRemaining = _formatMillis(millisLeft);
      final progress = await _computeProgress(testId, userTestId);

      active.add(
        _ActiveTestCardData(
          testId: testId,
          userTestId: userTestId,
          sectionIndex: sectionIndex,
          title: title,
          status: 'Resume $status',
          progress: progress,
          timeRemaining: timeRemaining,
        ),
      );
    }

    final completedCards = completed.map((ut) {
      final title = testNameById[ut.test] ?? 'Test ${ut.test}';
      final total = (ut.mathScore + ut.englishScore).toStringAsFixed(0);
      final math = ut.mathScore.toStringAsFixed(0);
      final eng = ut.englishScore.toStringAsFixed(0);
      final scoreSummary =
          'Total: $total - Reading/Writing: $eng - Math: $math';
      final dateLabel = ut.createdAt.toLocal().toString().split(' ').first;
      return _CompletedTestCardData(
        title: title,
        dateLabel: dateLabel,
        scoreSummary: scoreSummary,
        progress: 1,
      );
    }).toList();

    return _HomeData(
      activeTests: active,
      completedTests: completedCards,
    );
  }

  String _sectionName(int index) {
    switch (index) {
      case 0:
        return 'Reading and Writing 1';
      case 1:
        return 'Reading and Writing 2';
      case 2:
        return 'Math 1';
      case 3:
        return 'Math 2';
      default:
        return 'Section ${index + 1}';
    }
  }

  Future<double> _computeProgress(int testId, int userTestId) async {
    try {
      final cachedQuestions = await _testsDb.getTestsById(testId);
      final total = cachedQuestions.length;
      if (total == 0) return 0;

      final answers = await _answersDb.getByUserTestId(userTestId);
      final answered = answers.length;
      return (answered / total).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error computing progress: $e');
      return 0;
    }
  }

  String _formatMillis(int millis) {
    if (millis <= 0) return 'Time saved';
    final totalSeconds = (millis / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s left';
  }

  Future<void> _editGoal() async {
    final controller = TextEditingController(text: '$_goalScore');
    final newGoal = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set your goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick a score to work toward. You can adjust this anytime.',
                style: TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Goal score',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final parsed = int.tryParse(controller.text);
                        if (parsed == null || parsed < 400 || parsed > 1600) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter a score between 400 and 1600.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, parsed);
                      },
                      child: const Text('Save goal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || newGoal == null) return;
    setState(() => _goalScore = newGoal);
    await _saveGoal(newGoal);
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
              onTap: () async {
                await Navigator.pushNamed(context, AppRouter.profile);
                await _loadProfilePhoto();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE5ECFF),
                  backgroundImage:
                  _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                  child: _photoBytes == null
                      ? Text(
                    _initials(greetingName),
                    style: const TextStyle(
                      color: Color(0xFF2557D6),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                      : null,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const MainNavigationBar(currentIndex: 0),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: SafeArea(
            child: FutureBuilder<_HomeData>(
              future: _homeFuture,
              builder: (context, snapshot) {
                final hasError = snapshot.hasError;
                final data = snapshot.data;
                final activeTests = data?.activeTests ?? const [];
                final completedTests = data?.completedTests ?? const [];
                final completedLabel =
                    'Overall progress: ${completedTests.length} test${completedTests.length == 1 ? '' : 's'} completed';
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
                      Text(
                        completedLabel,
                        style: const TextStyle(
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
                            _ActiveTestsTab(
                              tests: activeTests,
                            ),
                            const _ScheduledTestsTab(),
                            _CompletedTestsTab(tests: completedTests),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProgressSummary(
                        bestScore: _bestScore,
                        goalScore: _goalScore,
                        onEditGoal: _editGoal,
                      ),
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

}

class _ActiveTestsTab extends StatelessWidget {
  const _ActiveTestsTab({
    required this.tests,
  });

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No scheduled tests.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRouter.testList),
            child: const Text('Find a test'),
          ),
        ],
      ),
    );
  }
}

class _CompletedTestsTab extends StatelessWidget {
  const _CompletedTestsTab({required this.tests});

  final List<_CompletedTestCardData> tests;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No completed tests yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.testList),
              child: const Text('Start a test'),
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

/// Active test card: keeps testId-based navigation *and* resume-latest callback
class _ActiveTestCard extends StatelessWidget {
  const _ActiveTestCard({
    required this.data,
  });

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
                      arguments: {
                        'testId': data.testId,
                        'userTestId': data.userTestId,
                        'resumeSectionIndex': data.sectionIndex,
                      },
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
        LayoutBuilder(
          builder: (context, constraints) {
            final canWrap = constraints.maxWidth > 520;
            if (canWrap) {
              final wrapWidth = constraints.maxWidth >= 880 ? 200.0 : 220.0;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: _practiceCards
                    .map(
                      (card) => _PracticeCard(
                    data: card,
                    width: wrapWidth,
                    onTap: () => onCardTap(card),
                  ),
                )
                    .toList(),
              );
            }

            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _practiceCards.length,
                padding: const EdgeInsets.only(right: 4),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final card = _practiceCards[index];
                  return _PracticeCard(
                    data: card,
                    onTap: () => onCardTap(card),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.data,
    required this.onTap,
    this.width = 220,
  });

  final _PracticeCardData data;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: data.color,
              child: Icon(data.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
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
  const _ProgressSummary({
    required this.bestScore,
    required this.goalScore,
    required this.onEditGoal,
  });

  final int bestScore;
  final int goalScore;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final statWidgets = _progressStats
        .map(
          (stat) => _CircularStat(
        label: stat.label,
        value: stat.value,
        tests: stat.tests,
        color: stat.color,
      ),
    )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 500;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: statWidgets,
                  ),
                  const SizedBox(height: 14),
                  _BestScoreCard(
                    bestScore: bestScore,
                    goalScore: goalScore,
                    onEditGoal: onEditGoal,
                    isFullWidth: true,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: statWidgets,
                  ),
                ),
                const SizedBox(width: 12),
                _BestScoreCard(
                  bestScore: bestScore,
                  goalScore: goalScore,
                  onEditGoal: onEditGoal,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BestScoreCard extends StatelessWidget {
  const _BestScoreCard({
    required this.bestScore,
    required this.goalScore,
    required this.onEditGoal,
    this.isFullWidth = false,
  });

  final int bestScore;
  final int goalScore;
  final VoidCallback onEditGoal;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5FF)),
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
          Text(
            '$bestScore',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Goal: $goalScore',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onEditGoal,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              side: const BorderSide(color: Color(0xFF2557D6)),
            ),
            child: const Text('Set goal'),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: content);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 190),
      child: content,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 90,
            width: 90,
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
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$tests tests completed',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActiveTestCardData {
  const _ActiveTestCardData({
    required this.testId,
    required this.userTestId,
    required this.sectionIndex,
    required this.title,
    required this.status,
    required this.progress,
    required this.timeRemaining,
  });

  final int testId;
  final int userTestId;
  final int sectionIndex;
  final String title;
  final String status;
  final double progress;
  final String timeRemaining;
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

class _HomeData {
  const _HomeData({
    required this.activeTests,
    required this.completedTests,
  });

  final List<_ActiveTestCardData> activeTests;
  final List<_CompletedTestCardData> completedTests;
}
