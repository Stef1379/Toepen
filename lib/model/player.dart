import '../database/firestore.dart';

const povertyScore = 14;

class Player {
  FireStore fireStore = FireStore();

  String id = "";
  String gameId = "";
  String name;
  int score = 0;

  Player({required this.name, required this.gameId});

  bool hasPoverty() {
    return score == povertyScore;
  }

  bool isDead() {
    return score > povertyScore;
  }

  void addScore() {
    if (score < 99) {
      bool isDead = this.isDead(); //isDead must be checked before score++, because then the score will be updated to the actual score a player is pronounced dead.
      score++;
      if (!isDead) fireStore.updatePlayerScore(gameId, id, score);
    }
  }

  void subtractScore() {
    if (score > 0) {
      score--;
      if (!isDead()) fireStore.updatePlayerScore(gameId, id, score);
    }
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
