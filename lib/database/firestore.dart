import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/game.dart';
import '../model/player.dart';

class FireStore {
  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addGame(Game game) async {
    var userDoc = getUserDoc();
    await userDoc.collection("games").add(game.toJson())
        .then((DocumentReference doc) => {
          game.id = doc.id,
          print('DocumentSnapshot added with ID: ${doc.id}')
        })
        .catchError((e) => {print("Error: $e")});
  }

  Future<void> addPlayerToGame(String gameId, Player player) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);

    await gameCollection.collection("players").add(player.toJson())
        .then((DocumentReference doc) => {
          player.id = doc.id,
          print("PLAYERNAME: ${player.name}"),
          print('DocumentSnapshot added with ID: ${doc.id}')
        })
        .catchError((e) => {print("Error: $e")});
  }

  Future<void> updatePlayerName(String playerId, Player player) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(player.gameId);
    var playerCollection = gameCollection.collection("players").doc(playerId);
    await playerCollection.update({"name": player.name});
  }

  Future<void> updatePlayerScore(String gameId, String playerId, int score) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    var playerCollection = gameCollection.collection("players").doc(playerId);
    await playerCollection.update({"score": score});
  }

  DocumentReference<Map<String, dynamic>> getUserDoc() {
    if (FirebaseAuth.instance.currentUser == null) throw FirebaseAuthException(code: 'user-not-logged-in', message: "User not logged in");
    return db.collection("users").doc(FirebaseAuth.instance.currentUser?.uid);
  }
}