import 'package:flutter/material.dart';

import '../../router.dart';
import '../../utils/DB_tests.dart';
import '../../widgets/main_navigation_bar.dart';

class TestList extends StatefulWidget {
  const TestList({super.key});

  @override
  State<TestList> createState() => _TestListState();
}

class _TestListState extends State<TestList> {
  final _db = DatabaseHelperTests.instance;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _savedTests = [];
  String _selectedFilter = _filters.first;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final data = await _db.getTests();
      setState(() => _savedTests = data);
    } catch (e) {
      debugPrint('Error loading saved tests: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LibraryTest> get _availableTests {
    final saved = _savedTests
        .map(
          (row) => _LibraryTest(
        id: (row['test_id'] as num).toInt(),
        title: 'Saved Test ${(row['test_id'] as num).toInt()}',
        tagline: 'Resume a locally saved attempt.',
        description: 'Loaded from offline storage on this device.',
        duration: 'Unknown duration',
        modules: 'Saved',
        difficulty: 'Saved',
        tags: const ['Saved'],
        ctaLabel: 'Resume',
      ),
    )
        .toList();
    return [..._tests, ...saved];
  }

  List<_LibraryTest> get _filteredTests {
    final query = _searchController.text.toLowerCase();
    return _availableTests.where((test) {
      final matchesFilter =
          _selectedFilter == 'All' || test.tags.contains(_selectedFilter);
      final matchesSearch = query.isEmpty ||
          test.title.toLowerCase().contains(query) ||
          test.description.toLowerCase().contains(query) ||
          test.tagline.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchField(
                controller: _searchController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters
                    .map(
                      (label) => ChoiceChip(
                    label: Text(label),
                    selected: _selectedFilter == label,
                    onSelected: (_) {
                      setState(() => _selectedFilter = label);
                    },
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredTests.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const _PreviewHeroCard();
                    }
                    final test = _filteredTests[index - 1];
                    return _TestCard(
                      test: test,
                      onStart: () => Navigator.pushNamed(
                        context,
                        AppRouter.test,
                        arguments: <int>[test.id ?? 0],
                      ),
                      onDetails: () => Navigator.pushNamed(
                        context,
                        AppRouter.testPreviewInfo,
                        arguments: {'title': test.title, 'tag': test.tags},
                      ),
                    );
                  },
                ),
              ),
            ],
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

class _PreviewHeroCard extends StatelessWidget {
  const _PreviewHeroCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.testPreviewInfo),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.visibility, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Preview (Demo)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore how the digital SAT looks and feels before a full test.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.onStart,
    required this.onDetails,
  });

  final _LibraryTest test;
  final VoidCallback onStart;
  final VoidCallback onDetails;

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
                    test.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(test.difficulty),
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: Color(0xFF2557D6),
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: const Color(0xFFE8EDFF),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              test.tagline,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Text(
              test.description,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoPill(icon: Icons.timer_outlined, label: test.duration),
                _InfoPill(icon: Icons.book_outlined, label: test.modules),
                _InfoPill(
                  icon: Icons.auto_graph,
                  label: test.lastTaken ?? 'Not taken yet',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStart,
                    child: Text(test.ctaLabel),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onDetails,
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTest {
  const _LibraryTest({
    required this.title,
    required this.tagline,
    required this.description,
    required this.duration,
    required this.modules,
    required this.difficulty,
    required this.tags,
    this.id,
    this.lastTaken,
    this.ctaLabel = 'Start',
  });

  final String title;
  final String tagline;
  final String description;
  final String duration;
  final String modules;
  final String difficulty;
  final List<String> tags;
  final int? id;
  final String? lastTaken;
  final String ctaLabel;
}

const _filters = [
  'All',
  'Reading & Writing',
  'Math',
  'Full Test',
  'Preview',
  'Saved'
];

const _tests = <_LibraryTest>[
  _LibraryTest(
    id: 1,
    title: 'Official SAT Practice Test 1',
    tagline: 'Full test - 2 modules - ~134 minutes',
    description:
    'Real SAT test from previous years, includes Reading & Writing + Math.',
    duration: '~134 min',
    modules: '2 modules',
    difficulty: 'Official',
    tags: ['Full Test', 'Reading & Writing', 'Math'],
    lastTaken: 'Last taken: 10 days ago - Score: 1290',
    ctaLabel: 'Resume',
  ),
  _LibraryTest(
    id: 2,
    title: 'Official SAT Practice Test 2',
    tagline: 'Full test - 2 modules - ~134 minutes',
    description: 'Great for a timed mock session with realistic pacing.',
    duration: '~134 min',
    modules: '2 modules',
    difficulty: 'Official',
    tags: ['Full Test'],
    lastTaken: 'Not taken yet',
  ),
  _LibraryTest(
    id: 3,
    title: 'Reading & Writing Skills Pack',
    tagline: 'RW focus - 1 module - 32 questions',
    description: 'Vocabulary, paired passages, and editing practice.',
    duration: '32 questions',
    modules: '1 module',
    difficulty: 'Mixed',
    tags: ['Reading & Writing'],
  ),
  _LibraryTest(
    id: 4,
    title: 'Math - Linear Equations Drill',
    tagline: 'Math focus - 1 module - 20 questions',
    description: 'Algebra-heavy practice with calculator allowed.',
    duration: '20 questions',
    modules: '1 module',
    difficulty: 'Mixed',
    tags: ['Math'],
  ),
  _LibraryTest(
    id: 5,
    title: 'Test Preview (Demo)',
    tagline: 'Preview - 1 short module',
    description: 'Quick untimed walkthrough of the digital SAT interface.',
    duration: '15 minutes',
    modules: 'Preview',
    difficulty: 'Easy',
    tags: ['Preview'],
  ),
];
