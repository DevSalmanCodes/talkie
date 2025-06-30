import 'package:permission_handler/permission_handler.dart';

Future<bool> requestMicrophonePermission() async {
  var status = await Permission.microphone.status;

  if (status.isGranted) {
    return true;
  }

  status = await Permission.microphone.request();

  if (status.isPermanentlyDenied) {
    openAppSettings(); // Optional
  }

  return status.isGranted;
}
