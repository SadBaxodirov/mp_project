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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparing Preview'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_top_outlined,
              size: 64,
              color: Color(0xFF2557D6),
            ),
            SizedBox(height: 20),
            Text(
              'We\'re preparing your test preview.\nThis may take a minute.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
