enum Audio {
  benUWeer,
  nuGaatHetGebeuren,
  hallo,
  deLul,
  quack
}

extension AudioPath on Audio {
  String get path {
    switch (this) {
      case Audio.benUWeer:
        return 'ahh-daar-ben-u-weer.mp3';
      case Audio.nuGaatHetGebeuren:
        return 'nu-gaat-het-gebeuren-hoor-en-nee.mp3';
      case Audio.hallo:
        return 'hallo.mp3';
      case Audio.deLul:
        return 'de-lul-wegmisbruikers.mp3';
      case Audio.quack:
        return 'quack.mp3';
    }
  }

  int get id {
    switch (this) {
      case Audio.benUWeer:
        return 1;
      case Audio.nuGaatHetGebeuren:
        return 2;
      case Audio.hallo:
        return 3;
      case Audio.deLul:
        return 4;
      case Audio.quack:
        return 5;
    }
  }

  String get fullPath => 'assets/$path';
}