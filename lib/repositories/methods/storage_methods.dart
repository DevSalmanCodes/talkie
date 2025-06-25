import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:talkie/utils/methods.dart';
import 'package:uuid/uuid.dart';

enum UploadType { image, voice }

class StorageMethods {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadFileToFirebase({
    required File file,
    required UploadType type,
    String? path,
    required BuildContext context,
  }) async {
    try {
      String storagePath;
      SettableMetadata? metadata;
      if (type == UploadType.image) {
        if (path == null) {
          showToast('Image path is required.');
          return null;
        }
        final filename = file.path.split('/').last;
        storagePath = 'images/$path/$filename';
      } else {
        final uid = const Uuid().v4();
        storagePath = 'voices/$uid.m4a';
        metadata = SettableMetadata(contentType: 'audio/m4a');
      }
      TaskSnapshot res = await _storage
          .ref()
          .child(storagePath)
          .putFile(file, metadata);
      final url = await res.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      showToast(e.message.toString());
      return null;
    } catch (e) {
      showToast('Unexpected error: $e');
      return null;
    }
  }
}
