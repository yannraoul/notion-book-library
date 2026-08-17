import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the Notion integration token in the platform keychain/keystore
/// — never plain prefs, per `planning/features/NBLM-1.md`'s security note.
class NotionTokenStorage {
  static const _key = 'notion_integration_token';

  final FlutterSecureStorage _storage;

  NotionTokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
