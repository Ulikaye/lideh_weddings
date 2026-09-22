import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads the bride/groom photos to Firebase Storage. Using `putData`
/// (raw bytes) rather than `putFile` so the exact same code path works on
/// web, Android and iOS - `image_picker` gives us bytes on every platform.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  /// [which] is 'bride' or 'groom'. Always overwrites the same path, since
  /// there's one active event per deployment - same behaviour as the
  /// original app replacing the single stored data-URL.
  Future<String> uploadEventPhoto(String which, Uint8List bytes) async {
    final ref = _storage.ref('event_images/$which.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
