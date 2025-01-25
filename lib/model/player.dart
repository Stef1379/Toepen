import 'dart:async';

import 'package:toepen_cardgame/database/firestore.dart';

const povertyScore = 14;

class Player {
  Timer? _scoreUpdateTimer;
  FireStore fireStore = FireStore();

  String id = "";
  String gameId = "";
  String name;
  int score = 0;

  Player({required this.name, required this.gameId});

  bool hasPoverty() => score == povertyScore;
  bool isDead() => score > povertyScore;

  void addScore() {
    if (score < 99) {
      /* isDead must be checked before score++, because then the score will be updated to the actual score a player is pronounced dead. */
      bool isDead = this.isDead();
      score++;
      if (!isDead) _debouncedUpdate();
    }
  }

  void subtractScore() {
    if (score > 0) {
      score--;
      if (!isDead()) _debouncedUpdate();
    }
  }

  void _debouncedUpdate() {
    _scoreUpdateTimer?.cancel();

    _scoreUpdateTimer = Timer(Duration(milliseconds: 1000),
            () => fireStore.updatePlayerScore(gameId, id, score));
  }

  void dispose() {
    _scoreUpdateTimer?.cancel();
    if (_scoreUpdateTimer != null) fireStore.updatePlayerScore(gameId, id, score);
  }

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'score': score,
      };

  factory Player.fromMap(Map<String, dynamic> map, String id, String gameId) {
    Player player = Player(name: map['name'], gameId: gameId);
    player.id = id;
    player.score = map['score'];
    return player;
  }
}
