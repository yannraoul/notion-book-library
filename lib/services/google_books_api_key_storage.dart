import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Optional Google Books API key, entered once in Settings — removes
/// `GoogleBooksApi`'s dependence on Google's shared, easily-exhausted
/// anonymous quota (NBLB-15 found it sitting at zero). Stored the same way
/// as the Notion token (`NotionTokenStorage`): platform keychain/keystore,
/// never plain prefs. Unlike the Notion token, this is genuinely optional —
/// Shelf still works on Open Library alone without one, just less
/// reliably.
class GoogleBooksApiKeyStorage {
  static const _key = 'google_books_api_key';

  final FlutterSecureStorage _storage;

  GoogleBooksApiKeyStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String key) => _storage.write(key: _key, value: key);

  Future<void> clear() => _storage.delete(key: _key);
}
