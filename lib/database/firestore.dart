import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/game.dart';
import '../model/player.dart';

class FireStore {
  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addGame(Game game) async {
    await db.collection("games").add(game.toJson())
        .then((DocumentReference doc) => {
          game.id = doc.id,
          print('DocumentSnapshot added with ID: ${doc.id}')
        })
        .catchError((e) => {print("Error: $e")});
  }

  //TODO: Player is added everytime, even when just updating the name. So, before adding the player, check if the id is already present in the game's players collection
  Future<void> addPlayerToGame(String gameId, Player player) async {
    var gameCollection = db.collection("games").doc(gameId);

    await gameCollection.collection("players").add(player.toJson())
        .then((DocumentReference doc) => {
          player.id = doc.id,
          print("PLAYERNAME: ${player.name}"),
          print('DocumentSnapshot added with ID: ${doc.id}')
        })
        .catchError((e) => {print("Error: $e")});
  }

  Future<void> updatePlayerScore(String gameId, String playerId, int score) async {
    var gameCollection = db.collection("games").doc(gameId);
    var playerCollection = gameCollection.collection("players").doc(playerId);
    await playerCollection.update({"score": score});
  }
}