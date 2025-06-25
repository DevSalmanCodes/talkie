import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

Future pickImage() async {
  try {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 400,
    );
    if (pickedImage == null) return;
    return File(pickedImage.path);
  } on PlatformException catch (e) {
         showToast("Failed to pick image ${e.message.toString()}");

  }
}

void showToast(String msg) {
  Fluttertoast.showToast(msg: msg);
}
