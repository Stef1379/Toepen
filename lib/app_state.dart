import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:toepen_cardgame/model/game.dart';
import 'package:toepen_cardgame/model/player.dart';
import 'package:toepen_cardgame/database/firestore.dart';

class MyAppState extends ChangeNotifier {
  Game currentGame = Game(players: []);

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

  void addPlayer(String name) {
    currentGame.addPlayer(name);
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
}