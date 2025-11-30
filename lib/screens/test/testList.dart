import 'package:flutter/material.dart';
import '../../utils/DB_tests.dart';
import '../../router.dart';

class TestList extends StatefulWidget {
  const TestList({super.key});

  @override
  State<TestList> createState() => _TestListState();
}

class _TestListState extends State<TestList> {
  final _db = DatabaseHelperTests.instance;
  List<Map<String, dynamic>> results = [];

  Future<void> _loadTests() async {
    final data = await _db.getTests();
    setState(() {
      results = data;
    });
    
  }

  @override
  void initState() {
    super.initState();
    _loadTests();
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
