import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toepen_cardgame/database/firestore.dart';
import 'package:toepen_cardgame/model/player.dart';

class Game {
  FireStore fireStore = FireStore();

  String id = "";
  List<Player>? players = [];
  DateTime createdAt = DateTime.now();

  Game({required this.players});

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
        'createdAt': createdAt,
      };

  factory Game.fromMap(Map<String, dynamic> map) {
    Game game = Game(players: List<Player>.from(map['players'].map((x) => Player.fromMap(x))));
    game.createdAt = (map['createdAt'] as Timestamp).toDate();
    return game;
  }
}
