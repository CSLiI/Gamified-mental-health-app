
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JournalEncryptionHelper {
  static final JournalEncryptionHelper _instance = JournalEncryptionHelper._internal();
  factory JournalEncryptionHelper() => _instance;
  JournalEncryptionHelper._internal();

  final _storage = const FlutterSecureStorage();
  String? _key;
  static const String _keyStorageKey = 'journal_encryption_key';
  static const String _prefix = 'ENC::';

  /// Initialize the encryption helper by loading or generating a key
  Future<void> initialize() async {
    // Try to read existing key
    _key = await _storage.read(key: _keyStorageKey);
    
    // If no key exists, generate a new one
    if (_key == null) {
      _key = _generateRandomKey(32); // 32 bytes = 256 bits
      await _storage.write(key: _keyStorageKey, value: _key);
    }
  }

  String _generateRandomKey(int length) {
    final rand = Random.secure();
    final codes = List<int>.generate(length, (i) => rand.nextInt(256));
    return base64Encode(codes);
  }

  /// Encrypts text using XOR + Base64
  String encrypt(String plainText) {
    if (_key == null) return plainText; // Fallback if not initialized (though logs will show error)
    if (plainText.isEmpty) return plainText;

    try {
      final keyBytes = base64Decode(_key!);
      final textBytes = utf8.encode(plainText);
      
      final encryptedBytes = List<int>.generate(textBytes.length, (i) {
        return textBytes[i] ^ keyBytes[i % keyBytes.length];
      });

      return _prefix + base64Encode(encryptedBytes);
    } catch (e) {
      print('Encryption error: $e');
      return plainText;
    }
  }

  /// Decrypts text if it starts with the ENC:: prefix
  String decrypt(String encryptedText) {
    if (_key == null) return encryptedText;
    if (encryptedText.isEmpty) return encryptedText;
    
    // Only try to decrypt if it has our prefix
    if (!encryptedText.startsWith(_prefix)) return encryptedText;

    try {
      final actualEncoded = encryptedText.substring(_prefix.length);
      final encryptedBytes = base64Decode(actualEncoded);
      final keyBytes = base64Decode(_key!);
      
      final decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
        return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      });
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('Decryption error: $e');
      // Return original text if decryption fails so we don't crash
      return encryptedText;
    }
  }
}
