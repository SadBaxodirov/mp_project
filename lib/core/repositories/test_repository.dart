import '../api/test_api.dart';
import '../models/test.dart';

class UserRepository {
  final TestApi api;

  UserRepository(this.api);

  Future<List<Test>> getAll() => api.getTests();
  Future<Test> get(int id) => api.getTest(id);
}
