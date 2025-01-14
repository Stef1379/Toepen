import 'package:toepen_cardgame/model/player.dart';
import 'package:uuid/uuid.dart';

class Game {
  String id = Uuid().v4();
  List<Player>? players = [];

  Game({required this.players});

  void addPlayer(String name) {
    players?.add(Player(name: name));
    sortPlayers();
  }

  void removePlayer(String id) {
    players?.removeWhere((player) => player.id == id);
  }

  Player? getPlayer(String id) {
    return players?.firstWhere((player) => player.id == id);
  }

  void updatePlayerName(String id, String name) {
    Player? player = getPlayer(id);
    if (player == null) return;
    player.name = name;
    sortPlayers();
  }

  void sortPlayers() {
    players?.sort((a, b) => a.name.compareTo(b.name));
  }
}
