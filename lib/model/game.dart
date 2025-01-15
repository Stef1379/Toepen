import 'package:toepen_cardgame/database/firestore.dart';
import 'package:toepen_cardgame/model/player.dart';

class Game {
  FireStore fireStore = FireStore();

  String id = "";
  List<Player>? players = [];

  Game({required this.players}) {
    fireStore.addGame(this);
  }

  void addPlayer(String name) {
    Player player = Player(name: name, gameId: id);
    players?.add(player);
    fireStore.addPlayerToGame(id, player);
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
    fireStore.updatePlayerName(id, player);
    sortPlayers();
  }

  void sortPlayers() {
    players?.sort((a, b) => a.name.compareTo(b.name));
  }

  Map<String, dynamic> toJson() =>
      {
        'players': players,
      };
}
