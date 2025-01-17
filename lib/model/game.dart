import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toepen_cardgame/database/firestore.dart';
import 'package:toepen_cardgame/model/player.dart';

class Game {
  FireStore fireStore = FireStore();

  String id = "";
  List<Player>? players = [];
  DateTime createdAt = DateTime.now();
  Player? winner;
  bool isCompleted = false;

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
    players?.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void checkWinner() {
    final players = this.players;
    if (players == null) return;

    List<Player> deadPlayers = players.where((player) => player.isDead()).toList();
    if (deadPlayers.length == players.length - 1) {
      winner = players.firstWhere((player) => !player.isDead());
      isCompleted = true;
      if (winner != null) fireStore.updateGameWinnerAndIsCompleted(id, isCompleted, winner!.id);
    }
  }

  Map<String, dynamic> toJson() =>
      {
        'createdAt': createdAt,
        'isCompleted': isCompleted,
        if (winner != null) 'winner': winner?.id
      };

  factory Game.fromMap(Map<String, dynamic> map, String id, List<Player> players, Player? winner) {
    Game game = Game(players: players);
    game.id = id;
    game.createdAt = (map['createdAt'] as Timestamp).toDate();
    game.winner = winner;
    game.isCompleted = map['isCompleted'];
    return game;
  }
}
