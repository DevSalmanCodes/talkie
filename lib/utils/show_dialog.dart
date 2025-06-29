import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<bool> showAlertDialog(
  BuildContext context,
  String title,
  String content,
  String confirmButtonText,
) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return Platform.isIOS
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(confirmButtonText),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            )
          : AlertDialog(
              title:  Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    confirmButtonText,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
    },
  );
}
