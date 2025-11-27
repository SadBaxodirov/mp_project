import 'package:flutter/material.dart';

import '../../router.dart';

class TestPreviewInfoScreen extends StatelessWidget {
  const TestPreviewInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const points = <String>[
      'Explore Bluebook',
      'Take Your Time',
      'Assistive Technology',
      'No Device Lock',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get familiar before exam day.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final label = points[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(label),
                      subtitle: const Text(
                        'Learn what to expect and make sure your setup works.',
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: points.length,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRouter.preparingTestPreview,
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
