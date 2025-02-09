import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:toepen_cardgame/model/game.dart';
import 'package:toepen_cardgame/model/player.dart';
import 'package:toepen_cardgame/database/firestore.dart';
import 'package:toepen_cardgame/helpers/custom_audio_player.dart';
import 'package:toepen_cardgame/helpers/audio.dart';

class MyAppState extends ChangeNotifier {
  static final _audioSamples = [Audio.nuGaatHetGebeuren, Audio.deLul];
  static final _random = Random();

  Game currentGame = Game(players: []);

  @override
  void dispose() {
    CustomAudioPlayer.releaseAudio();
    super.dispose();
  }

  MyAppState() {
    saveGameToDatabase(currentGame);
  }

  void saveGameToDatabase(Game game) {
    FireStore().addGame(currentGame);
  }

  void createGame() {
    currentGame = Game(players: []);
    saveGameToDatabase(currentGame);
    notifyListeners();
  }

  void addPlayer(String name) async {
    currentGame.addPlayer(name);
    CustomAudioPlayer.playAudio(Audio.hallo);
    notifyListeners();
  }

  void addPlayers(List<String> names) {
    currentGame.addPlayers(names);
    notifyListeners();
  }

  void removePlayer(String id) {
    currentGame.removePlayer(id);
    notifyListeners();
  }

  void addScore(String id) {
    Player? player = currentGame.getPlayer(id);
    if (player == null) return;
    player.addScore();
    currentGame.checkWinner();
    if (player.isDead()) CustomAudioPlayer.playAudio(chooseRandomAudioSample());
    notifyListeners();
  }

  void subtractScore(String id) {
    Player? player = currentGame.getPlayer(id);
    if (player == null) return;
    player.subtractScore();
    notifyListeners();
  }

  void updatePlayerName(String id, String name) {
    currentGame.updatePlayerName(id, name);
    notifyListeners();
  }

  void sortPlayers() {
    currentGame.sortPlayers();
  }

  Audio chooseRandomAudioSample() {
    var randomIndex = _random.nextInt(_audioSamples.length);
    return _audioSamples[randomIndex];
  }
}