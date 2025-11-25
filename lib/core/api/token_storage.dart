import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const storage = FlutterSecureStorage();

  static Future<String?> getAccess() => storage.read(key: "access");
  static Future<String?> getRefresh() => storage.read(key: "refresh");

  static Future<void> saveTokens(String access, String refresh) async {
    await storage.write(key: "access", value: access);
    await storage.write(key: "refresh", value: refresh);
  }

  static Future<void> clear() async {
    await storage.delete(key: "access");
    await storage.delete(key: "refresh");
  }
}
