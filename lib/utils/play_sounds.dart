import 'package:audioplayers/audioplayers.dart';

Future<void> playSound(String path) async {
  final AudioPlayer audioPlayer = AudioPlayer();
  await audioPlayer.play(AssetSource(path), volume: 0.7);
}
