import 'package:audioplayers/audioplayers.dart';

class CustomAudioPlayer {
  static final audioPlayer = AudioPlayer();

  static void playAudio(String audioPath) async {
    await audioPlayer.play(AssetSource(audioPath));
  }
}