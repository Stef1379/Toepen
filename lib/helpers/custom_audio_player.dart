import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:toepen_cardgame/helpers/audio.dart';

class CustomAudioPlayer {
  static final Soundpool soundPool = Soundpool.fromOptions();
  static final Map<String, int> audioIds = {};

  static void loadAudio() async {
    for (final value in Audio.values) {
      String audioPath = value.fullPath;
      audioIds[value.name] = await soundPool.load(await rootBundle.load(audioPath));
    }
    print(audioIds.length);
  }

  static void playAudio(Audio audioEnum) async {
    int? audioId = audioIds[audioEnum.name];
    if (audioId != null) await soundPool.play(audioId);
  }

  static void releaseAudio() async {
    await soundPool.release();
  }
}