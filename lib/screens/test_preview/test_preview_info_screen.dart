import 'package:flutter/material.dart';

import '../../router.dart';

class TestPreviewInfoScreen extends StatefulWidget {
  const TestPreviewInfoScreen({super.key});

  @override
  State<TestPreviewInfoScreen> createState() => _TestPreviewInfoScreenState();
}

class _TestPreviewInfoScreenState extends State<TestPreviewInfoScreen> {
  bool _isTimed = true;
  String _mode = 'Full Test';
  String _difficulty = 'Mixed';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final title = (args?['title'] as String?) ?? 'SAT Practice Test 1';
    final subtitle = (args?['subtitle'] as String?) ?? 'Full-length mock exam';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              _SummaryCard(
                isTimed: _isTimed,
                onToggle: (value) => setState(() => _isTimed = value),
              ),
              const SizedBox(height: 16),
              const _BulletInfo(),
              const SizedBox(height: 16),
              _OptionsCard(
                mode: _mode,
                difficulty: _difficulty,
                onModeChanged: (value) =>
                    setState(() => _mode = value ?? _mode),
                onDifficultyChanged: (value) =>
                    setState(() => _difficulty = value ?? _difficulty),
              ),
              const SizedBox(height: 18),
              const Text(
                'Estimated completion: Today - 10:45-12:45',
                style: TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.preparingTestPreview,
                        arguments: {
                          'title': title,
                          'isTimed': _isTimed,
                          'mode': _mode,
                        },
                      ),
                      child: const Text('Start Test'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isTimed,
    required this.onToggle,
  });

  final bool isTimed;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _SummaryTile(
                  label: 'Total Time',
                  value: 'About 2h 14m',
                ),
                _SummaryTile(
                  label: 'Sections',
                  value: 'Reading & Writing + Math',
                ),
                _SummaryTile(
                  label: 'Questions',
                  value: '~98',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Timed'),
                    selected: isTimed,
                    onSelected: (_) => onToggle(true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Untimed'),
                    selected: !isTimed,
                    onSelected: (_) => onToggle(false),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletInfo extends StatelessWidget {
  const _BulletInfo();

  @override
  Widget build(BuildContext context) {
    const bullets = [
      (
        Icons.menu_book_outlined,
        'Explore the Test Format',
        'See how the real digital SAT looks and feels.'
      ),
      (
        Icons.timer_off_outlined,
        'Take Your Time',
        'You can pause between modules in practice mode.'
      ),
      (
        Icons.accessibility_new_outlined,
        'Assistive Technology',
        'Compatible with screen readers and adjustable font sizes.'
      ),
      (
        Icons.lock_open_outlined,
        'No Device Lock',
        'This practice app does not lock your device.'
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: bullets
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8EDFF),
                    child: Icon(
                      item.$1,
                      color: const Color(0xFF2557D6),
                    ),
                  ),
                  title: Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    item.$3,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.mode,
    required this.difficulty,
    required this.onModeChanged,
    required this.onDifficultyChanged,
  });

  final String mode;
  final String difficulty;
  final ValueChanged<String?> onModeChanged;
  final ValueChanged<String?> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: mode,
              decoration: const InputDecoration(
                labelText: 'Test Mode',
              ),
              items: const [
                DropdownMenuItem(value: 'Full Test', child: Text('Full Test')),
                DropdownMenuItem(
                    value: 'Only Reading & Writing',
                    child: Text('Only Reading & Writing')),
                DropdownMenuItem(value: 'Only Math', child: Text('Only Math')),
              ],
              onChanged: onModeChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
              ),
              items: const [
                DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                DropdownMenuItem(value: 'Easier', child: Text('Easier')),
                DropdownMenuItem(value: 'Harder', child: Text('Harder')),
              ],
              onChanged: onDifficultyChanged,
            ),
          ],
        ),
      ),
    );
  }
}
