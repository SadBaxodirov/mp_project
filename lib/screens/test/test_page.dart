import 'package:flutter/material.dart';
import '../../utils/DB_tests.dart';
import '../../router.dart';

class TestPage extends StatefulWidget {
    final List<int> testList; 
  const TestPage({super.key, required this.testList});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> results = [];

  Future<void> _loadResults() async {
    final data = await _db.getTestsByIdList(widget.testList);
    setState(() {
      results = data;
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
            const Text('Test Page Placeholder'),
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
