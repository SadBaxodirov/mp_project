import 'package:flutter/material.dart';
import '../../utils/DB_results.dart';

import '../../router.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> results = [];


  Future<void> _loadResults() async {
    final data = await _db.getResultsSums();
    setState(() {
      results = data;//[{total_score: float, start_time: string}, ...]
    });
    
  }

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Results Page Placeholder'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
              child: const Text('Go to Register'),
            ),
          ],
        ),
      ),
    );
  }
}
