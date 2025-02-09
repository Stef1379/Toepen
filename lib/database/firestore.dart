import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:toepen_cardgame/auth/auth_service.dart';
import 'package:toepen_cardgame/model/game.dart';
import 'package:toepen_cardgame/model/player.dart';

class FireStore {
  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addGame(Game game) async {
    try {
      var userDoc = getUserDoc();
      var gameJson = game.toJson();

      final docRef = await userDoc.collection("games").add(gameJson);
      game.id = docRef.id;

      if (game.players != null) addPlayersToGame(game.id, game.players);
    } catch (e) {
      debugPrint("Error adding game: $e");
      await AuthService().signOut();
    }
  }

  Future<List<Game>> getGameHistory() async {
    var userDoc = getUserDoc();
    var gamesCollection = userDoc.collection("games");

    final gamesQuerySnapshot = await gamesCollection
        .orderBy("createdAt")
        .get();

    List<Game> games = [];
    for (var doc in gamesQuerySnapshot.docs) {
      final data = doc.data();

      List<Player> players = await getPlayersFromGame(doc.id);
      Player? winner = await tryGetPlayerFromGame(doc.id, data['winnerId']);
      Game game = Game.fromMap(data, doc.id, players, winner);
      games.add(game);
    }

    return games;
  }

  Future<void> deleteGame(String gameId) {
    var userDoc = getUserDoc();
    return userDoc.collection("games").doc(gameId).delete();
  }

  Future<Player?> tryGetPlayerFromGame(String gameId, String? playerId) async {
    if (playerId == null) return null;

    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    var playerDoc = await gameCollection.collection("players").doc(playerId).get();

    final data = playerDoc.data();

    if (data != null) return Player.fromMap(data, playerDoc.id, gameId);
    return null;
  }

  Future<List<Player>> getPlayersFromGame(String gameId) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    var playersCollection = gameCollection.collection("players");

    final playersQuerySnapshot = await playersCollection
        .orderBy("name")
        .get();

    return playersQuerySnapshot.docs.map((doc) {
      final data = doc.data();
      return Player.fromMap(data, doc.id, gameId);
    }).toList();
  }

  Future<void> addPlayerToGame(String gameId, Player player) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);

    await gameCollection.collection("players").add(player.toJson())
        .then((DocumentReference doc) => {
          player.id = doc.id,
          debugPrint('DocumentSnapshot added with ID: ${doc.id}')
        })
        .catchError((e) => {debugPrint("Error: $e")});
  }

  Future<void> addPlayersToGame(String gameId, List<Player>? players) async {
    if (players == null) return;

    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    var batch = db.batch();

    for (var player in players) {
      var playerDoc = gameCollection.collection("players").doc();
      player.id = playerDoc.id;
      batch.set(playerDoc, player.toJson());
    }

    try {
      await batch.commit();
      debugPrint('Successfully added ${players.length} players to the game with ID: $gameId');
    } catch (e) {
      debugPrint('Error adding players to game: $e');
      rethrow;
    }
  }

  Future<void> removePlayerFromGame(String gameId, String playerId) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    await gameCollection.collection("players").doc(playerId).delete();
  }

  Future<void> updatePlayerName(String playerId, Player player) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(player.gameId);
    var playerDoc = gameCollection.collection("players").doc(playerId);
    await playerDoc.update({"name": player.name});
  }

  Future<void> updatePlayerScore(String gameId, String playerId, int score) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    var playerCollection = gameCollection.collection("players").doc(playerId);
    await playerCollection.update({"score": score});
  }

  Future<void> updateGameWinnerAndIsCompleted(String gameId, bool isComplete, String winnerId) async {
    var userDoc = getUserDoc();
    var gameCollection = userDoc.collection("games").doc(gameId);
    await gameCollection.update({"isCompleted": isComplete, "winnerId": winnerId});
  }

  Future<void> deleteUserData(String userId) async {
    /*
    * Only delete the user document, because if all user data has to be deleted it will cost a lot of money.
    * Also, if a user wants their data removed completely they can request a data removal using the website (See Google Play Console).
    */
    await getUserDoc().delete();
  }


  DocumentReference<Map<String, dynamic>> getUserDoc() {
    if (FirebaseAuth.instance.currentUser == null) throw FirebaseAuthException(code: 'user-not-logged-in', message: "User not logged in");
    return db.collection("users").doc(FirebaseAuth.instance.currentUser?.uid);
  }
}