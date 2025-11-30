import 'package:flutter/material.dart';

import '../../router.dart';

class PreparingTestPreviewScreen extends StatefulWidget {
  const PreparingTestPreviewScreen({super.key});

  @override
  State<PreparingTestPreviewScreen> createState() =>
      _PreparingTestPreviewScreenState();
}

class _PreparingTestPreviewScreenState
    extends State<PreparingTestPreviewScreen> {
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRouter.test,
      arguments: const <int>[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final title = (args?['title'] as String?) ?? "We're preparing your test";
    final isTimed = (args?['isTimed'] as bool?) ?? true;
    final mode = (args?['mode'] as String?) ?? 'Full Test';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 110,
                  width: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF2557D6)),
                    backgroundColor: Color(0xFFE8EDFF),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: Color(0xFF2557D6),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "This may take up to a minute. Don't close the app.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTimed ? 'Timed mode' : 'Untimed mode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Mode: $mode',
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Make sure your device is charged and notifications are muted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
